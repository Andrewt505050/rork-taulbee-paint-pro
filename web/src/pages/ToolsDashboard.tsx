import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { format, isPast, parseISO } from "date-fns";
import { Archive, ArrowRight, BellRing, Camera, CheckCircle2, Clock3, FileText, MessageCircleQuestion, Paintbrush, Sparkles, WandSparkles } from "lucide-react";
import EstimateDialog from "@/components/EstimateDialog";
import { useHomeowner } from "@/hooks/useHomeowner";
import type { ActivityEvent, PaintReminder } from "@/lib/homeownerTypes";

const activityIcon = (kind: ActivityEvent["kind"]) => {
  if (kind === "scan") return Camera;
  if (kind === "vision" || kind === "color") return WandSparkles;
  if (kind === "expert") return MessageCircleQuestion;
  if (kind === "reminder" || kind === "reminderDone") return BellRing;
  if (kind === "document") return FileText;
  if (kind === "estimate") return Paintbrush;
  return Archive;
};

const ToolsDashboard = () => {
  const { state } = useHomeowner();
  const [estimateOpen, setEstimateOpen] = useState<boolean>(false);
  const nextReminder = useMemo<PaintReminder | undefined>(() => state.reminders
    .filter((reminder: PaintReminder): boolean => !reminder.completedAt)
    .sort((a: PaintReminder, b: PaintReminder): number => a.dueDate.localeCompare(b.dueDate))[0], [state.reminders]);
  const recentActivity = state.activity.slice(0, 5);
  const firstName = state.profile.name.trim().split(/\s+/)[0] || "Homeowner";

  return (
    <div className="space-y-7">
      <section className="flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-sm font-bold uppercase tracking-[0.16em] text-primary/70">Your home, remembered</p>
          <h1 className="mt-1 font-display text-3xl font-bold tracking-tight sm:text-4xl">Welcome, {firstName}</h1>
          <p className="mt-2 max-w-xl text-sm leading-6 text-muted-foreground">Plan colors, diagnose paint problems, and keep every room detail in one private place.</p>
        </div>
        <Link to="/tools/more" className="mt-3 inline-flex min-h-11 items-center gap-2 self-start rounded-full border border-border bg-card px-4 text-sm font-bold text-foreground shadow-sm sm:mt-0">Your settings <ArrowRight className="h-4 w-4" /></Link>
      </section>

      <section className="relative overflow-hidden rounded-[2rem] bg-[linear-gradient(135deg,hsl(268_55%_25%),hsl(273_60%_42%)_55%,hsl(296_54%_48%))] p-6 text-white shadow-[0_24px_70px_hsl(268_52%_25%/0.3)] sm:p-8">
        <div aria-hidden className="absolute -right-12 -top-16 h-56 w-56 rounded-full bg-white/10 blur-2xl" />
        <div aria-hidden className="absolute -bottom-24 right-24 h-52 w-52 rounded-full bg-amber-300/20 blur-3xl" />
        <div className="relative max-w-2xl">
          <div className="inline-flex items-center gap-2 rounded-full bg-white/12 px-3 py-1.5 text-xs font-bold uppercase tracking-wider"><Sparkles className="h-3.5 w-3.5" /> Color Visualizer</div>
          <h2 className="mt-4 font-display text-3xl font-bold leading-tight sm:text-4xl">See the finished room before the first drop cloth.</h2>
          <p className="mt-3 max-w-xl text-sm leading-6 text-white/82 sm:text-base">Upload one photo, choose real manufacturer colors, and build a complete walls-and-trim scheme.</p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Link to="/tools/visualize" className="inline-flex min-h-12 items-center gap-2 rounded-full bg-white px-5 text-sm font-bold text-primary shadow-lg"><WandSparkles className="h-4 w-4" /> Start Visualizing</Link>
            <Link to="/tools/expert" className="inline-flex min-h-12 items-center gap-2 rounded-full border border-white/25 bg-white/10 px-5 text-sm font-bold text-white backdrop-blur"><MessageCircleQuestion className="h-4 w-4" /> Ask an Expert</Link>
          </div>
        </div>
      </section>

      <section>
        <div className="mb-3 flex items-center justify-between"><h2 className="font-display text-xl font-bold">Quick actions</h2></div>
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <Link to="/tools/scanner" className="group rounded-2xl border border-border/70 bg-card p-4 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-lg">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-rose-50 text-rose-700 dark:bg-rose-950"><Camera className="h-5 w-5" /></span>
            <h3 className="mt-3 font-bold">Scan a defect</h3><p className="mt-1 text-xs leading-5 text-muted-foreground">Find causes and next steps from a photo.</p>
          </Link>
          <Link to="/tools/expert" className="group rounded-2xl border border-border/70 bg-card p-4 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-lg">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-accent text-primary"><MessageCircleQuestion className="h-5 w-5" /></span>
            <h3 className="mt-3 font-bold">Ask an expert</h3><p className="mt-1 text-xs leading-5 text-muted-foreground">Get practical guidance for prep and products.</p>
          </Link>
          <Link to="/tools/vault" className="group rounded-2xl border border-border/70 bg-card p-4 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-lg">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-sky-50 text-sky-700 dark:bg-sky-950"><Archive className="h-5 w-5" /></span>
            <h3 className="mt-3 font-bold">Open Paint Vault</h3><p className="mt-1 text-xs leading-5 text-muted-foreground">Rooms, colors, photos, scans, and documents.</p>
          </Link>
          <button type="button" onClick={() => setEstimateOpen(true)} className="group rounded-2xl border border-border/70 bg-card p-4 text-left shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-lg">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-amber-50 text-amber-700 dark:bg-amber-950"><Paintbrush className="h-5 w-5" /></span>
            <h3 className="mt-3 font-bold">Request estimate</h3><p className="mt-1 text-xs leading-5 text-muted-foreground">Send your project details to the Taulbee team.</p>
          </button>
        </div>
      </section>

      <div className="grid gap-6 xl:grid-cols-[0.9fr_1.1fr]">
        <section>
          <div className="mb-3 flex items-center justify-between"><h2 className="font-display text-xl font-bold">Protect your paint</h2><Link to="/tools/maintenance" className="text-sm font-bold text-primary">See all</Link></div>
          <div className="rounded-2xl border border-border/70 bg-card p-5 shadow-sm">
            {nextReminder ? <div className="flex items-start gap-4">
              <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-amber-50 text-amber-700 dark:bg-amber-950"><BellRing className="h-5 w-5" /></span>
              <div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><h3 className="font-bold">{nextReminder.title}</h3>{isPast(parseISO(nextReminder.dueDate)) && <span className="rounded-full bg-rose-100 px-2 py-1 text-[10px] font-extrabold uppercase text-rose-700">Overdue</span>}</div><p className="mt-1 text-sm text-muted-foreground">{format(parseISO(nextReminder.dueDate), "MMM d, yyyy")}{nextReminder.surface ? ` · ${nextReminder.surface}` : ""}</p><Link to="/tools/maintenance" className="mt-3 inline-flex items-center gap-1 text-sm font-bold text-primary">View reminder <ArrowRight className="h-4 w-4" /></Link></div>
            </div> : <div className="text-center"><BellRing className="mx-auto h-10 w-10 text-primary/55" /><h3 className="mt-3 font-bold">Stay ahead of touch-ups</h3><p className="mx-auto mt-1 max-w-sm text-sm leading-6 text-muted-foreground">Set reminders for caulk, exterior checks, cleaning, and seasonal maintenance.</p><Link to="/tools/maintenance" className="mt-4 inline-flex min-h-11 items-center gap-2 rounded-full bg-primary px-5 text-sm font-bold text-primary-foreground"><BellRing className="h-4 w-4" /> Add reminder</Link></div>}
          </div>
        </section>

        <section>
          <div className="mb-3 flex items-center justify-between"><h2 className="font-display text-xl font-bold">Recent activity</h2>{recentActivity.length > 0 && <Link to="/tools/activity" className="text-sm font-bold text-primary">See all</Link>}</div>
          <div className="overflow-hidden rounded-2xl border border-border/70 bg-card shadow-sm">
            {recentActivity.length === 0 ? <div className="p-8 text-center"><Clock3 className="mx-auto h-10 w-10 text-primary/45" /><h3 className="mt-3 font-bold">No saved projects yet</h3><p className="mt-1 text-sm text-muted-foreground">Your scans, colors, rooms, and reminders will appear here.</p></div> : recentActivity.map((event: ActivityEvent, index: number) => {
              const Icon = activityIcon(event.kind);
              return <div key={event.id} className={`flex items-center gap-3 p-4 ${index > 0 ? "border-t border-border/60" : ""}`}><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-accent text-primary"><Icon className="h-4 w-4" /></span><div className="min-w-0 flex-1"><div className="truncate text-sm font-bold">{event.title}</div><div className="mt-0.5 flex items-center gap-1.5 text-xs text-muted-foreground"><Clock3 className="h-3 w-3" />{format(parseISO(event.createdAt), "MMM d · h:mm a")}</div></div>{event.kind === "reminderDone" && <CheckCircle2 className="h-5 w-5 text-emerald-600" />}</div>;
            })}
          </div>
        </section>
      </div>
      <EstimateDialog open={estimateOpen} onOpenChange={setEstimateOpen} />
    </div>
  );
};

export default ToolsDashboard;
