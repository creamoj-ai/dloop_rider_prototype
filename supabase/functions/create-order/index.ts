// Edge Function: create-order — WoZ operator endpoint for manual order creation
// Inserts orders into the orders table using service_role (bypasses RLS).
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/create-order \
//     -H "Content-Type: application/json" \
//     -H "X-Admin-Key: <WOZ_ADMIN_KEY>" \
//     -d '{"rider_id":"<uuid>","restaurant_name":"Pizzeria Da Mario","restaurant_address":"Via Torino 25","customer_name":"Marco Rossi","customer_address":"Via Roma 15","distance_km":2.5}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { checkRateLimit, rateLimitResponse } from "../_shared/rate_limit.ts";

const WOZ_ADMIN_KEY = Deno.env.get("WOZ_ADMIN_KEY") ?? "";

// Rate per km — matches Order.defaultRatePerKm in Dart model
const RATE_PER_KM = 1.50;
const MIN_GUARANTEE = 3.00;

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // Authenticate via admin key
    const adminKey = req.headers.get("X-Admin-Key");
    if (!WOZ_ADMIN_KEY || adminKey !== WOZ_ADMIN_KEY) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Rate limit: 10 orders/min
    if (!checkRateLimit("create-order", 10)) {
      return rateLimitResponse(corsHeaders);
    }

    // Parse request body
    const body = await req.json();
    const {
      rider_id,
      restaurant_name,
      restaurant_address,
      customer_name,
      customer_address,
      distance_km,
      tip_amount,
      dealer_contact_id,
      estimated_amount,
    } = body;

    // Validate required fields
    if (!rider_id || !restaurant_name || !restaurant_address ||
        !customer_name || !customer_address || !distance_km) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields",
          required: ["rider_id", "restaurant_name", "restaurant_address",
                     "customer_name", "customer_address", "distance_km"],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (typeof distance_km !== "number" || distance_km <= 0) {
      return new Response(
        JSON.stringify({ error: "distance_km must be a positive number" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Calculate earnings
    const baseEarning = Math.max(distance_km * RATE_PER_KM, MIN_GUARANTEE);
    const orderId = crypto.randomUUID();

    // Insert using service client (bypasses RLS)
    const db = getServiceClient();
    const orderRow: Record<string, unknown> = {
      id: orderId,
      rider_id: rider_id,
      restaurant_name: restaurant_name,
      restaurant_address: restaurant_address,
      customer_name: customer_name,
      customer_address: customer_address,
      distance_km: distance_km,
      base_earning: baseEarning,
      bonus_earning: 0,
      tip_amount: tip_amount ?? 0,
      rush_multiplier: 1.0,
      hold_cost: 0,
      hold_minutes: 0,
      min_guarantee: MIN_GUARANTEE,
      status: "pending",
      source: "woz",
    };

    // Attach dealer if pre-assigned
    if (dealer_contact_id) {
      orderRow.dealer_contact_id = dealer_contact_id;
    }

    const { error } = await db.from("orders").insert(orderRow);

    if (error) {
      console.error("Insert error:", error);
      return new Response(
        JSON.stringify({ error: "Failed to create order", details: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Auto-create relay if dealer was pre-assigned
    let relayId: string | null = null;
    if (dealer_contact_id) {
      const relayRow = {
        order_id: orderId,
        rider_id: rider_id,
        dealer_contact_id: dealer_contact_id,
        status: "pending",
        relay_channel: "in_app",
        payment_status: "pending",
        estimated_amount: estimated_amount ?? null,
      };
      const { data: relayData, error: relayError } = await db
        .from("order_relays")
        .insert(relayRow)
        .select("id")
        .single();

      if (relayError) {
        console.error("Relay insert error (non-blocking):", relayError);
      } else {
        relayId = relayData?.id ?? null;
      }
    }

    // Auto-dispatch: trigger Smart Dispatch (fire-and-forget)
    let dispatchResult: Record<string, unknown> | null = null;
    try {
      const dispatchRes = await fetch(
        `${Deno.env.get("SUPABASE_URL")}/functions/v1/dispatch-order`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Admin-Key": WOZ_ADMIN_KEY,
            "Authorization": `Bearer ${Deno.env.get("SUPABASE_ANON_KEY") ?? ""}`,
          },
          body: JSON.stringify({ order_id: orderId }),
        }
      );
      dispatchResult = await dispatchRes.json();
      console.log("Auto-dispatch result:", dispatchResult);
    } catch (dispatchErr) {
      console.error("Auto-dispatch failed (non-blocking):", dispatchErr);
    }

    return new Response(
      JSON.stringify({
        success: true,
        order_id: orderId,
        base_earning: baseEarning,
        rider_id: rider_id,
        relay_id: relayId,
        dispatch: dispatchResult,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Create order error:", error);
    return new Response(
      JSON.stringify({
        error: "Processing failed",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
