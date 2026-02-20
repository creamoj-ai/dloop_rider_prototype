// Edge Function: stripe-onboard — Create Stripe Connect Account for dealer (controller properties)
// Handles:
//   POST { dealer_contact_id } → creates Express Account + returns onboarding link
//   POST { dealer_contact_id, refresh: true } → generates new Account Link for incomplete onboarding
//   GET  ?dealer_contact_id=<uuid> → returns onboarding status
//
// Auth: X-Admin-Key (WoZ operator)
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";

const WOZ_ADMIN_KEY = Deno.env.get("WOZ_ADMIN_KEY") ?? "";
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const DLOOP_BASE_URL = Deno.env.get("DLOOP_BASE_URL") ?? "https://dloop.it";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Auth
  const adminKey = req.headers.get("X-Admin-Key");
  if (!WOZ_ADMIN_KEY || adminKey !== WOZ_ADMIN_KEY) {
    return json({ error: "Unauthorized" }, 401);
  }

  if (!STRIPE_SECRET_KEY) {
    return json({ error: "STRIPE_SECRET_KEY not configured" }, 500);
  }

  const db = getServiceClient();

  try {
    // GET: check onboarding status
    if (req.method === "GET") {
      const url = new URL(req.url);
      const dealerContactId = url.searchParams.get("dealer_contact_id");
      if (!dealerContactId) {
        return json({ error: "Missing dealer_contact_id param" }, 400);
      }

      const { data, error } = await db
        .from("dealer_platforms")
        .select("stripe_account_id, stripe_onboarding_status, stripe_charges_enabled, stripe_payouts_enabled, stripe_onboarded_at")
        .eq("contact_id", dealerContactId)
        .eq("is_active", true)
        .not("stripe_account_id", "is", null)
        .maybeSingle();

      if (error) {
        return json({ error: "DB error", details: error.message }, 500);
      }

      if (!data || !data.stripe_account_id) {
        return json({ status: "not_started", dealer_contact_id: dealerContactId });
      }

      // Fetch fresh status from Stripe
      const account = await stripeGet(`/v1/accounts/${data.stripe_account_id}`);

      return json({
        dealer_contact_id: dealerContactId,
        stripe_account_id: data.stripe_account_id,
        status: data.stripe_onboarding_status,
        charges_enabled: account.charges_enabled ?? false,
        payouts_enabled: account.payouts_enabled ?? false,
        details_submitted: account.details_submitted ?? false,
      });
    }

    // POST: create account or refresh link
    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const body = await req.json();
    const { dealer_contact_id, refresh } = body;

    if (!dealer_contact_id) {
      return json({ error: "Missing dealer_contact_id" }, 400);
    }

    // Get dealer info
    const { data: dealer, error: dealerErr } = await db
      .from("rider_contacts")
      .select("id, name, phone")
      .eq("id", dealer_contact_id)
      .eq("contact_type", "dealer")
      .single();

    if (dealerErr || !dealer) {
      return json({ error: "Dealer not found", details: dealerErr?.message }, 404);
    }

    // Check existing platform entry with Stripe
    const { data: platform } = await db
      .from("dealer_platforms")
      .select("id, stripe_account_id, stripe_onboarding_status")
      .eq("contact_id", dealer_contact_id)
      .eq("is_active", true)
      .not("stripe_account_id", "is", null)
      .maybeSingle();

    let stripeAccountId = platform?.stripe_account_id;

    // Create Connect Account with controller properties (replaces legacy type: "express")
    if (!stripeAccountId) {
      const accountParams = new URLSearchParams({
        type: "express",
        country: "IT",
        "capabilities[card_payments][requested]": "true",
        "capabilities[transfers][requested]": "true",
        "metadata[dloop_dealer_id]": dealer_contact_id,
        "metadata[dealer_name]": dealer.name,
      });

      // Note: rider_contacts doesn't have email; Stripe will collect it during onboarding

      const account = await stripePost("/v1/accounts", accountParams);

      if (account.error) {
        return json({ error: "Stripe account creation failed", details: account.error.message }, 502);
      }

      stripeAccountId = account.id;

      // Save to DB
      if (platform) {
        // Update existing platform entry
        await db
          .from("dealer_platforms")
          .update({
            stripe_account_id: stripeAccountId,
            stripe_onboarding_status: "pending",
          })
          .eq("id", platform.id);
      } else {
        // Get rider_id for this dealer contact
        const { data: contact } = await db
          .from("rider_contacts")
          .select("rider_id")
          .eq("id", dealer_contact_id)
          .single();

        // Create new platform entry
        await db
          .from("dealer_platforms")
          .insert({
            rider_id: contact?.rider_id,
            contact_id: dealer_contact_id,
            platform_type: "custom",
            platform_name: `${dealer.name} - Stripe Connect`,
            stripe_account_id: stripeAccountId,
            stripe_onboarding_status: "pending",
          });
      }
    }

    // Generate Account Link for onboarding
    const linkParams = new URLSearchParams({
      account: stripeAccountId,
      refresh_url: `${DLOOP_BASE_URL}/stripe/refresh?dealer=${dealer_contact_id}`,
      return_url: `${DLOOP_BASE_URL}/stripe/complete?dealer=${dealer_contact_id}`,
      type: "account_onboarding",
    });

    const link = await stripePost("/v1/account_links", linkParams);

    if (link.error) {
      return json({ error: "Account link creation failed", details: link.error.message }, 502);
    }

    return json({
      success: true,
      dealer_contact_id,
      dealer_name: dealer.name,
      stripe_account_id: stripeAccountId,
      onboarding_url: link.url,
      expires_at: new Date(link.expires_at * 1000).toISOString(),
      is_new_account: !refresh && !platform?.stripe_account_id,
    });
  } catch (error) {
    console.error("stripe-onboard error:", error);
    return json({
      error: "Processing failed",
      details: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});

// --- Helpers ---

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function stripePost(path: string, params: URLSearchParams) {
  const res = await fetch(`https://api.stripe.com${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params.toString(),
  });
  return res.json();
}

async function stripeGet(path: string) {
  const res = await fetch(`https://api.stripe.com${path}`, {
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
    },
  });
  return res.json();
}
