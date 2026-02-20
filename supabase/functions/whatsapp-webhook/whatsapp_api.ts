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
