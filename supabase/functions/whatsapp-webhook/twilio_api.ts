// Twilio WhatsApp API client
// Replaces Meta Business API — using Twilio REST API

function getTwilioConfig() {
  const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";
  const authToken = Deno.env.get("TWILIO_AUTH_TOKEN") ?? "";
  const phoneNumber = Deno.env.get("TWILIO_PHONE_NUMBER") ?? "";
  return { accountSid, authToken, phoneNumber };
}

interface SendResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * Send a text message via Twilio WhatsApp API.
 */
export async function sendWhatsAppMessage(
  to: string,
  text: string
): Promise<SendResult> {
  try {
    const { accountSid, authToken, phoneNumber } = getTwilioConfig();

    if (!accountSid || !authToken || !phoneNumber) {
      return {
        success: false,
        error: "Missing Twilio credentials",
      };
    }

    // Twilio expects numbers without + prefix
    const toNumber = to.replace("+", "");
    const fromNumber = phoneNumber.replace("+", "");

    // Basic Auth: base64(accountSid:authToken)
    const authHeader = btoa(`${accountSid}:${authToken}`);

    // Twilio expects form-encoded body
    const formData = new URLSearchParams();
    formData.append("From", `whatsapp:+${fromNumber}`);
    formData.append("To", `whatsapp:+${toNumber}`);
    formData.append("Body", text);

    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${authHeader}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: formData.toString(),
      }
    );

    const data = await response.json();

    if (!response.ok) {
      console.error("Twilio send failed:", JSON.stringify(data));
      return {
        success: false,
        error: data.message ?? `HTTP ${response.status}`,
      };
    }

    return {
      success: true,
      messageId: data.sid,
    };
  } catch (error) {
    console.error("Twilio send exception:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

/**
 * Send a template message (Twilio doesn't have native templates like Meta).
 * For now, we convert template to plain text.
 */
export async function sendTemplate(
  to: string,
  templateName: string,
  params: string[] = []
): Promise<SendResult> {
  // Convert template to plain text
  let text = `[Template: ${templateName}]`;
  if (params.length > 0) {
    text += ` ${params.join(" - ")}`;
  }

  return await sendWhatsAppMessage(to, text);
}

// ── Template Names (for reference) ─────────
export const WA_TEMPLATES = {
  NUOVO_ORDINE: "dloop_nuovo_ordine",
  ORDINE_CONFERMATO: "dloop_ordine_confermato",
  ORDINE_PRONTO: "dloop_ordine_pronto",
  PAGAMENTO: "dloop_pagamento",
  BENVENUTO: "dloop_benvenuto",
} as const;

/**
 * Try sending a template message first. If it fails, fall back to plain text.
 */
export async function sendTemplateOrText(
  to: string,
  templateName: string,
  params: string[],
  fallbackText: string
): Promise<SendResult> {
  return await sendWhatsAppMessage(to, fallbackText);
}

/**
 * Download media from Twilio (for voice/image messages).
 */
export async function downloadMedia(mediaId: string): Promise<Uint8Array> {
  const { accountSid, authToken } = getTwilioConfig();

  if (!accountSid || !authToken) {
    throw new Error("Missing Twilio credentials");
  }

  const authHeader = btoa(`${accountSid}:${authToken}`);

  const response = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages/${mediaId}/Media.json`,
    {
      headers: {
        Authorization: `Basic ${authHeader}`,
      },
    }
  );

  if (!response.ok) {
    throw new Error(`Failed to get media: ${response.status}`);
  }

  const data = await response.json();
  const mediaUrl = data.uri;

  const fileResponse = await fetch(mediaUrl, {
    headers: {
      Authorization: `Basic ${authHeader}`,
    },
  });

  if (!fileResponse.ok) {
    throw new Error(`Failed to download media: ${fileResponse.status}`);
  }

  const buffer = await fileResponse.arrayBuffer();
  return new Uint8Array(buffer);
}
