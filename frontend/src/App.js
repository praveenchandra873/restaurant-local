import { BrowserRouter, Routes, Route } from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import Home from "@/pages/Home";
import CaptainApp from "@/pages/CaptainApp";
import KitchenDisplay from "@/pages/KitchenDisplay";
import BillingDashboard from "@/pages/BillingDashboard";
import AdminPanel from "@/pages/AdminPanel";
import OwnerPanel from "@/pages/OwnerPanel";

function App() {
  return (
    <div className="App">
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/captain" element={<CaptainApp />} />
          <Route path="/kitchen" element={<KitchenDisplay />} />
          <Route path="/billing" element={<BillingDashboard />} />
          <Route path="/admin" element={<AdminPanel />} />
          <Route path="/owner" element={<OwnerPanel />} />
        </Routes>
      </BrowserRouter>
      <Toaster position="top-center" />
    </div>
  );
}

export default App;
