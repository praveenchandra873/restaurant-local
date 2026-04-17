import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { toast } from "sonner";
import { ArrowLeft, Receipt, CheckCircle, Clock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const BillingDashboard = () => {
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [bills, setBills] = useState([]);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [showBillDialog, setShowBillDialog] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchOrders();
    fetchBills();
    const interval = setInterval(() => {
      fetchOrders();
      fetchBills();
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchOrders = async () => {
    try {
      const response = await axios.get(`${API}/orders`);
      setOrders(response.data);
    } catch (error) {
      console.error("Error fetching orders:", error);
    }
  };

  const fetchBills = async () => {
    try {
      const response = await axios.get(`${API}/bills`);
      setBills(response.data);
    } catch (error) {
      console.error("Error fetching bills:", error);
    }
  };

  const generateBill = async () => {
    if (!paymentMethod) {
      toast.error("Please select payment method");
      return;
    }

    setLoading(true);
    try {
      await axios.post(`${API}/bills`, {
        order_id: selectedOrder.id,
        payment_method: paymentMethod
      });
      toast.success("Bill generated successfully!");
      setShowBillDialog(false);
      setSelectedOrder(null);
      setPaymentMethod("");
      fetchOrders();
      fetchBills();
    } catch (error) {
      console.error("Error generating bill:", error);
      toast.error("Failed to generate bill");
    } finally {
      setLoading(false);
    }
  };

  const markAsPaid = async (billId, method) => {
    try {
      await axios.put(`${API}/bills/${billId}`, {
        payment_status: "paid",
        payment_method: method
      });
      toast.success("Bill marked as paid!");
      fetchBills();
      fetchOrders();
    } catch (error) {
      console.error("Error updating bill:", error);
      toast.error("Failed to update bill");
    }
  };

  const readyOrders = orders.filter(o => o.status === "ready");
  const pendingBills = bills.filter(b => b.payment_status === "pending");
  const paidBills = bills.filter(b => b.payment_status === "paid");

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
            Billing Counter
          </h1>
          <div className="w-16"></div>
        </div>
      </div>

      <div className="p-6">
        <Tabs defaultValue="ready" className="w-full">
          <TabsList className="grid w-full max-w-md grid-cols-3 mb-6" data-testid="billing-tabs">
            <TabsTrigger value="ready" data-testid="ready-tab">
              Ready ({readyOrders.length})
            </TabsTrigger>
            <TabsTrigger value="pending" data-testid="pending-tab">
              Pending ({pendingBills.length})
            </TabsTrigger>
            <TabsTrigger value="paid" data-testid="paid-tab">
              Paid ({paidBills.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="ready" data-testid="ready-orders-section">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {readyOrders.length === 0 ? (
                <div className="col-span-full flex flex-col items-center justify-center py-20" data-testid="no-ready-orders">
                  <Clock className="w-16 h-16 text-[#5A615C] mb-4" />
                  <p className="text-lg text-[#5A615C]">No orders ready for billing</p>
                </div>
              ) : (
                readyOrders.map((order) => (
                  <div
                    key={order.id}
                    data-testid={`ready-order-${order.id}`}
                    className="bg-white border border-[#E0DBD3] rounded-xl p-6 shadow-[0_4px_12px_rgba(42,47,43,0.04)]"
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div>
                        <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-1">
                          Table
                        </div>
                        <div className="text-2xl font-semibold text-[#2A2F2B]" data-testid={`order-table-${order.id}`}>
                          {order.table_number}
                        </div>
                      </div>
                      <div className="bg-[#E9F0EC] text-[#4A6B56] px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-[0.15em]">
                        Ready
                      </div>
                    </div>

                    <div className="mb-4">
                      <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-2">
                        Items
                      </div>
                      <div className="space-y-2">
                        {order.items.map((item, idx) => (
                          <div key={idx} className="flex justify-between text-sm">
                            <span className="text-[#2A2F2B]">
                              {item.quantity}x {item.name}
                            </span>
                            <span className="font-semibold text-[#2A2F2B]">
                              ₹{(item.price * item.quantity).toFixed(2)}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className="border-t border-[#E0DBD3] pt-4 mb-4">
                      <div className="flex justify-between items-center">
                        <span className="text-sm font-semibold text-[#5A615C]">Total</span>
                        <span className="text-xl font-semibold text-[#C25934]" data-testid={`order-total-${order.id}`}>
                          ₹{order.total_amount.toFixed(2)}
                        </span>
                      </div>
                    </div>

                    <Button
                      onClick={() => {
                        setSelectedOrder(order);
                        setShowBillDialog(true);
                      }}
                      data-testid={`generate-bill-${order.id}`}
                      className="w-full min-h-[48px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md font-semibold"
                    >
                      <Receipt className="w-4 h-4 mr-2" />
                      Generate Bill
                    </Button>
                  </div>
                ))
              )}
            </div>
          </TabsContent>

          <TabsContent value="pending" data-testid="pending-bills-section">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {pendingBills.length === 0 ? (
                <div className="col-span-full flex flex-col items-center justify-center py-20" data-testid="no-pending-bills">
                  <CheckCircle className="w-16 h-16 text-[#4A6B56] mb-4" />
                  <p className="text-lg text-[#5A615C]">No pending bills</p>
                </div>
              ) : (
                pendingBills.map((bill) => (
                  <div
                    key={bill.id}
                    data-testid={`pending-bill-${bill.id}`}
                    className="bg-white border border-[#E0DBD3] rounded-xl p-6 shadow-[0_4px_12px_rgba(42,47,43,0.04)]"
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div>
                        <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-1">
                          Table
                        </div>
                        <div className="text-2xl font-semibold text-[#2A2F2B]">
                          {bill.table_number}
                        </div>
                      </div>
                      <div className="bg-[#FDF4E6] text-[#D99C3D] px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-[0.15em]">
                        Pending
                      </div>
                    </div>

                    <div className="mb-4 space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-[#5A615C]">Subtotal</span>
                        <span className="font-semibold text-[#2A2F2B]">₹{bill.subtotal.toFixed(2)}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-[#5A615C]">Tax (18%)</span>
                        <span className="font-semibold text-[#2A2F2B]">₹{bill.tax.toFixed(2)}</span>
                      </div>
                      <div className="border-t border-[#E0DBD3] pt-2 flex justify-between items-center">
                        <span className="text-sm font-semibold text-[#5A615C]">Total</span>
                        <span className="text-xl font-semibold text-[#C25934]" data-testid={`bill-total-${bill.id}`}>
                          ₹{bill.total.toFixed(2)}
                        </span>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Button
                        onClick={() => markAsPaid(bill.id, "Cash")}
                        data-testid={`mark-paid-cash-${bill.id}`}
                        className="w-full min-h-[48px] bg-[#4A6B56] hover:bg-[#3D5647] text-white rounded-md font-semibold"
                      >
                        Mark as Paid (Cash)
                      </Button>
                      <Button
                        onClick={() => markAsPaid(bill.id, "Card")}
                        data-testid={`mark-paid-card-${bill.id}`}
                        className="w-full min-h-[48px] bg-[#4A6B56] hover:bg-[#3D5647] text-white rounded-md font-semibold"
                      >
                        Mark as Paid (Card)
                      </Button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </TabsContent>

          <TabsContent value="paid" data-testid="paid-bills-section">
            <div className="bg-white border border-[#E0DBD3] rounded-xl overflow-hidden shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-[#F2EFE9]">
                    <tr>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Table
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Total
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Payment Method
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Date
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {paidBills.length === 0 ? (
                      <tr>
                        <td colSpan="5" className="text-center py-12" data-testid="no-paid-bills">
                          <p className="text-[#5A615C]">No paid bills yet</p>
                        </td>
                      </tr>
                    ) : (
                      paidBills.map((bill) => (
                        <tr key={bill.id} className="border-t border-[#E0DBD3]" data-testid={`paid-bill-${bill.id}`}>
                          <td className="p-4 font-semibold text-[#2A2F2B]">
                            {bill.table_number}
                          </td>
                          <td className="p-4 font-semibold text-[#C25934]">
                            ₹{bill.total.toFixed(2)}
                          </td>
                          <td className="p-4 text-[#5A615C]">
                            {bill.payment_method}
                          </td>
                          <td className="p-4 text-[#5A615C]">
                            {new Date(bill.created_at).toLocaleDateString()}
                          </td>
                          <td className="p-4">
                            <span className="bg-[#E9F0EC] text-[#4A6B56] px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-[0.15em]">
                              Paid
                            </span>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </div>

      <Dialog open={showBillDialog} onOpenChange={setShowBillDialog}>
        <DialogContent className="max-w-md bg-white rounded-2xl" data-testid="generate-bill-dialog">
          <DialogHeader>
            <DialogTitle className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">
              Generate Bill
            </DialogTitle>
          </DialogHeader>

          {selectedOrder && (
            <div className="space-y-4">
              <div className="bg-[#F2EFE9] rounded-xl p-4">
                <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-2">
                  Table {selectedOrder.table_number}
                </div>
                <div className="space-y-2 mb-4">
                  {selectedOrder.items.map((item, idx) => (
                    <div key={idx} className="flex justify-between text-sm">
                      <span className="text-[#2A2F2B]">
                        {item.quantity}x {item.name}
                      </span>
                      <span className="font-semibold text-[#2A2F2B]">
                        ₹{(item.price * item.quantity).toFixed(2)}
                      </span>
                    </div>
                  ))}
                </div>
                <div className="border-t border-[#E0DBD3] pt-3 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-[#5A615C]">Subtotal</span>
                    <span className="font-semibold text-[#2A2F2B]">₹{selectedOrder.total_amount.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-[#5A615C]">Tax (18%)</span>
                    <span className="font-semibold text-[#2A2F2B]">₹{(selectedOrder.total_amount * 0.18).toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between items-center pt-2 border-t border-[#E0DBD3]">
                    <span className="text-lg font-semibold text-[#2A2F2B]">Total</span>
                    <span className="text-2xl font-semibold text-[#C25934]">
                      ₹{(selectedOrder.total_amount * 1.18).toFixed(2)}
                    </span>
                  </div>
                </div>
              </div>

              <div>
                <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                  Payment Method
                </label>
                <Select value={paymentMethod} onValueChange={setPaymentMethod}>
                  <SelectTrigger data-testid="payment-method-select" className="bg-[#F2EFE9] border-[#E0DBD3]">
                    <SelectValue placeholder="Select payment method" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Cash" data-testid="payment-cash">Cash</SelectItem>
                    <SelectItem value="Card" data-testid="payment-card">Card</SelectItem>
                    <SelectItem value="UPI" data-testid="payment-upi">UPI</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <Button
                onClick={generateBill}
                disabled={loading}
                data-testid="confirm-generate-bill-btn"
                className="w-full min-h-[56px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md text-base font-semibold"
              >
                {loading ? "Generating..." : "Generate Bill"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default BillingDashboard;
