import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import HostingBadgeHider from "@/components/HostingBadgeHider";
import ToolShell from "@/components/ToolShell";
import { HomeownerProvider } from "@/hooks/useHomeowner";

import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";

import Index from "./pages/Index";
import Support from "./pages/Support";
import Privacy from "./pages/Privacy";
import Terms from "./pages/Terms";
import NotFound from "./pages/NotFound";
import ToolsDashboard from "./pages/ToolsDashboard";
import Visualizer from "./pages/Visualizer";
import Scanner from "./pages/Scanner";
import Expert from "./pages/Expert";
import Vault from "./pages/Vault";
import Maintenance from "./pages/Maintenance";
import Activity from "./pages/Activity";
import MoreTools from "./pages/MoreTools";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <HostingBadgeHider />
      <HomeownerProvider>
        <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/support" element={<Support />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/terms" element={<Terms />} />
            <Route path="/tools" element={<ToolShell />}>
              <Route index element={<ToolsDashboard />} />
              <Route path="visualize" element={<Visualizer />} />
              <Route path="scanner" element={<Scanner />} />
              <Route path="expert" element={<Expert />} />
              <Route path="vault" element={<Vault />} />
              <Route path="maintenance" element={<Maintenance />} />
              <Route path="activity" element={<Activity />} />
              <Route path="more" element={<MoreTools />} />
            </Route>
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </HomeownerProvider>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
