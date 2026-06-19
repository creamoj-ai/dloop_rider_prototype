// ============================================================================
// EDGE FUNCTION: assign-rider
// ============================================================================
// Assegna un ordine a un rider manualmente (da Admin Panel).
// Aggiorna DB e invia push notification FCM all'app rider.
//
// Endpoint: POST /functions/v1/assign-rider
// Auth: X-Admin-Key header
//
// Usa Firebase Admin SDK (FCM v1 API) con Service Account JSON
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
import { encode as base64url } from "https://deno.land/std@0.168.0/encoding/base64url.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ADMIN_SECRET = Deno.env.get("ADMIN_SECRET") || "admin_secret_change_me";

// Firebase Service Account JSON (replaces legacy FCM_SERVER_KEY)
const FIREBASE_SERVICE_ACCOUNT_JSON = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-admin-key",
};

// ============================================================================
// FIREBASE ADMIN SDK - FCM v1 API
// ============================================================================

// Cache per access token (evita di rigenerarlo ad ogni richiesta)
let cachedAccessToken: string | null = null;
let tokenExpiresAt = 0;

/**
 * Importa una PEM private key come CryptoKey per firmare JWT RS256
 */
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemContents = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "")
    .replace(/\r/g, "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  return await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
}

/**
 * Genera un Google OAuth2 access token usando il Service Account JWT
 */
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Riutilizza token in cache se ancora valido (con 60s di margine)
  if (cachedAccessToken && now < tokenExpiresAt - 60) {
    return cachedAccessToken;
  }

  const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT_JSON);

  // Crea JWT header
  const header = { alg: "RS256", typ: "JWT" };

  // Crea JWT payload (claim set)
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600, // 1 ora
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  // Encode header e payload
  const encoder = new TextEncoder();
  const headerB64 = base64url(encoder.encode(JSON.stringify(header)));
  const payloadB64 = base64url(encoder.encode(JSON.stringify(payload)));
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Firma con la private key del Service Account
  const privateKey = await importPrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    encoder.encode(unsignedToken)
  );
  const signatureB64 = base64url(new Uint8Array(signature));
  const jwt = `${unsignedToken}.${signatureB64}`;

  // Scambia JWT per access token Google OAuth2
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errBody = await tokenResponse.text();
    throw new Error(`Failed to get access token: ${tokenResponse.status} - ${errBody}`);
  }

  const tokenData = await tokenResponse.json();
  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = now + tokenData.expires_in;

  console.log("✅ Firebase access token obtained successfully");
  return cachedAccessToken!;
}

// ============================================================================
// SEND FCM PUSH NOTIFICATION (Firebase Admin SDK - FCM v1 API)
// ============================================================================
async function sendFCMNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  try {
    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT_JSON);
    const projectId = serviceAccount.project_id;
    const accessToken = await getAccessToken();

    // FCM v1 API endpoint
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const message = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: data,
        android: {
          priority: "high" as const,
          notification: {
            sound: "default",
            channel_id: "dloop_orders",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    });

    if (response.ok) {
      const result = await response.json();
      console.log(`✅ FCM v1 sent successfully to token ${fcmToken.slice(0, 10)}... | Message ID: ${result.name}`);
      return true;
    } else {
      const errorBody = await response.text();
      console.error(`❌ FCM v1 send failed [${response.status}]:`, errorBody);
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

    // 4. Fetch rider FCM token from riders table
    const { data: riderData, error: riderError } = await supabase
      .from("riders")
      .select("fcm_token, name")
      .eq("id", rider_id)
      .single();

    const fcmToken = riderData?.fcm_token;

    if (riderError || !fcmToken) {
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
