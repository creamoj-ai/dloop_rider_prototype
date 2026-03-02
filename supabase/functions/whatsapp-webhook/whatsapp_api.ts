// WhatsApp Cloud API client
// Uses Meta Business API (free tier — Cloud API direct)

const WA_API_VERSION = "v21.0";

function getWaConfig() {
  const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") ?? "";
  const accessToken = Deno.env.get("WHATSAPP_ACCESS_TOKEN") ?? "";
  const baseUrl = `https://graph.facebook.com/${WA_API_VERSION}/${phoneNumberId}`;
  return { phoneNumberId, accessToken, baseUrl };
}

interface SendResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * Send a text message via WhatsApp Cloud API.
 */
export async function sendWhatsAppMessage(
  to: string,
  text: string
): Promise<SendResult> {
  try {
    const { accessToken, baseUrl } = getWaConfig();
    const response = await fetch(`${baseUrl}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: to.replace("+", ""),
        type: "text",
        text: { body: text },
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("WA send failed:", JSON.stringify(data));
      return {
        success: false,
        error: data.error?.message ?? `HTTP ${response.status}`,
      };
    }

    return {
      success: true,
      messageId: data.messages?.[0]?.id,
    };
  } catch (error) {
    console.error("WA send exception:", error);
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

/**
 * Send a pre-approved template message.
 */
export async function sendTemplate(
  to: string,
  templateName: string,
  params: string[] = []
): Promise<SendResult> {
  try {
    const { accessToken, baseUrl } = getWaConfig();
    const components =
      params.length > 0
        ? [
            {
              type: "body",
              parameters: params.map((p) => ({
                type: "text",
                text: p,
              })),
            },
          ]
        : [];

    const response = await fetch(`${baseUrl}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: to.replace("+", ""),
        type: "template",
        template: {
          name: templateName,
          language: { code: "it" },
          components,
        },
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      return {
        success: false,
        error: data.error?.message ?? `HTTP ${response.status}`,
      };
    }

    return {
      success: true,
      messageId: data.messages?.[0]?.id,
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

// ── Template Names (must be pre-approved on Meta Business) ─────────
export const WA_TEMPLATES = {
  NUOVO_ORDINE: "dloop_nuovo_ordine",     // params: [dealer_name, order_details]
  ORDINE_CONFERMATO: "dloop_ordine_confermato", // params: [order_id, dealer_name]
  ORDINE_PRONTO: "dloop_ordine_pronto",   // params: [order_id, estimated_time]
  PAGAMENTO: "dloop_pagamento",           // params: [amount, payment_link]
  BENVENUTO: "dloop_benvenuto",           // params: [customer_name]
} as const;

/**
 * Try sending a template message first. If it fails (template not approved),
 * fall back to a plain text message. This allows seamless transition when
 * Meta approves templates without code changes.
 */
export async function sendTemplateOrText(
  to: string,
  templateName: string,
  params: string[],
  fallbackText: string
): Promise<SendResult> {
  // Try template first
  const templateResult = await sendTemplate(to, templateName, params);
  if (templateResult.success) return templateResult;

  // Template failed (likely not approved yet) — fallback to plain text
  console.log(`Template ${templateName} failed, falling back to text: ${templateResult.error}`);
  return await sendWhatsAppMessage(to, fallbackText);
}

/**
 * Download media from WhatsApp (for voice messages).
 * Returns the raw bytes.
 */
export async function downloadMedia(mediaId: string): Promise<Uint8Array> {
  const { accessToken } = getWaConfig();
  // Step 1: Get media URL
  const metaResponse = await fetch(
    `https://graph.facebook.com/${WA_API_VERSION}/${mediaId}`,
    {
      headers: { Authorization: `Bearer ${accessToken}` },
    }
  );

  if (!metaResponse.ok) {
    throw new Error(`Failed to get media URL: ${metaResponse.status}`);
  }

  const metaData = await metaResponse.json();
  const mediaUrl = metaData.url;

  // Step 2: Download the file
  const fileResponse = await fetch(mediaUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!fileResponse.ok) {
    throw new Error(`Failed to download media: ${fileResponse.status}`);
  }

  const buffer = await fileResponse.arrayBuffer();
  return new Uint8Array(buffer);
}
