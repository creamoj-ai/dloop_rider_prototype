// Edge Function: customer-order-form
// Serves the customer delivery-slot selection form and saves the choice.
//
// GET  /functions/v1/customer-order-form/<order_id>  → HTML form
// POST /functions/v1/customer-order-form/<order_id>  → saves delivery_slot
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient } from "../_shared/supabase.ts";

const VALID_SLOTS = ["09-11", "11-13", "13-15", "15-17", "17-19", "19-21"] as const;
type Slot = typeof VALID_SLOTS[number];

function html(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}

function renderForm(order: Record<string, unknown>, selectedSlot?: string, error?: string): string {
  const slots: Slot[] = [...VALID_SLOTS];
  const slotButtons = slots.map((slot) => {
    const active = slot === selectedSlot ? "slot-btn active" : "slot-btn";
    return `<button type="submit" name="slot" value="${slot}" class="${active}">${slot}</button>`;
  }).join("\n      ");

  const errorHtml = error
    ? `<div class="error">${error}</div>`
    : "";

  const confirmedHtml = selectedSlot
    ? `<div class="confirmed">✅ Fascia confermata: <strong>${selectedSlot}</strong></div>`
    : "";

  return `<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Scegli la tua fascia oraria — dloop</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0a0a0a;
      color: #e0e0e0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px 16px;
    }
    .card {
      background: #141414;
      border: 1px solid #222;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 420px;
      width: 100%;
    }
    .logo { font-size: 1.1rem; font-weight: 700; color: #00e676; margin-bottom: 24px; }
    h1 { font-size: 1.25rem; margin-bottom: 4px; }
    .subtitle { font-size: 0.85rem; color: #888; margin-bottom: 8px; }
    .order-info {
      background: #1a1a1a;
      border: 1px solid #2a2a2a;
      border-radius: 10px;
      padding: 14px 16px;
      margin: 20px 0;
      font-size: 0.85rem;
    }
    .order-info .row { display: flex; justify-content: space-between; margin-bottom: 6px; }
    .order-info .row:last-child { margin-bottom: 0; }
    .order-info .label { color: #888; }
    .order-info .value { color: #e0e0e0; text-align: right; }
    .section-label {
      font-size: 0.8rem;
      color: #aaa;
      font-weight: 600;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      margin-bottom: 12px;
    }
    .slot-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 10px;
      margin-bottom: 24px;
    }
    .slot-btn {
      width: 100%;
      padding: 14px 10px;
      background: #1a1a1a;
      color: #e0e0e0;
      font-size: 1rem;
      font-weight: 600;
      border: 1px solid #333;
      border-radius: 10px;
      cursor: pointer;
      transition: border-color 0.15s, background 0.15s;
    }
    .slot-btn:hover { border-color: #00e676; background: #0d1f0d; color: #00e676; }
    .slot-btn.active { border-color: #00e676; background: #0d2a0d; color: #00e676; }
    .confirmed {
      padding: 14px 16px;
      background: #0d2a0d;
      border: 1px solid #00e676;
      border-radius: 10px;
      color: #00e676;
      font-size: 0.95rem;
      margin-bottom: 16px;
    }
    .error {
      padding: 12px 16px;
      background: #2a0d0d;
      border: 1px solid #f44336;
      border-radius: 10px;
      color: #f44336;
      font-size: 0.9rem;
      margin-bottom: 16px;
    }
    .footer { font-size: 0.75rem; color: #555; text-align: center; margin-top: 20px; }
    .footer a { color: #555; text-decoration: none; }
    form { margin: 0; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">dloop</div>
    <h1>Quando vuoi la consegna?</h1>
    <p class="subtitle">Scegli la fascia oraria che preferisci</p>

    <div class="order-info">
      <div class="row">
        <span class="label">Ordine</span>
        <span class="value">#${String(order.id).slice(0, 8).toUpperCase()}</span>
      </div>
      ${order.customer_address ? `<div class="row">
        <span class="label">Consegna a</span>
        <span class="value">${order.customer_address}</span>
      </div>` : ""}
    </div>

    ${errorHtml}
    ${confirmedHtml}

    <p class="section-label">Fascia oraria di consegna</p>
    <form method="POST">
      <div class="slot-grid">
        ${slotButtons}
      </div>
    </form>

    <p class="footer">
      Servizio di consegna gestito da <a href="https://dloop.it">dloop.it</a>
    </p>
  </div>
</body>
</html>`;
}

function renderSuccess(slot: string): string {
  return `<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Fascia confermata — dloop</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0a0a0a;
      color: #e0e0e0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px 16px;
    }
    .card {
      background: #141414;
      border: 1px solid #222;
      border-radius: 16px;
      padding: 32px 24px;
      max-width: 420px;
      width: 100%;
      text-align: center;
    }
    .logo { font-size: 1.1rem; font-weight: 700; color: #00e676; margin-bottom: 24px; }
    .check { font-size: 3rem; margin-bottom: 16px; }
    h1 { font-size: 1.25rem; margin-bottom: 8px; }
    .slot-display {
      font-size: 2rem;
      font-weight: 700;
      color: #00e676;
      margin: 20px 0;
    }
    .note { font-size: 0.85rem; color: #888; margin-top: 8px; }
    .footer { font-size: 0.75rem; color: #555; margin-top: 24px; }
    .footer a { color: #555; text-decoration: none; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">dloop</div>
    <div class="check">✅</div>
    <h1>Fascia oraria confermata!</h1>
    <div class="slot-display">${slot}</div>
    <p class="note">Riceverai la tua consegna tra le ${slot.replace("-", ":00 e le ")}:00</p>
    <p class="footer">
      <a href="https://dloop.it">dloop.it</a> — La consegna locale
    </p>
  </div>
</body>
</html>`;
}

function renderError(message: string): string {
  return `<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Errore — dloop</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0a0a0a; color: #e0e0e0;
      min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px 16px;
    }
    .card {
      background: #141414; border: 1px solid #222; border-radius: 16px;
      padding: 32px 24px; max-width: 420px; width: 100%; text-align: center;
    }
    .logo { font-size: 1.1rem; font-weight: 700; color: #00e676; margin-bottom: 24px; }
    h1 { font-size: 1.1rem; color: #f44336; margin-bottom: 8px; }
    p { font-size: 0.85rem; color: #888; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">dloop</div>
    <h1>Ordine non trovato</h1>
    <p>${message}</p>
  </div>
</body>
</html>`;
}

serve(async (req: Request) => {
  const url = new URL(req.url);

  // Extract order_id from the URL path: /customer-order-form/<order_id>
  const pathParts = url.pathname.split("/").filter(Boolean);
  const orderId = pathParts[pathParts.length - 1];

  if (!orderId || orderId === "customer-order-form") {
    return html(renderError("Link non valido. Contatta il merchant per un nuovo link."), 400);
  }

  const db = getServiceClient();

  if (req.method === "GET") {
    const { data: order, error } = await db
      .from("orders")
      .select("id, customer_address, delivery_slot")
      .eq("id", orderId)
      .single();

    if (error || !order) {
      return html(renderError("Ordine non trovato. Il link potrebbe essere scaduto."), 404);
    }

    return html(renderForm(order as Record<string, unknown>, order.delivery_slot ?? undefined));
  }

  if (req.method === "POST") {
    // Parse form-encoded body
    const body = await req.text();
    const params = new URLSearchParams(body);
    const slot = params.get("slot");

    if (!slot || !(VALID_SLOTS as readonly string[]).includes(slot)) {
      const { data: order } = await db
        .from("orders")
        .select("id, customer_address, delivery_slot")
        .eq("id", orderId)
        .single();

      return html(
        renderForm(
          (order ?? { id: orderId }) as Record<string, unknown>,
          undefined,
          "Fascia oraria non valida. Seleziona una delle opzioni disponibili."
        ),
        400
      );
    }

    const { error } = await db
      .from("orders")
      .update({ delivery_slot: slot })
      .eq("id", orderId);

    if (error) {
      return html(renderError("Errore nel salvataggio. Riprova tra qualche secondo."), 500);
    }

    return html(renderSuccess(slot));
  }

  return html(renderError("Metodo non consentito."), 405);
});
