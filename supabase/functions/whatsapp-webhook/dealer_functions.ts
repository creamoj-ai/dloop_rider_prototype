// Function calling definitions and executors for WhatsApp dealer bot
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { ToolDefinition } from "../_shared/openai.ts";

// ── Tool Definitions ──────────────────────────────────────────────

export const dealerTools: ToolDefinition[] = [
  {
    type: "function",
    function: {
      name: "confirm_order",
      description:
        "Conferma un ordine relay e inizia la preparazione. Se relay_id non è fornito, conferma l'ultimo ordine in attesa.",
      parameters: {
        type: "object",
        properties: {
          relay_id: {
            type: "string",
            description:
              "ID del relay da confermare (opzionale, usa il più recente se omesso)",
          },
        },
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "decline_order",
      description:
        "Rifiuta un ordine relay con motivo opzionale. Se relay_id non è fornito, rifiuta l'ultimo in attesa.",
      parameters: {
        type: "object",
        properties: {
          relay_id: {
            type: "string",
            description: "ID del relay da rifiutare (opzionale)",
          },
          reason: {
            type: "string",
            description: "Motivo del rifiuto (es. 'prodotto esaurito', 'chiusi')",
          },
        },
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "mark_order_ready",
      description:
        "Segna un ordine come pronto per il ritiro del rider. Se relay_id non è fornito, segna l'ultimo in preparazione.",
      parameters: {
        type: "object",
        properties: {
          relay_id: {
            type: "string",
            description: "ID del relay da segnare come pronto (opzionale)",
          },
        },
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "view_pending_orders",
      description:
        "Mostra tutti gli ordini attivi per questo dealer (in attesa, confermati, in preparazione).",
      parameters: {
        type: "object",
        properties: {},
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "update_availability",
      description:
        "Aggiorna la disponibilità del dealer (aperto/chiuso/pausa).",
      parameters: {
        type: "object",
        properties: {
          available: {
            type: "boolean",
            description: "true = aperto, false = chiuso/pausa",
          },
          until: {
            type: "string",
            description:
              "Fino a quando (es. '14:00', 'domani'). Solo se available=false.",
          },
        },
        required: ["available"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "get_daily_summary",
      description:
        "Riepilogo ordini del giorno: completati, rifiutati, totale guadagni.",
      parameters: {
        type: "object",
        properties: {},
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "set_conversation_state",
      description:
        "Aggiorna lo stato della conversazione dealer.",
      parameters: {
        type: "object",
        properties: {
          new_state: {
            type: "string",
            enum: ["idle", "confirming", "preparing", "support"],
            description: "Nuovo stato della conversazione",
          },
        },
        required: ["new_state"],
      },
    },
  },
];

// ── Function Executor ─────────────────────────────────────────────

export async function executeDealerFunction(
  name: string,
  args: Record<string, unknown>,
  db: SupabaseClient,
  conversationId: string,
  dealerContactId: string,
  riderId: string
): Promise<string> {
  switch (name) {
    case "confirm_order":
      return await confirmOrder(
        db,
        dealerContactId,
        riderId,
        args.relay_id as string | undefined
      );
    case "decline_order":
      return await declineOrder(
        db,
        dealerContactId,
        riderId,
        args.relay_id as string | undefined,
        args.reason as string | undefined
      );
    case "mark_order_ready":
      return await markOrderReady(
        db,
        dealerContactId,
        riderId,
        args.relay_id as string | undefined
      );
    case "view_pending_orders":
      return await viewPendingOrders(db, dealerContactId);
    case "update_availability":
      return await updateAvailability(
        db,
        dealerContactId,
        args.available as boolean,
        args.until as string | undefined
      );
    case "get_daily_summary":
      return await getDailySummary(db, dealerContactId);
    case "set_conversation_state":
      return await setDealerConversationState(
        db,
        conversationId,
        args.new_state as string
      );
    default:
      return JSON.stringify({ error: `Funzione sconosciuta: ${name}` });
  }
}

// ── Individual Functions ──────────────────────────────────────────

/**
 * Find the most recent relay for this dealer with a given status.
 */
async function findLatestRelay(
  db: SupabaseClient,
  dealerContactId: string,
  statuses: string[]
): Promise<Record<string, unknown> | null> {
  const { data } = await db
    .from("order_relays")
    .select("id, order_id, status, dealer_message, estimated_amount, created_at")
    .eq("dealer_contact_id", dealerContactId)
    .in("status", statuses)
    .order("created_at", { ascending: false })
    .limit(1);

  return data && data.length > 0 ? data[0] : null;
}

/**
 * Send a notification to the rider via the notifications table.
 */
async function notifyRider(
  db: SupabaseClient,
  riderId: string,
  title: string,
  body: string,
  type: string = "order_update"
): Promise<void> {
  await db.from("notifications").insert({
    rider_id: riderId,
    type,
    title,
    body,
    is_read: false,
  });
}

async function confirmOrder(
  db: SupabaseClient,
  dealerContactId: string,
  riderId: string,
  relayId?: string
): Promise<string> {
  let relay: Record<string, unknown> | null = null;

  if (relayId) {
    const { data } = await db
      .from("order_relays")
      .select("id, order_id, status, dealer_message, estimated_amount")
      .eq("id", relayId)
      .eq("dealer_contact_id", dealerContactId)
      .single();
    relay = data;
  } else {
    relay = await findLatestRelay(db, dealerContactId, ["sent", "pending"]);
  }

  if (!relay) {
    return JSON.stringify({
      error: "Nessun ordine in attesa di conferma trovato.",
    });
  }

  if (relay.status !== "sent" && relay.status !== "pending") {
    return JSON.stringify({
      error: `L'ordine è già in stato "${relay.status}". Non può essere confermato.`,
    });
  }

  // Update relay status
  const { error } = await db
    .from("order_relays")
    .update({
      status: "confirmed",
      confirmed_at: new Date().toISOString(),
      dealer_reply: "Confermato",
    })
    .eq("id", relay.id);

  if (error) {
    return JSON.stringify({ error: `Errore: ${error.message}` });
  }

  // Notify rider
  await notifyRider(
    db,
    riderId,
    "Ordine confermato!",
    `Il dealer ha confermato l'ordine. Preparazione in corso.`
  );

  return JSON.stringify({
    success: true,
    relay_id: (relay.id as string).slice(0, 8),
    message: "Ordine confermato! Inizia la preparazione e scrivi PRONTO quando è pronto.",
  });
}

async function declineOrder(
  db: SupabaseClient,
  dealerContactId: string,
  riderId: string,
  relayId?: string,
  reason?: string
): Promise<string> {
  let relay: Record<string, unknown> | null = null;

  if (relayId) {
    const { data } = await db
      .from("order_relays")
      .select("id, order_id, status")
      .eq("id", relayId)
      .eq("dealer_contact_id", dealerContactId)
      .single();
    relay = data;
  } else {
    relay = await findLatestRelay(db, dealerContactId, ["sent", "pending"]);
  }

  if (!relay) {
    return JSON.stringify({
      error: "Nessun ordine in attesa trovato da rifiutare.",
    });
  }

  if (relay.status !== "sent" && relay.status !== "pending") {
    return JSON.stringify({
      error: `L'ordine è già in stato "${relay.status}". Non può essere rifiutato.`,
    });
  }

  const replyText = reason ? `Rifiutato: ${reason}` : "Rifiutato";

  const { error } = await db
    .from("order_relays")
    .update({
      status: "cancelled",
      dealer_reply: replyText,
    })
    .eq("id", relay.id);

  if (error) {
    return JSON.stringify({ error: `Errore: ${error.message}` });
  }

  // Notify rider
  await notifyRider(
    db,
    riderId,
    "Ordine rifiutato",
    `Il dealer ha rifiutato l'ordine.${reason ? ` Motivo: ${reason}` : ""}`
  );

  return JSON.stringify({
    success: true,
    relay_id: (relay.id as string).slice(0, 8),
    message: `Ordine rifiutato.${reason ? ` Motivo: ${reason}` : ""}`,
  });
}

async function markOrderReady(
  db: SupabaseClient,
  dealerContactId: string,
  riderId: string,
  relayId?: string
): Promise<string> {
  let relay: Record<string, unknown> | null = null;

  if (relayId) {
    const { data } = await db
      .from("order_relays")
      .select("id, order_id, status")
      .eq("id", relayId)
      .eq("dealer_contact_id", dealerContactId)
      .single();
    relay = data;
  } else {
    relay = await findLatestRelay(db, dealerContactId, [
      "confirmed",
      "preparing",
    ]);
  }

  if (!relay) {
    return JSON.stringify({
      error: "Nessun ordine in preparazione trovato.",
    });
  }

  if (relay.status !== "confirmed" && relay.status !== "preparing") {
    return JSON.stringify({
      error: `L'ordine è in stato "${relay.status}". Deve essere "confermato" o "in preparazione".`,
    });
  }

  const { error } = await db
    .from("order_relays")
    .update({
      status: "ready",
      ready_at: new Date().toISOString(),
    })
    .eq("id", relay.id);

  if (error) {
    return JSON.stringify({ error: `Errore: ${error.message}` });
  }

  // Notify rider
  await notifyRider(
    db,
    riderId,
    "Ordine pronto per il ritiro!",
    "Il dealer ha preparato l'ordine. Vai a ritirarlo!"
  );

  return JSON.stringify({
    success: true,
    relay_id: (relay.id as string).slice(0, 8),
    message: "Ordine segnato come pronto! Il rider sta arrivando.",
  });
}

async function viewPendingOrders(
  db: SupabaseClient,
  dealerContactId: string
): Promise<string> {
  const { data, error } = await db
    .from("order_relays")
    .select(
      "id, status, dealer_message, estimated_amount, created_at, orders(customer_name, customer_address)"
    )
    .eq("dealer_contact_id", dealerContactId)
    .in("status", ["pending", "sent", "confirmed", "preparing", "ready"])
    .order("created_at", { ascending: false })
    .limit(10);

  if (error) {
    return JSON.stringify({ error: error.message });
  }

  if (!data || data.length === 0) {
    return JSON.stringify({
      message: "Nessun ordine attivo al momento.",
      count: 0,
    });
  }

  const statusLabels: Record<string, string> = {
    pending: "In attesa",
    sent: "In attesa di conferma",
    confirmed: "Confermato",
    preparing: "In preparazione",
    ready: "Pronto per ritiro",
  };

  const orders = data.map((r: Record<string, unknown>) => {
    const order = r.orders as Record<string, unknown> | null;
    return {
      relay_id: (r.id as string).slice(0, 8),
      status: statusLabels[r.status as string] ?? r.status,
      dettagli: r.dealer_message ?? "—",
      importo: r.estimated_amount
        ? `€${(r.estimated_amount as number).toFixed(2)}`
        : "—",
      cliente: order?.customer_name ?? "—",
      indirizzo: order?.customer_address ?? "—",
    };
  });

  return JSON.stringify({ count: orders.length, orders });
}

async function updateAvailability(
  db: SupabaseClient,
  dealerContactId: string,
  available: boolean,
  until?: string
): Promise<string> {
  const update: Record<string, unknown> = {
    is_available: available,
  };

  if (!available && until) {
    // Parse simple time strings
    const now = new Date();
    let untilDate: Date | null = null;

    if (/^\d{1,2}:\d{2}$/.test(until)) {
      // "14:00" format — same day
      const [h, m] = until.split(":").map(Number);
      untilDate = new Date(now);
      untilDate.setHours(h, m, 0, 0);
      if (untilDate <= now) {
        // If time is past, assume tomorrow
        untilDate.setDate(untilDate.getDate() + 1);
      }
    } else if (until.toLowerCase() === "domani") {
      untilDate = new Date(now);
      untilDate.setDate(untilDate.getDate() + 1);
      untilDate.setHours(9, 0, 0, 0); // Default: 9 AM tomorrow
    }

    if (untilDate) {
      update.unavailable_until = untilDate.toISOString();
    }
  } else if (available) {
    update.unavailable_until = null;
  }

  const { error } = await db
    .from("rider_contacts")
    .update(update)
    .eq("id", dealerContactId);

  if (error) {
    return JSON.stringify({ error: error.message });
  }

  if (available) {
    return JSON.stringify({
      success: true,
      message: "Sei di nuovo disponibile! Gli ordini possono arrivare.",
    });
  }

  return JSON.stringify({
    success: true,
    message: `Sei in pausa.${until ? ` Fino a: ${until}` : ""} Scrivi APERTO per tornare disponibile.`,
  });
}

async function getDailySummary(
  db: SupabaseClient,
  dealerContactId: string
): Promise<string> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayISO = today.toISOString();

  const { data, error } = await db
    .from("order_relays")
    .select("id, status, estimated_amount, actual_amount, created_at")
    .eq("dealer_contact_id", dealerContactId)
    .gte("created_at", todayISO);

  if (error) {
    return JSON.stringify({ error: error.message });
  }

  if (!data || data.length === 0) {
    return JSON.stringify({
      message: "Nessun ordine oggi.",
      completed: 0,
      declined: 0,
      total: "€0.00",
    });
  }

  let completed = 0;
  let declined = 0;
  let totalAmount = 0;
  let pending = 0;

  for (const relay of data) {
    const status = relay.status as string;
    const amount =
      (relay.actual_amount as number) ?? (relay.estimated_amount as number) ?? 0;

    if (status === "picked_up" || status === "completed") {
      completed++;
      totalAmount += amount;
    } else if (status === "cancelled") {
      declined++;
    } else {
      pending++;
    }
  }

  return JSON.stringify({
    completed,
    declined,
    pending,
    total: `€${totalAmount.toFixed(2)}`,
    total_orders: data.length,
    message: `Oggi: ${completed} completati, ${declined} rifiutati, ${pending} attivi. Totale: €${totalAmount.toFixed(2)}`,
  });
}

async function setDealerConversationState(
  db: SupabaseClient,
  conversationId: string,
  newState: string
): Promise<string> {
  const { error } = await db
    .from("whatsapp_conversations")
    .update({ state: newState, last_message_at: new Date().toISOString() })
    .eq("id", conversationId);

  if (error) return JSON.stringify({ error: error.message });

  return JSON.stringify({
    success: true,
    new_state: newState,
  });
}
