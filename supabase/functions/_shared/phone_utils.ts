// Shared phone number normalization for Italian numbers
// Used by whatsapp-webhook router to match dealer phones

/**
 * Normalize a phone number to digits-only with country code.
 * Handles Italian formats:
 *   "+39 333 1234567" → "393331234567"
 *   "333 1234567"     → "393331234567"
 *   "+393331234567"   → "393331234567"
 *   "0039 333 123"    → "393331234567" (international prefix)
 */
export function normalizePhone(phone: string): string {
  // Strip everything except digits
  let digits = phone.replace(/[^\d]/g, "");

  // Remove leading "00" international prefix (e.g., "0039...")
  if (digits.startsWith("00")) {
    digits = digits.slice(2);
  }

  // If starts with Italian mobile prefix (3xx) without country code, add 39
  if (digits.length === 10 && digits.startsWith("3")) {
    digits = "39" + digits;
  }

  // If starts with Italian landline (0x) without country code, add 39
  if (digits.length >= 9 && digits.length <= 11 && digits.startsWith("0")) {
    digits = "39" + digits;
  }

  return digits;
}

/**
 * Check if two phone numbers are the same after normalization.
 */
export function matchPhone(a: string, b: string): boolean {
  return normalizePhone(a) === normalizePhone(b);
}
