import { useState } from "react";
import axios from "axios";
import { toast } from "sonner";
import { Lock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import OwnerDashboard from "@/pages/OwnerDashboard";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const OwnerPanel = () => {
  const [authenticated, setAuthenticated] = useState(false);
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!password) return;

    setLoading(true);
    try {
      await axios.post(`${API}/owner/verify`, { password });
      setAuthenticated(true);
      toast.success("Access granted");
    } catch (error) {
      toast.error("Invalid password");
    } finally {
      setLoading(false);
    }
  };

  if (authenticated) {
    return <OwnerDashboard onLogout={() => setAuthenticated(false)} />;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#F9F8F6] p-6">
      <div className="w-full max-w-sm">
        <div className="bg-white border border-[#E0DBD3] rounded-xl p-8 shadow-[0_12px_32px_rgba(42,47,43,0.08)]">
          <div className="flex flex-col items-center mb-8">
            <div className="bg-[#2A2F2B] w-16 h-16 rounded-md flex items-center justify-center mb-4">
              <Lock className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">
              Owner Access
            </h1>
            <p className="text-sm text-[#5A615C] mt-2">
              Enter password to manage staff & salaries
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter owner password"
              data-testid="owner-password-input"
              className="bg-[#F2EFE9] border-[#E0DBD3] min-h-[48px] text-center text-lg"
              autoFocus
            />
            <Button
              type="submit"
              disabled={loading}
              data-testid="owner-login-btn"
              className="w-full min-h-[56px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md text-base font-semibold"
            >
              {loading ? "Verifying..." : "Unlock"}
            </Button>
          </form>

          <p className="text-xs text-[#5A615C] text-center mt-4">
            Default password: owner123
          </p>
        </div>
      </div>
    </div>
  );
};

export default OwnerPanel;
