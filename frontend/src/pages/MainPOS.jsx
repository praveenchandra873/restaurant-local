import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { toast } from "sonner";
import { Printer, Eye, Plus, Minus, X, ChefHat, Lock, Settings, RefreshCw, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const CATEGORIES = ["All", "Starter", "Maggi", "Sandwich", "Pasta", "Rice", "Chinese", "Mocktail", "Cold Coffee", "Combo"];

const MainPOS = () => {
  const navigate = useNavigate();
  const [tables, setTables] = useState([]);
  const [menuItems, setMenuItems] = useState([]);
  const [orders, setOrders] = useState([]);
  const [selectedTable, setSelectedTable] = useState(null);
  const [cart, setCart] = useState([]);
  const [activeCategory, setActiveCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [showBillDialog, setShowBillDialog] = useState(false);
  const [billOrder, setBillOrder] = useState(null);
  const [paymentMethod, setPaymentMethod] = useState("");
  const [loading, setLoading] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const [tablesRes, menuRes, ordersRes] = await Promise.all([
        axios.get(`${API}/tables`),
        axios.get(`${API}/menu`),
        axios.get(`${API}/orders`)
      ]);
      setTables(tablesRes.data);
      setMenuItems(menuRes.data.filter(i => i.available));
      setOrders(ordersRes.data);
    } catch (err) { console.error(err); }
  }, []);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 5000);
    return () => clearInterval(interval);
  }, [fetchData]);

  const getTableOrder = (tableId) => {
    return orders.find(o => o.table_id === tableId && ["pending", "preparing", "ready"].includes(o.status));
  };

  const getOrderTime = (createdAt) => {
    const mins = Math.floor((new Date() - new Date(createdAt)) / 60000);
    return mins;
  };

  const handleTableClick = (table) => {
    setSelectedTable(table);
    const existing = getTableOrder(table.id);
    if (existing) {
      setCart(existing.items.map(i => ({
        id: i.menu_item_id, name: i.name, price: i.price, quantity: i.quantity,
        image: menuItems.find(m => m.id === i.menu_item_id)?.image || ""
      })));
    } else {
      setCart([]);
    }
  };

  const addToCart = (item) => {
    const existing = cart.find(c => c.id === item.id);
    if (existing) {
      setCart(cart.map(c => c.id === item.id ? { ...c, quantity: c.quantity + 1 } : c));
    } else {
      setCart([...cart, { id: item.id, name: item.name, price: item.price, quantity: 1, image: item.image }]);
    }
  };

  const updateQty = (itemId, delta) => {
    setCart(cart.map(c => {
      if (c.id === itemId) {
        const newQty = c.quantity + delta;
        return newQty > 0 ? { ...c, quantity: newQty } : c;
      }
      return c;
    }).filter(c => c.quantity > 0));
  };

  const removeItem = (itemId) => setCart(cart.filter(c => c.id !== itemId));

  const cartTotal = cart.reduce((s, c) => s + c.price * c.quantity, 0);

  const placeOrder = async () => {
    if (!selectedTable || cart.length === 0) return;
    setLoading(true);
    try {
      await axios.post(`${API}/orders`, {
        table_id: selectedTable.id,
        table_number: selectedTable.table_number,
        items: cart.map(c => ({ menu_item_id: c.id, name: c.name, quantity: c.quantity, price: c.price })),
        notes: ""
      });
      toast.success("Order placed!");
      fetchData();
      setSelectedTable(null);
      setCart([]);
    } catch (err) { toast.error("Failed to place order"); }
    finally { setLoading(false); }
  };

  const handlePrintBill = (order) => {
    setBillOrder(order);
    setPaymentMethod("");
    setShowBillDialog(true);
  };

  const printReceipt = (order) => {
    const total = order.total_amount;
    const now = new Date().toLocaleString();

    const receiptHtml = `
      <html><head><title>Receipt - Table ${order.table_number}</title>
      <style>
        body { font-family: monospace; width: 250px; margin: 0 auto; padding: 10px; font-size: 16px; }
        h2 { text-align: center; margin: 0 0 5px; font-size: 22px; }
        p.center { text-align: center; margin: 4px 0; font-size: 14px; }
        hr { border: 1px dashed #000; margin: 8px 0; }
        .item { display: flex; justify-content: space-between; font-size: 16px; margin: 5px 0; }
        .total { display: flex; justify-content: space-between; font-weight: bold; font-size: 20px; margin: 6px 0; }
        .footer { text-align: center; font-size: 14px; margin-top: 12px; }
      </style></head><body>
      <h2>Dubeyji's</h2>
      <p class="center">Table: ${order.table_number}</p>
      <p class="center">${now}</p>
      <hr/>
      ${order.items.map(i => `<div class="item"><span>${i.quantity}x ${i.name}</span><span>₹${(i.price * i.quantity).toFixed(0)}</span></div>`).join('')}
      <hr/>
      <div class="total"><span>TOTAL</span><span>₹${total.toFixed(0)}</span></div>
      <hr/>
      <div class="footer">Thank you! Visit again.</div>
      </body></html>
    `;

    const printWindow = window.open('', '_blank', 'width=300,height=500');
    printWindow.document.write(receiptHtml);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
  };

  const generateBill = async () => {
    if (!billOrder) return;
    setLoading(true);
    try {
      const billRes = await axios.post(`${API}/bills`, { order_id: billOrder.id, payment_method: "Cash" });
      await axios.put(`${API}/bills/${billRes.data.id}`, { payment_status: "paid", payment_method: "Cash" });
      toast.success("Bill generated & paid!");
      setShowBillDialog(false);
      setBillOrder(null);
      fetchData();
    } catch (err) { toast.error("Failed to generate bill"); }
    finally { setLoading(false); }
  };

  const updateOrderStatus = async (orderId, status) => {
    try {
      await axios.put(`${API}/orders/${orderId}`, { status });
      toast.success(`Order marked ${status}`);
      fetchData();
    } catch (err) { toast.error("Failed"); }
  };

  const filteredMenu = menuItems.filter(i => {
    const matchCat = activeCategory === "All" || i.category === activeCategory;
    const matchSearch = !searchQuery || i.name.toLowerCase().includes(searchQuery.toLowerCase());
    return matchCat && matchSearch;
  });

  return (
    <div className="h-screen flex flex-col bg-[#F9F8F6] overflow-hidden">
      {/* ===== TOP BAR ===== */}
      <div className="bg-white border-b border-[#E0DBD3] px-4 py-3 flex items-center justify-between shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-medium text-[#2A2F2B] tracking-tight" data-testid="app-title">
            Dine Local Hub
          </h1>
          <button onClick={fetchData} className="p-2 text-[#5A615C] hover:bg-[#F2EFE9] rounded-md" data-testid="refresh-btn">
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => navigate("/kitchen")} data-testid="nav-kitchen"
            className="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-[#5A615C] hover:bg-[#F2EFE9] rounded-md transition-colors">
            <ChefHat className="w-4 h-4" /> Kitchen
          </button>
          <button onClick={() => navigate("/admin")} data-testid="nav-admin"
            className="flex items-center gap-2 px-4 py-2 text-sm font-semibold text-[#5A615C] hover:bg-[#F2EFE9] rounded-md transition-colors">
            <Settings className="w-4 h-4" /> Admin
          </button>
          <button onClick={() => navigate("/owner")} data-testid="nav-owner"
            className="flex items-center gap-2 px-4 py-2 text-sm font-semibold bg-[#2A2F2B] text-white rounded-md hover:bg-[#3a3f3b] transition-colors">
            <Lock className="w-4 h-4" /> Owner
          </button>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* ===== LEFT: TABLE GRID ===== */}
        <div className="flex-1 p-6 overflow-y-auto">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-[#2A2F2B]" data-testid="table-view-title">Table View</h2>
            <div className="flex items-center gap-4 text-xs">
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-sm bg-[#E8E5E0]"></div>
                <span className="text-[#5A615C]">Available</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-sm bg-[#FDE68A]"></div>
                <span className="text-[#5A615C]">Occupied</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-sm bg-[#BBF7D0]"></div>
                <span className="text-[#5A615C]">Ready</span>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 xl:grid-cols-8 gap-3" data-testid="table-grid">
            {tables.map(table => {
              const order = getTableOrder(table.id);
              const isSelected = selectedTable?.id === table.id;
              const isReady = order?.status === "ready";

              let bgColor = "bg-[#E8E5E0]";
              let borderColor = "border-transparent";
              if (order && isReady) { bgColor = "bg-[#BBF7D0]"; }
              else if (order) { bgColor = "bg-[#FDE68A]"; }
              if (isSelected) { borderColor = "border-[#C25934]"; }

              return (
                <div
                  key={table.id}
                  data-testid={`table-${table.table_number}`}
                  onClick={() => handleTableClick(table)}
                  className={`${bgColor} border-2 ${borderColor} rounded-xl p-3 cursor-pointer hover:shadow-md transition-all min-h-[100px] flex flex-col justify-between`}
                >
                  <div className="text-center">
                    <div className="text-lg font-bold text-[#2A2F2B]">{table.table_number}</div>
                  </div>

                  {order ? (
                    <div className="text-center mt-1">
                      <div className="text-xs font-semibold text-[#5A615C]">{getOrderTime(order.created_at)} Min</div>
                      <div className="text-sm font-bold text-[#2A2F2B]">₹{order.total_amount.toFixed(0)}</div>
                      <div className="flex justify-center gap-1 mt-1">
                        <button onClick={(e) => { e.stopPropagation(); printReceipt(order); }}
                          data-testid={`print-bill-${table.table_number}`}
                          className="p-1 bg-white/70 rounded hover:bg-white transition-colors" title="Print Receipt">
                          <Printer className="w-3.5 h-3.5 text-[#5A615C]" />
                        </button>
                        <button onClick={(e) => { e.stopPropagation(); handleTableClick(table); }}
                          data-testid={`view-order-${table.table_number}`}
                          className="p-1 bg-white/70 rounded hover:bg-white transition-colors" title="View Order">
                          <Eye className="w-3.5 h-3.5 text-[#5A615C]" />
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="text-center mt-1">
                      <div className="text-xs text-[#999] font-medium">Cap: {table.capacity}</div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* ===== KITCHEN ORDERS (inline) ===== */}
          <div className="mt-8">
            <h2 className="text-lg font-semibold text-[#2A2F2B] mb-4" data-testid="kitchen-section-title">Kitchen Orders</h2>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
              {orders.filter(o => ["pending", "preparing"].includes(o.status)).map(order => (
                <div key={order.id} data-testid={`kitchen-order-${order.id}`}
                  className={`rounded-xl p-4 border ${order.status === "pending" ? "bg-[#FDF4E6] border-[#D99C3D]" : "bg-[#E9F0EC] border-[#4A6B56]"}`}>
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <span className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Table</span>
                      <div className="text-xl font-bold text-[#2A2F2B]">{order.table_number}</div>
                    </div>
                    <span className={`text-xs font-semibold px-2 py-1 rounded ${order.status === "pending" ? "bg-[#D99C3D] text-white" : "bg-[#4A6B56] text-white"}`}>
                      {order.status}
                    </span>
                  </div>
                  <div className="space-y-1 mb-3">
                    {order.items.map((item, idx) => (
                      <div key={idx} className="text-sm text-[#2A2F2B]">{item.quantity}x {item.name}</div>
                    ))}
                  </div>
                  {order.status === "pending" && (
                    <Button onClick={() => updateOrderStatus(order.id, "preparing")} data-testid={`start-prep-${order.id}`}
                      className="w-full bg-[#D99C3D] hover:bg-[#c88a2e] text-white text-sm py-1">
                      Start Preparing
                    </Button>
                  )}
                  {order.status === "preparing" && (
                    <Button onClick={() => updateOrderStatus(order.id, "ready")} data-testid={`mark-ready-${order.id}`}
                      className="w-full bg-[#4A6B56] hover:bg-[#3d5647] text-white text-sm py-1">
                      Mark Ready
                    </Button>
                  )}
                </div>
              ))}
              {orders.filter(o => ["pending", "preparing"].includes(o.status)).length === 0 && (
                <div className="col-span-full text-center py-8 text-[#5A615C]" data-testid="no-kitchen-orders">
                  No active kitchen orders
                </div>
              )}
            </div>
          </div>
        </div>

        {/* ===== RIGHT: ORDER PANEL ===== */}
        {selectedTable && (
          <div className="w-[420px] bg-white border-l border-[#E0DBD3] flex flex-col shadow-[-4px_0_12px_rgba(42,47,43,0.04)]" data-testid="order-panel">
            {/* Panel Header */}
            <div className="p-4 border-b border-[#E0DBD3] flex items-center justify-between">
              <div>
                <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">Table</div>
                <div className="text-2xl font-bold text-[#2A2F2B]">{selectedTable.table_number}</div>
              </div>
              <button onClick={() => { setSelectedTable(null); setCart([]); }}
                data-testid="close-panel" className="p-2 hover:bg-[#F2EFE9] rounded-md">
                <X className="w-5 h-5 text-[#5A615C]" />
              </button>
            </div>

            {/* Current Order Items */}
            <div className="flex-shrink-0 max-h-[200px] overflow-y-auto border-b border-[#E0DBD3]">
              {cart.length === 0 ? (
                <div className="p-4 text-center text-sm text-[#5A615C]">No items yet. Add from menu below.</div>
              ) : (
                <div className="p-3 space-y-2">
                  {cart.map(item => (
                    <div key={item.id} className="flex items-center justify-between bg-[#F2EFE9] rounded-lg p-2" data-testid={`cart-item-${item.id}`}>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm font-semibold text-[#2A2F2B] truncate">{item.name}</div>
                        <div className="text-xs text-[#C25934] font-semibold">₹{item.price}</div>
                      </div>
                      <div className="flex items-center gap-1 ml-2">
                        <button onClick={() => updateQty(item.id, -1)} data-testid={`dec-${item.id}`}
                          className="w-6 h-6 bg-white rounded flex items-center justify-center border border-[#E0DBD3] hover:bg-[#F2EFE9]">
                          <Minus className="w-3 h-3" />
                        </button>
                        <span className="w-6 text-center text-sm font-bold">{item.quantity}</span>
                        <button onClick={() => updateQty(item.id, 1)} data-testid={`inc-${item.id}`}
                          className="w-6 h-6 bg-white rounded flex items-center justify-center border border-[#E0DBD3] hover:bg-[#F2EFE9]">
                          <Plus className="w-3 h-3" />
                        </button>
                        <button onClick={() => removeItem(item.id)} data-testid={`rm-${item.id}`}
                          className="w-6 h-6 text-[#B24040] hover:bg-[#FAEDED] rounded flex items-center justify-center ml-1">
                          <X className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  ))}
                  <div className="flex justify-between items-center pt-2 px-1">
                    <span className="text-sm font-semibold text-[#5A615C]">Total</span>
                    <span className="text-lg font-bold text-[#C25934]" data-testid="order-total">₹{cartTotal.toFixed(2)}</span>
                  </div>
                </div>
              )}
            </div>

            {/* Menu Browser */}
            <div className="flex-1 overflow-hidden flex flex-col">
              <div className="p-3 border-b border-[#E0DBD3]">
                <div className="relative mb-2">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#5A615C]" />
                  <Input value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search menu..." data-testid="menu-search"
                    className="pl-9 bg-[#F2EFE9] border-[#E0DBD3] h-9 text-sm" />
                </div>
                <div className="flex gap-1 overflow-x-auto pb-1">
                  {CATEGORIES.map(cat => (
                    <button key={cat} onClick={() => setActiveCategory(cat)} data-testid={`cat-${cat}`}
                      className={`px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap transition-colors ${
                        activeCategory === cat
                          ? "bg-[#C25934] text-white"
                          : "bg-[#F2EFE9] text-[#5A615C] hover:bg-[#E0DBD3]"
                      }`}>
                      {cat}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex-1 overflow-y-auto p-3 space-y-2">
                {filteredMenu.map(item => (
                  <div key={item.id} data-testid={`menu-${item.id}`}
                    className="flex items-center gap-3 p-2 rounded-lg hover:bg-[#F2EFE9] transition-colors cursor-pointer"
                    onClick={() => addToCart(item)}>
                    <img src={item.image} alt={item.name} className="w-10 h-10 rounded-md object-cover flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <div className="text-sm font-semibold text-[#2A2F2B] truncate">{item.name}</div>
                      <div className="text-xs text-[#5A615C]">{item.category}</div>
                    </div>
                    <div className="text-sm font-bold text-[#C25934] flex-shrink-0">₹{item.price}</div>
                    <button className="w-7 h-7 bg-[#C25934] text-white rounded-md flex items-center justify-center hover:bg-[#A84C2B] flex-shrink-0"
                      data-testid={`add-${item.id}`}>
                      <Plus className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Place Order / Bill Buttons */}
            {cart.length > 0 && (
              <div className="p-3 border-t border-[#E0DBD3] space-y-2">
                <Button onClick={placeOrder} disabled={loading} data-testid="place-order-btn"
                  className="w-full min-h-[48px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md font-semibold text-base">
                  {loading ? "Placing..." : `Place Order - ₹${cartTotal.toFixed(2)}`}
                </Button>
                {getTableOrder(selectedTable.id) && (
                  <div className="flex gap-2">
                    <Button onClick={() => printReceipt(getTableOrder(selectedTable.id))} data-testid="panel-print-btn"
                      className="flex-1 min-h-[40px] bg-[#2A2F2B] hover:bg-[#3a3f3b] text-white rounded-md font-semibold text-sm">
                      <Printer className="w-4 h-4 mr-1" /> Print
                    </Button>
                    <Button onClick={() => handlePrintBill(getTableOrder(selectedTable.id))} data-testid="panel-bill-btn"
                      className="flex-1 min-h-[40px] bg-[#4A6B56] hover:bg-[#3d5647] text-white rounded-md font-semibold text-sm">
                      Bill & Pay
                    </Button>
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>

      {/* ===== BILL DIALOG ===== */}
      <Dialog open={showBillDialog} onOpenChange={setShowBillDialog}>
        <DialogContent className="max-w-md bg-white rounded-2xl" data-testid="bill-dialog">
          <DialogHeader>
            <DialogTitle className="text-2xl tracking-tight font-medium text-[#2A2F2B]">Generate Bill</DialogTitle>
          </DialogHeader>
          {billOrder && (
            <div className="space-y-4">
              <div className="bg-[#F2EFE9] rounded-xl p-4">
                <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-2">
                  Table {billOrder.table_number}
                </div>
                <div className="space-y-1 mb-3">
                  {billOrder.items.map((item, idx) => (
                    <div key={idx} className="flex justify-between text-sm">
                      <span className="text-[#2A2F2B]">{item.quantity}x {item.name}</span>
                      <span className="font-semibold text-[#2A2F2B]">₹{(item.price * item.quantity).toFixed(2)}</span>
                    </div>
                  ))}
                </div>
                <div className="border-t border-[#E0DBD3] pt-2 space-y-1">
                  <div className="flex justify-between text-sm">
                    <span className="text-[#5A615C]">Subtotal</span>
                    <span className="font-semibold">₹{billOrder.total_amount.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-[#5A615C]">Tax 18%</span>
                    <span className="font-semibold">₹{(billOrder.total_amount * 0.18).toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between pt-1 border-t border-[#E0DBD3]">
                    <span className="font-semibold">Total</span>
                    <span className="text-xl font-bold text-[#C25934]">₹{(billOrder.total_amount * 1.18).toFixed(2)}</span>
                  </div>
                </div>
              </div>
              <Button onClick={generateBill} disabled={loading} data-testid="confirm-bill-btn"
                className="w-full min-h-[48px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md font-semibold">
                {loading ? "Processing..." : "Generate Bill & Mark Paid"}
              </Button>
              <Button onClick={() => printReceipt(billOrder)} data-testid="print-receipt-btn"
                className="w-full min-h-[48px] bg-[#2A2F2B] hover:bg-[#3a3f3b] text-white rounded-md font-semibold">
                <Printer className="w-4 h-4 mr-2" /> Print Receipt
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default MainPOS;
