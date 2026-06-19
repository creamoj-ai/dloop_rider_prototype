// ============================================================================
// EDGE FUNCTION: assign-rider
// ============================================================================
// Assegna un ordine a un rider manualmente (da Admin Panel).
// Aggiorna DB e invia push notification FCM all'app rider.
//
// Endpoint: POST /functions/v1/assign-rider
// Auth: X-Admin-Key header
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ADMIN_SECRET = Deno.env.get("ADMIN_SECRET") || "admin_secret_change_me";
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!; // Firebase Cloud Messaging legacy server key

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-admin-key",
};

// ============================================================================
// SEND FCM PUSH NOTIFICATION
// ============================================================================
async function sendFCMNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  try {
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Authorization": `key=${FCM_SERVER_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        to: fcmToken,
        priority: "high",
        notification: {
          title: title,
          body: body,
          sound: "default",
          badge: "1",
        },
        data: data,
      }),
    });

    const result = await response.json();

    if (result.success === 1) {
      console.log(`✅ FCM sent successfully to token ${fcmToken.slice(0, 10)}...`);
      return true;
    } else {
      console.error(`❌ FCM send failed:`, result);
      return false;
    }
  } catch (error) {
    console.error(`❌ FCM error:`, error);
    return false;
  }
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
    // 1. Validate admin key
    const adminKey = req.headers.get("X-Admin-Key");
    if (adminKey !== ADMIN_SECRET) {
      console.error("❌ Invalid admin key");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Parse request body
    const { order_id, rider_id } = await req.json();

    if (!order_id || !rider_id) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields",
          required: ["order_id", "rider_id"],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Fetch order info
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, restaurant_name, customer_address, distance_km, base_earning, status")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      console.error("❌ Order not found:", orderError);
      return new Response(
        JSON.stringify({ error: "Order not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (order.status !== "pending") {
      return new Response(
        JSON.stringify({ error: `Order already ${order.status}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Fetch rider FCM token
    const { data: fcmData, error: fcmError } = await supabase
      .from("fcm_tokens")
      .select("token")
      .eq("rider_id", rider_id)
      .eq("is_active", true)
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    const fcmToken = fcmData?.token;

    if (fcmError || !fcmToken) {
      console.warn(`⚠️ No FCM token found for rider ${rider_id}. Order assigned but no push sent.`);
    }

    // 5. Update order: assign rider
    const { error: updateError } = await supabase
      .from("orders")
      .update({
        assigned_rider_id: rider_id,
        rider_id: rider_id,  // Compatibility con app che usa rider_id
        status: "assigned",
        updated_at: new Date().toISOString(),
      })
      .eq("id", order_id);

    if (updateError) {
      console.error("❌ Update error:", updateError);
      return new Response(
        JSON.stringify({ error: "Failed to assign rider", details: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`✅ Order ${order_id} assigned to rider ${rider_id}`);

    // 6. Send FCM push notification
    let fcmSent = false;
    if (fcmToken) {
      fcmSent = await sendFCMNotification(
        fcmToken,
        "Nuovo Ordine Assegnato! 🎉",
        `${order.restaurant_name} → ${order.distance_km}km | €${order.base_earning}`,
        {
          order_id: order.id,
          type: "new_order",
          restaurant_name: order.restaurant_name,
          customer_address: order.customer_address,
          distance_km: order.distance_km.toString(),
          earning: order.base_earning.toString(),
        }
      );
    }

    // 7. Success response
    return new Response(
      JSON.stringify({
        success: true,
        order_id: order.id,
        rider_id: rider_id,
        fcm_sent: fcmSent,
        message: fcmSent
          ? "Order assigned and rider notified"
          : "Order assigned (no FCM token found)",
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
