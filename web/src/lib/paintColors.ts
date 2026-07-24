import sherwinWilliamsData from "../../../ios-taulbee-painting/TaulbeePainting/Resources/PaintCatalog/sherwin_williams.json";
import benjaminMooreData from "../../../ios-taulbee-painting/TaulbeePainting/Resources/PaintCatalog/benjamin_moore.json";
import ppgData from "../../../ios-taulbee-painting/TaulbeePainting/Resources/PaintCatalog/ppg.json";
import type { ColorFamily, PaintBrand, PaintColor } from "@/lib/homeownerTypes";

type ColorBook = { colors: string[][] };

const normalizeHex = (hex: string): string => hex.replace("#", "").toUpperCase();

const classifyFamily = (hexValue: string): ColorFamily => {
  const hex = normalizeHex(hexValue);
  const red = Number.parseInt(hex.slice(0, 2), 16) / 255;
  const green = Number.parseInt(hex.slice(2, 4), 16) / 255;
  const blue = Number.parseInt(hex.slice(4, 6), 16) / 255;
  const max = Math.max(red, green, blue);
  const min = Math.min(red, green, blue);
  const delta = max - min;
  const saturation = max === 0 ? 0 : delta / max;
  const luma = 0.299 * red + 0.587 * green + 0.114 * blue;

  if (luma < 0.2) return "Darks";
  if (saturation < 0.08) return luma > 0.84 ? "Whites" : "Neutrals";
  if (saturation < 0.18 && luma > 0.25) return "Neutrals";

  let hue = 0;
  if (delta > 0) {
    if (max === red) hue = ((green - blue) / delta) % 6;
    else if (max === green) hue = (blue - red) / delta + 2;
    else hue = (red - green) / delta + 4;
    hue *= 60;
    if (hue < 0) hue += 360;
  }

  if (hue < 15 || hue >= 345) return "Reds";
  if (hue < 45) return "Oranges";
  if (hue < 70) return "Yellows";
  if (hue < 165) return "Greens";
  if (hue < 260) return "Blues";
  if (hue < 345) return "Purples";
  return "Neutrals";
};

const decodeBook = (data: ColorBook, brand: PaintBrand): PaintColor[] =>
  data.colors
    .filter((entry: string[]) => entry.length >= 3)
    .map((entry: string[]): PaintColor => ({
      id: `${brand}-${entry[1]}`,
      brand,
      name: entry[0],
      code: entry[1],
      hex: normalizeHex(entry[2]),
      family: classifyFamily(entry[2]),
    }));

export const ALL_PAINT_COLORS: PaintColor[] = [
  ...decodeBook(sherwinWilliamsData as ColorBook, "Sherwin-Williams"),
  ...decodeBook(benjaminMooreData as ColorBook, "Benjamin Moore"),
  ...decodeBook(ppgData as ColorBook, "PPG"),
];

const popularCodes: string[] = [
  "Sherwin-Williams|7008", "Sherwin-Williams|7029", "Benjamin Moore|OC-117",
  "Benjamin Moore|OC-17", "Sherwin-Williams|7015", "Benjamin Moore|HC-172",
  "Sherwin-Williams|6204", "Sherwin-Williams|7036", "Benjamin Moore|HC-173",
  "Sherwin-Williams|9130", "Benjamin Moore|HC-144", "Sherwin-Williams|6244",
  "Benjamin Moore|HC-154", "Sherwin-Williams|7069", "Benjamin Moore|HC-166",
  "Sherwin-Williams|7048", "Sherwin-Williams|6258", "Benjamin Moore|2124-10",
  "PPG|PPG1001-1", "PPG|PPG1011-3", "PPG|PPG1043-7",
];

const colorIndex = new Map<string, PaintColor>(
  ALL_PAINT_COLORS.map((color: PaintColor): [string, PaintColor] => [`${color.brand}|${color.code}`, color]),
);

export const POPULAR_PAINT_COLORS: PaintColor[] = popularCodes
  .map((key: string): PaintColor | undefined => colorIndex.get(key))
  .filter((color: PaintColor | undefined): color is PaintColor => color !== undefined);

export const COLOR_FAMILIES: ColorFamily[] = [
  "Whites", "Neutrals", "Reds", "Oranges", "Yellows", "Greens", "Blues", "Purples", "Darks",
];

export const PAINT_BRANDS: PaintBrand[] = ["Sherwin-Williams", "Benjamin Moore", "PPG"];
