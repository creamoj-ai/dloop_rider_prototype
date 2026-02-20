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
  // ── New tools (6-10) ──────────────────────────────────────────
  {
    type: "function",
    function: {
      name: "browse_dealer_menu",
      description:
        "Mostra il menu/prodotti di un dealer specifico o cerca dealer per tipo di prodotto.",
      parameters: {
        type: "object",
        properties: {
          dealer_name: {
            type: "string",
            description: "Nome del dealer/negozio (es. 'Pizzeria Da Mario')",
          },
          product_type: {
            type: "string",
            description: "Tipo di prodotto (es. 'pizza', 'profumo', 'dolci')",
          },
        },
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "create_delivery_order",
      description:
        "Crea un ordine di consegna completo tramite un rider DLOOP. Collega il cliente al dealer e crea il relay.",
      parameters: {
        type: "object",
        properties: {
          items: {
            type: "string",
            description:
              "Descrizione degli articoli ordinati (es. '2x Margherita, 1x Tiramisù')",
          },
          delivery_address: {
            type: "string",
            description: "Indirizzo di consegna completo",
          },
          dealer_name: {
            type: "string",
            description:
              "Nome del dealer da cui ordinare (cerca in rider_contacts)",
          },
          customer_notes: {
            type: "string",
            description: "Note per la consegna",
          },
        },
        required: ["items", "delivery_address"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "get_payment_link",
      description:
        "Genera un link Stripe per pagare un ordine online.",
      parameters: {
        type: "object",
        properties: {
          order_id: {
            type: "string",
            description: "ID dell'ordine da pagare",
          },
        },
        required: ["order_id"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "submit_feedback",
      description:
        "Invia una valutazione dopo la consegna. Chiedere voto (1-5) e commento opzionale.",
      parameters: {
        type: "object",
        properties: {
          order_id: {
            type: "string",
            description: "ID dell'ordine da valutare",
          },
          rating: {
            type: "number",
            description: "Voto da 1 a 5",
          },
          comment: {
            type: "string",
            description: "Commento opzionale",
          },
        },
        required: ["order_id", "rating"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "get_faq",
      description:
        "Rispondi a domande frequenti su dloop: tempi, costi, zone, pagamento, come funziona.",
      parameters: {
        type: "object",
        properties: {
          topic: {
            type: "string",
            description:
              "Argomento della domanda (tempi, costi, zone, pagamento, funzionamento, altro)",
          },
        },
        required: ["topic"],
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
    case "browse_dealer_menu":
      return await browseDealerMenu(
        db,
        args.dealer_name as string | undefined,
        args.product_type as string | undefined
      );
    case "create_delivery_order": {
      const { data: conv2 } = await db
        .from("whatsapp_conversations")
        .select("customer_name")
        .eq("id", conversationId)
        .single();
      return await createDeliveryOrder(db, phone, conversationId, {
        items: args.items as string,
        deliveryAddress: args.delivery_address as string,
        dealerName: args.dealer_name as string | undefined,
        customerNotes: args.customer_notes as string | undefined,
        customerName: (conv2?.customer_name as string) ?? "Cliente WhatsApp",
      });
    }
    case "get_payment_link":
      return await getPaymentLink(db, args.order_id as string);
    case "submit_feedback":
      return await submitFeedback(
        db,
        phone,
        args.order_id as string,
        args.rating as number,
        args.comment as string | undefined
      );
    case "get_faq":
      return getFaq(args.topic as string);
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

// ── New Functions (6-10) ──────────────────────────────────────────

async function browseDealerMenu(
  db: SupabaseClient,
  dealerName?: string,
  productType?: string
): Promise<string> {
  // If dealer name provided, find the dealer and their products
  if (dealerName) {
    const pattern = `%${dealerName.trim()}%`;
    const { data: dealers } = await db
      .from("rider_contacts")
      .select("id, rider_id, name, phone")
      .eq("contact_type", "dealer")
      .ilike("name", pattern)
      .limit(3);

    if (!dealers || dealers.length === 0) {
      return JSON.stringify({
        message: `Nessun negozio trovato per "${dealerName}". Prova un nome diverso.`,
      });
    }

    // For each dealer, get their rider's products
    const results = [];
    for (const dealer of dealers) {
      const { data: products } = await db
        .from("market_products")
        .select("id, name, price, category, stock, description")
        .eq("rider_id", dealer.rider_id)
        .eq("is_active", true)
        .limit(10);

      results.push({
        dealer_name: dealer.name,
        products: (products ?? []).map((p: Record<string, unknown>) => ({
          id: p.id,
          name: p.name,
          price: `€${(p.price as number)?.toFixed(2)}`,
          category: p.category,
          available: (p.stock as number) > 0,
        })),
      });
    }

    return JSON.stringify({ dealers: results });
  }

  // If product type provided, search across all products
  if (productType) {
    const pattern = `%${productType.trim()}%`;
    const { data: products } = await db
      .from("market_products")
      .select("id, name, price, category, stock, rider_id")
      .eq("is_active", true)
      .or(`name.ilike.${pattern},category.ilike.${pattern}`)
      .limit(8);

    if (!products || products.length === 0) {
      return JSON.stringify({
        message: `Nessun prodotto di tipo "${productType}" trovato.`,
      });
    }

    return JSON.stringify({
      results: products.map((p: Record<string, unknown>) => ({
        id: p.id,
        name: p.name,
        price: `€${(p.price as number)?.toFixed(2)}`,
        category: p.category,
        available: (p.stock as number) > 0,
      })),
    });
  }

  // No filters — show available dealers
  const { data: dealers } = await db
    .from("rider_contacts")
    .select("id, name, status")
    .eq("contact_type", "dealer")
    .eq("status", "active")
    .limit(10);

  return JSON.stringify({
    message: "Ecco i negozi disponibili. Dimmi da quale vuoi ordinare!",
    dealers: (dealers ?? []).map((d: Record<string, unknown>) => ({
      name: d.name,
    })),
  });
}

async function createDeliveryOrder(
  db: SupabaseClient,
  phone: string,
  conversationId: string,
  opts: {
    items: string;
    deliveryAddress: string;
    dealerName?: string;
    customerNotes?: string;
    customerName: string;
  }
): Promise<string> {
  // Find dealer by name
  let dealerContact: Record<string, unknown> | null = null;

  if (opts.dealerName) {
    const pattern = `%${opts.dealerName.trim()}%`;
    const { data } = await db
      .from("rider_contacts")
      .select("id, rider_id, name, phone")
      .eq("contact_type", "dealer")
      .ilike("name", pattern)
      .limit(1)
      .single();
    dealerContact = data;
  } else {
    // Try to find the most recently used dealer for this customer
    const { data } = await db
      .from("rider_contacts")
      .select("id, rider_id, name, phone")
      .eq("contact_type", "dealer")
      .eq("status", "active")
      .limit(1)
      .single();
    dealerContact = data;
  }

  if (!dealerContact) {
    return JSON.stringify({
      error: opts.dealerName
        ? `Negozio "${opts.dealerName}" non trovato. Scrivi il nome esatto.`
        : "Nessun negozio disponibile. Specifica il nome del negozio.",
    });
  }

  // Get rider's pricing or use defaults
  const { data: pricing } = await db
    .from("rider_pricing")
    .select("base_fee, per_km_fee")
    .eq("rider_id", dealerContact.rider_id as string)
    .single();

  const baseEarning = (pricing?.base_fee as number) ?? 3.5;
  const minGuarantee = Math.max(baseEarning, 3.0);

  // Create order in the main orders table
  const { data: order, error: orderErr } = await db
    .from("orders")
    .insert({
      rider_id: dealerContact.rider_id,
      restaurant_name: dealerContact.name,
      restaurant_address: "", // Will be filled by dealer
      customer_name: opts.customerName,
      customer_address: opts.deliveryAddress,
      customer_phone: phone,
      wa_conversation_id: conversationId,
      status: "pending",
      source: "whatsapp",
      base_earning: baseEarning,
      bonus_earning: 0,
      tip_amount: 0,
      rush_multiplier: 1.0,
      hold_cost: 0,
      hold_minutes: 0,
      min_guarantee: minGuarantee,
      total_earning: baseEarning,
      distance_km: 0,
      dealer_contact_id: dealerContact.id,
    })
    .select("id")
    .single();

  if (orderErr || !order) {
    return JSON.stringify({
      error: `Errore creazione ordine: ${orderErr?.message ?? "sconosciuto"}`,
    });
  }

  // Auto-create order relay
  const { error: relayErr } = await db.from("order_relays").insert({
    order_id: order.id,
    rider_id: dealerContact.rider_id,
    dealer_contact_id: dealerContact.id,
    relay_channel: "whatsapp",
    status: "pending",
    dealer_message: opts.items,
    estimated_amount: 0,
  });

  if (relayErr) {
    console.error("Failed to create relay:", relayErr);
  }

  return JSON.stringify({
    success: true,
    order_id: (order.id as string).slice(0, 8),
    dealer: dealerContact.name,
    items: opts.items,
    delivery_address: opts.deliveryAddress,
    estimated_time: "30-45 min",
    message: `Ordine inviato a ${dealerContact.name}! ID: ${(order.id as string).slice(0, 8)}. Il rider ti aggiornerà sullo stato. Tempo stimato: 30-45 min.`,
  });
}

async function getPaymentLink(
  db: SupabaseClient,
  orderId: string
): Promise<string> {
  // Check if this order has a relay with a Stripe link
  const { data: relay } = await db
    .from("order_relays")
    .select("id, stripe_payment_link, payment_status, estimated_amount, actual_amount")
    .eq("order_id", orderId)
    .limit(1)
    .single();

  if (!relay) {
    // Try market_orders
    const { data: marketOrder } = await db
      .from("market_orders")
      .select("id, total_price")
      .eq("id", orderId)
      .single();

    if (!marketOrder) {
      return JSON.stringify({ error: "Ordine non trovato." });
    }

    return JSON.stringify({
      message: "Per il pagamento di questo ordine, contatta il rider alla consegna (contanti o POS).",
      amount: `€${(marketOrder.total_price as number)?.toFixed(2)}`,
    });
  }

  if (relay.stripe_payment_link) {
    return JSON.stringify({
      success: true,
      payment_link: relay.stripe_payment_link,
      amount: relay.actual_amount ?? relay.estimated_amount,
      status: relay.payment_status,
      message: "Ecco il link per pagare:",
    });
  }

  return JSON.stringify({
    message: "Il link di pagamento non è ancora disponibile. Il rider lo genererà dopo la conferma del dealer.",
  });
}

async function submitFeedback(
  db: SupabaseClient,
  phone: string,
  orderId: string,
  rating: number,
  comment?: string
): Promise<string> {
  if (rating < 1 || rating > 5) {
    return JSON.stringify({ error: "Il voto deve essere tra 1 e 5." });
  }

  // Check order exists (in either orders or market_orders)
  const { data: order } = await db
    .from("orders")
    .select("id")
    .eq("id", orderId)
    .single();

  const { data: marketOrder } = !order
    ? await db.from("market_orders").select("id").eq("id", orderId).single()
    : { data: order };

  if (!order && !marketOrder) {
    return JSON.stringify({ error: "Ordine non trovato." });
  }

  const actualOrderId = order?.id ?? marketOrder?.id;

  // Check for duplicate feedback
  const { data: existing } = await db
    .from("customer_feedback")
    .select("id")
    .eq("order_id", actualOrderId)
    .eq("customer_phone", phone)
    .limit(1);

  if (existing && existing.length > 0) {
    return JSON.stringify({
      message: "Hai già lasciato un feedback per questo ordine. Grazie!",
    });
  }

  const { error } = await db.from("customer_feedback").insert({
    order_id: actualOrderId,
    customer_phone: phone,
    rating,
    comment: comment ?? null,
  });

  if (error) {
    return JSON.stringify({ error: `Errore: ${error.message}` });
  }

  const stars = "⭐".repeat(rating);
  return JSON.stringify({
    success: true,
    message: `Grazie per il feedback! ${stars}${comment ? ` — "${comment}"` : ""}`,
  });
}

function getFaq(topic: string): string {
  const faqs: Record<string, string> = {
    tempi:
      "La consegna richiede di solito 30-60 minuti, a seconda della distanza e del tempo di preparazione del negozio.",
    costi:
      "La consegna costa da €3.50. Gratuita per ordini sopra €50. Nessun costo aggiuntivo nascosto.",
    zone:
      "DLOOP opera a Napoli e provincia (Campania). Le zone attive dipendono dai rider disponibili.",
    pagamento:
      "Puoi pagare con: link Stripe (carta online), contanti alla consegna, o POS del rider.",
    funzionamento:
      "1. Scegli un negozio e ordina via WhatsApp\n2. Il rider invia l'ordine al negozio\n3. Il negozio prepara\n4. Il rider ritira e consegna a te\nTutto in 30-60 min!",
    supporto:
      "Per assistenza, scrivi 'supporto' in chat o contatta il nostro team. Siamo qui per aiutarti!",
    orari:
      "Gli orari dipendono dal negozio. La maggior parte è disponibile dalle 10:00 alle 22:00.",
    annullamento:
      "Puoi annullare un ordine solo se è ancora in stato 'in attesa'. Una volta confermato dal negozio, non è più annullabile.",
  };

  const key = topic.toLowerCase().trim();

  // Try exact match
  if (faqs[key]) {
    return JSON.stringify({ answer: faqs[key] });
  }

  // Fuzzy match
  for (const [faqKey, answer] of Object.entries(faqs)) {
    if (key.includes(faqKey) || faqKey.includes(key)) {
      return JSON.stringify({ answer });
    }
  }

  return JSON.stringify({
    answer:
      "Non ho una risposta specifica per questa domanda. Posso aiutarti con: tempi, costi, zone, pagamento, come funziona, supporto, orari, annullamento.",
  });
}
