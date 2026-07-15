import { Mail, LifeBuoy, Camera, Wand2, BellRing, Trash2 } from "lucide-react";
import SiteLayout, { SUPPORT_EMAIL } from "@/components/SiteLayout";

const FAQS: { icon: React.ElementType; q: string; a: string }[] = [
  {
    icon: Wand2,
    q: "The visualizer can't find my wall or surface",
    a: "Surface detection works best on clear, well-lit photos taken straight on. Try a photo where the surface fills more of the frame and isn't heavily obstructed. If detection still can't find it, the app automatically falls back to full AI renders per color — you can keep going either way.",
  },
  {
    icon: Wand2,
    q: "HD renders or the Paint Expert aren't responding",
    a: "Instant previews and the color library work offline, but HD renders, surface detection, defect scans, and Expert answers need an internet connection. Check your connection and try again — if it keeps failing, email us with the time it happened.",
  },
  {
    icon: Camera,
    q: "The camera or photo picker isn't working",
    a: "Open iOS Settings → Privacy & Security → Camera (or Photos) and make sure Taulbee Painting is allowed. You can change these permissions at any time.",
  },
  {
    icon: BellRing,
    q: "Maintenance reminders aren't appearing",
    a: "Reminders use local notifications. Check iOS Settings → Notifications → Taulbee Painting and make sure notifications are allowed.",
  },
  {
    icon: Mail,
    q: "What happens when I request an estimate?",
    a: "The app composes an email (with your name, contact details, project notes, and any photos you attached) in your own mail app — nothing is sent until you hit send. It goes to our team, and we'll reply to arrange the estimate.",
  },
  {
    icon: Trash2,
    q: "How do I delete my data?",
    a: "Your rooms, saved colors, scans, visualizations, reminders, and chat history live only on your device. Delete individual items in the app, or delete the app to remove everything. There is no account to close.",
  },
];

const Support = () => (
  <SiteLayout>
    <div className="mx-auto w-full max-w-3xl px-4 py-12 sm:px-6 sm:py-16">
      <p className="text-xs font-semibold uppercase tracking-widest text-primary">
        Taulbee Painting for iPhone
      </p>
      <h1 className="font-display mt-2 text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
        Support
      </h1>
      <p className="mt-4 text-[15px] leading-7 text-muted-foreground">
        Need help with the Taulbee Painting app? We're happy to help with
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
              Email is the fastest way to reach the team. We usually reply
              within two business days.
            </p>
            <a
              href={`mailto:${SUPPORT_EMAIL}?subject=Taulbee%20Painting%20app%20support`}
              className="mt-3 inline-flex items-center gap-2 rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground transition-transform hover:scale-[1.02]"
            >
              <Mail className="h-4 w-4" />
              {SUPPORT_EMAIL}
            </a>
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
        The Taulbee Painting app is free, has no accounts, and no in-app
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
