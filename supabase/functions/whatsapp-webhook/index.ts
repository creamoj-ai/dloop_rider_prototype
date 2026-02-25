// Edge Function: whatsapp-webhook — WhatsApp Cloud API webhook handler
// Routes messages to customer or dealer pipeline based on phone lookup.
// Redeploy to new Supabase project: imhjdsjtaommutdmkouf
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { normalizePhone } from "../_shared/phone_utils.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { processInboundMessage } from "./processor.ts";
import { processDealerMessage } from "./dealer_processor.ts";

const VERIFY_TOKEN = Deno.env.get("WHATSAPP_VERIFY_TOKEN") ?? "dloop_wa_verify_2026";

serve(async (req: Request) => {
  // ── GET: Webhook Verification (Meta challenge) ──────────────
  if (req.method === "GET") {
    const url = new URL(req.url);
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    if (mode === "subscribe" && token === VERIFY_TOKEN) {
      console.log("Webhook verified successfully");
      return new Response(challenge, { status: 200 });
    }

    return new Response("Forbidden", { status: 403 });
  }

  // ── OPTIONS: CORS ───────────────────────────────────────────
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // ── POST: Incoming webhook events ───────────────────────────
  if (req.method === "POST") {
    try {
      const body = await req.json();
      const db = getServiceClient();

      // Process each entry in the webhook payload
      const entries = body.entry ?? [];
      for (const entry of entries) {
        const changes = entry.changes ?? [];
        for (const change of changes) {
          if (change.field !== "messages") continue;

          const value = change.value;
          const messages = value?.messages ?? [];
          const contacts = value?.contacts ?? [];
          const statuses = value?.statuses ?? [];

          // Handle status updates (delivered, read)
          for (const status of statuses) {
            await handleStatusUpdate(db, status);
          }

          // Handle incoming messages
          for (let i = 0; i < messages.length; i++) {
            const msg = messages[i];
            const contact = contacts[i] ?? contacts[0];

            await handleIncomingMessage(db, msg, contact);
          }
        }
      }

      // Always return 200 to Meta (they retry on non-200)
      return new Response(JSON.stringify({ status: "ok" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (error) {
      console.error("Webhook processing error:", error);
      // Still return 200 to prevent Meta retries
      return new Response(JSON.stringify({ status: "error_logged" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  }

  return new Response("Method not allowed", { status: 405 });
});

// ── Handlers ────────────────────────────────────────────────────

async function handleIncomingMessage(
  db: ReturnType<typeof getServiceClient>,
  msg: Record<string, unknown>,
  contact: Record<string, unknown>
): Promise<void> {
  const phone = msg.from as string;
  const name =
    (contact?.profile as Record<string, unknown>)?.name as string | undefined;
  const msgType = msg.type as string;

  // Rate limit: 60 messages/min per phone number
  if (!checkRateLimit(`wa:${phone}`, 60)) {
    console.warn(`Rate limited: ${phone}`);
    return;
  }

  // Build InboundMessage based on type
  const inbound: Record<string, unknown> = { phone, name };

  switch (msgType) {
    case "text":
      inbound.text = (msg.text as Record<string, unknown>)?.body as string;
      break;
    case "audio":
      inbound.audioMediaId = (msg.audio as Record<string, unknown>)
        ?.id as string;
      break;
    case "image":
      inbound.imageMediaId = (msg.image as Record<string, unknown>)
        ?.id as string;
      inbound.imageCaption = (msg.image as Record<string, unknown>)
        ?.caption as string;
      break;
    case "location":
      inbound.latitude = (msg.location as Record<string, unknown>)
        ?.latitude as number;
      inbound.longitude = (msg.location as Record<string, unknown>)
        ?.longitude as number;
      break;
    default:
      // Unsupported message type — treat as text
      inbound.text = `[${msgType} non supportato]`;
      break;
  }

  try {
    // Route: check if sender is a dealer by matching phone in rider_contacts
    const normalized = normalizePhone(phone);
    const { data: dealerContacts } = await db
      .from("rider_contacts")
      .select("id, rider_id, name, phone")
      .eq("contact_type", "dealer");

    const matchedDealer = (dealerContacts ?? []).find(
      (d: Record<string, unknown>) =>
        normalizePhone(d.phone as string) === normalized
    );

    if (matchedDealer) {
      // DEALER pipeline
      console.log(`Routing to DEALER pipeline: ${matchedDealer.name}`);
      await processDealerMessage(db, inbound as {
        phone: string;
        text?: string;
        name?: string;
        audioMediaId?: string;
        imageMediaId?: string;
        imageCaption?: string;
        latitude?: number;
        longitude?: number;
      }, {
        id: matchedDealer.id as string,
        rider_id: matchedDealer.rider_id as string,
        name: matchedDealer.name as string,
      });
    } else {
      // CUSTOMER pipeline (existing)
      console.log(`Routing to CUSTOMER pipeline: ${phone}`);
      await processInboundMessage(db, inbound as {
        phone: string;
        text?: string;
        name?: string;
        audioMediaId?: string;
        imageMediaId?: string;
        imageCaption?: string;
        latitude?: number;
        longitude?: number;
      });
    }
  } catch (error) {
    console.error(`Failed to process message from ${phone}:`, error);
  }
}

async function handleStatusUpdate(
  db: ReturnType<typeof getServiceClient>,
  status: Record<string, unknown>
): Promise<void> {
  const waMessageId = status.id as string;
  const newStatus = status.status as string;

  if (!waMessageId || !newStatus) return;

  // Map Meta status to our status
  const statusMap: Record<string, string> = {
    sent: "sent",
    delivered: "delivered",
    read: "read",
    failed: "failed",
  };

  const mappedStatus = statusMap[newStatus];
  if (!mappedStatus) return;

  try {
    await db
      .from("whatsapp_messages")
      .update({ status: mappedStatus })
      .eq("wa_message_id", waMessageId);
  } catch (error) {
    console.error(`Failed to update status for ${waMessageId}:`, error);
  }
}
