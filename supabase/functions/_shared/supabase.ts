// Shared Supabase client factory for Edge Functions
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// Connect to MAIN database (imhjdsjtaommutdmkouf) where WhatsApp tables are
// Use custom env var names (Supabase doesn't allow SUPABASE_ prefix in secrets)
const SUPABASE_URL = Deno.env.get("DB_URL") ?? Deno.env.get("SUPABASE_URL") ?? "https://imhjdsjtaommutdmkouf.supabase.co";
const SUPABASE_ANON_KEY = Deno.env.get("DB_ANON_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("DB_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

/**
 * Service client — bypasses RLS.
 * Use for: WhatsApp bot (customers are not Supabase users), admin operations.
 */
export function getServiceClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
}

/**
 * Auth client — respects RLS using the rider's JWT.
 * Use for: Authenticated rider operations (chatbot).
 */
export function getAuthClient(jwt: string): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });
}

/**
 * Extract JWT from request Authorization header.
 * Returns null if missing or malformed.
 */
export function extractJwt(req: Request): string | null {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;
  return authHeader.slice(7);
}

/**
 * Get the authenticated user ID from a JWT via Supabase Auth API.
 * Uses direct fetch to avoid supabase-js client key format issues.
 */
export async function getUserId(jwt: string): Promise<string | null> {
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: {
        "Authorization": `Bearer ${jwt}`,
        "apikey": SUPABASE_ANON_KEY,
      },
    });
    if (!res.ok) {
      console.error("getUserId failed:", res.status, await res.text());
      return null;
    }
    const user = await res.json();
    return user?.id ?? null;
  } catch (e) {
    console.error("getUserId error:", e);
    return null;
  }
}

/**
 * Standard CORS headers for Edge Functions.
 */
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-admin-key",
};
