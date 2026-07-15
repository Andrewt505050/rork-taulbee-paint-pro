import SiteLayout from "@/components/SiteLayout";

type LegalShellProps = {
  title: string;
  effectiveDate: string;
  intro: string;
  children: React.ReactNode;
};

/** Consistent wrapper for the privacy policy and terms pages. */
const LegalShell = ({ title, effectiveDate, intro, children }: LegalShellProps) => (
  <SiteLayout>
    <div className="mx-auto w-full max-w-3xl px-4 py-12 sm:px-6 sm:py-16">
      <p className="text-xs font-semibold uppercase tracking-widest text-primary">
        Taulbee Painting for iPhone
      </p>
      <h1 className="font-display mt-2 text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
        {title}
      </h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Effective date: {effectiveDate}
      </p>
      <p className="mt-6 text-[15px] leading-7 text-muted-foreground">{intro}</p>
      <div className="legal-prose mt-4">{children}</div>
    </div>
  </SiteLayout>
);

export default LegalShell;
