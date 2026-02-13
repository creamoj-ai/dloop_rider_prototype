// Shared Supabase client factory for Edge Functions
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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
 * Get the authenticated user ID from a JWT via Supabase.
 */
export async function getUserId(jwt: string): Promise<string | null> {
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });

  const { data, error } = await client.auth.getUser(jwt);
  if (error || !data.user) return null;
  return data.user.id;
}

/**
 * Standard CORS headers for Edge Functions.
 */
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
