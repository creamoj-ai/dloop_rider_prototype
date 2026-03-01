import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const db = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false },
});

serve(async (req: Request) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = await req.json();

    const {
      customer_name,
      customer_phone,
      customer_address,
      items,
      total_price,
      status = "PENDING",
    } = body;

    // Insert into pwa_orders (simple schema, no RLS)
    const { data, error } = await db
      .from("pwa_orders")
      .insert([
        {
          customer_name,
          customer_phone,
          customer_address,
          items,
          total_price,
          status,
          created_at: new Date().toISOString(),
        },
      ])
      .select();

    if (error) {
      console.error("DB Error:", error);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!data || !data[0]) {
      return new Response(
        JSON.stringify({ error: "Order creation failed" }),
        { status: 500 }
      );
    }

    console.log(`✅ Test order created: ${data[0].id}`);

    return new Response(
      JSON.stringify({
        success: true,
        orderId: data[0].id,
        order: data[0],
      }),
      {
        status: 201,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err) {
    console.error("Function error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500 }
    );
  }
});
