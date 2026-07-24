import { useMemo, useRef, useState } from "react";
import { format, parseISO } from "date-fns";
import { ArrowLeftRight, Camera, Check, ChevronRight, LoaderCircle, PaintBucket, Save, Search, Sparkles, Upload, WandSparkles } from "lucide-react";
import EstimateDialog from "@/components/EstimateDialog";
import { useHomeowner } from "@/hooks/useHomeowner";
import { prepareImage, renderPaintScheme } from "@/lib/ai";
import { ALL_PAINT_COLORS, COLOR_FAMILIES, PAINT_BRANDS, POPULAR_PAINT_COLORS } from "@/lib/paintColors";
import type { ColorFamily, PaintBrand, PaintColor, SurfacePaint, SurfaceTarget, VisionProject } from "@/lib/homeownerTypes";

const SURFACES: SurfaceTarget[] = ["Interior walls", "Exterior siding", "Trim & accents", "Front door", "Cabinets"];

const Visualizer = () => {
  const { state, addProject } = useHomeowner();
  const fileRef = useRef<HTMLInputElement>(null);
  const [original, setOriginal] = useState<string>("");
  const [result, setResult] = useState<string>("");
  const [scheme, setScheme] = useState<SurfacePaint[]>([]);
  const [activeSurface, setActiveSurface] = useState<SurfaceTarget>("Interior walls");
  const [query, setQuery] = useState<string>("");
  const [brand, setBrand] = useState<PaintBrand | "All">("All");
  const [family, setFamily] = useState<ColorFamily | "All">("All");
  const [isLoadingPhoto, setIsLoadingPhoto] = useState<boolean>(false);
  const [isRendering, setIsRendering] = useState<boolean>(false);
  const [error, setError] = useState<string>("");
  const [compare, setCompare] = useState<number>(50);
  const [notes, setNotes] = useState<string>("");
  const [saved, setSaved] = useState<boolean>(false);
  const [estimateOpen, setEstimateOpen] = useState<boolean>(false);

  const filteredColors = useMemo<PaintColor[]>(() => {
    const normalized = query.trim().toLowerCase();
    return ALL_PAINT_COLORS.filter((color: PaintColor): boolean =>
      (brand === "All" || color.brand === brand)
      && (family === "All" || color.family === family)
      && (!normalized || color.name.toLowerCase().includes(normalized) || color.code.toLowerCase().includes(normalized)),
    ).slice(0, 180);
  }, [brand, family, query]);

  const handlePhoto = async (file: File | undefined): Promise<void> => {
    if (!file) return;
    setIsLoadingPhoto(true);
    setError("");
    try {
      const prepared = await prepareImage(file);
      setOriginal(prepared);
      setResult("");
      setScheme([]);
      setSaved(false);
    } catch (photoError: unknown) {
      setError(photoError instanceof Error ? photoError.message : "We couldn't open that photo.");
    } finally {
      setIsLoadingPhoto(false);
    }
  };

  const selectColor = (color: PaintColor): void => {
    setScheme((current: SurfacePaint[]): SurfacePaint[] => [
      ...current.filter((item: SurfacePaint): boolean => item.surface !== activeSurface),
      { surface: activeSurface, color },
    ]);
    setResult("");
    setSaved(false);
  };

  const render = async (): Promise<void> => {
    if (!original || scheme.length === 0) return;
    setIsRendering(true);
    setError("");
    try {
      setResult(await renderPaintScheme(original, scheme));
      setCompare(50);
      setSaved(false);
    } catch (renderError: unknown) {
      setError(renderError instanceof Error ? renderError.message : "We couldn't render that preview.");
    } finally {
      setIsRendering(false);
    }
  };

  const save = (): void => {
    if (!original || !result || scheme.length === 0 || saved) return;
    addProject({ originalImage: original, resultImage: result, scheme, notes: notes.trim() });
    setSaved(true);
  };

  const currentPaint = (surface: SurfaceTarget): SurfacePaint | undefined => scheme.find((item: SurfacePaint): boolean => item.surface === surface);
  const quoteContext = scheme.length > 0 ? `Color plan: ${scheme.map((item: SurfacePaint) => `${item.surface} — ${item.color.brand} ${item.color.code} ${item.color.name}`).join("; ")}` : "";

  if (!original) {
    return (
      <div className="space-y-6">
        <div><p className="text-sm font-bold uppercase tracking-[0.16em] text-primary/70">Color Visualizer</p><h1 className="mt-1 font-display text-3xl font-bold sm:text-4xl">See your space in a new color</h1><p className="mt-2 max-w-2xl text-sm leading-6 text-muted-foreground">Upload a room or exterior photo, then build a real manufacturer color scheme for walls, siding, trim, doors, or cabinets.</p></div>
        <section className="relative overflow-hidden rounded-[2rem] bg-[linear-gradient(135deg,hsl(268_55%_25%),hsl(280_55%_42%))] p-7 text-center text-white shadow-2xl sm:p-12">
          <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-[1.5rem] border border-white/20 bg-white/12"><WandSparkles className="h-9 w-9" /></div>
          <h2 className="mt-5 font-display text-3xl font-bold">Preview your home before you commit</h2>
          <p className="mx-auto mt-3 max-w-xl text-sm leading-6 text-white/80">Browse {ALL_PAINT_COLORS.length.toLocaleString()} Sherwin-Williams, Benjamin Moore, and PPG colors. Your finished preview can be saved privately in this browser.</p>
          <button type="button" onClick={() => fileRef.current?.click()} disabled={isLoadingPhoto} className="mt-6 inline-flex min-h-13 items-center gap-2 rounded-full bg-white px-6 text-sm font-bold text-primary shadow-xl disabled:opacity-70">{isLoadingPhoto ? <LoaderCircle className="h-5 w-5 animate-spin" /> : <Upload className="h-5 w-5" />} Choose a Photo</button>
          <input ref={fileRef} type="file" accept="image/*" capture="environment" className="sr-only" onChange={(event) => void handlePhoto(event.target.files?.[0])} />
        </section>
        {error && <div role="alert" className="rounded-xl border border-destructive/25 bg-destructive/5 p-4 text-sm font-semibold text-destructive">{error}</div>}
        {state.projects.length > 0 && <section><h2 className="font-display text-xl font-bold">Recent visualizations</h2><div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">{state.projects.slice(0, 6).map((project: VisionProject) => <button type="button" key={project.id} onClick={() => { setOriginal(project.originalImage); setResult(project.resultImage); setScheme(project.scheme); setNotes(project.notes); setSaved(true); }} className="overflow-hidden rounded-2xl border border-border bg-card text-left shadow-sm"><img src={project.resultImage} alt="Saved paint visualization" className="h-40 w-full object-cover" /><div className="p-3"><div className="truncate text-sm font-bold">{project.scheme.map((item) => item.color.name).join(" + ")}</div><div className="mt-1 text-xs text-muted-foreground">{format(parseISO(project.createdAt), "MMM d, yyyy")}</div></div></button>)}</div></section>}
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-end justify-between gap-3"><div><p className="text-sm font-bold uppercase tracking-[0.16em] text-primary/70">Color Visualizer</p><h1 className="mt-1 font-display text-3xl font-bold">Build your color scheme</h1></div><button type="button" onClick={() => { setOriginal(""); setResult(""); setScheme([]); }} className="inline-flex min-h-11 items-center gap-2 rounded-full border border-border bg-card px-4 text-sm font-bold"><Camera className="h-4 w-4" /> New photo</button></div>
      <div className="grid gap-5 xl:grid-cols-[1.12fr_0.88fr]">
        <section className="space-y-4">
          <div className="relative aspect-[4/3] overflow-hidden rounded-[1.75rem] border border-border bg-muted shadow-xl">
            <img src={original} alt="Original room" className="h-full w-full object-contain" />
            {result && <div className="absolute inset-y-0 left-0 overflow-hidden" style={{ width: `${compare}%` }}><img src={result} alt="Painted room preview" className="h-full max-w-none object-contain" style={{ width: "var(--preview-width, 100%)" }} onLoad={(event) => { const container = event.currentTarget.parentElement?.parentElement; if (container) event.currentTarget.style.width = `${container.clientWidth}px`; }} /></div>}
            {result && <div className="pointer-events-none absolute inset-y-0 w-0.5 bg-white shadow-lg" style={{ left: `${compare}%` }}><span className="absolute left-1/2 top-1/2 flex h-10 w-10 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-white text-primary shadow-xl"><ArrowLeftRight className="h-4 w-4" /></span></div>}
            {isRendering && <div className="absolute inset-0 flex flex-col items-center justify-center bg-primary/75 text-white backdrop-blur-sm"><LoaderCircle className="h-10 w-10 animate-spin" /><div className="mt-4 font-display text-xl font-bold">Painting your preview</div><div className="mt-1 text-sm text-white/75">Preserving light, texture, and room details…</div></div>}
          </div>
          {result && <div className="rounded-2xl border border-border bg-card p-4"><div className="mb-2 flex items-center justify-between text-xs font-bold"><span>Original</span><span>Painted</span></div><input aria-label="Before and after comparison" type="range" min="0" max="100" value={compare} onChange={(event) => setCompare(Number(event.target.value))} className="w-full accent-primary" /></div>}
          {error && <div role="alert" className="rounded-xl border border-destructive/25 bg-destructive/5 p-4 text-sm font-semibold text-destructive">{error}</div>}
          {result && <div className="rounded-2xl border border-border bg-card p-4"><label className="text-sm font-bold">Project notes<textarea value={notes} onChange={(event) => setNotes(event.target.value)} rows={3} className="mt-2 w-full rounded-xl border border-input bg-background p-3 font-normal outline-none focus:ring-2 focus:ring-ring" placeholder="Lighting, finish, room details…" /></label><div className="mt-3 flex flex-wrap gap-2"><button type="button" onClick={save} disabled={saved} className="inline-flex min-h-11 flex-1 items-center justify-center gap-2 rounded-xl bg-primary px-4 text-sm font-bold text-primary-foreground disabled:opacity-60">{saved ? <Check className="h-4 w-4" /> : <Save className="h-4 w-4" />}{saved ? "Saved to Vault" : "Save Project"}</button><button type="button" onClick={() => setEstimateOpen(true)} className="inline-flex min-h-11 flex-1 items-center justify-center gap-2 rounded-xl border border-primary/25 bg-accent px-4 text-sm font-bold text-primary"><PaintBucket className="h-4 w-4" /> Send for Quote</button></div></div>}
        </section>

        <aside className="min-w-0 space-y-4">
          <div className="rounded-2xl border border-border bg-card p-4 shadow-sm"><div className="flex items-center gap-2 text-sm font-bold"><Sparkles className="h-4 w-4 text-primary" /> 1. Choose surfaces</div><div className="mt-3 flex flex-wrap gap-2">{SURFACES.map((surface: SurfaceTarget) => { const paint = currentPaint(surface); return <button type="button" key={surface} onClick={() => setActiveSurface(surface)} className={`inline-flex min-h-10 items-center gap-2 rounded-full border px-3 text-xs font-bold transition ${activeSurface === surface ? "border-primary bg-primary text-primary-foreground" : "border-border bg-background text-foreground"}`}>{paint && <span className="h-3.5 w-3.5 rounded-full border border-black/10" style={{ backgroundColor: `#${paint.color.hex}` }} />}{surface}</button>; })}</div></div>
          <div className="rounded-2xl border border-border bg-card p-4 shadow-sm"><div className="flex items-center gap-2 text-sm font-bold"><PaintBucket className="h-4 w-4 text-primary" /> 2. Pick a color for {activeSurface.toLowerCase()}</div><div className="relative mt-3"><Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" /><input value={query} onChange={(event) => setQuery(event.target.value)} className="min-h-11 w-full rounded-xl border border-input bg-background pl-9 pr-3 text-sm outline-none focus:ring-2 focus:ring-ring" placeholder="Search name or code" /></div><div className="mt-2 flex gap-2 overflow-x-auto pb-1"><select value={brand} onChange={(event) => setBrand(event.target.value as PaintBrand | "All")} className="h-10 rounded-xl border border-input bg-background px-3 text-xs font-bold"><option>All</option>{PAINT_BRANDS.map((item) => <option key={item}>{item}</option>)}</select><select value={family} onChange={(event) => setFamily(event.target.value as ColorFamily | "All")} className="h-10 rounded-xl border border-input bg-background px-3 text-xs font-bold"><option>All</option>{COLOR_FAMILIES.map((item) => <option key={item}>{item}</option>)}</select></div>
            {!query && brand === "All" && family === "All" && <div className="mt-4"><div className="text-xs font-extrabold uppercase tracking-wider text-muted-foreground">Popular picks</div><div className="mt-2 flex gap-2 overflow-x-auto pb-2">{POPULAR_PAINT_COLORS.slice(0, 12).map((color) => <button type="button" key={color.id} onClick={() => selectColor(color)} className="w-24 shrink-0 text-left"><span className="block h-14 rounded-xl border border-black/10" style={{ backgroundColor: `#${color.hex}` }} /><span className="mt-1.5 block truncate text-[11px] font-bold">{color.name}</span><span className="block text-[10px] text-muted-foreground">{color.code}</span></button>)}</div></div>}
            <div className="mt-4 grid max-h-[340px] grid-cols-2 gap-2 overflow-y-auto pr-1 sm:grid-cols-3 xl:grid-cols-2 2xl:grid-cols-3">{filteredColors.map((color: PaintColor) => { const selected = currentPaint(activeSurface)?.color.id === color.id; return <button type="button" key={color.id} onClick={() => selectColor(color)} className={`rounded-xl border p-2 text-left transition ${selected ? "border-primary ring-2 ring-primary/20" : "border-border hover:border-primary/40"}`}><span className="block h-12 rounded-lg border border-black/10" style={{ backgroundColor: `#${color.hex}` }} /><span className="mt-1.5 block truncate text-xs font-bold">{color.name}</span><span className="block truncate text-[10px] text-muted-foreground">{color.brand} · {color.code}</span></button>; })}</div>{filteredColors.length === 180 && <p className="mt-2 text-center text-[11px] text-muted-foreground">Showing the first 180 matches. Narrow your search for more.</p>}</div>
          <button type="button" onClick={() => void render()} disabled={scheme.length === 0 || isRendering} className="inline-flex min-h-13 w-full items-center justify-center gap-2 rounded-2xl bg-primary px-5 text-sm font-bold text-primary-foreground shadow-lg shadow-primary/20 disabled:opacity-50"><WandSparkles className="h-5 w-5" /> Render {scheme.length > 1 ? `${scheme.length}-surface scheme` : "paint preview"}<ChevronRight className="h-4 w-4" /></button>
        </aside>
      </div>
      <EstimateDialog open={estimateOpen} onOpenChange={setEstimateOpen} context={quoteContext} />
    </div>
  );
};

export default Visualizer;
