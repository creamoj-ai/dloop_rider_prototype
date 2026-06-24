// Function calling definitions and executors for the rider chatbot
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { ToolDefinition } from "../_shared/openai.ts";

// ── Tool Definitions ──────────────────────────────────────────────

export const chatBotTools: ToolDefinition[] = [
  {
    type: "function",
    function: {
      name: "get_active_orders",
      description:
        "Recupera gli ordini attivi del rider (pending, accepted, picked_up)",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
  {
    type: "function",
    function: {
      name: "get_today_earnings",
      description: "Recupera i guadagni di oggi dal database transazioni",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
  {
    type: "function",
    function: {
      name: "get_rider_stats",
      description:
        "Recupera le statistiche complete del rider (livello, XP, streak, rating, ordini totali)",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
  {
    type: "function",
    function: {
      name: "get_hot_zones",
      description:
        "Recupera le zone calde con più ordini per ora, ordinate per attività",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
  {
    type: "function",
    function: {
      name: "get_pricing_info",
      description:
        "Recupera le tariffe del rider (prezzo base, per km, supplementi)",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
  {
    type: "function",
    function: {
      name: "calculate_delivery_fee",
      description:
        "Calcola il compenso stimato per una consegna data la distanza in km",
      parameters: {
        type: "object",
        properties: {
          distance_km: {
            type: "number",
            description: "Distanza della consegna in chilometri",
          },
          is_luxury: {
            type: "boolean",
            description: "Se è una consegna luxury (bonus +30%)",
          },
        },
        required: ["distance_km"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "get_luxury_delivery_info",
      description:
        "Informazioni sulle procedure di consegna luxury (Yamamay, Jolie, gioielli)",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
  {
    type: "function",
    function: {
      name: "get_caution_deposit_info",
      description:
        "Informazioni sulla cauzione €250 e le differenze tra piano Free e Pro",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
  {
    type: "function",
    function: {
      name: "get_market_products",
      description:
        "Recupera i prodotti disponibili nel marketplace dloop (filtro opzionale per categoria)",
      parameters: {
        type: "object",
        properties: {
          category: {
            type: "string",
            description:
              "Categoria prodotto da filtrare (es. 'profumi', 'abbigliamento')",
          },
        },
        required: [],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "get_referral_system_info",
      description:
        "Informazioni complete sul sistema referral: come invitare rider (€10) e segnalare dealer (€50)",
      parameters: { type: "object", properties: {}, required: [] },
    },
  },
];

// ── Function Executors ────────────────────────────────────────────

export async function executeFunction(
  name: string,
  args: Record<string, unknown>,
  db: SupabaseClient,
  riderId: string
): Promise<string> {
  switch (name) {
    case "get_active_orders":
      return await getActiveOrders(db, riderId);
    case "get_today_earnings":
      return await getTodayEarnings(db, riderId);
    case "get_rider_stats":
      return await getRiderStats(db, riderId);
    case "get_hot_zones":
      return await getHotZones(db);
    case "get_pricing_info":
      return await getPricingInfo(db, riderId);
    case "calculate_delivery_fee":
      return await calculateDeliveryFee(
        db,
        riderId,
        args.distance_km as number,
        (args.is_luxury as boolean) ?? false
      );
    case "get_luxury_delivery_info":
      return getLuxuryDeliveryInfo();
    case "get_caution_deposit_info":
      return getCautionDepositInfo();
    case "get_market_products":
      return await getMarketProducts(db, args.category as string | undefined);
    case "get_referral_system_info":
      return getReferralSystemInfo();
    default:
      return JSON.stringify({ error: `Funzione sconosciuta: ${name}` });
  }
}

// ── Individual Functions ──────────────────────────────────────────

async function getActiveOrders(
  db: SupabaseClient,
  riderId: string
): Promise<string> {
  const { data, error } = await db
    .from("orders")
    .select(
      "id, status, pickup_address, delivery_address, total_amount, created_at, estimated_delivery_time"
    )
    .eq("rider_id", riderId)
    .in("status", ["pending", "accepted", "picked_up"])
    .order("created_at", { ascending: false });

  if (error) return JSON.stringify({ error: error.message });
  if (!data || data.length === 0)
    return JSON.stringify({ message: "Nessun ordine attivo al momento." });

  return JSON.stringify({
    active_orders: data.length,
    orders: data.map((o: Record<string, unknown>) => ({
      id: (o.id as string).slice(0, 8),
      status: o.status,
      pickup: o.pickup_address,
      delivery: o.delivery_address,
      amount: `€${(o.total_amount as number)?.toFixed(2) ?? "0.00"}`,
      created: o.created_at,
    })),
  });
}

async function getTodayEarnings(
  db: SupabaseClient,
  riderId: string
): Promise<string> {
  const today = new Date().toISOString().split("T")[0];

  const { data, error } = await db
    .from("transactions")
    .select("amount, type, description, created_at")
    .eq("rider_id", riderId)
    .gte("created_at", `${today}T00:00:00`)
    .lte("created_at", `${today}T23:59:59`);

  if (error) return JSON.stringify({ error: error.message });

  const earnings = (data ?? []).filter(
    (t: Record<string, unknown>) => (t.amount as number) > 0
  );
  const total = earnings.reduce(
    (sum: number, t: Record<string, unknown>) => sum + (t.amount as number),
    0
  );

  return JSON.stringify({
    today_total: `€${total.toFixed(2)}`,
    transactions_count: earnings.length,
    breakdown: earnings.map((t: Record<string, unknown>) => ({
      amount: `€${(t.amount as number).toFixed(2)}`,
      type: t.type,
      description: t.description,
    })),
  });
}

async function getRiderStats(
  db: SupabaseClient,
  riderId: string
): Promise<string> {
  const { data, error } = await db
    .from("rider_stats")
    .select("*")
    .eq("rider_id", riderId)
    .single();

  if (error) return JSON.stringify({ error: error.message });
  if (!data) return JSON.stringify({ message: "Statistiche non trovate." });

  return JSON.stringify({
    level: data.current_level,
    xp: data.total_xp,
    xp_next_level: data.xp_for_next_level,
    rating: data.avg_rating,
    streak: data.current_daily_streak,
    best_streak: data.best_daily_streak,
    lifetime_earnings: `€${(data.lifetime_earnings as number)?.toFixed(2)}`,
    lifetime_orders: data.lifetime_orders,
    acceptance_rate: `${((data.acceptance_rate as number) * 100)?.toFixed(0)}%`,
  });
}

async function getHotZones(db: SupabaseClient): Promise<string> {
  const { data, error } = await db
    .from("hot_zones")
    .select("zone_name, orders_per_hour, surge_multiplier, active_riders")
    .eq("is_active", true)
    .order("orders_per_hour", { ascending: false })
    .limit(5);

  if (error) return JSON.stringify({ error: error.message });
  if (!data || data.length === 0)
    return JSON.stringify({
      message: "Nessuna zona calda attiva al momento.",
    });

  return JSON.stringify({
    hot_zones: data.map((z: Record<string, unknown>) => ({
      zone: z.zone_name,
      orders_per_hour: z.orders_per_hour,
      surge: `${z.surge_multiplier}x`,
      active_riders: z.active_riders,
    })),
  });
}

async function getPricingInfo(
  db: SupabaseClient,
  riderId: string
): Promise<string> {
  const { data, error } = await db
    .from("rider_pricing")
    .select("*")
    .eq("rider_id", riderId)
    .single();

  if (error || !data) {
    return JSON.stringify({
      base_fee: "€3.50",
      per_km: "€0.80",
      surge_multiplier: "1.0x",
      note: "Tariffe standard (nessuna personalizzazione trovata)",
    });
  }

  return JSON.stringify({
    base_fee: `€${(data.base_fee as number)?.toFixed(2)}`,
    per_km: `€${(data.per_km_fee as number)?.toFixed(2)}`,
    surge_multiplier: `${data.surge_multiplier}x`,
    night_bonus: data.night_bonus ? `€${(data.night_bonus as number)?.toFixed(2)}` : "N/A",
    rain_bonus: data.rain_bonus ? `€${(data.rain_bonus as number)?.toFixed(2)}` : "N/A",
  });
}

async function calculateDeliveryFee(
  db: SupabaseClient,
  riderId: string,
  distanceKm: number,
  isLuxury: boolean
): Promise<string> {
  // Get rider's pricing or use defaults
  const { data } = await db
    .from("rider_pricing")
    .select("base_fee, per_km_fee")
    .eq("rider_id", riderId)
    .single();

  const baseFee = (data?.base_fee as number) ?? 3.5;
  const perKm = (data?.per_km_fee as number) ?? 0.8;

  let fee = baseFee + perKm * distanceKm;
  const luxuryBonus = isLuxury ? fee * 0.3 : 0;
  fee += luxuryBonus;

  return JSON.stringify({
    distance_km: distanceKm,
    base_fee: `€${baseFee.toFixed(2)}`,
    distance_fee: `€${(perKm * distanceKm).toFixed(2)}`,
    luxury_bonus: isLuxury ? `€${luxuryBonus.toFixed(2)} (+30%)` : "N/A",
    estimated_total: `€${fee.toFixed(2)}`,
    note: "Stima basata sulle tue tariffe attuali. Il compenso finale può variare.",
  });
}

function getLuxuryDeliveryInfo(): string {
  return JSON.stringify({
    luxury_delivery: {
      overview:
        "dloop offre consegne speciali per brand di lusso e moda con bonus +30% sulla tariffa base.",
      requisiti: {
        rating_minimo: "4.5/5",
        completamento_training: true,
      },
      brands: [
        {
          name: "Yamamay / Cimmino Group",
          category: "Intimo e abbigliamento",
          procedure: [
            "Consegna in busta elegante brandizzata",
            "Mai piegare o schiacciare i capi",
            "Conferma visiva al ritiro (foto packaging)",
            "Tempo max consegna: 45 min zona urbana",
          ],
        },
        {
          name: "Jolie profumerie (Afragola)",
          category: "Profumi e cosmetici",
          procedure: [
            "Trasporto SEMPRE in posizione verticale",
            "Evitare sbalzi termici (no sole diretto, no bagagliaio caldo)",
            "Packaging originale deve restare intatto",
            "Consegna delicata: appoggare, non lanciare",
          ],
        },
        {
          name: "Gioielli e accessori",
          category: "Gioielleria",
          procedure: [
            "Custodia rigida obbligatoria",
            "Foto al ritiro e alla consegna",
            "Firma del destinatario obbligatoria",
            "Contatto telefonico 5 min prima della consegna",
          ],
        },
      ],
    },
  });
}

function getCautionDepositInfo(): string {
  return JSON.stringify({
    piani_confronto: {
      piano_free: {
        costo_mensile: "€0",
        cauzione: "€250 obbligatoria",
        descrizione_cauzione:
          "Deposito cauzionale come garanzia per merci di valore trasportate (specialmente luxury)",
        rimborso:
          "Rimborsabile alla cessazione del rapporto, meno eventuali danni a merci",
        assicurazione: "Nessuna",
        partner_benefits: "Non inclusi",
      },
      piano_pro: {
        costo_mensile: "€29",
        cauzione: "€0 — ESENZIONE COMPLETA",
        assicurazione: {
          provider: "Qover",
          descrizione:
            "Stesso partner assicurativo di Deliveroo, Glovo e Wolt",
          coperture: [
            "Infortuni durante l'attività di consegna",
            "Responsabilità civile verso terzi",
            "Copertura in caso di malattia",
          ],
        },
        vantaggi_inclusi: [
          "Assicurazione Qover completa",
          "Esenzione cauzione €250",
          "Partner Benefits (Fiscozen P.IVA, Finom conto business, ho.Mobile dati, SumUp POS)",
          "Zone prioritarie",
          "Badge PRO visibile ai dealer",
          "Supporto prioritario via chat",
        ],
      },
      nuovo_modello_guadagni: {
        descrizione:
          "Con il modello SaaS di dloop, NON ci sono commissioni sui tuoi guadagni",
        come_funziona: [
          "Tu imposti le tariffe con i tuoi dealer (es. €5/consegna)",
          "Guadagni il 100% di quanto pattuito",
          "dloop guadagna solo dall'abbonamento del dealer (€19-€49/mese)",
          "Bonus extra: €10 per ogni rider che inviti, €50 per ogni dealer che segnali",
        ],
        confronto_vecchio_modello: {
          prima: "Commissioni 6% primi 3 mesi, poi 3% dal 4° mese",
          ora: "0% commissioni — guadagni tutto tu",
        },
      },
      consiglio:
        "Il piano PRO costa €29/mese ma ti risparmia €250 di cauzione subito + hai assicurazione completa Qover. Con il nuovo modello senza commissioni, guadagni di più e lavori protetto.",
    },
  });
}

async function getMarketProducts(
  db: SupabaseClient,
  category?: string
): Promise<string> {
  let query = db
    .from("market_products")
    .select("id, name, description, price, category, stock, image_url")
    .eq("is_active", true)
    .order("name");

  if (category) {
    query = query.ilike("category", `%${category}%`);
  }

  const { data, error } = await query.limit(10);

  if (error) return JSON.stringify({ error: error.message });
  if (!data || data.length === 0)
    return JSON.stringify({
      message: category
        ? `Nessun prodotto trovato nella categoria "${category}".`
        : "Nessun prodotto disponibile nel marketplace.",
    });

  return JSON.stringify({
    products_count: data.length,
    products: data.map((p: Record<string, unknown>) => ({
      name: p.name,
      category: p.category,
      price: `€${(p.price as number)?.toFixed(2)}`,
      available: (p.stock as number) > 0,
      description: p.description,
    })),
  });
}

function getReferralSystemInfo(): string {
  return JSON.stringify({
    sistema_referral: {
      rider_referral: {
        bonus: "€10",
        come_funziona: [
          "Vai su 'Invita e guadagna' nella schermata Money",
          "Condividi il tuo codice referral (es. DLOOP1234)",
          "Il nuovo rider si registra usando il tuo codice",
          "Quando completa 5 consegne, ricevi €10 bonus",
        ],
        condizioni: "Il bonus viene accreditato automaticamente dopo la 5a consegna completata dal rider invitato",
      },
      dealer_referral: {
        bonus: "€50",
        come_funziona: [
          "Segnala un dealer/ristorante/negozio dalla sezione 'Segnala Dealer'",
          "Inserisci nome, telefono/email del dealer",
          "dloop contatta il dealer e lo onboarda sulla piattaforma",
          "Quando il dealer completa 10 ordini tramite dloop, ricevi €50 bonus",
        ],
        condizioni: "Bonus pagato dopo 10 ordini completati dal dealer segnalato (tracciamento automatico)",
        nota: "I dealer pagano un abbonamento mensile a dloop (€19-€49), NON ti tolgono commissioni",
      },
      nuovo_modello: {
        zero_commissioni: "dloop NON prende commissioni sui tuoi guadagni",
        come_guadagni: [
          "Tu imposti le tariffe con i tuoi dealer (es. €5/consegna)",
          "Guadagni il 100% di quanto pattuito",
          "dloop guadagna solo dall'abbonamento del dealer",
        ],
        vantaggi: [
          "Più dealer segnali = più rete = più ordini per te",
          "Bonus €50 per ogni dealer attivato",
          "Nessuna perdita percentuale sui guadagni",
        ],
      },
    },
  });
}
