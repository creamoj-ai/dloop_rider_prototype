// Edge Function: stripe-dashboard — Generate Express Dashboard login link for dealer
// Dealer can view transactions, payouts, and balance.
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/stripe-dashboard \
//     -H "Content-Type: application/json" \
//     -H "X-Admin-Key: <WOZ_ADMIN_KEY>" \
//     -H "Authorization: Bearer <anon_jwt>" \
//     -d '{"dealer_contact_id":"<uuid>"}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { checkRateLimit, rateLimitResponse } from "../_shared/rate_limit.ts";

const WOZ_ADMIN_KEY = Deno.env.get("WOZ_ADMIN_KEY") ?? "";
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // Auth
  const adminKey = req.headers.get("X-Admin-Key");
  if (!WOZ_ADMIN_KEY || adminKey !== WOZ_ADMIN_KEY) {
    return json({ error: "Unauthorized" }, 401);
  }

  // Rate limit: 20 requests/min
  if (!checkRateLimit("stripe-dashboard", 20)) {
    return rateLimitResponse(corsHeaders);
  }

  if (!STRIPE_SECRET_KEY) {
    return json({ error: "STRIPE_SECRET_KEY not configured" }, 500);
  }

  try {
    const { dealer_contact_id } = await req.json();
    if (!dealer_contact_id) {
      return json({ error: "Missing dealer_contact_id" }, 400);
    }

    const db = getServiceClient();

    // Look up dealer's Stripe account
    const { data: platform, error: dbErr } = await db
      .from("dealer_platforms")
      .select("stripe_account_id, contact_id")
      .eq("contact_id", dealer_contact_id)
      .eq("is_active", true)
      .not("stripe_account_id", "is", null)
      .maybeSingle();

    if (dbErr) {
      return json({ error: "DB error", details: dbErr.message }, 500);
    }

    if (!platform?.stripe_account_id) {
      return json({ error: "Dealer has no Stripe account" }, 404);
    }

    // Get dealer name
    const { data: dealer } = await db
      .from("rider_contacts")
      .select("name")
      .eq("id", dealer_contact_id)
      .single();

    // Create Express Dashboard login link
    const res = await fetch(
      `https://api.stripe.com/v1/accounts/${platform.stripe_account_id}/login_links`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );

    const linkData = await res.json();
    if (!res.ok) {
      return json({
        error: "Stripe login link failed",
        details: linkData.error?.message,
      }, 502);
    }

    return json({
      success: true,
      dealer_contact_id,
      dealer_name: dealer?.name ?? "Unknown",
      dashboard_url: linkData.url,
    });
  } catch (error) {
    console.error("stripe-dashboard error:", error);
    return json({
      error: "Processing failed",
      details: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
