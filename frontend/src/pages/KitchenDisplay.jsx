import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { toast } from "sonner";
import { ArrowLeft, Clock, CheckCircle } from "lucide-react";
import { Button } from "@/components/ui/button";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const KitchenDisplay = () => {
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);

  useEffect(() => {
    fetchOrders();
    const interval = setInterval(fetchOrders, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchOrders = async () => {
    try {
      const response = await axios.get(`${API}/orders`);
      const activeOrders = response.data.filter(
        order => order.status === "pending" || order.status === "preparing"
      );
      setOrders(activeOrders);
    } catch (error) {
      console.error("Error fetching orders:", error);
    }
  };

  const getWaitTime = (createdAt) => {
    const now = new Date();
    const created = new Date(createdAt);
    const diffMinutes = Math.floor((now - created) / 60000);
    return diffMinutes;
  };

  const getStatusColor = (waitTime) => {
    if (waitTime < 10) return "bg-[#E9F0EC] border-[#4A6B56]";
    if (waitTime < 20) return "bg-[#FDF4E6] border-[#D99C3D]";
    return "bg-[#FAEDED] border-[#B24040]";
  };

  const updateOrderStatus = async (orderId, status) => {
    try {
      await axios.put(`${API}/orders/${orderId}`, { status });
      toast.success(`Order marked as ${status}`);
      fetchOrders();
    } catch (error) {
      console.error("Error updating order:", error);
      toast.error("Failed to update order");
    }
  };

  return (
    <div className="min-h-screen bg-[#F9F8F6]">
      <div className="sticky top-0 z-10 bg-white border-b border-[#E0DBD3] shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
        <div className="flex items-center justify-between p-4">
          <button
            onClick={() => navigate("/")}
            className="flex items-center gap-2 text-[#5A615C] hover:text-[#2A2F2B]"
            data-testid="back-btn"
          >
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm font-semibold">Back</span>
          </button>
          <h1 className="text-xl md:text-2xl font-medium text-[#2A2F2B] tracking-tight">
            Kitchen Display
          </h1>
          <div className="bg-[#C25934] text-white px-4 py-2 rounded-md text-sm font-semibold" data-testid="active-orders-count">
            {orders.length} Active
          </div>
        </div>
      </div>

      <div className="p-6">
        {orders.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20" data-testid="no-orders">
            <CheckCircle className="w-16 h-16 text-[#4A6B56] mb-4" />
            <p className="text-lg text-[#5A615C]">No pending orders</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4">
            {orders.map((order) => {
              const waitTime = getWaitTime(order.created_at);
              const statusColor = getStatusColor(waitTime);
              
              return (
                <div
                  key={order.id}
                  data-testid={`order-ticket-${order.id}`}
                  className={`${statusColor} border-2 rounded-xl p-4 h-full flex flex-col shadow-[0_4px_12px_rgba(42,47,43,0.04)] hover:-translate-y-0.5 hover:shadow-[0_12px_32px_rgba(42,47,43,0.08)] transition-all duration-200`}
                >
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-1">
                        Table
                      </div>
                      <div className="text-2xl font-semibold text-[#2A2F2B]" data-testid={`table-number-${order.id}`}>
                        {order.table_number}
                      </div>
                    </div>
                    <div className="flex items-center gap-1 text-[#5A615C]">
                      <Clock className="w-4 h-4" />
                      <span className="text-sm font-semibold" data-testid={`wait-time-${order.id}`}>
                        {waitTime}m
                      </span>
                    </div>
                  </div>

                  <div className="flex-1 mb-4">
                    <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-2">
                      Items
                    </div>
                    <div className="space-y-2">
                      {order.items.map((item, idx) => (
                        <div key={idx} className="flex justify-between text-sm" data-testid={`order-item-${order.id}-${idx}`}>
                          <span className="font-medium text-[#2A2F2B]">
                            {item.quantity}x {item.name}
                          </span>
                        </div>
                      ))}
                    </div>
                    {order.notes && (
                      <div className="mt-3 p-2 bg-white/50 rounded-md">
                        <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-1">
                          Notes
                        </div>
                        <p className="text-sm text-[#2A2F2B]" data-testid={`order-notes-${order.id}`}>
                          {order.notes}
                        </p>
                      </div>
                    )}
                  </div>

                  <div className="space-y-2">
                    {order.status === "pending" && (
                      <Button
                        onClick={() => updateOrderStatus(order.id, "preparing")}
                        data-testid={`start-preparing-${order.id}`}
                        className="w-full min-h-[48px] bg-[#D99C3D] hover:bg-[#C88A2E] text-white rounded-md font-semibold"
                      >
                        Start Preparing
                      </Button>
                    )}
                    {order.status === "preparing" && (
                      <Button
                        onClick={() => updateOrderStatus(order.id, "ready")}
                        data-testid={`mark-ready-${order.id}`}
                        className="w-full min-h-[48px] bg-[#4A6B56] hover:bg-[#3D5647] text-white rounded-md font-semibold"
                      >
                        Mark Ready
                      </Button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default KitchenDisplay;
