import type { SurfacePaint, SurfacePoint, SurfaceTarget } from "@/lib/homeownerTypes";

export type SurfaceMask = { width: number; height: number; alpha: Uint8ClampedArray; point: SurfacePoint };
export type VisualizerWorkspace = { width: number; height: number; original: ImageData };

const imageElement = (dataURL: string): Promise<HTMLImageElement> => new Promise((resolve, reject): void => {
  const image = new Image();
  image.onload = (): void => resolve(image);
  image.onerror = (): void => reject(new Error("We couldn't open that photo."));
  image.src = dataURL;
});

/** Creates a bounded canvas workspace for fast, local surface recoloring. */
export const createWorkspace = async (dataURL: string, maxDimension = 900): Promise<VisualizerWorkspace> => {
  const image = await imageElement(dataURL);
  const scale = Math.min(1, maxDimension / Math.max(image.naturalWidth, image.naturalHeight));
  const width = Math.max(1, Math.round(image.naturalWidth * scale));
  const height = Math.max(1, Math.round(image.naturalHeight * scale));
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const context = canvas.getContext("2d", { willReadFrequently: true });
  if (!context) throw new Error("Your browser could not start the color preview.");
  context.drawImage(image, 0, 0, width, height);
  return { width, height, original: context.getImageData(0, 0, width, height) };
};

const difference = (data: Uint8ClampedArray, a: number, b: number): number => {
  const ar = data[a * 4]; const ag = data[a * 4 + 1]; const ab = data[a * 4 + 2];
  const br = data[b * 4]; const bg = data[b * 4 + 1]; const bb = data[b * 4 + 2];
  const dr = ar - br; const dg = ag - bg; const db = ab - bb;
  return Math.sqrt(dr * dr * 0.3 + dg * dg * 0.59 + db * db * 0.11);
};

/** Detects one connected, similarly lit painted region from a user-selected point. */
export const detectSurface = (workspace: VisualizerWorkspace, point: SurfacePoint): SurfaceMask => {
  const { width, height, original } = workspace;
  const x = Math.max(0, Math.min(width - 1, Math.round(point.x * (width - 1))));
  const y = Math.max(0, Math.min(height - 1, Math.round(point.y * (height - 1))));
  const seed = y * width + x;
  const alpha = new Uint8ClampedArray(width * height);
  const visited = new Uint8Array(width * height);
  const queue = new Int32Array(width * height);
  let start = 0; let end = 0; queue[end++] = seed; visited[seed] = 1;
  const seedLuma = original.data[seed * 4] * 0.3 + original.data[seed * 4 + 1] * 0.59 + original.data[seed * 4 + 2] * 0.11;
  const seedTolerance = seedLuma < 45 ? 42 : seedLuma > 215 ? 34 : 58;

  while (start < end) {
    const index = queue[start++];
    alpha[index] = 230;
    const px = index % width; const py = Math.floor(index / width);
    const neighbors = [px > 0 ? index - 1 : -1, px < width - 1 ? index + 1 : -1, py > 0 ? index - width : -1, py < height - 1 ? index + width : -1];
    for (const neighbor of neighbors) {
      if (neighbor < 0 || visited[neighbor]) continue;
      visited[neighbor] = 1;
      if (difference(original.data, seed, neighbor) <= seedTolerance && difference(original.data, index, neighbor) <= 24) queue[end++] = neighbor;
    }
  }

  if (end < Math.max(24, width * height * 0.002)) throw new Error("That spot is too detailed. Tap a flatter part of the surface.");
  const softened = new Uint8ClampedArray(alpha);
  for (let row = 1; row < height - 1; row += 1) for (let column = 1; column < width - 1; column += 1) {
    const index = row * width + column;
    if (alpha[index] === 0) continue;
    const count = Number(alpha[index - 1] > 0) + Number(alpha[index + 1] > 0) + Number(alpha[index - width] > 0) + Number(alpha[index + width] > 0);
    softened[index] = count < 4 ? 155 : 230;
  }
  return { width, height, alpha: softened, point };
};

const hexRGB = (hex: string): [number, number, number] => {
  const normalized = hex.replace("#", "").padEnd(6, "0").slice(0, 6);
  return [Number.parseInt(normalized.slice(0, 2), 16), Number.parseInt(normalized.slice(2, 4), 16), Number.parseInt(normalized.slice(4, 6), 16)];
};

/** Composites all detected surface colors instantly while retaining source texture and lighting. */
export const renderWorkspace = (workspace: VisualizerWorkspace, masks: Partial<Record<SurfaceTarget, SurfaceMask>>, scheme: SurfacePaint[]): string => {
  const output = new ImageData(new Uint8ClampedArray(workspace.original.data), workspace.width, workspace.height);
  for (const paint of scheme) {
    const mask = masks[paint.surface];
    if (!mask) continue;
    const [red, green, blue] = hexRGB(paint.color.hex);
    for (let index = 0; index < mask.alpha.length; index += 1) {
      const coverage = mask.alpha[index] / 255;
      if (!coverage) continue;
      const offset = index * 4;
      const sourceLuma = workspace.original.data[offset] * 0.3 + workspace.original.data[offset + 1] * 0.59 + workspace.original.data[offset + 2] * 0.11;
      const light = Math.max(0.35, Math.min(1.45, 0.38 + sourceLuma / 235));
      const strength = coverage * 0.82;
      output.data[offset] = Math.round(output.data[offset] * (1 - strength) + Math.min(255, red * light) * strength);
      output.data[offset + 1] = Math.round(output.data[offset + 1] * (1 - strength) + Math.min(255, green * light) * strength);
      output.data[offset + 2] = Math.round(output.data[offset + 2] * (1 - strength) + Math.min(255, blue * light) * strength);
    }
  }
  const canvas = document.createElement("canvas");
  canvas.width = workspace.width; canvas.height = workspace.height;
  canvas.getContext("2d")?.putImageData(output, 0, 0);
  return canvas.toDataURL("image/jpeg", 0.9);
};

export const surfacePointMap = (masks: Partial<Record<SurfaceTarget, SurfaceMask>>): Partial<Record<SurfaceTarget, SurfacePoint>> => Object.fromEntries(Object.entries(masks).map(([key, mask]) => [key, mask?.point])) as Partial<Record<SurfaceTarget, SurfacePoint>>;
