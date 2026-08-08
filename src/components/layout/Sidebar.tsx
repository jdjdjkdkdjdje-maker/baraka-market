"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard, Package, Tag, Award, Warehouse, ShoppingCart,
  Users, Truck, Image, Percent, Ticket, BarChart3, Shield, Activity,
  ChevronRight, Store, Star, MessageSquare, RefreshCw, Settings,
  X, TrendingUp,
} from "lucide-react";

interface NavItem {
  href: string;
  label: string;
  icon: React.ReactNode;
  badge?: number;
  children?: NavItem[];
}

const navItems: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: <LayoutDashboard size={18} /> },
  {
    href: "/products",
    label: "Mahsulotlar",
    icon: <Package size={18} />,
    children: [
      { href: "/products", label: "Barcha mahsulotlar", icon: <Package size={16} /> },
      { href: "/products/new", label: "Yangi mahsulot", icon: <ChevronRight size={16} /> },
    ],
  },
  { href: "/categories", label: "Kategoriyalar", icon: <Tag size={18} /> },
  { href: "/brands", label: "Brendlar", icon: <Award size={18} /> },
  { href: "/inventory", label: "Ombor", icon: <Warehouse size={18} /> },
  { href: "/orders", label: "Buyurtmalar", icon: <ShoppingCart size={18} /> },
  { href: "/users", label: "Foydalanuvchilar", icon: <Users size={18} /> },
  { href: "/couriers", label: "Kuryerlar", icon: <Truck size={18} /> },
  { href: "/banners", label: "Bannerlar", icon: <Image size={18} /> },
  { href: "/promotions", label: "Aksiyalar", icon: <Percent size={18} /> },
  { href: "/coupons", label: "Kuponlar", icon: <Ticket size={18} /> },
  { href: "/reviews", label: "Sharhlar", icon: <Star size={18} /> },
  { href: "/reports", label: "Hisobotlar", icon: <BarChart3 size={18} /> },
  { href: "/activity-logs", label: "Faollik jurnali", icon: <Activity size={18} /> },
  { href: "/settings", label: "Sozlamalar", icon: <Settings size={18} /> },
];

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function Sidebar({ isOpen, onClose }: SidebarProps) {
  const pathname = usePathname();

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed left-0 top-0 h-full w-64 bg-white border-r border-gray-100 z-50 transition-transform duration-300 ease-in-out flex flex-col shadow-xl",
          isOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"
        )}
      >
        {/* Logo */}
        <div className="flex items-center justify-between p-6 border-b border-gray-100">
          <Link href="/dashboard" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-[#16a34a] to-[#059669] rounded-xl flex items-center justify-center shadow-lg shadow-green-200">
              <Store size={20} className="text-white" />
            </div>
            <div>
              <h1 className="text-base font-bold text-gray-900">Baraka</h1>
              <p className="text-xs text-gray-500">Market Admin</p>
            </div>
          </Link>
          <button
            onClick={onClose}
            className="lg:hidden p-1.5 rounded-lg hover:bg-gray-100 text-gray-500"
          >
            <X size={18} />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4 px-3">
          <div className="space-y-0.5">
            {navItems.map((item) => {
              const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
              const isParentActive = item.children?.some(
                (child) => pathname === child.href || pathname.startsWith(child.href + "/")
              );

              return (
                <div key={item.href}>
                  <Link
                    href={item.href}
                    onClick={() => {
                      if (window.innerWidth < 1024) onClose();
                    }}
                    className={cn(
                      "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-150",
                      isActive || isParentActive
                        ? "bg-gradient-to-r from-[#16a34a] to-[#059669] text-white shadow-md shadow-green-200"
                        : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
                    )}
                  >
                    <span className={cn(
                      isActive || isParentActive ? "text-white" : "text-gray-400"
                    )}>
                      {item.icon}
                    </span>
                    <span>{item.label}</span>
                    {item.badge && (
                      <span className="ml-auto bg-red-500 text-white text-xs rounded-full px-1.5 py-0.5 font-bold">
                        {item.badge}
                      </span>
                    )}
                  </Link>
                </div>
              );
            })}
          </div>
        </nav>

        {/* Bottom User Info */}
        <div className="p-4 border-t border-gray-100 bg-gray-50">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-gradient-to-br from-[#16a34a] to-[#059669] rounded-xl flex items-center justify-center">
              <span className="text-white text-sm font-bold">A</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-gray-900 truncate">Admin</p>
              <p className="text-xs text-gray-500 truncate">Super Admin</p>
            </div>
            <div className="w-2 h-2 bg-green-500 rounded-full ring-2 ring-white"></div>
          </div>
        </div>
      </aside>
    </>
  );
}
