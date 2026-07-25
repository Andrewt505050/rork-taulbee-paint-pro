import { lazy, Suspense } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import HostingBadgeHider from "@/components/HostingBadgeHider";
import { HomeownerProvider } from "@/hooks/useHomeowner";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import Index from "./pages/Index";
import Support from "./pages/Support";
import Privacy from "./pages/Privacy";
import Terms from "./pages/Terms";
import NotFound from "./pages/NotFound";

const ToolShell = lazy(() => import("@/components/ToolShell"));
const ToolsDashboard = lazy(() => import("./pages/ToolsDashboard"));
const Visualizer = lazy(() => import("./pages/Visualizer"));
const Scanner = lazy(() => import("./pages/Scanner"));
const Expert = lazy(() => import("./pages/Expert"));
const Vault = lazy(() => import("./pages/Vault"));
const Maintenance = lazy(() => import("./pages/Maintenance"));
const Activity = lazy(() => import("./pages/Activity"));
const MoreTools = lazy(() => import("./pages/MoreTools"));
const queryClient = new QueryClient();
const Loading = () => <div className="flex min-h-[50vh] items-center justify-center bg-background"><div className="text-center"><img src="/logo.png" alt="" className="mx-auto h-14 w-14 animate-pulse" /><p className="mt-3 text-sm font-semibold text-muted-foreground">Opening Taulbee Painting…</p></div></div>;

const App = () => <QueryClientProvider client={queryClient}><TooltipProvider><Toaster /><HostingBadgeHider /><HomeownerProvider><BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}><Suspense fallback={<Loading />}><Routes><Route path="/" element={<Index />} /><Route path="/support" element={<Support />} /><Route path="/privacy" element={<Privacy />} /><Route path="/terms" element={<Terms />} /><Route path="/tools" element={<ToolShell />}><Route index element={<ToolsDashboard />} /><Route path="visualize" element={<Visualizer />} /><Route path="scanner" element={<Scanner />} /><Route path="expert" element={<Expert />} /><Route path="vault" element={<Vault />} /><Route path="maintenance" element={<Maintenance />} /><Route path="activity" element={<Activity />} /><Route path="more" element={<MoreTools />} /></Route><Route path="*" element={<NotFound />} /></Routes></Suspense></BrowserRouter></HomeownerProvider></TooltipProvider></QueryClientProvider>;
export default App;
