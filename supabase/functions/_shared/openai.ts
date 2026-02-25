// Shared OpenAI client for all Edge Functions
// Uses Deno environment variables (set via `supabase secrets set`)

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_BASE_URL = "https://api.openai.com/v1";

export interface ChatMessage {
  role: "system" | "user" | "assistant" | "tool";
  content: string | null;
  tool_call_id?: string;
  tool_calls?: ToolCall[];
}

export interface ToolCall {
  id: string;
  type: "function";
  function: {
    name: string;
    arguments: string;
  };
}

export interface ToolDefinition {
  type: "function";
  function: {
    name: string;
    description: string;
    parameters: Record<string, unknown>;
  };
}

interface ChatCompletionOptions {
  messages: ChatMessage[];
  tools?: ToolDefinition[];
  model?: string;
  maxTokens?: number;
  temperature?: number;
}

interface ChatCompletionResponse {
  content: string | null;
  toolCalls: ToolCall[];
  usage: { prompt_tokens: number; completion_tokens: number; total_tokens: number };
  finishReason: string;
}

/**
 * Call OpenAI Chat Completions API with optional function calling.
 */
export async function chatCompletion(
  opts: ChatCompletionOptions
): Promise<ChatCompletionResponse> {
  const {
    messages,
    tools,
    model = "gpt-3.5-turbo",
    maxTokens = 512,
    temperature = 0.7,
  } = opts;

  const body: Record<string, unknown> = {
    model,
    messages,
    max_tokens: maxTokens,
    temperature,
  };

  if (tools && tools.length > 0) {
    body.tools = tools;
    body.tool_choice = "auto";
  }

  const response = await fetch(`${OPENAI_BASE_URL}/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`OpenAI API error ${response.status}: ${errorBody}`);
  }

  const data = await response.json();
  const choice = data.choices?.[0];

  return {
    content: choice?.message?.content ?? null,
    toolCalls: choice?.message?.tool_calls ?? [],
    usage: data.usage ?? { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 },
    finishReason: choice?.finish_reason ?? "stop",
  };
}

/**
 * Transcribe audio using Whisper API.
 */
export async function transcribeAudio(
  audioBuffer: Uint8Array,
  filename = "audio.ogg"
): Promise<string> {
  const formData = new FormData();
  formData.append("file", new Blob([audioBuffer]), filename);
  formData.append("model", "whisper-1");
  formData.append("language", "it");

  const response = await fetch(`${OPENAI_BASE_URL}/audio/transcriptions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Whisper API error ${response.status}: ${errorBody}`);
  }

  const data = await response.json();
  return data.text ?? "";
}
