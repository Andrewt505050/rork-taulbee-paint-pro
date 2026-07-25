import { useState } from "react";
import { Link } from "react-router-dom";
import {
  Paintbrush,
  ScanSearch,
  MessageCircleQuestion,
  Archive,
  BellRing,
  Mail,
  ArrowRight,
  Smartphone,
  Sparkles,
  CheckCircle2,
} from "lucide-react";
import SiteLayout, { SUPPORT_EMAIL, SUPPORT_PHONE_TEL } from "@/components/SiteLayout";
import EstimateDialog from "@/components/EstimateDialog";

const FEATURES: { icon: React.ElementType; title: string; body: string }[] = [
  {
    icon: Paintbrush,
    title: "Live paint visualizer",
    body: "Snap a room or exterior photo and repaint walls, siding, trim, doors, and cabinets instantly — with the room's real lighting and shadows kept intact.",
  },
  {
    icon: Archive,
    title: "7,700+ real colors",
    body: "The complete Sherwin-Williams, Benjamin Moore, and PPG color books, searchable by name or code, with true swatches — browsable offline.",
  },
  {
    icon: ScanSearch,
    title: "Paint defect scanner",
    body: "Photograph peeling, cracking, or bubbling paint and get an instant diagnosis with severity, likely causes, and what to do next.",
  },
  {
    icon: MessageCircleQuestion,
    title: "Ask the Paint Expert",
    body: "A friendly advisor for prep, products, and finishes — from humid bathrooms to kitchen cabinets. Your conversation stays on your phone.",
  },
  {
    icon: BellRing,
    title: "Paint vault & reminders",
    body: "Never forget what color is on your walls. Save rooms, colors, sheens, photos, and documents, and get maintenance reminders before problems start.",
  },
  {
    icon: Mail,
    title: "Estimates from real pros",
    body: "Love a color scheme? Send it to Taulbee Painting with your photos as a ready-to-quote paint spec, straight from the app.",
  },
];

const STEPS: { step: string; title: string; body: string }[] = [
  {
    step: "1",
    title: "Photograph your space",
    body: "Take a photo of any room or exterior, or pick one from your library.",
  },
  {
    step: "2",
    title: "Flick through colors",
    body: "Paint every surface instantly from the full pro color books — walls, trim, doors, and more in one scheme.",
  },
  {
    step: "3",
    title: "Get it painted for real",
    body: "Request an estimate and your exact colors arrive with it — no guesswork for anyone.",
  },
];

const Index = () => {
  const [estimateOpen, setEstimateOpen] = useState<boolean>(false);
  return (
  <SiteLayout>
    {/* Hero */}
    <section className="relative overflow-hidden">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(70%_60%_at_50%_0%,hsl(268_45%_92%)_0%,transparent_70%)]"
      />
      <div className="relative mx-auto w-full max-w-5xl px-4 pb-16 pt-14 text-center sm:px-6 sm:pb-24 sm:pt-20">
        <img
          src="/logo.png"
          alt="Taulbee Painting logo"
          className="mx-auto h-24 w-24 object-contain sm:h-28 sm:w-28"
        />
        <h1 className="font-display mx-auto mt-6 max-w-2xl text-4xl font-bold leading-tight tracking-tight text-foreground sm:text-5xl">
          See your home in a new color{" "}
          <span className="text-primary">before the brush comes out</span>
        </h1>
        <p className="mx-auto mt-5 max-w-xl text-base leading-7 text-muted-foreground sm:text-lg">
          Plan the project online with 7,700+ real paint colors, AI paint guidance,
          and a private Paint Vault — then connect with the local professionals who
          make it real.
        </p>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <Link to="/tools/visualize" className="inline-flex min-h-13 min-w-[220px] items-center justify-center gap-2 rounded-full bg-primary px-6 text-sm font-bold text-primary-foreground shadow-[0_12px_30px_hsl(var(--primary)/0.28)] transition-transform hover:scale-[1.02]"><Sparkles className="h-4 w-4" /> Try the Color Visualizer <ArrowRight className="h-4 w-4" /></Link>
          <button type="button" onClick={() => setEstimateOpen(true)} className="inline-flex min-h-13 min-w-[220px] items-center justify-center gap-2 rounded-full border-2 border-primary bg-card px-6 text-sm font-bold text-primary shadow-sm transition-transform hover:scale-[1.02]"><Paintbrush className="h-4 w-4" /> Request a Free Estimate</button>
        </div>
        <div className="mx-auto mt-5 flex max-w-xl flex-wrap items-center justify-center gap-x-5 gap-y-2 text-xs font-semibold text-muted-foreground">
          <span className="inline-flex items-center gap-1.5"><CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" /> No account required</span>
          <span className="inline-flex items-center gap-1.5"><CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" /> Projects stay in your browser</span>
          <span className="inline-flex items-center gap-1.5"><CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" /> Free to use</span>
        </div>
        <div className="mt-6 flex flex-wrap items-center justify-center gap-4 text-sm font-semibold"><a href={SUPPORT_PHONE_TEL} className="text-primary underline underline-offset-4">Call 513-594-7595</a><span className="text-muted-foreground">Local interior & exterior painting</span><a href="https://apps.apple.com/us/search?term=Taulbee%20Painting" target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 text-primary underline underline-offset-4"><Smartphone className="h-4 w-4" /> Find the iPhone app</a></div>
      </div>
    </section>

    {/* Features */}
    <section className="mx-auto w-full max-w-5xl px-4 pb-16 sm:px-6">
      <h2 className="font-display text-center text-2xl font-bold text-foreground sm:text-3xl">
        Everything a paint project needs
      </h2>
      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((feature) => (
          <div
            key={feature.title}
            className="rounded-2xl border border-border/70 bg-card p-5 shadow-[0_1px_3px_rgba(46,26,71,0.06)]"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent text-primary">
              <feature.icon className="h-5 w-5" />
            </div>
            <h3 className="mt-3 text-base font-semibold text-foreground">
              {feature.title}
            </h3>
            <p className="mt-1.5 text-sm leading-6 text-muted-foreground">
              {feature.body}
            </p>
          </div>
        ))}
      </div>
    </section>

    {/* How it works */}
    <section className="border-y border-border/70 bg-muted/40">
      <div className="mx-auto w-full max-w-5xl px-4 py-14 sm:px-6">
        <h2 className="font-display text-center text-2xl font-bold text-foreground sm:text-3xl">
          How it works
        </h2>
        <div className="mt-8 grid gap-6 sm:grid-cols-3">
          {STEPS.map((item) => (
            <div key={item.step} className="text-center">
              <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-primary font-display text-lg font-bold text-primary-foreground">
                {item.step}
              </div>
              <h3 className="mt-3 text-base font-semibold text-foreground">
                {item.title}
              </h3>
              <p className="mx-auto mt-1.5 max-w-xs text-sm leading-6 text-muted-foreground">
                {item.body}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>

    {/* CTA */}
    <section className="mx-auto w-full max-w-5xl px-4 py-16 sm:px-6">
      <div className="rounded-3xl bg-primary px-6 py-10 text-center sm:px-10">
        <h2 className="font-display text-2xl font-bold text-primary-foreground sm:text-3xl">
          Ready for a fresh coat?
        </h2>
        <p className="mx-auto mt-3 max-w-md text-sm leading-6 text-primary-foreground/80">
          Visualize colors, scan a problem area, or send your project directly to the Taulbee Painting team.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          <Link to="/tools/visualize" className="inline-flex items-center gap-2 rounded-full bg-card px-6 py-3 text-sm font-bold text-primary shadow-sm transition-transform hover:scale-[1.02]"><Sparkles className="h-4 w-4" /> Try the Visualizer</Link>
          <button type="button" onClick={() => setEstimateOpen(true)} className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-6 py-3 text-sm font-semibold text-primary-foreground"><Paintbrush className="h-4 w-4" /> Request an Estimate</button>
          <a href={`mailto:${SUPPORT_EMAIL}`} className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-6 py-3 text-sm font-semibold text-primary-foreground"><Mail className="h-4 w-4" /> Email Taulbee</a>
        </div>
      </div>
      <p className="mt-8 text-center text-xs leading-5 text-muted-foreground">Serving homeowners with quality interior and exterior painting, practical planning tools, and clear project guidance.</p>
    </section>
    <EstimateDialog open={estimateOpen} onOpenChange={setEstimateOpen} context="Estimate requested from the website landing page" />
  </SiteLayout>
  );
};

export default Index;
