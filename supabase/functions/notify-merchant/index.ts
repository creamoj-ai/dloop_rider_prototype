// ============================================================================
// EDGE FUNCTION: notify-merchant
// ============================================================================
// Invia notifiche al merchant quando lo stato dell'ordine cambia.
// - Email (Resend API) - sempre
// - WhatsApp (se numero presente) - opzionale
//
// Triggered by: Database trigger su orders.status UPDATE
// Oppure chiamata manuale: POST /functions/v1/notify-merchant
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") || "noreply@dloop.app";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// EMAIL TEMPLATES
// ============================================================================
function getEmailTemplate(
  status: string,
  orderData: {
    order_id: string;
    restaurant_name: string;
    customer_name: string;
    customer_address: string;
    distance_km: number;
    base_earning: number;
    rider_name?: string;
    eta_minutes?: number;
  }
): { subject: string; html: string } {
  const orderId = orderData.order_id.slice(0, 8).toUpperCase();

  switch (status) {
    case "assigned":
      return {
        subject: `✅ Ordine #${orderId} assegnato a rider`,
        html: `
          <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #2563eb;">✅ Ordine Assegnato</h2>
              <p>Buongiorno <strong>${orderData.restaurant_name}</strong>,</p>
              <p>Il vostro ordine <strong>#${orderId}</strong> è stato assegnato a un rider.</p>

              <div style="background: #f3f4f6; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p><strong>📦 Dettagli Ordine:</strong></p>
                <ul style="list-style: none; padding: 0;">
                  <li>👤 Cliente: ${orderData.customer_name}</li>
                  <li>📍 Indirizzo: ${orderData.customer_address}</li>
                  <li>📏 Distanza: ${orderData.distance_km} km</li>
                  ${orderData.rider_name ? `<li>🚴 Rider: ${orderData.rider_name}</li>` : ""}
                </ul>
              </div>

              <p>Il rider arriverà presto per ritirare l'ordine.</p>
              <p style="color: #6b7280; font-size: 12px; margin-top: 30px;">
                DLOOP - Delivery cooperativo<br>
                Questo è un messaggio automatico, non rispondere a questa email.
              </p>
            </body>
          </html>
        `,
      };

    case "picked_up":
      return {
        subject: `📦 Ordine #${orderId} ritirato - In consegna`,
        html: `
          <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #059669;">📦 Ordine Ritirato</h2>
              <p>Buongiorno <strong>${orderData.restaurant_name}</strong>,</p>
              <p>Il rider ha ritirato l'ordine <strong>#${orderId}</strong> ed è in viaggio verso il cliente.</p>

              <div style="background: #f3f4f6; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p><strong>📍 Destinazione:</strong></p>
                <ul style="list-style: none; padding: 0;">
                  <li>👤 ${orderData.customer_name}</li>
                  <li>📍 ${orderData.customer_address}</li>
                  ${orderData.eta_minutes ? `<li>⏱️ ETA: ~${orderData.eta_minutes} minuti</li>` : ""}
                </ul>
              </div>

              <p>Riceverai una conferma appena l'ordine sarà consegnato.</p>
              <p style="color: #6b7280; font-size: 12px; margin-top: 30px;">
                DLOOP - Delivery cooperativo
              </p>
            </body>
          </html>
        `,
      };

    case "delivered":
      return {
        subject: `🎉 Ordine #${orderId} consegnato con successo`,
        html: `
          <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #059669;">🎉 Ordine Consegnato!</h2>
              <p>Buongiorno <strong>${orderData.restaurant_name}</strong>,</p>
              <p>L'ordine <strong>#${orderId}</strong> è stato consegnato con successo al cliente.</p>

              <div style="background: #ecfdf5; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #059669;">
                <p><strong>✅ Consegna Completata</strong></p>
                <ul style="list-style: none; padding: 0;">
                  <li>👤 Cliente: ${orderData.customer_name}</li>
                  <li>📍 ${orderData.customer_address}</li>
                  <li>📏 Distanza: ${orderData.distance_km} km</li>
                </ul>
              </div>

              <p>Grazie per aver usato DLOOP!</p>
              <p style="color: #6b7280; font-size: 12px; margin-top: 30px;">
                DLOOP - Delivery cooperativo
              </p>
            </body>
          </html>
        `,
      };

    case "cancelled":
      return {
        subject: `❌ Ordine #${orderId} annullato`,
        html: `
          <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #dc2626;">❌ Ordine Annullato</h2>
              <p>Buongiorno <strong>${orderData.restaurant_name}</strong>,</p>
              <p>L'ordine <strong>#${orderId}</strong> è stato annullato.</p>

              <div style="background: #fef2f2; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #dc2626;">
                <p><strong>Dettagli Ordine Annullato:</strong></p>
                <ul style="list-style: none; padding: 0;">
                  <li>👤 Cliente: ${orderData.customer_name}</li>
                  <li>📍 ${orderData.customer_address}</li>
                </ul>
              </div>

              <p>Se hai domande, contattaci.</p>
              <p style="color: #6b7280; font-size: 12px; margin-top: 30px;">
                DLOOP - Delivery cooperativo
              </p>
            </body>
          </html>
        `,
      };

    default:
      return {
        subject: `Aggiornamento Ordine #${orderId}`,
        html: `<p>Stato ordine: ${status}</p>`,
      };
  }
}

// ============================================================================
// SEND EMAIL (Resend API)
// ============================================================================
async function sendEmail(
  toEmail: string,
  subject: string,
  html: string
): Promise<boolean> {
  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: [toEmail],
        subject: subject,
        html: html,
      }),
    });

    const result = await response.json();

    if (response.ok) {
      console.log(`✅ Email sent to ${toEmail} | ID: ${result.id}`);
      return true;
    } else {
      console.error(`❌ Email send failed:`, result);
      return false;
    }
  } catch (error) {
    console.error(`❌ Email error:`, error);
    return false;
  }
}

// ============================================================================
// SEND WHATSAPP (TODO - Requires WhatsApp Business API setup + template approval)
// ============================================================================
async function sendWhatsApp(
  phoneNumber: string,
  templateName: string,
  params: string[]
): Promise<boolean> {
  // TODO FASE 2: Implementare dopo approval template Meta
  // const WHATSAPP_API_URL = "https://graph.facebook.com/v18.0/{phone_number_id}/messages";
  // const WHATSAPP_TOKEN = Deno.env.get("WHATSAPP_TOKEN");

  console.log(`ℹ️ WhatsApp notification skipped (not implemented yet): ${phoneNumber} | Template: ${templateName}`);
  return false;
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
    // Parse request body
    const { order_id, new_status } = await req.json();

    if (!order_id || !new_status) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields",
          required: ["order_id", "new_status"],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch order + dealer info
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select(`
        id,
        restaurant_name,
        customer_name,
        customer_address,
        distance_km,
        base_earning,
        dealer_contact_id
      `)
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      console.error("❌ Order not found:", orderError);
      return new Response(
        JSON.stringify({ error: "Order not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch dealer contact info
    const { data: dealer, error: dealerError } = await supabase
      .from("dealers")
      .select("email, whatsapp_number")
      .eq("id", order.dealer_contact_id)
      .single();

    if (dealerError || !dealer || !dealer.email) {
      console.warn(`⚠️ No dealer email found for order ${order_id}`);
      return new Response(
        JSON.stringify({ error: "Dealer email not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get email template
    const { subject, html } = getEmailTemplate(new_status, {
      order_id: order.id,
      restaurant_name: order.restaurant_name,
      customer_name: order.customer_name,
      customer_address: order.customer_address,
      distance_km: order.distance_km,
      base_earning: order.base_earning,
      eta_minutes: Math.round(order.distance_km * 4), // 4 min/km average
    });

    // Send email
    const emailSent = await sendEmail(dealer.email, subject, html);

    // Send WhatsApp (if number present)
    let whatsappSent = false;
    if (dealer.whatsapp_number) {
      whatsappSent = await sendWhatsApp(
        dealer.whatsapp_number,
        `order_${new_status}`,
        [order.id.slice(0, 8), order.customer_name]
      );
    }

    console.log(`✅ Notifications sent for order ${order_id} | Email: ${emailSent} | WhatsApp: ${whatsappSent}`);

    return new Response(
      JSON.stringify({
        success: true,
        order_id: order.id,
        email_sent: emailSent,
        whatsapp_sent: whatsappSent,
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
