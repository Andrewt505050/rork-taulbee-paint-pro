import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { Mail, Menu, Phone, Sparkles, X } from "lucide-react";
import { cn } from "@/lib/utils";

const NAV_LINKS: { label: string; to: string }[] = [
  { label: "Homeowner Tools", to: "/tools" },
  { label: "Support", to: "/support" },
  { label: "Privacy", to: "/privacy" },
  { label: "Terms", to: "/terms" },
];

const SUPPORT_EMAIL = "taulbeepainting2@gmail.com";
const SUPPORT_PHONE = "513-594-7595";
const SUPPORT_PHONE_TEL = "tel:+15135947595";

/** Shared chrome (header + footer) for every page of the Taulbee Painting site. */
const SiteLayout = ({ children }: { children: React.ReactNode }) => {
  const { pathname } = useLocation();
  const [menuOpen, setMenuOpen] = useState<boolean>(false);

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <header className="sticky top-0 z-40 border-b border-border/70 bg-background/85 backdrop-blur">
        <div className="mx-auto flex h-16 w-full max-w-5xl items-center justify-between px-4 sm:px-6">
          <Link to="/" className="flex items-center gap-2.5">
            <img
              src="/logo.png"
              alt="Taulbee Painting logo"
              className="h-9 w-9 object-contain"
            />
            <span className="font-display text-lg font-bold tracking-tight text-foreground">
              Taulbee Painting
            </span>
          </Link>
          <nav className="hidden items-center gap-1 sm:flex sm:gap-2">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.to}
                to={link.to}
                className={cn(
                  "rounded-full px-2.5 py-1.5 text-xs font-semibold transition-colors sm:px-3 sm:text-sm",
                  pathname === link.to
                    ? "bg-accent text-accent-foreground"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                {link.to === "/tools" && <Sparkles className="mr-1 hidden h-3.5 w-3.5 sm:inline" />}
                {link.label}
              </Link>
            ))}
          </nav>
          <button type="button" onClick={() => setMenuOpen((open) => !open)} className="flex h-11 w-11 items-center justify-center rounded-full border border-border bg-card sm:hidden" aria-label="Toggle navigation" aria-expanded={menuOpen}>{menuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}</button>
        </div>
        {menuOpen && <nav className="border-t border-border/70 bg-card p-3 sm:hidden" aria-label="Mobile navigation">{NAV_LINKS.map((link) => <Link key={link.to} to={link.to} onClick={() => setMenuOpen(false)} className={cn("flex min-h-12 items-center rounded-xl px-4 text-sm font-bold", pathname === link.to ? "bg-accent text-primary" : "text-foreground")}>{link.to === "/tools" && <Sparkles className="mr-2 h-4 w-4" />}{link.label}</Link>)}</nav>}
      </header>

      <main className="flex-1">{children}</main>

      <footer className="border-t border-border/70 bg-muted/40">
        <div className="mx-auto w-full max-w-5xl px-4 py-10 sm:px-6">
          <div className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
            <div className="max-w-xs">
              <div className="flex items-center gap-2">
                <img
                  src="/logo.png"
                  alt=""
                  aria-hidden
                  className="h-7 w-7 object-contain"
                />
                <span className="font-display text-base font-bold text-foreground">
                  Taulbee Painting
                </span>
              </div>
              <p className="mt-2 text-sm leading-6 text-muted-foreground">
                Quality interior &amp; exterior painting — and the app that lets
                you see your home in a new color first.
              </p>
            </div>
            <div className="flex flex-col gap-2 text-sm">
              <span className="font-semibold text-foreground">Pages</span>
              {NAV_LINKS.map((link) => (
                <Link
                  key={link.to}
                  to={link.to}
                  className="text-muted-foreground transition-colors hover:text-foreground"
                >
                  {link.to === "/tools" && <Sparkles className="mr-1 hidden h-3.5 w-3.5 sm:inline" />}
                {link.label}
                </Link>
              ))}
            </div>
            <div className="flex flex-col gap-2 text-sm">
              <span className="font-semibold text-foreground">Contact</span>
              <a
                href={`mailto:${SUPPORT_EMAIL}`}
                className="inline-flex items-center gap-1.5 text-muted-foreground transition-colors hover:text-foreground"
              >
                <Mail className="h-4 w-4" />
                {SUPPORT_EMAIL}
              </a>
              <a
                href={SUPPORT_PHONE_TEL}
                className="inline-flex items-center gap-1.5 text-muted-foreground transition-colors hover:text-foreground"
              >
                <Phone className="h-4 w-4" />
                {SUPPORT_PHONE}
              </a>
            </div>
          </div>
          <p className="mt-8 text-xs text-muted-foreground">
            © {new Date().getFullYear()} Taulbee Painting. All rights reserved.
            Sherwin-Williams, Benjamin Moore, and PPG are trademarks of their
            respective owners; Taulbee Painting is not affiliated with or
            endorsed by them.
          </p>
        </div>
      </footer>
    </div>
  );
};

export { SUPPORT_EMAIL, SUPPORT_PHONE, SUPPORT_PHONE_TEL };
export default SiteLayout;
