import { NavLink, Outlet, Link, useLocation } from "react-router-dom";
import { Archive, Home, MoreHorizontal, MessageCircleQuestion, WandSparkles, ArrowLeft, ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";
import { useHomeowner } from "@/hooks/useHomeowner";

const NAV_ITEMS = [
  { to: "/tools", label: "Home", icon: Home, exact: true },
  { to: "/tools/visualize", label: "Visualize", icon: WandSparkles },
  { to: "/tools/vault", label: "Vault", icon: Archive },
  { to: "/tools/expert", label: "Expert", icon: MessageCircleQuestion },
  { to: "/tools/more", label: "More", icon: MoreHorizontal },
] as const;

const ToolShell = () => {
  const { pathname } = useLocation();
  const { isReady, storageError } = useHomeowner();

  if (!isReady) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="text-center">
          <img src="/logo.png" alt="" className="mx-auto h-16 w-16 animate-pulse object-contain" />
          <p className="mt-4 text-sm font-semibold text-muted-foreground">Opening your private Paint Vault…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top_left,hsl(var(--accent)/0.7),transparent_34%),hsl(var(--background))] lg:grid lg:grid-cols-[244px_1fr]">
      <aside className="hidden border-r border-border/70 bg-card/90 p-4 backdrop-blur-xl lg:sticky lg:top-0 lg:flex lg:h-screen lg:flex-col">
        <Link to="/" className="flex items-center gap-3 rounded-2xl p-2 transition-colors hover:bg-accent/70">
          <img src="/logo.png" alt="Taulbee Painting" className="h-11 w-11 object-contain" />
          <div>
            <div className="font-display text-base font-bold leading-tight">Taulbee Painting</div>
            <div className="text-xs font-medium text-muted-foreground">Homeowner Tools</div>
          </div>
        </Link>
        <nav className="mt-8 space-y-2" aria-label="Homeowner tools">
          {NAV_ITEMS.map((item) => {
            const { to, label, icon: Icon } = item;
            const active = "exact" in item && item.exact ? pathname === to : pathname.startsWith(to);
            return (
              <NavLink key={to} to={to} className={cn(
                "flex min-h-12 items-center gap-3 rounded-2xl px-3.5 text-sm font-semibold transition-all",
                active ? "bg-primary text-primary-foreground shadow-[0_10px_24px_hsl(var(--primary)/0.22)]" : "text-muted-foreground hover:bg-accent hover:text-foreground",
              )}>
                <Icon className="h-5 w-5" />
                {label}
              </NavLink>
            );
          })}
        </nav>
        <div className="mt-auto rounded-2xl border border-primary/15 bg-accent/70 p-4">
          <div className="flex items-center gap-2 text-sm font-bold text-primary"><ShieldCheck className="h-4 w-4" /> Private by default</div>
          <p className="mt-1.5 text-xs leading-5 text-muted-foreground">Projects are saved only in this browser. No account is required.</p>
        </div>
        <Link to="/" className="mt-3 inline-flex min-h-11 items-center gap-2 px-2 text-sm font-semibold text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-4 w-4" /> Back to website
        </Link>
      </aside>

      <div className="min-w-0 pb-24 lg:pb-0">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-border/60 bg-background/85 px-4 backdrop-blur-xl lg:hidden">
          <Link to="/" className="flex items-center gap-2.5">
            <img src="/logo.png" alt="Taulbee Painting" className="h-9 w-9 object-contain" />
            <div>
              <div className="font-display text-sm font-bold leading-tight">Taulbee Painting</div>
              <div className="text-[11px] font-medium text-muted-foreground">Homeowner Tools</div>
            </div>
          </Link>
          <Link to="/" className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-border bg-card text-muted-foreground" aria-label="Back to website">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </header>

        {storageError && <div role="alert" className="mx-4 mt-4 rounded-xl border border-amber-300 bg-amber-50 px-4 py-3 text-sm font-medium text-amber-900 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-100">{storageError}</div>}
        <main className="mx-auto w-full max-w-6xl px-4 py-5 sm:px-6 sm:py-7 lg:px-8"><Outlet /></main>
      </div>

      <nav className="fixed inset-x-0 bottom-0 z-40 grid grid-cols-5 border-t border-border/70 bg-card/95 px-2 pb-[max(0.45rem,env(safe-area-inset-bottom))] pt-2 shadow-[0_-12px_30px_rgba(32,18,50,0.08)] backdrop-blur-xl lg:hidden" aria-label="Homeowner tools">
        {NAV_ITEMS.map((item) => {
          const { to, label, icon: Icon } = item;
          const active = "exact" in item && item.exact ? pathname === to : pathname.startsWith(to);
          return (
            <NavLink key={to} to={to} className="flex min-h-14 flex-col items-center justify-center gap-1" aria-current={active ? "page" : undefined}>
              <span className={cn("flex h-8 min-w-11 items-center justify-center rounded-xl transition-all", active ? "bg-accent text-primary" : "text-muted-foreground")}><Icon className="h-[18px] w-[18px]" /></span>
              <span className={cn("text-[10px] font-bold", active ? "text-primary" : "text-muted-foreground")}>{label}</span>
            </NavLink>
          );
        })}
      </nav>
    </div>
  );
};

export default ToolShell;
