import { Mail, Phone, LifeBuoy, Camera, Wand2, BellRing, Trash2 } from "lucide-react";
import SiteLayout, {
  SUPPORT_EMAIL,
  SUPPORT_PHONE,
  SUPPORT_PHONE_TEL,
} from "@/components/SiteLayout";

const FAQS: { icon: React.ElementType; q: string; a: string }[] = [
  {
    icon: Wand2,
    q: "The visualizer can't find my wall or surface",
    a: "Use a clear, well-lit photo, choose a surface, and tap a flat area of it. Once selected, colors change instantly. If the tap catches too little detail, try another spot. You can also request an optional high-quality render.",
  },
  {
    icon: Wand2,
    q: "HD renders or the Paint Expert aren't responding",
    a: "Instant website previews and the color library run in your browser. High-quality renders, defect scans, and Expert answers need an internet connection. Check your connection and retry; your instant preview and saved browser work remain available.",
  },
  {
    icon: Camera,
    q: "The camera or photo picker isn't working",
    a: "On the website, allow camera or photo access when your browser asks, or use the file picker. On iPhone, open Settings → Privacy & Security → Camera or Photos and confirm Taulbee Painting is allowed.",
  },
  {
    icon: BellRing,
    q: "Maintenance reminders aren't appearing",
    a: "On the website, add important reminders to your calendar because browser alerts are not reliable when the site is closed. On iPhone, check Settings → Notifications → Taulbee Painting.",
  },
  {
    icon: Mail,
    q: "What happens when I request an estimate?",
    a: "The website sends your name, contact details, project notes, and selected photos directly after you press Send. A success message appears only after delivery. If delivery is unavailable, the form offers email and share fallbacks.",
  },
  {
    icon: Trash2,
    q: "How do I delete my data?",
    a: "Your rooms, colors, scans, visualizations, reminders, and chat history live only in this browser or on your iPhone. Delete individual items, use Delete All on the website’s More page, clear site data, or delete the iPhone app. There is no account to close.",
  },
];

const Support = () => (
  <SiteLayout>
    <div className="mx-auto w-full max-w-3xl px-4 py-12 sm:px-6 sm:py-16">
      <p className="text-xs font-semibold uppercase tracking-widest text-primary">
        Taulbee Painting website & iPhone app
      </p>
      <h1 className="font-display mt-2 text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
        Support
      </h1>
      <p className="mt-4 text-[15px] leading-7 text-muted-foreground">
        Need help with the Taulbee Painting website or iPhone app? We're happy to help with
        anything — from visualizer questions to estimate requests.
      </p>

      <div className="mt-8 rounded-2xl border border-border/70 bg-card p-6">
        <div className="flex items-start gap-4">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-accent text-primary">
            <LifeBuoy className="h-5 w-5" />
          </div>
          <div>
            <h2 className="text-lg font-semibold text-foreground">
              Contact us
            </h2>
            <p className="mt-1 text-sm leading-6 text-muted-foreground">
              Email or call — we usually reply within two business days.
            </p>
            <div className="mt-3 flex flex-wrap gap-2.5">
              <a
                href={`mailto:${SUPPORT_EMAIL}?subject=Taulbee%20Painting%20app%20support`}
                className="inline-flex items-center gap-2 rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground transition-transform hover:scale-[1.02]"
              >
                <Mail className="h-4 w-4" />
                {SUPPORT_EMAIL}
              </a>
              <a
                href={SUPPORT_PHONE_TEL}
                className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-5 py-2.5 text-sm font-semibold text-foreground transition-transform hover:scale-[1.02]"
              >
                <Phone className="h-4 w-4" />
                {SUPPORT_PHONE}
              </a>
            </div>
          </div>
        </div>
        <div className="mt-5 rounded-xl bg-muted/60 p-4">
          <p className="text-sm font-semibold text-foreground">
            To help us help you faster, include:
          </p>
          <ul className="mt-2 list-disc space-y-1 pl-5 text-sm leading-6 text-muted-foreground">
            <li>The app version (More tab → About)</li>
            <li>Your device model and iOS version</li>
            <li>What you were doing when the problem happened</li>
            <li>Screenshots or the exact error message, if any</li>
          </ul>
        </div>
      </div>

      <h2 className="font-display mt-12 text-2xl font-bold text-foreground">
        Common questions
      </h2>
      <div className="mt-5 space-y-4">
        {FAQS.map((faq) => (
          <div
            key={faq.q}
            className="rounded-2xl border border-border/70 bg-card p-5"
          >
            <div className="flex items-center gap-3">
              <faq.icon className="h-4.5 w-4.5 h-5 w-5 shrink-0 text-primary" />
              <h3 className="text-base font-semibold text-foreground">
                {faq.q}
              </h3>
            </div>
            <p className="mt-2 text-sm leading-6 text-muted-foreground">
              {faq.a}
            </p>
          </div>
        ))}
      </div>

      <p className="mt-10 text-sm leading-6 text-muted-foreground">
        The Taulbee Painting website and iPhone app are free, have no accounts, and no
        purchases — so there's nothing to cancel or refund. For privacy
        questions or data requests, see our{" "}
        <a
          href="/privacy"
          className="text-primary underline underline-offset-4"
        >
          Privacy Policy
        </a>
        .
      </p>
    </div>
  </SiteLayout>
);

export default Support;
