import type { SurfaceTarget } from "@/lib/homeownerTypes";

export type SurfaceInfo = { id: SurfaceTarget; group: "Interior" | "Exterior"; layer: number; phrase: string };

/** Every paintable surface the visualizer supports, matching the iPhone app. `layer` paints higher values over lower ones. */
export const SURFACE_INFO: SurfaceInfo[] = [
  { id: "Interior walls", group: "Interior", layer: 0, phrase: "the main interior wall surfaces" },
  { id: "Accent wall", group: "Interior", layer: 3, phrase: "only the single most prominent feature wall facing the camera" },
  { id: "Ceiling", group: "Interior", layer: 2, phrase: "only the ceiling surface" },
  { id: "Trim & accents", group: "Interior", layer: 9, phrase: "only the trim, molding, baseboards and accent woodwork" },
  { id: "Baseboards", group: "Interior", layer: 10, phrase: "only the baseboards along the bottom of the walls" },
  { id: "Interior doors", group: "Interior", layer: 13, phrase: "only the interior door slabs" },
  { id: "Cabinets", group: "Interior", layer: 7, phrase: "only the cabinet doors, drawer fronts and cabinet frames" },
  { id: "Kitchen island", group: "Interior", layer: 8, phrase: "only the painted base cabinetry of the kitchen island" },
  { id: "Exterior siding", group: "Exterior", layer: 1, phrase: "the exterior siding and main wall surfaces of the house" },
  { id: "Front door", group: "Exterior", layer: 15, phrase: "only the front entry door" },
  { id: "Garage door", group: "Exterior", layer: 14, phrase: "only the garage door panels" },
  { id: "Shutters", group: "Exterior", layer: 12, phrase: "only the window shutters" },
  { id: "Window trim", group: "Exterior", layer: 11, phrase: "only the exterior window frames, casings and window trim" },
  { id: "Porch & railings", group: "Exterior", layer: 6, phrase: "only the porch columns, posts, spindles and railings" },
  { id: "Deck", group: "Exterior", layer: 4, phrase: "only the deck floor boards, deck stairs and deck railings" },
  { id: "Fence", group: "Exterior", layer: 5, phrase: "only the fence boards, pickets and posts" },
];

export const SURFACES: SurfaceTarget[] = SURFACE_INFO.map((item) => item.id);
const byId = new Map<SurfaceTarget, SurfaceInfo>(SURFACE_INFO.map((item) => [item.id, item]));

/** Paint layer order (trim and doors over walls). */
export const surfaceLayer = (surface: SurfaceTarget): number => byId.get(surface)?.layer ?? 0;
/** Precise AI prompt phrase for a surface. */
export const surfacePhrase = (surface: SurfaceTarget): string => byId.get(surface)?.phrase ?? surface.toLowerCase();
