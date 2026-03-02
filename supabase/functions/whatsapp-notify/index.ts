// Edge Function: whatsapp-notify — Send proactive WhatsApp notifications
// Triggered by order status changes to notify customers and dealers.
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/whatsapp-notify \
//     -H "Content-Type: application/json" \
//     -H "X-Admin-Key: <WOZ_ADMIN_KEY>" \
//     -d '{"order_id":"<uuid>","event":"order_confirmed"}'
//
// Events: order_confirmed, order_ready, order_picked_up, order_delivered, payment_received
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import {
  sendTemplateOrText,
  WA_TEMPLATES,
} from "../whatsapp-webhook/whatsapp_api.ts";
import { checkRateLimit, rateLimitResponse } from "../_shared/rate_limit.ts";

const WOZ_ADMIN_KEY = Deno.env.get("WOZ_ADMIN_KEY") ?? "";

type NotifyEvent =
  | "order_confirmed"
  | "order_ready"
  | "order_picked_up"
  | "order_delivered"
  | "payment_received";

const VALID_EVENTS: NotifyEvent[] = [
  "order_confirmed",
  "order_ready",
  "order_picked_up",
  "order_delivered",
  "payment_received",
];

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // Auth
    const adminKey = req.headers.get("X-Admin-Key");
    if (!WOZ_ADMIN_KEY || adminKey !== WOZ_ADMIN_KEY) {
      return json({ error: "Unauthorized" }, 401);
    }

    // Rate limit: 60 notifications/min
    if (!checkRateLimit("whatsapp-notify", 60)) {
      return rateLimitResponse(corsHeaders);
    }

    const body = await req.json();
    const { order_id, event } = body as {
      order_id: string;
      event: NotifyEvent;
    };

    if (!order_id || !event) {
      return json(
        { error: "Missing required fields", required: ["order_id", "event"] },
        400
      );
    }

    if (!VALID_EVENTS.includes(event)) {
      return json(
        { error: `Invalid event. Valid: ${VALID_EVENTS.join(", ")}` },
        400
      );
    }

    const db = getServiceClient();

    // Fetch order with customer phone
    const { data: order, error: orderErr } = await db
      .from("orders")
      .select(
        "id, status, customer_phone, pickup_address, delivery_address, total_amount, dealer_contact_id"
      )
      .eq("id", order_id)
      .single();

    if (orderErr || !order) {
      return json({ error: "Order not found" }, 404);
    }

    const customerPhone = order.customer_phone as string;
    if (!customerPhone) {
      return json({ error: "No customer phone on order" }, 400);
    }

    // Get dealer name if available
    let dealerName = "il negozio";
    if (order.dealer_contact_id) {
      const { data: dealer } = await db
        .from("rider_contacts")
        .select("name")
        .eq("id", order.dealer_contact_id)
        .single();
      if (dealer?.name) dealerName = dealer.name as string;
    }

    const orderId = (order.id as string).slice(0, 8);

    // Build message based on event
    const { templateName, templateParams, fallbackText } = buildNotification(
      event,
      orderId,
      dealerName,
      order
    );

    // Send notification
    const result = await sendTemplateOrText(
      customerPhone,
      templateName,
      templateParams,
      fallbackText
    );

    // Log notification
    console.log(
      `Notify [${event}] order=${orderId} phone=${customerPhone} success=${result.success}`
    );

    return json({
      success: result.success,
      event,
      order_id: orderId,
      wa_message_id: result.messageId ?? null,
      error: result.error ?? null,
    });
  } catch (error) {
    console.error("whatsapp-notify error:", error);
    return json(
      {
        error: "Processing failed",
        details: error instanceof Error ? error.message : String(error),
      },
      500
    );
  }
});

function buildNotification(
  event: NotifyEvent,
  orderId: string,
  dealerName: string,
  order: Record<string, unknown>
): {
  templateName: string;
  templateParams: string[];
  fallbackText: string;
} {
  switch (event) {
    case "order_confirmed":
      return {
        templateName: WA_TEMPLATES.ORDINE_CONFERMATO,
        templateParams: [orderId, dealerName],
        fallbackText:
          `Il tuo ordine #${orderId} è stato confermato da ${dealerName}! ` +
          `Stanno preparando il tuo ordine. Ti avviseremo quando sarà pronto.`,
      };

    case "order_ready":
      return {
        templateName: WA_TEMPLATES.ORDINE_PRONTO,
        templateParams: [orderId, "10-15 min"],
        fallbackText:
          `Il tuo ordine #${orderId} è pronto! ` +
          `Il rider sta venendo a ritirarlo. Arrivo stimato: 10-15 min.`,
      };

    case "order_picked_up":
      return {
        templateName: WA_TEMPLATES.ORDINE_PRONTO,
        templateParams: [orderId, "15-20 min"],
        fallbackText:
          `Il rider ha ritirato il tuo ordine #${orderId} da ${dealerName}! ` +
          `Sta arrivando da te. Tempo stimato: 15-20 min.`,
      };

    case "order_delivered":
      return {
        templateName: WA_TEMPLATES.ORDINE_CONFERMATO,
        templateParams: [orderId, dealerName],
        fallbackText:
          `Il tuo ordine #${orderId} è stato consegnato! ` +
          `Grazie per aver scelto DLOOP. Come è andata? Rispondi con un voto da 1 a 5.`,
      };

    case "payment_received":
      return {
        templateName: WA_TEMPLATES.PAGAMENTO,
        templateParams: [
          `€${((order.total_amount as number) ?? 0).toFixed(2)}`,
          orderId,
        ],
        fallbackText:
          `Pagamento ricevuto per l'ordine #${orderId}! ` +
          `Importo: €${((order.total_amount as number) ?? 0).toFixed(2)}. Grazie!`,
      };
  }
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
