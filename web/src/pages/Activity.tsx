import { format, parseISO } from "date-fns";
import { Archive, BellRing, Camera, Clock3, FileText, MessageCircleQuestion, Paintbrush, WandSparkles } from "lucide-react";
import { useHomeowner } from "@/hooks/useHomeowner";
import type { ActivityEvent } from "@/lib/homeownerTypes";

const iconFor = (kind: ActivityEvent["kind"]) => {
  if (kind === "scan") return Camera;
  if (kind === "vision" || kind === "color") return WandSparkles;
  if (kind === "expert") return MessageCircleQuestion;
  if (kind === "reminder" || kind === "reminderDone") return BellRing;
  if (kind === "document") return FileText;
  if (kind === "estimate") return Paintbrush;
  return Archive;
};

const Activity = () => {
  const { state } = useHomeowner();
  return <div className="mx-auto max-w-3xl"><p className="text-sm font-bold uppercase tracking-[0.16em] text-primary/70">History</p><h1 className="mt-1 font-display text-3xl font-bold sm:text-4xl">Activity Timeline</h1><p className="mt-2 text-sm text-muted-foreground">A private record of the work you’ve planned and saved in this browser.</p><div className="mt-6 overflow-hidden rounded-2xl border border-border bg-card shadow-sm">{state.activity.length === 0 ? <div className="p-10 text-center"><Clock3 className="mx-auto h-10 w-10 text-primary/45" /><h2 className="mt-3 font-bold">No activity yet</h2><p className="mt-1 text-sm text-muted-foreground">Start a visualization, scan, room, or reminder.</p></div> : state.activity.map((event: ActivityEvent, index: number) => { const Icon = iconFor(event.kind); return <div key={event.id} className={`flex gap-4 p-4 sm:p-5 ${index > 0 ? "border-t border-border/60" : ""}`}><span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-accent text-primary"><Icon className="h-5 w-5" /></span><div className="min-w-0 flex-1"><div className="font-bold">{event.title}</div>{event.detail && <div className="mt-1 text-sm leading-5 text-muted-foreground">{event.detail}</div>}<div className="mt-2 flex items-center gap-1.5 text-xs text-muted-foreground"><Clock3 className="h-3 w-3" />{format(parseISO(event.createdAt), "MMMM d, yyyy · h:mm a")}</div></div></div>; })}</div></div>;
};

export default Activity;
