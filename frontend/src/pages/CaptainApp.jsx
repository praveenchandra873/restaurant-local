import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { toast } from "sonner";
import { ArrowLeft, Plus, Minus, ShoppingCart, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const CaptainApp = () => {
  const navigate = useNavigate();
  const [menuItems, setMenuItems] = useState([]);
  const [tables, setTables] = useState([]);
  const [cart, setCart] = useState([]);
  const [selectedTable, setSelectedTable] = useState(null);
  const [notes, setNotes] = useState("");
  const [showCart, setShowCart] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchMenuItems();
    fetchTables();
  }, []);

  const fetchMenuItems = async () => {
    try {
      const response = await axios.get(`${API}/menu`);
      setMenuItems(response.data.filter(item => item.available));
    } catch (error) {
      console.error("Error fetching menu:", error);
      toast.error("Failed to load menu");
    }
  };

  const fetchTables = async () => {
    try {
      const response = await axios.get(`${API}/tables`);
      setTables(response.data);
    } catch (error) {
      console.error("Error fetching tables:", error);
    }
  };

  const addToCart = (item) => {
    const existingItem = cart.find(cartItem => cartItem.id === item.id);
    if (existingItem) {
      setCart(cart.map(cartItem => 
        cartItem.id === item.id 
          ? { ...cartItem, quantity: cartItem.quantity + 1 }
          : cartItem
      ));
    } else {
      setCart([...cart, { ...item, quantity: 1 }]);
    }
    toast.success(`${item.name} added to cart`);
  };

  const updateQuantity = (itemId, delta) => {
    setCart(cart.map(item => {
      if (item.id === itemId) {
        const newQuantity = item.quantity + delta;
        return newQuantity > 0 ? { ...item, quantity: newQuantity } : item;
      }
      return item;
    }).filter(item => item.quantity > 0));
  };

  const removeFromCart = (itemId) => {
    setCart(cart.filter(item => item.id !== itemId));
  };

  const placeOrder = async () => {
    if (!selectedTable) {
      toast.error("Please select a table");
      return;
    }
    if (cart.length === 0) {
      toast.error("Cart is empty");
      return;
    }

    setLoading(true);
    try {
      const table = tables.find(t => t.id === selectedTable);
      const orderItems = cart.map(item => ({
        menu_item_id: item.id,
        name: item.name,
        quantity: item.quantity,
        price: item.price
      }));

      await axios.post(`${API}/orders`, {
        table_id: selectedTable,
        table_number: table.table_number,
        items: orderItems,
        notes: notes
      });

      toast.success("Order placed successfully!");
      setCart([]);
      setSelectedTable(null);
      setNotes("");
      setShowCart(false);
      fetchTables();
    } catch (error) {
      console.error("Error placing order:", error);
      toast.error("Failed to place order");
    } finally {
      setLoading(false);
    }
  };

  const cartTotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <div className="min-h-screen pb-24 bg-[#F9F8F6]">
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
            Take Order
          </h1>
          <div className="w-16"></div>
        </div>
      </div>

      <div className="p-6">
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {menuItems.map((item) => (
            <div
              key={item.id}
              data-testid={`menu-item-${item.id}`}
              className="bg-white border border-[#E0DBD3] rounded-xl overflow-hidden shadow-[0_4px_12px_rgba(42,47,43,0.04)] hover:-translate-y-0.5 hover:shadow-[0_12px_32px_rgba(42,47,43,0.08)] transition-all duration-200"
            >
              <img
                src={item.image}
                alt={item.name}
                className="w-full h-40 object-cover"
              />
              <div className="p-4">
                <div className="mb-2">
                  <span className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                    {item.category}
                  </span>
                </div>
                <h3 className="text-lg font-semibold text-[#2A2F2B] mb-1">
                  {item.name}
                </h3>
                <p className="text-sm text-[#5A615C] mb-3 line-clamp-2">
                  {item.description}
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-lg font-semibold text-[#C25934]">
                    ₹{item.price.toFixed(2)}
                  </span>
                  <button
                    onClick={() => addToCart(item)}
                    data-testid={`add-to-cart-${item.id}`}
                    className="min-h-[48px] px-4 bg-[#C25934] text-white rounded-md hover:bg-[#A84C2B] transition-colors flex items-center gap-2"
                  >
                    <Plus className="w-4 h-4" />
                    <span className="text-sm font-semibold">Add</span>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {cartCount > 0 && (
        <div className="fixed bottom-0 left-0 right-0 backdrop-blur-xl bg-[#F9F8F6]/80 border-t border-[#E0DBD3] p-4">
          <button
            onClick={() => setShowCart(true)}
            data-testid="view-cart-btn"
            className="w-full min-h-[56px] bg-[#C25934] text-white rounded-md hover:bg-[#A84C2B] transition-colors flex items-center justify-between px-6 shadow-[0_12px_32px_rgba(42,47,43,0.08)]"
          >
            <div className="flex items-center gap-3">
              <ShoppingCart className="w-5 h-5" />
              <span className="font-semibold">{cartCount} Items</span>
            </div>
            <span className="font-semibold">₹{cartTotal.toFixed(2)}</span>
          </button>
        </div>
      )}

      <Dialog open={showCart} onOpenChange={setShowCart}>
        <DialogContent className="max-w-lg bg-white rounded-2xl" data-testid="cart-dialog">
          <DialogHeader>
            <DialogTitle className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">
              Order Cart
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4 max-h-[400px] overflow-y-auto">
            {cart.map((item) => (
              <div
                key={item.id}
                data-testid={`cart-item-${item.id}`}
                className="flex items-center gap-4 p-4 bg-[#F2EFE9] rounded-xl"
              >
                <img
                  src={item.image}
                  alt={item.name}
                  className="w-16 h-16 object-cover rounded-md"
                />
                <div className="flex-1">
                  <h4 className="font-semibold text-[#2A2F2B]">{item.name}</h4>
                  <p className="text-sm text-[#C25934] font-semibold">
                    ₹{item.price.toFixed(2)}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => updateQuantity(item.id, -1)}
                    data-testid={`decrease-qty-${item.id}`}
                    className="w-8 h-8 bg-white border border-[#E0DBD3] rounded-md flex items-center justify-center hover:bg-[#F2EFE9]"
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="w-8 text-center font-semibold" data-testid={`qty-${item.id}`}>
                    {item.quantity}
                  </span>
                  <button
                    onClick={() => updateQuantity(item.id, 1)}
                    data-testid={`increase-qty-${item.id}`}
                    className="w-8 h-8 bg-white border border-[#E0DBD3] rounded-md flex items-center justify-center hover:bg-[#F2EFE9]"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
                <button
                  onClick={() => removeFromCart(item.id)}
                  data-testid={`remove-item-${item.id}`}
                  className="text-[#B24040] hover:bg-[#FAEDED] rounded-md p-2"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            ))}
          </div>

          <div className="space-y-4 pt-4 border-t border-[#E0DBD3]">
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Select Table
              </label>
              <Select value={selectedTable} onValueChange={setSelectedTable}>
                <SelectTrigger data-testid="table-select" className="bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue placeholder="Choose a table" />
                </SelectTrigger>
                <SelectContent>
                  {tables.filter(t => t.status === "available").map((table) => (
                    <SelectItem key={table.id} value={table.id} data-testid={`table-option-${table.id}`}>
                      Table {table.table_number} (Capacity: {table.capacity})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Special Notes (Optional)
              </label>
              <Textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Any special requests..."
                data-testid="order-notes"
                className="bg-[#F2EFE9] border-[#E0DBD3] resize-none"
                rows={3}
              />
            </div>

            <div className="bg-[#F2EFE9] rounded-xl p-4">
              <div className="flex justify-between items-center">
                <span className="text-lg font-semibold text-[#2A2F2B]">Total</span>
                <span className="text-2xl font-semibold text-[#C25934]" data-testid="cart-total">
                  ₹{cartTotal.toFixed(2)}
                </span>
              </div>
            </div>

            <Button
              onClick={placeOrder}
              disabled={loading}
              data-testid="place-order-btn"
              className="w-full min-h-[56px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md text-base font-semibold"
            >
              {loading ? "Placing Order..." : "Place Order"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default CaptainApp;
