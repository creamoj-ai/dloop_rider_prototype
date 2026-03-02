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
    caution_deposit: {
      piano_free: {
        cauzione: "€250",
        descrizione:
          "Deposito cauzionale obbligatorio per rider senza piano PRO",
        rimborso:
          "Rimborsabile alla cessazione del rapporto, meno eventuali danni a merci",
        motivo:
          "Garanzia per merci di valore trasportate (specialmente luxury)",
      },
      piano_pro: {
        costo: "€29/mese",
        cauzione: "€0 — NESSUNA cauzione richiesta",
        assicurazione: {
          tipo: "Assicurazione Qover",
          copertura_infortuni: "Infortuni durante l'attività di consegna",
          copertura_rc: "Responsabilità civile verso terzi",
          copertura_malattia: "Copertura in caso di malattia",
          partner: "Qover (usato anche da Deliveroo, Glovo, Wolt)",
        },
        vantaggi_extra: [
          "Assicurazione Qover inclusa",
          "Esenzione deposito cauzionale €250",
          "Accesso a Partner Benefits",
          "Zone prioritarie",
          "Badge PRO visibile ai dealer",
          "Supporto prioritario",
        ],
      },
      consiglio:
        "Il piano PRO a €29/mese include l'assicurazione Qover e ti esonera dal deposito di €250. Si ripaga da solo con i vantaggi e la tranquillità.",
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
