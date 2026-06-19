// ============================================================================
// EDGE FUNCTION: receive-yamamay-order
// ============================================================================
// Riceve webhook da e-commerce Yamamay, calcola distanza e compenso,
// inserisce ordine in Supabase per assegnazione rider.
//
// Endpoint: POST /functions/v1/receive-yamamay-order
// Auth: X-Webhook-Secret header
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_SECRET = Deno.env.get("YAMAMAY_WEBHOOK_SECRET") || "default_secret_change_me";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-webhook-secret",
};

// ============================================================================
// HAVERSINE FORMULA - Calcola distanza tra due punti GPS (in km)
// ============================================================================
function haversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) *
    Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// ============================================================================
// GEOCODE SEMPLICE - MVP con lookup manuale zone Napoli
// ============================================================================
// Per MVP: mappa zone comuni di Napoli con coordinate approssimate
const NAPOLI_ZONES: Record<string, { lat: number; lng: number }> = {
  "centro": { lat: 40.8518, lng: 14.2681 },      // Centro Storico
  "vomero": { lat: 40.8467, lng: 14.2380 },      // Vomero
  "chiaia": { lat: 40.8303, lng: 14.2387 },      // Chiaia
  "posillipo": { lat: 40.8047, lng: 14.2033 },   // Posillipo
  "fuorigrotta": { lat: 40.8258, lng: 14.1857 }, // Fuorigrotta
  "default": { lat: 40.8518, lng: 14.2681 },     // Fallback centro
};

function geocodeAddress(address: string): { lat: number; lng: number } {
  // MVP: estrai zona dall'indirizzo e usa coordinate approssimate
  const lowerAddress = address.toLowerCase();

  for (const [zone, coords] of Object.entries(NAPOLI_ZONES)) {
    if (lowerAddress.includes(zone)) {
      return coords;
    }
  }

  // TODO FASE 2: Integrare Google Maps Geocoding API
  // const response = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${GOOGLE_MAPS_KEY}`);
  // const data = await response.json();
  // return { lat: data.results[0].geometry.location.lat, lng: data.results[0].geometry.location.lng };

  // Fallback: usa centro Napoli
  console.warn(`⚠️ Zona non riconosciuta in indirizzo: ${address}. Uso coordinate centro Napoli.`);
  return NAPOLI_ZONES.default;
}

// ============================================================================
// MAIN HANDLER
// ============================================================================
serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    // 1. Validate webhook secret
    const webhookSecret = req.headers.get("X-Webhook-Secret");
    if (webhookSecret !== WEBHOOK_SECRET) {
      console.error("❌ Invalid webhook secret");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Parse request body
    const payload = await req.json();
    const {
      order_id,          // ID ordine Yamamay
      dealer_id,         // UUID dealer in tabella dealers (Yamamay)
      customer_name,
      customer_phone,
      customer_address,
      items,             // Array prodotti (opzionale per rider app)
      total_amount,      // Importo totale (opzionale)
    } = payload;

    // 3. Validate required fields
    if (!dealer_id || !customer_name || !customer_address) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields",
          required: ["dealer_id", "customer_name", "customer_address"],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Fetch dealer info (per location e nome)
    const { data: dealer, error: dealerError } = await supabase
      .from("dealers")
      .select("id, business_name, address, location")
      .eq("id", dealer_id)
      .eq("status", "active")
      .single();

    if (dealerError || !dealer) {
      console.error("❌ Dealer not found:", dealerError);
      return new Response(
        JSON.stringify({ error: "Dealer not found or inactive" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Estrai coordinate dealer
    // Supabase restituisce POINT come "(lng,lat)" o "POINT(lng lat)"
    let dealerLng: number;
    let dealerLat: number;

    const locationStr = String(dealer.location);
    const wktMatch = locationStr.match(/POINT\(([0-9.-]+)\s+([0-9.-]+)\)/);
    const tupleMatch = locationStr.match(/\(([0-9.-]+),([0-9.-]+)\)/);

    if (wktMatch) {
      dealerLng = parseFloat(wktMatch[1]);
      dealerLat = parseFloat(wktMatch[2]);
    } else if (tupleMatch) {
      dealerLng = parseFloat(tupleMatch[1]);
      dealerLat = parseFloat(tupleMatch[2]);
    } else {
      console.error("❌ Invalid dealer location format:", dealer.location);
      return new Response(
        JSON.stringify({ error: "Invalid dealer location" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Geocode customer address
    const customerCoords = geocodeAddress(customer_address);

    // 7. Calcola distanza Haversine con moltiplicatore urbano (1.3x per strade tortuose)
    const distanceStraight = haversineDistance(
      dealerLat,
      dealerLng,
      customerCoords.lat,
      customerCoords.lng
    );
    const distanceKm = Math.round(distanceStraight * 1.3 * 100) / 100; // × 1.3 e arrotonda a 2 decimali

    // 8. Calcola base earning (1.50€/km, minimo 3.00€)
    const RATE_PER_KM = 1.50;
    const MIN_GUARANTEE = 3.00;
    const baseEarning = Math.max(distanceKm * RATE_PER_KM, MIN_GUARANTEE);

    // 9. Costruisci ordine per Supabase
    const newOrder = {
      id: crypto.randomUUID(),
      restaurant_name: dealer.business_name,
      restaurant_address: dealer.address,
      customer_name: customer_name,
      customer_phone: customer_phone || null,
      customer_address: customer_address,
      distance_km: distanceKm,
      base_earning: Math.round(baseEarning * 100) / 100,
      bonus_earning: 0,
      tip_amount: 0,
      rush_multiplier: 1.0,
      min_guarantee: MIN_GUARANTEE,
      status: "pending",
      source: "yamamay_webhook",
      dealer_contact_id: dealer_id,
      created_at: new Date().toISOString(),
    };

    // 10. Insert ordine in Supabase
    const { data: insertedOrder, error: insertError } = await supabase
      .from("orders")
      .insert([newOrder])
      .select()
      .single();

    if (insertError) {
      console.error("❌ Insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to create order", details: insertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`✅ Order created: ${insertedOrder.id} | ${distanceKm}km | €${baseEarning}`);

    // 11. Success response
    return new Response(
      JSON.stringify({
        success: true,
        order_id: insertedOrder.id,
        distance_km: distanceKm,
        base_earning: baseEarning,
        restaurant_name: dealer.business_name,
        yamamay_order_id: order_id,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Unhandled error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
