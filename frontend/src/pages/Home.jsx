import { useNavigate } from "react-router-dom";
import { ChefHat, Utensils, Calculator, Settings } from "lucide-react";

const Home = () => {
  const navigate = useNavigate();

  const roles = [
    {
      id: "captain",
      title: "Captain/Waiter",
      description: "Take orders at tables",
      icon: Utensils,
      color: "bg-[#C25934]",
      path: "/captain"
    },
    {
      id: "kitchen",
      title: "Kitchen Display",
      description: "View orders to prepare",
      icon: ChefHat,
      color: "bg-[#4A6B56]",
      path: "/kitchen"
    },
    {
      id: "billing",
      title: "Billing Counter",
      description: "Generate bills & track payments",
      icon: Calculator,
      color: "bg-[#D99C3D]",
      path: "/billing"
    },
    {
      id: "admin",
      title: "Admin Panel",
      description: "Manage menu, tables & staff",
      icon: Settings,
      color: "bg-[#2A2F2B]",
      path: "/admin"
    }
  ];

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6">
      <div className="text-center mb-12">
        <img 
          src="https://images.unsplash.com/photo-1770993136387-e27c9d30782d?crop=entropy&cs=srgb&fm=jpg&ixid=M3w4NTYxODF8MHwxfHNlYXJjaHwxfHxtaW5pbWFsaXN0JTIwcmVzdGF1cmFudCUyMGxvZ28lMjBzaWdufGVufDB8fHx8MTc3NjQwMzEzMnww&ixlib=rb-4.1.0&q=85" 
          alt="Restaurant Logo" 
          className="w-32 h-32 object-cover rounded-full mx-auto mb-6 shadow-[0_12px_32px_rgba(42,47,43,0.08)]"
          data-testid="restaurant-logo"
        />
        <h1 className="text-4xl md:text-5xl tracking-tight font-medium text-[#2A2F2B] mb-3">
          Dine Local Hub
        </h1>
        <p className="text-base text-[#5A615C]">
          Restaurant Management System
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl w-full">
        {roles.map((role) => {
          const Icon = role.icon;
          return (
            <button
              key={role.id}
              data-testid={`role-${role.id}-btn`}
              onClick={() => navigate(role.path)}
              className="bg-white border border-[#E0DBD3] rounded-xl p-8 hover:-translate-y-0.5 hover:shadow-[0_12px_32px_rgba(42,47,43,0.08)] transition-all duration-200 text-left group"
            >
              <div className={`${role.color} w-14 h-14 rounded-md flex items-center justify-center mb-4`}>
                <Icon className="w-7 h-7 text-white" strokeWidth={2} />
              </div>
              <h3 className="text-xl md:text-2xl font-medium text-[#2A2F2B] mb-2">
                {role.title}
              </h3>
              <p className="text-sm text-[#5A615C]">
                {role.description}
              </p>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default Home;
