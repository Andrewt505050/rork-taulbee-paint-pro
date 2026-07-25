import { detectSurface, surfacePointMap } from "@/lib/visualizerEngine";
import type { SurfaceMask, VisualizerWorkspace } from "@/lib/visualizerEngine";

const workspace = (): VisualizerWorkspace => {
  const width = 20; const height = 10; const data = new Uint8ClampedArray(width * height * 4);
  for (let y = 0; y < height; y += 1) for (let x = 0; x < width; x += 1) {
    const offset = (y * width + x) * 4; const value = x < 10 ? 190 : 45;
    data[offset] = value; data[offset + 1] = value; data[offset + 2] = value; data[offset + 3] = 255;
  }
  return { width, height, original: { width, height, data, colorSpace: "srgb" } as ImageData };
};

describe("instant visualizer surface detection", () => {
  it("keeps a selected surface inside a strong boundary", () => {
    const mask = detectSurface(workspace(), { x: 0.2, y: 0.5 });
    expect(mask.alpha[5 * 20 + 4]).toBeGreaterThan(0);
    expect(mask.alpha[5 * 20 + 15]).toBe(0);
  });

  it("stores stable normalized points for saved-project recovery", () => {
    const wall = detectSurface(workspace(), { x: 0.25, y: 0.4 });
    const masks: Partial<Record<"Interior walls", SurfaceMask>> = { "Interior walls": wall };
    expect(surfacePointMap(masks)["Interior walls"]).toEqual({ x: 0.25, y: 0.4 });
  });

  it("rejects isolated detail instead of claiming detection succeeded", () => {
    const tiny = workspace();
    tiny.original.data.fill(0);
    const center = (5 * tiny.width + 5) * 4;
    tiny.original.data[center] = 255; tiny.original.data[center + 1] = 255; tiny.original.data[center + 2] = 255;
    expect(() => detectSurface(tiny, { x: 5 / 19, y: 5 / 9 })).toThrow(/too detailed/i);
  });
});
