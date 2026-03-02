// Edge Function: dispatch-order — Smart Dispatch Engine
// Assigns orders to the best-fit rider using multi-factor scoring.
//
// Algorithm:
//   1. Fetch order + pickup coordinates
//   2. get_nearby_riders() → online riders within radius
//   3. Score each rider (proximity 40%, rating 30%, acceptance 15%, specialization 10%, availability 5%)
//   4. Assign to top scorer (priority window 60s)
//   5. Log all scores to dispatch_log
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/dispatch-order \
//     -H "Content-Type: application/json" \
//     -H "X-Admin-Key: <WOZ_ADMIN_KEY>" \
//     -d '{"order_id":"<uuid>"}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { checkRateLimit, rateLimitResponse } from "../_shared/rate_limit.ts";

const WOZ_ADMIN_KEY = Deno.env.get("WOZ_ADMIN_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";

// Dispatch constants
const PRIORITY_WINDOW_SECONDS = 60;
const DEFAULT_RADIUS_KM = 5.0;

// Score weights (from roadmap-vision-2026.md Section 3)
const W_PROXIMITY = 0.40;
const W_RATING = 0.30;
const W_ACCEPTANCE = 0.15;
const W_SPECIALIZATION = 0.10;
const W_AVAILABILITY = 0.05;

// Default pickup coordinates (Afragola Centro — WoZ area)
const DEFAULT_LAT = 40.9219;
const DEFAULT_LNG = 14.3094;

interface NearbyRider {
  rider_id: string;
  distance_km: number;
  heading: number | null;
  speed: number;
  avg_rating: number;
  acceptance_rate: number;
  lifetime_orders: number;
}

interface ScoreResult {
  rider_id: string;
  total_score: number;
  factors: Record<string, number>;
  distance_km: number;
}

function scoreRider(
  rider: NearbyRider,
  maxDistance: number,
  dealerRiderIds: Set<string>,
): ScoreResult {
  // Proximity: inverse normalized distance [0, 1]
  const proximity = maxDistance > 0
    ? Math.max(0, 1 - (rider.distance_km / maxDistance))
    : 1.0;

  // Rating: normalized 0–5 → 0–1
  const rating = Math.min((rider.avg_rating || 5.0) / 5.0, 1.0);

  // Acceptance rate: already 0–1
  const acceptance = Math.min(rider.acceptance_rate || 1.0, 1.0);

  // Specialization: 1.0 if rider has delivered from this dealer before
  const specialization = dealerRiderIds.has(rider.rider_id) ? 1.0 : 0.0;

  // Availability: placeholder (future: hours remaining in shift)
  const availability = 1.0;

  const total_score =
    W_PROXIMITY * proximity +
    W_RATING * rating +
    W_ACCEPTANCE * acceptance +
    W_SPECIALIZATION * specialization +
    W_AVAILABILITY * availability;

  return {
    rider_id: rider.rider_id,
    total_score: Math.round(total_score * 1000) / 1000,
    factors: {
      proximity: Math.round(proximity * 100) / 100,
      rating: Math.round(rating * 100) / 100,
      acceptance: Math.round(acceptance * 100) / 100,
      specialization,
      availability,
    },
    distance_km: Math.round(rider.distance_km * 100) / 100,
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // Auth via admin key
    const adminKey = req.headers.get("X-Admin-Key");
    if (!WOZ_ADMIN_KEY || adminKey !== WOZ_ADMIN_KEY) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Rate limit: 30 dispatches/min
    if (!checkRateLimit("dispatch-order", 30)) {
      return rateLimitResponse(corsHeaders);
    }

    const body = await req.json();
    const { order_id, exclude_rider_ids = [] } = body;

    if (!order_id) {
      return new Response(
        JSON.stringify({ error: "order_id required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const db = getServiceClient();

    // 1. Fetch order
    const { data: order, error: orderErr } = await db
      .from("orders")
      .select("*")
      .eq("id", order_id)
      .single();

    if (orderErr || !order) {
      return new Response(
        JSON.stringify({ error: "Order not found", details: orderErr?.message }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Determine pickup coordinates
    let pickupLat = DEFAULT_LAT;
    let pickupLng = DEFAULT_LNG;

    if (order.zone_id) {
      const { data: zone } = await db
        .from("hot_zones")
        .select("latitude, longitude")
        .eq("id", order.zone_id)
        .single();
      if (zone) {
        pickupLat = zone.latitude;
        pickupLng = zone.longitude;
      }
    }

    // 3. Get nearby riders via PostGIS RPC
    const { data: nearbyRiders, error: ridersErr } = await db.rpc(
      "get_nearby_riders",
      {
        p_lat: pickupLat,
        p_lng: pickupLng,
        p_radius_km: DEFAULT_RADIUS_KM,
      }
    );

    if (ridersErr) {
      console.error("get_nearby_riders error:", ridersErr);
    }

    // Filter out excluded riders (e.g., those who already rejected)
    const excludeSet = new Set(exclude_rider_ids as string[]);
    const candidates: NearbyRider[] = (nearbyRiders || []).filter(
      (r: NearbyRider) => !excludeSet.has(r.rider_id)
    );

    // 4. No candidates → broadcast
    if (candidates.length === 0) {
      await db.from("orders").update({
        dispatch_status: "broadcast",
        assigned_rider_id: null,
        priority_expires_at: null,
      }).eq("id", order_id);

      await db.from("dispatch_log").insert({
        order_id,
        action: "no_riders",
        factors_json: { radius_km: DEFAULT_RADIUS_KM, excluded: exclude_rider_ids },
      });

      return new Response(
        JSON.stringify({
          success: true,
          action: "broadcast",
          reason: "no_riders_available",
          radius_km: DEFAULT_RADIUS_KM,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Check specialization — has any candidate delivered from this dealer before?
    const dealerRiderIds = new Set<string>();
    if (order.dealer_contact_id) {
      // Find all relays for this dealer contact to determine specialization
      const { data: relays } = await db
        .from("order_relays")
        .select("rider_id")
        .eq("dealer_contact_id", order.dealer_contact_id)
        .eq("status", "picked_up");
      (relays || []).forEach((r: { rider_id: string }) =>
        dealerRiderIds.add(r.rider_id)
      );
    }

    // 6. Score all candidates
    const maxDistance = Math.max(
      ...candidates.map((r: NearbyRider) => r.distance_km),
      0.1
    );
    const scores: ScoreResult[] = candidates
      .map((r: NearbyRider) => scoreRider(r, maxDistance, dealerRiderIds))
      .sort((a: ScoreResult, b: ScoreResult) => b.total_score - a.total_score);

    // 7. Log all scores to dispatch_log
    const currentAttempt = (order.dispatch_attempts || 0) + 1;
    const logRows = scores.map((s: ScoreResult, i: number) => ({
      order_id,
      rider_id: s.rider_id,
      action: i === 0 ? "assigned" : "scored",
      score: s.total_score,
      factors_json: s.factors,
      distance_km: s.distance_km,
      attempt_number: currentAttempt,
    }));

    await db.from("dispatch_log").insert(logRows);

    // 8. Assign to top scorer
    const winner = scores[0];
    const priorityExpires = new Date(
      Date.now() + PRIORITY_WINDOW_SECONDS * 1000
    ).toISOString();

    await db.from("orders").update({
      assigned_rider_id: winner.rider_id,
      priority_expires_at: priorityExpires,
      dispatch_status: "assigned",
      dispatch_attempts: currentAttempt,
    }).eq("id", order_id);

    // 9. Create notification for the assigned rider
    await db.from("notifications").insert({
      rider_id: winner.rider_id,
      title: "Nuovo ordine assegnato!",
      body: `${order.restaurant_name || "Ordine"} → ${order.customer_address || "Consegna"} (€${(order.base_earning || 0).toFixed(2)})`,
      type: "new_order",
      metadata: {
        order_id,
        score: winner.total_score,
        distance_km: winner.distance_km,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        action: "assigned",
        assigned_rider_id: winner.rider_id,
        score: winner.total_score,
        factors: winner.factors,
        distance_km: winner.distance_km,
        priority_expires_at: priorityExpires,
        candidates_count: candidates.length,
        attempt_number: currentAttempt,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Dispatch error:", error);
    return new Response(
      JSON.stringify({
        error: "Dispatch failed",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
