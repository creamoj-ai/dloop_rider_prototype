// Edge Function: stripe-webhook — Handle Stripe Connect events
// Listens for:
//   - checkout.session.completed → update order/relay payment status
//   - payment_intent.succeeded → confirm payment
//   - payment_intent.payment_failed → mark as failed
//   - account.updated → track dealer onboarding progress
//
// Setup in Stripe Dashboard:
//   Developers → Webhooks → Add endpoint
//   URL: https://<project>.supabase.co/functions/v1/stripe-webhook
//   Events: checkout.session.completed, payment_intent.succeeded,
//           payment_intent.payment_failed, account.updated
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";

const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = await req.text();
    const sig = req.headers.get("stripe-signature");

    // Verify webhook signature if secret is configured
    let event: StripeEvent;
    if (STRIPE_WEBHOOK_SECRET && sig) {
      event = await verifyWebhookSignature(body, sig, STRIPE_WEBHOOK_SECRET);
    } else {
      // In test mode / development, accept without verification
      event = JSON.parse(body);
      console.warn("⚠️ Webhook signature verification skipped (no STRIPE_WEBHOOK_SECRET)");
    }

    console.log(`📩 Stripe event: ${event.type} [${event.id}]`);

    const db = getServiceClient();

    switch (event.type) {
      case "checkout.session.completed":
        await handleCheckoutCompleted(db, event.data.object);
        break;

      case "payment_intent.succeeded":
        await handlePaymentSucceeded(db, event.data.object);
        break;

      case "payment_intent.payment_failed":
        await handlePaymentFailed(db, event.data.object);
        break;

      case "account.updated":
        await handleAccountUpdated(db, event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("stripe-webhook error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
});

// --- Event Handlers ---

async function handleCheckoutCompleted(
  db: ReturnType<typeof getServiceClient>,
  session: Record<string, unknown>
) {
  const paymentIntentId = session.payment_intent as string;
  if (!paymentIntentId) return;

  console.log(`✅ Checkout completed: PI=${paymentIntentId}`);

  // Update order
  const { error: orderErr } = await db
    .from("orders")
    .update({ stripe_payment_status: "succeeded" })
    .eq("stripe_payment_intent_id", paymentIntentId);

  if (orderErr) console.error("Order update error:", orderErr);

  // Update relay
  const { error: relayErr } = await db
    .from("order_relays")
    .update({ payment_status: "paid" })
    .eq("stripe_payment_intent_id", paymentIntentId);

  if (relayErr) console.error("Relay update error:", relayErr);
}

async function handlePaymentSucceeded(
  db: ReturnType<typeof getServiceClient>,
  paymentIntent: Record<string, unknown>
) {
  const piId = paymentIntent.id as string;
  const metadata = (paymentIntent.metadata ?? {}) as Record<string, string>;
  const transferId = (paymentIntent.transfer as Record<string, unknown>)?.id as string
    ?? paymentIntent.latest_charge as string;

  console.log(`✅ Payment succeeded: PI=${piId}, transfer=${transferId}`);

  // Update order
  const updateData: Record<string, unknown> = {
    stripe_payment_status: "succeeded",
  };
  if (transferId) {
    updateData.stripe_transfer_id = transferId;
  }

  if (metadata.order_id) {
    await db.from("orders").update(updateData).eq("id", metadata.order_id);
  } else {
    await db.from("orders").update(updateData).eq("stripe_payment_intent_id", piId);
  }

  // Update relay
  if (metadata.relay_id) {
    await db
      .from("order_relays")
      .update({ payment_status: "paid" })
      .eq("id", metadata.relay_id);
  }

  // Create fee_audit record
  if (metadata.order_id) {
    const totalCents = (paymentIntent.amount as number) ?? 0;
    const appFeeCents = (paymentIntent.application_fee_amount as number) ?? 0;
    // Estimate Stripe fees (Italy/EEA 2026): 1.5% + €0.25 transaction + 0.25% + €0.10 payout
    const stripeFee = Math.round(totalCents * 0.015 + 25 + totalCents * 0.0025 + 10);

    // Look up dealer tier
    let dealerTier: string | null = null;
    if (metadata.dealer_contact_id) {
      const { data: tierData } = await db
        .rpc("get_dealer_tier", { p_dealer_contact_id: metadata.dealer_contact_id });
      dealerTier = tierData as string | null;
    }

    // Look up rider_id from order
    let riderId: string | null = null;
    if (metadata.order_id) {
      const { data: orderData } = await db
        .from("orders")
        .select("rider_id")
        .eq("id", metadata.order_id)
        .maybeSingle();
      riderId = orderData?.rider_id as string | null;
    }

    const { error: feeErr } = await db.from("fee_audit").insert({
      order_id: metadata.order_id,
      relay_id: metadata.relay_id || null,
      dealer_contact_id: metadata.dealer_contact_id || null,
      rider_id: riderId,
      total_amount_cents: totalCents,
      dealer_amount_cents: totalCents - appFeeCents,
      platform_fee_cents: appFeeCents,
      stripe_fee_cents: stripeFee,
      dealer_tier: dealerTier,
      per_order_fee_applied: dealerTier === "starter",
    });

    if (feeErr) {
      console.error("Fee audit insert error:", feeErr);
    } else {
      console.log(`📊 Fee audit created: order=${metadata.order_id}, total=${totalCents}, platform=${appFeeCents}`);
    }
  }
}

async function handlePaymentFailed(
  db: ReturnType<typeof getServiceClient>,
  paymentIntent: Record<string, unknown>
) {
  const piId = paymentIntent.id as string;
  const metadata = (paymentIntent.metadata ?? {}) as Record<string, string>;
  const failureMessage = (paymentIntent.last_payment_error as Record<string, unknown>)?.message as string ?? "unknown";

  console.error(`❌ Payment failed: PI=${piId}, reason=${failureMessage}`);

  // Update order
  await db
    .from("orders")
    .update({ stripe_payment_status: "failed" })
    .eq("stripe_payment_intent_id", piId);

  // Update relay
  if (metadata.relay_id) {
    await db
      .from("order_relays")
      .update({ payment_status: "failed" })
      .eq("id", metadata.relay_id);
  }
}

async function handleAccountUpdated(
  db: ReturnType<typeof getServiceClient>,
  account: Record<string, unknown>
) {
  const accountId = account.id as string;
  const chargesEnabled = account.charges_enabled as boolean;
  const payoutsEnabled = account.payouts_enabled as boolean;
  const detailsSubmitted = account.details_submitted as boolean;

  let status = "pending";
  if (chargesEnabled && payoutsEnabled) {
    status = "complete";
  } else if (detailsSubmitted) {
    status = "incomplete";
  }

  console.log(`🏪 Account updated: ${accountId} → charges=${chargesEnabled}, payouts=${payoutsEnabled}, status=${status}`);

  const updateData: Record<string, unknown> = {
    stripe_onboarding_status: status,
    stripe_charges_enabled: chargesEnabled,
    stripe_payouts_enabled: payoutsEnabled,
  };

  if (status === "complete") {
    updateData.stripe_onboarded_at = new Date().toISOString();
  }

  const { error } = await db
    .from("dealer_platforms")
    .update(updateData)
    .eq("stripe_account_id", accountId);

  if (error) {
    console.error("Dealer platform update error:", error);
  }
}

// --- Webhook Signature Verification ---

async function verifyWebhookSignature(
  payload: string,
  sigHeader: string,
  secret: string
): Promise<StripeEvent> {
  const parts = sigHeader.split(",").reduce((acc, part) => {
    const [key, value] = part.split("=");
    acc[key] = value;
    return acc;
  }, {} as Record<string, string>);

  const timestamp = parts["t"];
  const expectedSig = parts["v1"];

  if (!timestamp || !expectedSig) {
    throw new Error("Invalid Stripe signature header");
  }

  // Check timestamp tolerance (5 minutes)
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - parseInt(timestamp)) > 300) {
    throw new Error("Webhook timestamp too old");
  }

  // Compute expected signature
  const signedPayload = `${timestamp}.${payload}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(signedPayload)
  );

  const computedSig = Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  if (computedSig !== expectedSig) {
    throw new Error("Webhook signature verification failed");
  }

  return JSON.parse(payload);
}

// --- Types ---

interface StripeEvent {
  id: string;
  type: string;
  data: {
    object: Record<string, unknown>;
  };
}
