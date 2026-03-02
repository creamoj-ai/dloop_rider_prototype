// Edge Function: stripe-link — Create Stripe Destination Charge for customer
// V2: Uses Stripe Connect Destination Charges (split payment to dealer Express Account).
// Falls back to simple Payment Link if dealer has no Stripe account.
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/stripe-link \
//     -H "Content-Type: application/json" \
//     -H "X-Admin-Key: <WOZ_ADMIN_KEY>" \
//     -d '{"relay_id":"<uuid>","amount":12.50,"description":"1x Margherita + consegna","customer_phone":"+393331234567","platform_fee":1.00}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { sendTemplateOrText, WA_TEMPLATES } from "../whatsapp-webhook/whatsapp_api.ts";
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

  try {
    const adminKey = req.headers.get("X-Admin-Key");
    if (!WOZ_ADMIN_KEY || adminKey !== WOZ_ADMIN_KEY) {
      return json({ error: "Unauthorized" }, 401);
    }

    // Rate limit: 20 links/min
    if (!checkRateLimit("stripe-link", 20)) {
      return rateLimitResponse(corsHeaders);
    }

    const body = await req.json();
    const {
      relay_id,
      amount,
      description,
      customer_phone,
      order_id,
      platform_fee,        // DLOOP fee in EUR (e.g. 1.00)
      dealer_contact_id,   // optional: override relay's dealer
    } = body;

    if (!relay_id || !amount) {
      return json({
        error: "Missing required fields",
        required: ["relay_id", "amount"],
      }, 400);
    }

    if (typeof amount !== "number" || amount <= 0) {
      return json({ error: "amount must be a positive number" }, 400);
    }

    if (!STRIPE_SECRET_KEY) {
      return json({ error: "STRIPE_SECRET_KEY not configured" }, 500);
    }

    const db = getServiceClient();
    const amountCents = Math.round(amount * 100);
    const feeCents = Math.round((platform_fee ?? 0) * 100);

    // Step 1: Look up dealer's Stripe Express Account
    let stripeAccountId: string | null = null;
    let effectiveDealerId = dealer_contact_id;

    if (!effectiveDealerId) {
      // Get dealer from relay
      const { data: relay } = await db
        .from("order_relays")
        .select("dealer_contact_id")
        .eq("id", relay_id)
        .single();
      effectiveDealerId = relay?.dealer_contact_id;
    }

    if (effectiveDealerId) {
      const { data: platform } = await db
        .from("dealer_platforms")
        .select("stripe_account_id, stripe_charges_enabled")
        .eq("contact_id", effectiveDealerId)
        .eq("is_active", true)
        .not("stripe_account_id", "is", null)
        .maybeSingle();

      if (platform?.stripe_account_id && platform?.stripe_charges_enabled) {
        stripeAccountId = platform.stripe_account_id;
      }
    }

    let paymentUrl: string;
    let paymentIntentId: string | null = null;
    let stripeObjectId: string;
    let chargeType: string;

    if (stripeAccountId && feeCents >= 0) {
      // ===== DESTINATION CHARGE (Connect) =====
      // Creates a Checkout Session with Destination Charge
      chargeType = "destination_charge";

      const sessionParams = new URLSearchParams({
        mode: "payment",
        "line_items[0][price_data][currency]": "eur",
        "line_items[0][price_data][unit_amount]": amountCents.toString(),
        "line_items[0][price_data][product_data][name]": description || "Ordine DLOOP",
        "line_items[0][quantity]": "1",
        "payment_intent_data[transfer_data][destination]": stripeAccountId,
        "payment_intent_data[metadata][relay_id]": relay_id,
        "payment_intent_data[metadata][order_id]": order_id || "",
        "payment_intent_data[metadata][dealer_contact_id]": effectiveDealerId || "",
        success_url: "https://dloop.it/grazie?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "https://dloop.it/pagamento-annullato",
      });

      // Platform fee (DLOOP keeps this)
      if (feeCents > 0) {
        sessionParams.set(
          "payment_intent_data[application_fee_amount]",
          feeCents.toString()
        );
      }

      const sessionRes = await fetch("https://api.stripe.com/v1/checkout/sessions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: sessionParams.toString(),
      });

      const sessionData = await sessionRes.json();
      if (!sessionRes.ok) {
        console.error("Stripe session error:", sessionData);
        return json({
          error: "Stripe Checkout Session failed",
          details: sessionData.error?.message,
        }, 502);
      }

      paymentUrl = sessionData.url;
      paymentIntentId = sessionData.payment_intent;
      stripeObjectId = sessionData.id;
    } else {
      // ===== FALLBACK: Simple Payment Link (no Connect) =====
      chargeType = "payment_link";

      const priceParams = new URLSearchParams({
        unit_amount: amountCents.toString(),
        currency: "eur",
        "product_data[name]": description || "Ordine DLOOP",
      });

      const priceRes = await fetch("https://api.stripe.com/v1/prices", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: priceParams.toString(),
      });

      const priceData = await priceRes.json();
      if (!priceRes.ok) {
        return json({ error: "Stripe price creation failed", details: priceData.error?.message }, 502);
      }

      const linkParams = new URLSearchParams({
        "line_items[0][price]": priceData.id,
        "line_items[0][quantity]": "1",
        "metadata[relay_id]": relay_id,
        "metadata[order_id]": order_id || "",
        "after_completion[type]": "redirect",
        "after_completion[redirect][url]": "https://dloop.it/grazie",
      });

      const linkRes = await fetch("https://api.stripe.com/v1/payment_links", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: linkParams.toString(),
      });

      const linkData = await linkRes.json();
      if (!linkRes.ok) {
        return json({ error: "Stripe link creation failed", details: linkData.error?.message }, 502);
      }

      paymentUrl = linkData.url;
      stripeObjectId = linkData.id;
    }

    // Step 3: Update relay with payment info
    const relayUpdate: Record<string, unknown> = {
      stripe_payment_link: paymentUrl,
      payment_status: "sent",
      estimated_amount: amount,
    };
    if (paymentIntentId) {
      relayUpdate.stripe_payment_intent_id = paymentIntentId;
    }

    const { error: updateError } = await db
      .from("order_relays")
      .update(relayUpdate)
      .eq("id", relay_id);

    if (updateError) {
      console.error("Relay update error:", updateError);
    }

    // Step 4: Update order with Stripe info
    if (order_id && paymentIntentId) {
      await db
        .from("orders")
        .update({
          stripe_payment_intent_id: paymentIntentId,
          stripe_amount_cents: amountCents,
          stripe_application_fee_cents: feeCents,
          stripe_payment_status: "processing",
        })
        .eq("id", order_id);
    }

    // Step 5 (optional): Send payment link to customer via WhatsApp (template with fallback)
    let waMessageId: string | null = null;
    if (customer_phone) {
      const fallbackMessage =
        `Ciao! Ecco il link per pagare il tuo ordine DLOOP:\n` +
        `${paymentUrl}\n\n` +
        `Importo: €${amount.toFixed(2)}\n` +
        `Grazie per aver scelto DLOOP!`;

      const waResult = await sendTemplateOrText(
        customer_phone,
        WA_TEMPLATES.PAGAMENTO,
        [`€${amount.toFixed(2)}`, paymentUrl],
        fallbackMessage
      );
      if (waResult.success) {
        waMessageId = waResult.messageId ?? null;
      } else {
        console.error("WhatsApp send failed (non-blocking):", waResult.error);
      }
    }

    return json({
      success: true,
      relay_id,
      charge_type: chargeType,
      payment_url: paymentUrl,
      stripe_object_id: stripeObjectId,
      payment_intent_id: paymentIntentId,
      dealer_stripe_account: stripeAccountId,
      application_fee: platform_fee ?? 0,
      wa_message_id: waMessageId,
    });
  } catch (error) {
    console.error("stripe-link error:", error);
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
