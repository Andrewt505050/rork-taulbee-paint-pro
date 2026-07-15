import { Link, useLocation } from "react-router-dom";
import { Mail } from "lucide-react";
import { cn } from "@/lib/utils";

const NAV_LINKS: { label: string; to: string }[] = [
  { label: "Support", to: "/support" },
  { label: "Privacy", to: "/privacy" },
  { label: "Terms", to: "/terms" },
];

const SUPPORT_EMAIL = "hello@taulbeepainting.com";

/** Shared chrome (header + footer) for every page of the Taulbee Painting site. */
const SiteLayout = ({ children }: { children: React.ReactNode }) => {
  const { pathname } = useLocation();

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
          <nav className="flex items-center gap-1 sm:gap-2">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.to}
                to={link.to}
                className={cn(
                  "rounded-full px-3 py-1.5 text-sm font-medium transition-colors",
                  pathname === link.to
                    ? "bg-accent text-accent-foreground"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                {link.label}
              </Link>
            ))}
          </nav>
        </div>
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

export { SUPPORT_EMAIL };
export default SiteLayout;
