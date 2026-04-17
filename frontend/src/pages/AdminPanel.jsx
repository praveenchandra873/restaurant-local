import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { toast } from "sonner";
import { ArrowLeft, Plus, Pencil, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Switch } from "@/components/ui/switch";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const AdminPanel = () => {
  const navigate = useNavigate();
  const [tables, setTables] = useState([]);
  const [menuItems, setMenuItems] = useState([]);
  const [showTableDialog, setShowTableDialog] = useState(false);
  const [showMenuDialog, setShowMenuDialog] = useState(false);
  const [editingTable, setEditingTable] = useState(null);
  const [editingMenuItem, setEditingMenuItem] = useState(null);

  const [tableForm, setTableForm] = useState({
    table_number: "",
    capacity: 4
  });

  const [menuForm, setMenuForm] = useState({
    name: "",
    description: "",
    category: "",
    price: 0,
    image: "",
    available: true
  });

  const sampleImages = [
    "https://images.unsplash.com/photo-1762922425232-ab2b6b251739?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwxfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
    "https://images.unsplash.com/photo-1761315600943-d8a5bb0c499f?crop=entropy&cs=srgb&fm=jpg&ixid=M3w3NDk1NzZ8MHwxfHNlYXJjaHwyfHxnb3VybWV0JTIwZm9vZCUyMHBsYXRlJTIwdG9wJTIwdmlld3xlbnwwfHx8fDE3NzY0MDMxMDh8MA&ixlib=rb-4.1.0&q=85",
    "https://images.pexels.com/photos/5865234/pexels-photo-5865234.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
    "https://images.unsplash.com/photo-1712727537456-3fc29b381ba3?crop=entropy&cs=srgb&fm=jpg&ixid=M3w4NjAxODF8MHwxfHNlYXJjaHwyfHxyZXN0YXVyYW50JTIwaW50ZXJpb3IlMjBibHVyfGVufDB8fHx8MTc3NjQwMzEwOHww&ixlib=rb-4.1.0&q=85"
  ];

  useEffect(() => {
    fetchTables();
    fetchMenuItems();
  }, []);

  const fetchTables = async () => {
    try {
      const response = await axios.get(`${API}/tables`);
      setTables(response.data);
    } catch (error) {
      console.error("Error fetching tables:", error);
      toast.error("Failed to load tables");
    }
  };

  const fetchMenuItems = async () => {
    try {
      const response = await axios.get(`${API}/menu`);
      setMenuItems(response.data);
    } catch (error) {
      console.error("Error fetching menu:", error);
      toast.error("Failed to load menu");
    }
  };

  const handleCreateTable = async () => {
    if (!tableForm.table_number) {
      toast.error("Please enter table number");
      return;
    }

    try {
      await axios.post(`${API}/tables`, tableForm);
      toast.success("Table created successfully!");
      setShowTableDialog(false);
      setTableForm({ table_number: "", capacity: 4 });
      fetchTables();
    } catch (error) {
      console.error("Error creating table:", error);
      toast.error("Failed to create table");
    }
  };

  const handleCreateMenuItem = async () => {
    if (!menuForm.name || !menuForm.category || !menuForm.price) {
      toast.error("Please fill all required fields");
      return;
    }

    try {
      if (editingMenuItem) {
        await axios.put(`${API}/menu/${editingMenuItem.id}`, menuForm);
        toast.success("Menu item updated successfully!");
      } else {
        await axios.post(`${API}/menu`, menuForm);
        toast.success("Menu item created successfully!");
      }
      setShowMenuDialog(false);
      setMenuForm({
        name: "",
        description: "",
        category: "",
        price: 0,
        image: "",
        available: true
      });
      setEditingMenuItem(null);
      fetchMenuItems();
    } catch (error) {
      console.error("Error saving menu item:", error);
      toast.error("Failed to save menu item");
    }
  };

  const handleDeleteMenuItem = async (itemId) => {
    if (!window.confirm("Are you sure you want to delete this item?")) return;

    try {
      await axios.delete(`${API}/menu/${itemId}`);
      toast.success("Menu item deleted successfully!");
      fetchMenuItems();
    } catch (error) {
      console.error("Error deleting menu item:", error);
      toast.error("Failed to delete menu item");
    }
  };

  const openEditMenuItem = (item) => {
    setEditingMenuItem(item);
    setMenuForm({
      name: item.name,
      description: item.description,
      category: item.category,
      price: item.price,
      image: item.image,
      available: item.available
    });
    setShowMenuDialog(true);
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
            Admin Panel
          </h1>
          <div className="w-16"></div>
        </div>
      </div>

      <div className="p-6">
        <Tabs defaultValue="menu" className="w-full">
          <TabsList className="grid w-full max-w-md grid-cols-2 mb-6" data-testid="admin-tabs">
            <TabsTrigger value="menu" data-testid="menu-tab">Menu Items</TabsTrigger>
            <TabsTrigger value="tables" data-testid="tables-tab">Tables</TabsTrigger>
          </TabsList>

          <TabsContent value="menu" data-testid="menu-section">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">
                Menu Management
              </h2>
              <Button
                onClick={() => {
                  setEditingMenuItem(null);
                  setMenuForm({
                    name: "",
                    description: "",
                    category: "",
                    price: 0,
                    image: sampleImages[0],
                    available: true
                  });
                  setShowMenuDialog(true);
                }}
                data-testid="add-menu-item-btn"
                className="min-h-[48px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md font-semibold"
              >
                <Plus className="w-4 h-4 mr-2" />
                Add Menu Item
              </Button>
            </div>

            <div className="bg-white border border-[#E0DBD3] rounded-xl overflow-hidden shadow-[0_4px_12px_rgba(42,47,43,0.04)]">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-[#F2EFE9]">
                    <tr>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Image
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Name
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Category
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Price
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Status
                      </th>
                      <th className="text-left p-4 text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C]">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {menuItems.map((item) => (
                      <tr key={item.id} className="border-t border-[#E0DBD3]" data-testid={`menu-item-row-${item.id}`}>
                        <td className="p-4">
                          <img
                            src={item.image}
                            alt={item.name}
                            className="w-16 h-16 object-cover rounded-md"
                          />
                        </td>
                        <td className="p-4 font-semibold text-[#2A2F2B]">
                          {item.name}
                        </td>
                        <td className="p-4 text-[#5A615C]">
                          {item.category}
                        </td>
                        <td className="p-4 font-semibold text-[#C25934]">
                          ₹{item.price.toFixed(2)}
                        </td>
                        <td className="p-4">
                          <span
                            className={`px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-[0.15em] ${
                              item.available
                                ? "bg-[#E9F0EC] text-[#4A6B56]"
                                : "bg-[#FAEDED] text-[#B24040]"
                            }`}
                          >
                            {item.available ? "Available" : "Unavailable"}
                          </span>
                        </td>
                        <td className="p-4">
                          <div className="flex gap-2">
                            <button
                              onClick={() => openEditMenuItem(item)}
                              data-testid={`edit-menu-${item.id}`}
                              className="p-2 text-[#5A615C] hover:bg-[#F2EFE9] rounded-md"
                            >
                              <Pencil className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => handleDeleteMenuItem(item.id)}
                              data-testid={`delete-menu-${item.id}`}
                              className="p-2 text-[#B24040] hover:bg-[#FAEDED] rounded-md"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </TabsContent>

          <TabsContent value="tables" data-testid="tables-section">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">
                Table Management
              </h2>
              <Button
                onClick={() => setShowTableDialog(true)}
                data-testid="add-table-btn"
                className="min-h-[48px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md font-semibold"
              >
                <Plus className="w-4 h-4 mr-2" />
                Add Table
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {tables.map((table) => (
                <div
                  key={table.id}
                  data-testid={`table-card-${table.id}`}
                  className="bg-white border border-[#E0DBD3] rounded-xl p-6 shadow-[0_4px_12px_rgba(42,47,43,0.04)]"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <div className="text-xs uppercase tracking-[0.15em] font-semibold text-[#5A615C] mb-1">
                        Table
                      </div>
                      <div className="text-2xl font-semibold text-[#2A2F2B]">
                        {table.table_number}
                      </div>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-md text-xs font-semibold uppercase tracking-[0.15em] ${
                        table.status === "available"
                          ? "bg-[#E9F0EC] text-[#4A6B56]"
                          : "bg-[#FDF4E6] text-[#D99C3D]"
                      }`}
                    >
                      {table.status}
                    </span>
                  </div>
                  <div className="text-sm text-[#5A615C]">
                    Capacity: <span className="font-semibold text-[#2A2F2B]">{table.capacity} people</span>
                  </div>
                </div>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </div>

      <Dialog open={showTableDialog} onOpenChange={setShowTableDialog}>
        <DialogContent className="max-w-md bg-white rounded-2xl" data-testid="table-dialog">
          <DialogHeader>
            <DialogTitle className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">
              Add New Table
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Table Number
              </label>
              <Input
                value={tableForm.table_number}
                onChange={(e) => setTableForm({ ...tableForm, table_number: e.target.value })}
                placeholder="e.g., 1, A1, T-01"
                data-testid="table-number-input"
                className="bg-[#F2EFE9] border-[#E0DBD3]"
              />
            </div>

            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Capacity
              </label>
              <Input
                type="number"
                value={tableForm.capacity}
                onChange={(e) => setTableForm({ ...tableForm, capacity: parseInt(e.target.value) })}
                min="1"
                data-testid="table-capacity-input"
                className="bg-[#F2EFE9] border-[#E0DBD3]"
              />
            </div>

            <Button
              onClick={handleCreateTable}
              data-testid="create-table-btn"
              className="w-full min-h-[56px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md text-base font-semibold"
            >
              Create Table
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={showMenuDialog} onOpenChange={setShowMenuDialog}>
        <DialogContent className="max-w-lg bg-white rounded-2xl max-h-[90vh] overflow-y-auto" data-testid="menu-dialog">
          <DialogHeader>
            <DialogTitle className="text-2xl md:text-3xl tracking-tight font-medium text-[#2A2F2B]">
              {editingMenuItem ? "Edit Menu Item" : "Add New Menu Item"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-4">
            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Name
              </label>
              <Input
                value={menuForm.name}
                onChange={(e) => setMenuForm({ ...menuForm, name: e.target.value })}
                placeholder="e.g., Margherita Pizza"
                data-testid="menu-name-input"
                className="bg-[#F2EFE9] border-[#E0DBD3]"
              />
            </div>

            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Description
              </label>
              <Textarea
                value={menuForm.description}
                onChange={(e) => setMenuForm({ ...menuForm, description: e.target.value })}
                placeholder="Describe the dish..."
                data-testid="menu-description-input"
                className="bg-[#F2EFE9] border-[#E0DBD3] resize-none"
                rows={3}
              />
            </div>

            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Category
              </label>
              <Select value={menuForm.category} onValueChange={(val) => setMenuForm({ ...menuForm, category: val })}>
                <SelectTrigger data-testid="menu-category-select" className="bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue placeholder="Select category" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Appetizer">Appetizer</SelectItem>
                  <SelectItem value="Main Course">Main Course</SelectItem>
                  <SelectItem value="Dessert">Dessert</SelectItem>
                  <SelectItem value="Beverage">Beverage</SelectItem>
                  <SelectItem value="Salad">Salad</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Price (₹)
              </label>
              <Input
                type="number"
                value={menuForm.price}
                onChange={(e) => setMenuForm({ ...menuForm, price: parseFloat(e.target.value) })}
                min="0"
                step="0.01"
                data-testid="menu-price-input"
                className="bg-[#F2EFE9] border-[#E0DBD3]"
              />
            </div>

            <div>
              <label className="text-sm font-semibold text-[#2A2F2B] mb-2 block">
                Image URL
              </label>
              <Select value={menuForm.image} onValueChange={(val) => setMenuForm({ ...menuForm, image: val })}>
                <SelectTrigger data-testid="menu-image-select" className="bg-[#F2EFE9] border-[#E0DBD3]">
                  <SelectValue placeholder="Select image" />
                </SelectTrigger>
                <SelectContent>
                  {sampleImages.map((img, idx) => (
                    <SelectItem key={idx} value={img}>
                      Sample Image {idx + 1}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {menuForm.image && (
                <img
                  src={menuForm.image}
                  alt="Preview"
                  className="mt-2 w-full h-40 object-cover rounded-md"
                />
              )}
            </div>

            <div className="flex items-center justify-between p-4 bg-[#F2EFE9] rounded-xl">
              <label className="text-sm font-semibold text-[#2A2F2B]">
                Available
              </label>
              <Switch
                checked={menuForm.available}
                onCheckedChange={(checked) => setMenuForm({ ...menuForm, available: checked })}
                data-testid="menu-available-switch"
              />
            </div>

            <Button
              onClick={handleCreateMenuItem}
              data-testid="save-menu-item-btn"
              className="w-full min-h-[56px] bg-[#C25934] hover:bg-[#A84C2B] text-white rounded-md text-base font-semibold"
            >
              {editingMenuItem ? "Update Menu Item" : "Create Menu Item"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AdminPanel;
