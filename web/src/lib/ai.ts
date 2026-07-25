import type { ChatMessage, DefectAnalysis, SurfacePaint } from "@/lib/homeownerTypes";

const TOOLKIT_URL = (import.meta.env.EXPO_PUBLIC_TOOLKIT_URL as string | undefined)?.replace(/\/$/, "") ?? "";
const CHAT_MODEL = "google/gemini-3.1-flash-lite";
const IMAGE_MODEL = "google/gemini-3.1-flash-lite-image";

const requestAI = async (body: unknown, timeoutMs: number): Promise<unknown> => {
  if (!TOOLKIT_URL) throw new Error("AI tools are temporarily unavailable. Please try again later.");
  const controller = new AbortController();
  const timeout = window.setTimeout((): void => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${TOOLKIT_URL}/v2/vercel/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    if (!response.ok) {
      if (response.status === 402) throw new Error("This AI tool is temporarily unavailable. Please try again later.");
      if (response.status === 413) throw new Error("That photo is too large. Try a smaller image.");
      if (response.status === 429) throw new Error("A lot of requests arrived at once. Please wait a moment and try again.");
      throw new Error("The AI tool could not finish that request. Please try again.");
    }
    return await response.json() as unknown;
  } catch (error: unknown) {
    if (error instanceof DOMException && error.name === "AbortError") {
      throw new Error("That request took too long. Please try again.");
    }
    throw error instanceof Error ? error : new Error("Something went wrong. Please try again.");
  } finally {
    window.clearTimeout(timeout);
  }
};

const readMessageContent = (payload: unknown): string => {
  const envelope = payload as { choices?: { message?: { content?: string } }[] };
  const content = envelope.choices?.[0]?.message?.content?.trim() ?? "";
  if (!content) throw new Error("The AI tool returned an empty response. Please try again.");
  return content;
};

const stripJSON = (value: string): string => {
  const withoutFences = value.replace(/```json/gi, "").replace(/```/g, "").trim();
  const start = withoutFences.indexOf("{");
  const end = withoutFences.lastIndexOf("}");
  return start >= 0 && end > start ? withoutFences.slice(start, end + 1) : withoutFences;
};

/** Resizes a browser image to remain under the AI gateway request limit. */
export const prepareImage = async (file: File, maxDimension = 1400): Promise<string> => {
  if (!file.type.startsWith("image/")) throw new Error("Choose a JPG, PNG, HEIC, or WebP photo.");
  const objectURL = URL.createObjectURL(file);
  try {
    const image = await new Promise<HTMLImageElement>((resolve, reject): void => {
      const element = new Image();
      element.onload = (): void => resolve(element);
      element.onerror = (): void => reject(new Error("We couldn't read that photo. Try another image."));
      element.src = objectURL;
    });
    const scale = Math.min(1, maxDimension / Math.max(image.naturalWidth, image.naturalHeight));
    const width = Math.max(1, Math.round(image.naturalWidth * scale));
    const height = Math.max(1, Math.round(image.naturalHeight * scale));
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const context = canvas.getContext("2d");
    if (!context) throw new Error("Your browser could not prepare that photo.");
    context.drawImage(image, 0, 0, width, height);
    let quality = 0.82;
    let dataURL = canvas.toDataURL("image/jpeg", quality);
    while (dataURL.length > 1_900_000 && quality > 0.48) {
      quality -= 0.08;
      dataURL = canvas.toDataURL("image/jpeg", quality);
    }
    if (dataURL.length > 2_500_000) throw new Error("That photo is too large. Try a smaller image.");
    return dataURL;
  } finally {
    URL.revokeObjectURL(objectURL);
  }
};

export const askPaintExpert = async (history: ChatMessage[]): Promise<string> => {
  const systemPrompt = `You are the Taulbee Painting Paint Expert, a warm residential painting advisor with decades of hands-on experience. Give concise, practical steps for paint, prep, finish, products, color, and home surfaces. Prefer short paragraphs and bullets. Warn about lead paint, heights, rot, and mold. When professional help is useful, gently suggest a free estimate from Taulbee Painting at taulbeepainting.app. Keep unrelated questions focused back on painting. Recommended products include Sherwin-Williams Emerald and Duration, Benjamin Moore Regal Select, Advance and Aura, PPG Diamond and Timeless, Zinsser B-I-N, KILZ Original, and Sherwin-Williams Extreme Bond.`;
  const payload = await requestAI({
    model: CHAT_MODEL,
    temperature: 0.5,
    messages: [
      { role: "system", content: systemPrompt },
      ...history.slice(-18).map((message: ChatMessage) => ({ role: message.role, content: message.text })),
    ],
  }, 60_000);
  return readMessageContent(payload);
};

export const analyzePaintDefect = async (imageDataURL: string): Promise<DefectAnalysis> => {
  const systemPrompt = `You are a senior residential painting inspector for Taulbee Painting. Analyze one photo and identify the most likely paint or coating defect. Return strict minified JSON only with this schema: {"isPaintIssue":boolean,"defectName":string,"confidence":number,"severity":"minor"|"moderate"|"serious","summary":string,"surface":string,"causes":string[],"solutions":string[],"whenToCallPro":string}. Be concise and homeowner-friendly. If no paint issue is visible, set isPaintIssue false.`;
  const payload = await requestAI({
    model: CHAT_MODEL,
    temperature: 0.2,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: [
        { type: "text", text: "Diagnose the paint defect in this photo and return JSON only." },
        { type: "image_url", image_url: { url: imageDataURL } },
      ] },
    ],
  }, 75_000);
  try {
    const parsed = JSON.parse(stripJSON(readMessageContent(payload))) as DefectAnalysis;
    return {
      ...parsed,
      confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0)),
      causes: Array.isArray(parsed.causes) ? parsed.causes : [],
      solutions: Array.isArray(parsed.solutions) ? parsed.solutions : [],
    };
  } catch {
    throw new Error("We couldn't interpret that diagnosis. Please try another photo.");
  }
};

const imageFromResponse = (payload: unknown): string => {
  const envelope = payload as { choices?: { message?: { images?: Array<string | { image_url?: { url?: string }; url?: string }> } }[] };
  const entry = envelope.choices?.[0]?.message?.images?.[0];
  const value = typeof entry === "string" ? entry : entry?.image_url?.url ?? entry?.url ?? "";
  if (!value) throw new Error("We couldn't render that preview. Try another photo or color.");
  return value.startsWith("data:") ? value : `data:image/png;base64,${value}`;
};

export const renderPaintScheme = async (imageDataURL: string, scheme: SurfacePaint[]): Promise<string> => {
  if (scheme.length === 0) throw new Error("Choose at least one surface and color.");
  const assignments = scheme.map((paint: SurfacePaint, index: number): string =>
    `${index + 1}. ${paint.surface}: ${paint.color.brand} ${paint.color.code}, ${paint.color.name}, exact hex #${paint.color.hex}.`,
  ).join("\n");
  const prompt = `Repaint only the assigned surfaces in this home photo:\n${assignments}\nKeep every surface assignment separate and exact. Preserve furniture, windows, floors, hardware, landscaping, people, composition, lighting, texture, shadows, and perspective. Keep boundaries crisp and produce a realistic professional paint finish. Do not modify anything except the listed surfaces.`;
  const payload = await requestAI({
    model: IMAGE_MODEL,
    modalities: ["text", "image"],
    messages: [{ role: "user", content: [
      { type: "image_url", image_url: { url: imageDataURL } },
      { type: "text", text: prompt },
    ] }],
  }, 120_000);
  return imageFromResponse(payload);
};

export const AI_MODELS = { chat: CHAT_MODEL, image: IMAGE_MODEL } as const;
