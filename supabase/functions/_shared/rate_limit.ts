// In-memory sliding window rate limiter for Edge Functions
// Note: Each EF invocation may run in a fresh isolate, so this provides
// per-isolate protection. For strict global limits, use a DB counter.

const windows = new Map<string, number[]>();

/**
 * Check if a request should be allowed under the rate limit.
 * @param key   Unique identifier (e.g. "admin" or phone number)
 * @param max   Max requests allowed in the window
 * @param windowMs  Window duration in milliseconds (default 60s)
 * @returns true if allowed, false if rate-limited
 */
export function checkRateLimit(
  key: string,
  max: number,
  windowMs = 60_000
): boolean {
  const now = Date.now();
  const timestamps = windows.get(key) ?? [];

  // Remove expired entries
  const valid = timestamps.filter((t) => now - t < windowMs);

  if (valid.length >= max) {
    windows.set(key, valid);
    return false; // rate limited
  }

  valid.push(now);
  windows.set(key, valid);
  return true; // allowed
}

/**
 * Returns a 429 Too Many Requests Response.
 */
export function rateLimitResponse(corsHeaders: Record<string, string>): Response {
  return new Response(
    JSON.stringify({ error: "Too many requests. Please try again later." }),
    {
      status: 429,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}
