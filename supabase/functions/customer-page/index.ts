// Edge Function: customer-page
// Public endpoint serving the customer order completion flow.
//
// GET  /functions/v1/customer-page/c/<token>
//   → validates token, returns order data for the form
//
// POST /functions/v1/customer-page/c/<token>
//   → saves customer delivery details + delivery_slot, returns PIN
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";

const VALID_SLOTS = ["09-11", "11-13", "13-15", "15-17", "17-19", "19-21"] as const;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function generatePin(): string {
  return String(Math.floor(1000 + Math.random() * 9000));
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Extract token from path: /customer-page/c/<token>
  const url = new URL(req.url);
  const parts = url.pathname.split("/").filter(Boolean);
  // parts may be ["customer-page", "c", "<token>"] or ["c", "<token>"]
  const token = parts[parts.length - 1];

  if (!token || token === "c" || token === "customer-page") {
    return json({ valid: false, reason: "not_found" }, 400);
  }

  const db = getServiceClient();

  // ── GET: validate token and return order data ──────────────────────────────
  if (req.method === "GET") {
    const { data: order, error } = await db
      .from("orders")
      .select(
        "id, customer_token, token_expires_at, customer_name, package_size, package_count, is_fragile, pickup_address, restaurant_name, restaurant_address, payment_mode, delivery_fee_estimate, delivery_fee_breakdown, delivery_pin"
      )
      .eq("customer_token", token)
      .maybeSingle();

    if (error || !order) {
      return json({ valid: false, reason: "not_found" });
    }

    // Token expired?
    if (order.token_expires_at && new Date(order.token_expires_at) < new Date()) {
      return json({ valid: false, reason: "expired" });
    }

    // Already completed (customer_name filled means the form was already submitted)?
    if (order.customer_name && order.customer_name.trim() !== "") {
      return json({
        valid: false,
        reason: "already_sent",
        pin: order.delivery_pin ?? undefined,
      });
    }

    return json({
      valid: true,
      order: {
        package_size: order.package_size ?? "M",
        package_count: order.package_count ?? 1,
        is_fragile: order.is_fragile ?? false,
        pickup_address: order.pickup_address ?? order.restaurant_address ?? "",
        restaurant_name: order.restaurant_name ?? "",
        payment_mode: order.payment_mode ?? "delivery_on_completion",
        delivery_fee_estimate: order.delivery_fee_estimate ?? undefined,
        delivery_fee_breakdown: order.delivery_fee_breakdown ?? undefined,
      },
    });
  }

  // ── POST: save customer data ───────────────────────────────────────────────
  if (req.method === "POST") {
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return json({ success: false, error: "Invalid JSON" }, 400);
    }

    const {
      recipient_name,
      recipient_phone,
      dropoff_address,
      dropoff_lat,
      dropoff_lng,
      delivery_notes,
      notes,
      delivery_slot,
    } = body as Record<string, unknown>;

    // Validate required fields
    if (!recipient_name || typeof recipient_name !== "string" || !recipient_name.trim()) {
      return json({ success: false, error: "Nome destinatario obbligatorio" }, 400);
    }
    if (!recipient_phone || typeof recipient_phone !== "string" || !recipient_phone.trim()) {
      return json({ success: false, error: "Telefono obbligatorio" }, 400);
    }
    if (!dropoff_address || typeof dropoff_address !== "string" || !dropoff_address.trim()) {
      return json({ success: false, error: "Indirizzo di consegna obbligatorio" }, 400);
    }
    if (delivery_slot !== undefined && !VALID_SLOTS.includes(delivery_slot as typeof VALID_SLOTS[number])) {
      return json({ success: false, error: "Fascia oraria non valida" }, 400);
    }

    // Lookup order by token
    const { data: order, error: fetchError } = await db
      .from("orders")
      .select("id, customer_name, token_expires_at, delivery_fee_breakdown")
      .eq("customer_token", token)
      .maybeSingle();

    if (fetchError || !order) {
      return json({ success: false, error: "Ordine non trovato" }, 404);
    }

    if (order.token_expires_at && new Date(order.token_expires_at) < new Date()) {
      return json({ success: false, error: "Link scaduto" }, 410);
    }

    if (order.customer_name && order.customer_name.trim() !== "") {
      return json({ success: false, error: "Ordine già inviato" }, 409);
    }

    const pin = generatePin();

    const updateData: Record<string, unknown> = {
      customer_name: String(recipient_name).trim(),
      customer_phone: String(recipient_phone).trim(),
      dropoff_address: String(dropoff_address).trim(),
      delivery_notes: delivery_notes ? String(delivery_notes).trim() : null,
      notes: notes ? String(notes).trim() : null,
      delivery_pin: pin,
      status: "pending",
    };

    if (dropoff_lat !== undefined && dropoff_lat !== null) {
      updateData.dropoff_lat = Number(dropoff_lat);
    }
    if (dropoff_lng !== undefined && dropoff_lng !== null) {
      updateData.dropoff_lng = Number(dropoff_lng);
    }
    if (delivery_slot) {
      updateData.delivery_slot = String(delivery_slot);
    }

    const { error: updateError } = await db
      .from("orders")
      .update(updateData)
      .eq("id", order.id);

    if (updateError) {
      console.error("[customer-page] Update error:", updateError);
      return json({ success: false, error: "Errore nel salvataggio" }, 500);
    }

    return json({
      success: true,
      pin,
      delivery_fee_breakdown: order.delivery_fee_breakdown ?? undefined,
    });
  }

  return json({ error: "Method not allowed" }, 405);
});
