import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Routes, Route, useNavigate } from "react-router-dom";
import { OfflineIndicator } from "./components/OfflineIndicator";
import AppRoutes from "./routes/routes";
import { RouteErrorBoundary } from "./components/RouteErrorBoundary";
import ScrollToTop from "./utils/ScollToTop";
import { TooltipProvider } from "./components/ui/tooltip";
import { addResponseInterceptor } from "./services/config";

const App: React.FC = () => {
  const navigate = useNavigate();
  addResponseInterceptor(navigate);
  return (
    <>
      <Toaster />
      <Sonner position="bottom-right" />
      <OfflineIndicator />
      <ScrollToTop />

      <RouteErrorBoundary>
        <TooltipProvider>
          <Routes>
            <Route path="/*" element={<AppRoutes />} />
          </Routes>
        </TooltipProvider>
      </RouteErrorBoundary>
    </>
  );
};

export default App;
