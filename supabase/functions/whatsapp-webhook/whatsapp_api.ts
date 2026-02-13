// WhatsApp Cloud API client
// Uses Meta Business API (free tier — Cloud API direct)

const WA_PHONE_NUMBER_ID = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") ?? "";
const WA_ACCESS_TOKEN = Deno.env.get("WHATSAPP_ACCESS_TOKEN") ?? "";
const WA_API_VERSION = "v21.0";
const WA_BASE_URL = `https://graph.facebook.com/${WA_API_VERSION}/${WA_PHONE_NUMBER_ID}`;

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
    const response = await fetch(`${WA_BASE_URL}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${WA_ACCESS_TOKEN}`,
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

/**
 * Send a pre-approved template message.
 */
export async function sendTemplate(
  to: string,
  templateName: string,
  params: string[] = []
): Promise<SendResult> {
  try {
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

    const response = await fetch(`${WA_BASE_URL}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${WA_ACCESS_TOKEN}`,
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

/**
 * Download media from WhatsApp (for voice messages).
 * Returns the raw bytes.
 */
export async function downloadMedia(mediaId: string): Promise<Uint8Array> {
  // Step 1: Get media URL
  const metaResponse = await fetch(
    `https://graph.facebook.com/${WA_API_VERSION}/${mediaId}`,
    {
      headers: { Authorization: `Bearer ${WA_ACCESS_TOKEN}` },
    }
  );

  if (!metaResponse.ok) {
    throw new Error(`Failed to get media URL: ${metaResponse.status}`);
  }

  const metaData = await metaResponse.json();
  const mediaUrl = metaData.url;

  // Step 2: Download the file
  const fileResponse = await fetch(mediaUrl, {
    headers: { Authorization: `Bearer ${WA_ACCESS_TOKEN}` },
  });

  if (!fileResponse.ok) {
    throw new Error(`Failed to download media: ${fileResponse.status}`);
  }

  const buffer = await fileResponse.arrayBuffer();
  return new Uint8Array(buffer);
}
