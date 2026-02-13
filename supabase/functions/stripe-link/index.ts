// Edge Function: stripe-link — Create Stripe Payment Link for customer
// Creates an ad-hoc Stripe Payment Link and optionally sends it via WhatsApp.
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/stripe-link \
//     -H "Content-Type: application/json" \
//     -H "X-Admin-Key: <WOZ_ADMIN_KEY>" \
//     -d '{"relay_id":"<uuid>","amount":12.50,"description":"1x Margherita + consegna","customer_phone":"+393331234567"}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { sendWhatsAppMessage } from "../whatsapp-webhook/whatsapp_api.ts";

const WOZ_ADMIN_KEY = Deno.env.get("WOZ_ADMIN_KEY") ?? "";
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

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

    const body = await req.json();
    const { relay_id, amount, description, customer_phone, order_id } = body;

    if (!relay_id || !amount) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields",
          required: ["relay_id", "amount"],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (typeof amount !== "number" || amount <= 0) {
      return new Response(
        JSON.stringify({ error: "amount must be a positive number" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!STRIPE_SECRET_KEY) {
      return new Response(
        JSON.stringify({ error: "STRIPE_SECRET_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 1: Create a Stripe Price (ad-hoc, one-time)
    const amountCents = Math.round(amount * 100);
    const priceParams = new URLSearchParams({
      "unit_amount": amountCents.toString(),
      "currency": "eur",
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
      return new Response(
        JSON.stringify({ error: "Stripe price creation failed", details: priceData.error?.message }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 2: Create a Payment Link
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
      return new Response(
        JSON.stringify({ error: "Stripe link creation failed", details: linkData.error?.message }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const paymentUrl = linkData.url;

    // Step 3: Update relay with payment info
    const db = getServiceClient();
    const { error: updateError } = await db
      .from("order_relays")
      .update({
        stripe_payment_link: paymentUrl,
        payment_status: "sent",
        estimated_amount: amount,
      })
      .eq("id", relay_id);

    if (updateError) {
      console.error("Relay update error:", updateError);
    }

    // Step 4 (optional): Send payment link to customer via WhatsApp
    let waMessageId: string | null = null;
    if (customer_phone) {
      const waMessage =
        `Ciao! Ecco il link per pagare il tuo ordine DLOOP:\n` +
        `${paymentUrl}\n\n` +
        `Importo: €${amount.toFixed(2)}\n` +
        `Grazie per aver scelto DLOOP!`;

      const waResult = await sendWhatsAppMessage(customer_phone, waMessage);
      if (waResult.success) {
        waMessageId = waResult.messageId ?? null;
      } else {
        console.error("WhatsApp send failed (non-blocking):", waResult.error);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        relay_id,
        payment_url: paymentUrl,
        stripe_link_id: linkData.id,
        wa_message_id: waMessageId,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("stripe-link error:", error);
    return new Response(
      JSON.stringify({
        error: "Processing failed",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
