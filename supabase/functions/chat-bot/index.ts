// Edge Function: chat-bot — Rider-facing AI chatbot with function calling
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { chatCompletion, type ChatMessage } from "../_shared/openai.ts";
import {
  getAuthClient,
  getServiceClient,
  extractJwt,
  getUserId,
  corsHeaders,
} from "../_shared/supabase.ts";
import { chatBotTools, executeFunction } from "./functions.ts";
import { buildSystemPrompt } from "./prompts.ts";

const MAX_FUNCTION_CALLS = 3;
const HISTORY_LIMIT = 20;

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Authenticate rider
    const jwt = extractJwt(req);
    if (!jwt) {
      return new Response(
        JSON.stringify({ error: "Missing authorization token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const riderId = await getUserId(jwt);
    if (!riderId) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Parse request
    const { text } = await req.json();
    if (!text || typeof text !== "string" || text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing 'text' field" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const authDb = getAuthClient(jwt);
    const serviceDb = getServiceClient();

    // 3. Save user message to DB
    await serviceDb.from("bot_messages").insert({
      rider_id: riderId,
      role: "user",
      content: text.trim(),
    });

    // 4. Fetch message history
    const { data: historyData } = await serviceDb
      .from("bot_messages")
      .select("role, content")
      .eq("rider_id", riderId)
      .order("created_at", { ascending: false })
      .limit(HISTORY_LIMIT);

    const history: ChatMessage[] = (historyData ?? [])
      .reverse()
      .map((m: Record<string, unknown>) => ({
        role: m.role as "user" | "assistant",
        content: m.content as string,
      }));

    // 5. Fetch rider context for system prompt
    const riderContext = await fetchRiderContext(serviceDb, riderId);

    // 6. Build messages array
    const systemPrompt = buildSystemPrompt(riderContext);
    const messages: ChatMessage[] = [
      { role: "system", content: systemPrompt },
      ...history,
    ];

    // 7. Call OpenAI with function calling loop (max 3 iterations)
    let response = await chatCompletion({
      messages,
      tools: chatBotTools,
    });

    let iterations = 0;
    while (response.toolCalls.length > 0 && iterations < MAX_FUNCTION_CALLS) {
      // Add assistant message with tool calls
      messages.push({
        role: "assistant",
        content: response.content,
        tool_calls: response.toolCalls,
      });

      // Execute each function call
      for (const toolCall of response.toolCalls) {
        let args: Record<string, unknown> = {};
        try {
          args = JSON.parse(toolCall.function.arguments || "{}");
        } catch {
          console.error("Failed to parse tool args:", toolCall.function.arguments);
        }
        const result = await executeFunction(
          toolCall.function.name,
          args,
          serviceDb,
          riderId
        );

        messages.push({
          role: "tool",
          content: result,
          tool_call_id: toolCall.id,
        });
      }

      // Call OpenAI again with function results
      response = await chatCompletion({
        messages,
        tools: chatBotTools,
      });

      iterations++;
    }

    const assistantContent =
      response.content?.trim() ??
      "Mi dispiace, non sono riuscito a elaborare la risposta. Riprova tra poco.";

    // 8. Save assistant response to DB
    await serviceDb.from("bot_messages").insert({
      rider_id: riderId,
      role: "assistant",
      content: assistantContent,
      tokens_used: response.usage.total_tokens,
      model: "gpt-4o-mini",
    });

    // 9. Return response
    return new Response(
      JSON.stringify({
        content: assistantContent,
        tokens_used: response.usage.total_tokens,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("chat-bot error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// ── Helpers ──────────────────────────────────────────────────────

interface RiderContext {
  riderName: string;
  todayEarnings: number;
  todayOrders: number;
  streak: number;
  rating: number;
  level: number;
  lifetimeEarnings: number;
  lifetimeOrders: number;
  plan: string;
  activeOrders: number;
}

async function fetchRiderContext(
  db: ReturnType<typeof getServiceClient>,
  riderId: string
): Promise<RiderContext> {
  const ctx: RiderContext = {
    riderName: "Rider",
    todayEarnings: 0,
    todayOrders: 0,
    streak: 0,
    rating: 0,
    level: 1,
    lifetimeEarnings: 0,
    lifetimeOrders: 0,
    plan: "free",
    activeOrders: 0,
  };

  // Fetch user profile
  try {
    const { data: user } = await db
      .from("users")
      .select("first_name, subscription_plan")
      .eq("id", riderId)
      .single();
    if (user) {
      ctx.riderName = (user.first_name as string) || "Rider";
      ctx.plan = (user.subscription_plan as string) || "free";
    }
  } catch (_) { /* continue with defaults */ }

  // Fetch rider stats
  try {
    const { data: stats } = await db
      .from("rider_stats")
      .select("current_level, avg_rating, current_daily_streak, lifetime_earnings, lifetime_orders")
      .eq("rider_id", riderId)
      .single();
    if (stats) {
      ctx.level = (stats.current_level as number) ?? 1;
      ctx.rating = (stats.avg_rating as number) ?? 0;
      ctx.streak = (stats.current_daily_streak as number) ?? 0;
      ctx.lifetimeEarnings = (stats.lifetime_earnings as number) ?? 0;
      ctx.lifetimeOrders = (stats.lifetime_orders as number) ?? 0;
    }
  } catch (_) { /* continue with defaults */ }

  // Fetch today's earnings
  try {
    const today = new Date().toISOString().split("T")[0];
    const { data: txns } = await db
      .from("transactions")
      .select("amount")
      .eq("rider_id", riderId)
      .gte("created_at", `${today}T00:00:00`)
      .gt("amount", 0);
    if (txns) {
      ctx.todayEarnings = txns.reduce(
        (sum: number, t: Record<string, unknown>) => sum + ((t.amount as number) ?? 0),
        0
      );
      ctx.todayOrders = txns.length;
    }
  } catch (_) { /* continue with defaults */ }

  // Fetch active orders count
  try {
    const { count } = await db
      .from("orders")
      .select("id", { count: "exact", head: true })
      .eq("rider_id", riderId)
      .in("status", ["pending", "accepted", "picked_up"]);
    ctx.activeOrders = count ?? 0;
  } catch (_) { /* continue with defaults */ }

  return ctx;
}
