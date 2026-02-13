// Function calling definitions and executors for WhatsApp customer bot
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { ToolDefinition } from "../_shared/openai.ts";

// ── Tool Definitions ──────────────────────────────────────────────

export const customerTools: ToolDefinition[] = [
  {
    type: "function",
    function: {
      name: "search_products",
      description:
        "Cerca prodotti nel catalogo dloop per nome o categoria (fuzzy search)",
      parameters: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description:
              "Testo di ricerca (nome prodotto, marca, o categoria)",
          },
        },
        required: ["query"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "create_order",
      description:
        "Crea un nuovo ordine per il cliente. Richiede product_id, quantità e indirizzo di consegna.",
      parameters: {
        type: "object",
        properties: {
          product_id: {
            type: "string",
            description: "ID del prodotto da ordinare",
          },
          quantity: {
            type: "number",
            description: "Quantità (default 1)",
          },
          delivery_address: {
            type: "string",
            description: "Indirizzo di consegna completo",
          },
          customer_notes: {
            type: "string",
            description: "Note aggiuntive del cliente",
          },
        },
        required: ["product_id", "delivery_address"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "check_order_status",
      description:
        "Controlla lo stato di un ordine. Senza order_id mostra l'ultimo ordine del cliente.",
      parameters: {
        type: "object",
        properties: {
          order_id: {
            type: "string",
            description:
              "ID dell'ordine (opzionale, se omesso mostra l'ultimo)",
          },
        },
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "cancel_order",
      description:
        "Annulla un ordine. Funziona solo se l'ordine è ancora in stato 'pending'.",
      parameters: {
        type: "object",
        properties: {
          order_id: {
            type: "string",
            description: "ID dell'ordine da annullare",
          },
        },
        required: ["order_id"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "set_conversation_state",
      description:
        "Aggiorna lo stato della conversazione (state machine). Usare per transizioni esplicite.",
      parameters: {
        type: "object",
        properties: {
          new_state: {
            type: "string",
            enum: ["idle", "ordering", "confirming", "tracking", "support"],
            description: "Nuovo stato della conversazione",
          },
        },
        required: ["new_state"],
      },
    },
  },
];

// ── Function Executors ────────────────────────────────────────────

export async function executeCustomerFunction(
  name: string,
  args: Record<string, unknown>,
  db: SupabaseClient,
  conversationId: string,
  phone: string
): Promise<string> {
  switch (name) {
    case "search_products":
      return await searchProducts(db, args.query as string);
    case "create_order": {
      // Get customer name from conversation
      const { data: conv } = await db
        .from("whatsapp_conversations")
        .select("customer_name")
        .eq("id", conversationId)
        .single();
      return await createOrder(db, phone, {
        productId: args.product_id as string,
        quantity: (args.quantity as number) ?? 1,
        deliveryAddress: args.delivery_address as string,
        customerNotes: args.customer_notes as string | undefined,
        customerName: (conv?.customer_name as string) ?? "Cliente WhatsApp",
      });
    }
    case "check_order_status":
      return await checkOrderStatus(
        db,
        phone,
        args.order_id as string | undefined
      );
    case "cancel_order":
      return await cancelOrder(db, phone, args.order_id as string);
    case "set_conversation_state":
      return await setConversationState(
        db,
        conversationId,
        args.new_state as string
      );
    default:
      return JSON.stringify({ error: `Funzione sconosciuta: ${name}` });
  }
}

// ── Individual Functions ──────────────────────────────────────────

async function searchProducts(
  db: SupabaseClient,
  query: string
): Promise<string> {
  // Search by name (primary), then by category/description as fallback
  const pattern = `%${query.trim()}%`;

  let { data, error } = await db
    .from("market_products")
    .select("id, name, description, price, category, stock")
    .eq("is_active", true)
    .ilike("name", pattern)
    .order("name")
    .limit(5);

  // Fallback: search by category if no name match
  if (!error && (!data || data.length === 0)) {
    ({ data, error } = await db
      .from("market_products")
      .select("id, name, description, price, category, stock")
      .eq("is_active", true)
      .ilike("category", pattern)
      .order("name")
      .limit(5));
  }

  if (error) return JSON.stringify({ error: error.message });
  if (!data || data.length === 0) {
    return JSON.stringify({
      message: `Nessun prodotto trovato per "${query}". Prova con un termine diverso.`,
    });
  }

  return JSON.stringify({
    results: data.map((p: Record<string, unknown>) => ({
      id: p.id,
      name: p.name,
      price: `€${(p.price as number)?.toFixed(2)}`,
      category: p.category,
      available: (p.stock as number) > 0,
      description: (p.description as string)?.slice(0, 100),
    })),
  });
}

async function createOrder(
  db: SupabaseClient,
  phone: string,
  opts: {
    productId: string;
    quantity: number;
    deliveryAddress: string;
    customerNotes?: string;
    customerName: string;
  }
): Promise<string> {
  // Verify product exists and is available
  const { data: product, error: prodErr } = await db
    .from("market_products")
    .select("id, name, price, stock")
    .eq("id", opts.productId)
    .eq("is_active", true)
    .single();

  if (prodErr || !product) {
    return JSON.stringify({ error: "Prodotto non trovato o non disponibile." });
  }

  if ((product.stock as number) < opts.quantity) {
    return JSON.stringify({
      error: `Disponibilità insufficiente. Stock attuale: ${product.stock}`,
    });
  }

  const unitPrice = product.price as number;
  const totalPrice = unitPrice * opts.quantity;

  // Create the order
  const { data: order, error: orderErr } = await db
    .from("market_orders")
    .insert({
      customer_name: opts.customerName,
      customer_phone: phone,
      product_id: opts.productId,
      product_name: product.name,
      quantity: opts.quantity,
      unit_price: unitPrice,
      total_price: totalPrice,
      customer_address: opts.deliveryAddress,
      notes: opts.customerNotes ?? null,
      status: "pending",
      source: "whatsapp",
    })
    .select("id, status, total_price")
    .single();

  if (orderErr) {
    return JSON.stringify({ error: `Errore creazione ordine: ${orderErr.message}` });
  }

  return JSON.stringify({
    success: true,
    order_id: order.id,
    product: product.name,
    quantity: opts.quantity,
    total: `€${totalPrice.toFixed(2)}`,
    status: "pending",
    message: `Ordine creato! ${opts.quantity}x ${product.name} per €${totalPrice.toFixed(2)}. In consegna a: ${opts.deliveryAddress}`,
  });
}

async function checkOrderStatus(
  db: SupabaseClient,
  phone: string,
  orderId?: string
): Promise<string> {
  let query = db
    .from("market_orders")
    .select("id, product_id, product_name, quantity, total_price, status, customer_address, created_at, notes")
    .eq("customer_phone", phone)
    .eq("source", "whatsapp");

  if (orderId) {
    query = query.eq("id", orderId);
  } else {
    query = query.order("created_at", { ascending: false }).limit(1);
  }

  const { data, error } = await query;

  if (error) return JSON.stringify({ error: error.message });
  if (!data || data.length === 0) {
    return JSON.stringify({
      message: "Nessun ordine trovato. Vuoi ordinare qualcosa?",
    });
  }

  const order = data[0];
  const statusLabels: Record<string, string> = {
    pending: "In attesa di conferma",
    accepted: "Accettato dal rider",
    picked_up: "In consegna",
    delivered: "Consegnato",
    cancelled: "Annullato",
  };

  return JSON.stringify({
    order_id: (order.id as string).slice(0, 8),
    status: statusLabels[order.status as string] ?? order.status,
    total: `€${(order.total_price as number)?.toFixed(2)}`,
    delivery_address: order.customer_address,
    created_at: order.created_at,
  });
}

async function cancelOrder(
  db: SupabaseClient,
  phone: string,
  orderId: string
): Promise<string> {
  // Check order exists and belongs to this phone
  const { data: order, error: fetchErr } = await db
    .from("market_orders")
    .select("id, status")
    .eq("id", orderId)
    .eq("customer_phone", phone)
    .eq("source", "whatsapp")
    .single();

  if (fetchErr || !order) {
    return JSON.stringify({ error: "Ordine non trovato." });
  }

  if (order.status !== "pending") {
    return JSON.stringify({
      error: `Impossibile annullare: l'ordine è già in stato "${order.status}". Solo ordini "pending" possono essere annullati.`,
    });
  }

  const { error: updateErr } = await db
    .from("market_orders")
    .update({ status: "cancelled" })
    .eq("id", orderId);

  if (updateErr) {
    return JSON.stringify({ error: `Errore: ${updateErr.message}` });
  }

  return JSON.stringify({
    success: true,
    message: "Ordine annullato con successo.",
  });
}

async function setConversationState(
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
