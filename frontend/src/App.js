import { BrowserRouter, Routes, Route } from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import MainPOS from "@/pages/MainPOS";
import KitchenDisplay from "@/pages/KitchenDisplay";
import AdminPanel from "@/pages/AdminPanel";
import OwnerPanel from "@/pages/OwnerPanel";

function App() {
  return (
    <div className="App">
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<MainPOS />} />
          <Route path="/kitchen" element={<KitchenDisplay />} />
          <Route path="/admin" element={<AdminPanel />} />
          <Route path="/owner" element={<OwnerPanel />} />
        </Routes>
      </BrowserRouter>
      <Toaster position="top-center" />
    </div>
  );
}

export default App;
