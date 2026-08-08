"use client";
import { useEffect, useState } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import StatsCard from "@/components/dashboard/StatsCard";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Progress } from "@/components/ui/progress";
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from "recharts";
import {
  Users, ShoppingCart, Package, TrendingUp, DollarSign,
  ArrowRight, Star, Clock, CheckCircle, XCircle, AlertTriangle,
  Truck, RefreshCw,
} from "lucide-react";
import { formatCurrency, getStatusColor, getStatusLabel, formatTimeAgo } from "@/lib/utils";
import Link from "next/link";

interface Stats {
  totalUsers: number;
  totalOrders: number;
  totalProducts: number;
  activeProducts: number;
  pendingOrders: number;
  totalRevenue: number;
  monthRevenue: number;
  monthOrders: number;
  monthUsers: number;
  userGrowth: number;
  revenueGrowth: number;
  averageOrderValue: number;
}

interface ChartData {
  revenueLast7Days: Array<{ date: string; orders: number; revenue: number }>;
  revenueByMonth: Array<{ month: string; month_label: string; orders: number; revenue: number }>;
  ordersByStatus: Array<{ status: string; count: number }>;
  topCategories: Array<{ name: string; orders: number; revenue: number }>;
  topProducts: Array<{ name: string; price: number; sold: number; revenue: number }>;
  paymentMethods: Array<{ payment_method: string; count: number; total: number }>;
}

interface RecentOrder {
  id: number;
  order_number: string;
  status: string;
  total_amount: number;
  payment_method: string;
  payment_status: string;
  created_at: string;
  first_name: string;
  last_name: string;
  phone: string;
  item_count: number;
}

const STATUS_COLORS: Record<string, string> = {
  pending: "#f59e0b",
  confirmed: "#3b82f6",
  preparing: "#8b5cf6",
  ready: "#06b6d4",
  delivering: "#f97316",
  delivered: "#22c55e",
  cancelled: "#ef4444",
  returned: "#6b7280",
};

const PAYMENT_COLORS = ["#16a34a", "#3b82f6", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4"];

const PAYMENT_LABELS: Record<string, string> = {
  cash: "Naqd",
  card: "Karta",
  payme: "Payme",
  click: "Click",
  wallet: "Hamyon",
  uzum: "Uzum",
};

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [charts, setCharts] = useState<ChartData | null>(null);
  const [recentOrders, setRecentOrders] = useState<RecentOrder[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAll = async () => {
      setLoading(true);
      try {
        const [statsRes, chartsRes, ordersRes] = await Promise.all([
          fetch("/api/dashboard/stats"),
          fetch("/api/dashboard/charts"),
          fetch("/api/dashboard/recent-orders"),
        ]);
        const [statsData, chartsData, ordersData] = await Promise.all([
          statsRes.json(),
          chartsRes.json(),
          ordersRes.json(),
        ]);
        setStats(statsData);
        setCharts(chartsData);
        setRecentOrders(ordersData.orders ?? []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchAll();
  }, []);

  const formatRevenue = (value: number) => {
    if (value >= 1000000) return `${(value / 1000000).toFixed(1)}M`;
    if (value >= 1000) return `${(value / 1000).toFixed(0)}K`;
    return value.toString();
  };

  return (
    <AdminLayout title="Dashboard" subtitle="Baraka Market boshqaruv paneli">
      {loading ? (
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="w-16 h-16 border-4 border-[#16a34a] border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
            <p className="text-gray-500 font-medium">Ma'lumotlar yuklanmoqda...</p>
            <p className="text-gray-400 text-sm mt-1">Demo Data tugmasini bosing</p>
          </div>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Stats Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <StatsCard
              title="Jami foydalanuvchilar"
              value={(stats?.totalUsers ?? 0).toLocaleString()}
              subtitle={`Bu oy: +${stats?.monthUsers ?? 0}`}
              icon={<Users size={22} />}
              trend={stats?.userGrowth}
              gradient="from-white to-blue-50"
              iconBg="bg-gradient-to-br from-blue-500 to-blue-600"
            />
            <StatsCard
              title="Bu oy daromad"
              value={formatCurrency(stats?.monthRevenue ?? 0)}
              subtitle={`Jami: ${formatCurrency(stats?.totalRevenue ?? 0)}`}
              icon={<DollarSign size={22} />}
              trend={stats?.revenueGrowth}
              gradient="from-white to-green-50"
              iconBg="bg-gradient-to-br from-[#16a34a] to-[#059669]"
            />
            <StatsCard
              title="Jami buyurtmalar"
              value={(stats?.totalOrders ?? 0).toLocaleString()}
              subtitle={`Bu oy: ${stats?.monthOrders ?? 0} ta`}
              icon={<ShoppingCart size={22} />}
              gradient="from-white to-purple-50"
              iconBg="bg-gradient-to-br from-purple-500 to-purple-600"
            />
            <StatsCard
              title="Mahsulotlar"
              value={(stats?.totalProducts ?? 0).toLocaleString()}
              subtitle={`Faol: ${stats?.activeProducts ?? 0} ta`}
              icon={<Package size={22} />}
              gradient="from-white to-orange-50"
              iconBg="bg-gradient-to-br from-orange-500 to-orange-600"
            />
          </div>

          {/* Secondary Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="rounded-2xl border border-yellow-100 bg-gradient-to-br from-yellow-50 to-orange-50 p-5 flex items-center gap-4">
              <div className="w-12 h-12 bg-yellow-500 rounded-2xl flex items-center justify-center shadow-md shadow-yellow-200">
                <Clock size={22} className="text-white" />
              </div>
              <div>
                <p className="text-sm text-yellow-700 font-medium">Kutayotgan buyurtmalar</p>
                <p className="text-2xl font-bold text-yellow-800">{stats?.pendingOrders ?? 0}</p>
              </div>
            </div>
            <div className="rounded-2xl border border-green-100 bg-gradient-to-br from-green-50 to-emerald-50 p-5 flex items-center gap-4">
              <div className="w-12 h-12 bg-[#16a34a] rounded-2xl flex items-center justify-center shadow-md shadow-green-200">
                <TrendingUp size={22} className="text-white" />
              </div>
              <div>
                <p className="text-sm text-green-700 font-medium">O'rtacha buyurtma</p>
                <p className="text-2xl font-bold text-green-800">{formatCurrency(stats?.averageOrderValue ?? 0)}</p>
              </div>
            </div>
            <div className="rounded-2xl border border-blue-100 bg-gradient-to-br from-blue-50 to-cyan-50 p-5 flex items-center gap-4">
              <div className="w-12 h-12 bg-blue-500 rounded-2xl flex items-center justify-center shadow-md shadow-blue-200">
                <Truck size={22} className="text-white" />
              </div>
              <div>
                <p className="text-sm text-blue-700 font-medium">Yetkazilmoqda</p>
                <p className="text-2xl font-bold text-blue-800">
                  {charts?.ordersByStatus?.find(o => o.status === "delivering")?.count ?? 0}
                </p>
              </div>
            </div>
          </div>

          {/* Charts Row 1 */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Revenue Chart */}
            <Card className="lg:col-span-2">
              <CardHeader className="pb-2">
                <CardTitle>Daromad (Oxirgi 7 kun)</CardTitle>
                <CardDescription>Kunlik savdo va buyurtmalar</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <AreaChart data={charts?.revenueLast7Days ?? []}>
                    <defs>
                      <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#16a34a" stopOpacity={0.2} />
                        <stop offset="95%" stopColor="#16a34a" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                    <XAxis
                      dataKey="date"
                      tickFormatter={(v) => {
                        const d = new Date(v);
                        return `${d.getDate()}/${d.getMonth() + 1}`;
                      }}
                      tick={{ fontSize: 12, fill: "#9ca3af" }}
                    />
                    <YAxis
                      tickFormatter={formatRevenue}
                      tick={{ fontSize: 12, fill: "#9ca3af" }}
                    />
                    <Tooltip
                      formatter={(value) => [formatCurrency(Number(value)), "Daromad"]}
                      labelFormatter={(label) => {
                        if (typeof label === "string") {
                          const d = new Date(label);
                          return d.toLocaleDateString("uz-UZ");
                        }
                        return String(label);
                      }}
                      contentStyle={{ borderRadius: "12px", border: "1px solid #f0f0f0", boxShadow: "0 4px 20px rgba(0,0,0,0.1)" }}
                    />
                    <Area
                      type="monotone"
                      dataKey="revenue"
                      stroke="#16a34a"
                      strokeWidth={3}
                      fill="url(#colorRevenue)"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Orders by Status Pie */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle>Buyurtma holatlari</CardTitle>
                <CardDescription>Holatlar bo'yicha taqsimot</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie
                      data={charts?.ordersByStatus ?? []}
                      cx="50%"
                      cy="50%"
                      innerRadius={55}
                      outerRadius={80}
                      paddingAngle={3}
                      dataKey="count"
                    >
                      {(charts?.ordersByStatus ?? []).map((entry, index) => (
                        <Cell
                          key={entry.status}
                          fill={STATUS_COLORS[entry.status] ?? "#9ca3af"}
                        />
                      ))}
                    </Pie>
                    <Tooltip
                      formatter={(value) => [value, "Buyurtmalar"]}
                      contentStyle={{ borderRadius: "12px", border: "1px solid #f0f0f0" }}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <div className="space-y-1.5 mt-2">
                  {(charts?.ordersByStatus ?? []).slice(0, 5).map((item) => (
                    <div key={item.status} className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div
                          className="w-2.5 h-2.5 rounded-full"
                          style={{ backgroundColor: STATUS_COLORS[item.status] ?? "#9ca3af" }}
                        />
                        <span className="text-xs text-gray-600">{getStatusLabel(item.status)}</span>
                      </div>
                      <span className="text-xs font-bold text-gray-900">{item.count}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Charts Row 2 */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Monthly Revenue */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle>Oylik daromad</CardTitle>
                <CardDescription>So'nggi 12 oy</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={charts?.revenueByMonth ?? []}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                    <XAxis dataKey="month_label" tick={{ fontSize: 11, fill: "#9ca3af" }} />
                    <YAxis tickFormatter={formatRevenue} tick={{ fontSize: 11, fill: "#9ca3af" }} />
                    <Tooltip
                      formatter={(value) => [formatCurrency(Number(value)), "Daromad"]}
                      contentStyle={{ borderRadius: "12px", border: "1px solid #f0f0f0" }}
                    />
                    <Bar dataKey="revenue" fill="#16a34a" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Payment Methods */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle>To'lov usullari</CardTitle>
                <CardDescription>To'lov turlari taqsimoti</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {(charts?.paymentMethods ?? []).map((pm, i) => {
                    const totalCount = charts?.paymentMethods.reduce((sum, m) => sum + m.count, 0) ?? 1;
                    const pct = Math.round((pm.count / totalCount) * 100);
                    return (
                      <div key={pm.payment_method}>
                        <div className="flex items-center justify-between mb-1.5">
                          <div className="flex items-center gap-2">
                            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: PAYMENT_COLORS[i % PAYMENT_COLORS.length] }} />
                            <span className="text-sm font-medium text-gray-700">
                              {PAYMENT_LABELS[pm.payment_method] ?? pm.payment_method}
                            </span>
                          </div>
                          <div className="flex items-center gap-3">
                            <span className="text-xs text-gray-400">{pm.count} ta</span>
                            <span className="text-sm font-bold text-gray-900">{pct}%</span>
                          </div>
                        </div>
                        <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                          <div
                            className="h-full rounded-full transition-all duration-700"
                            style={{ width: `${pct}%`, backgroundColor: PAYMENT_COLORS[i % PAYMENT_COLORS.length] }}
                          />
                        </div>
                      </div>
                    );
                  })}
                  {(charts?.paymentMethods ?? []).length === 0 && (
                    <p className="text-center text-gray-400 text-sm py-8">Ma'lumot yo'q</p>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Bottom Row */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Recent Orders */}
            <Card className="lg:col-span-2">
              <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle>So'nggi buyurtmalar</CardTitle>
                    <CardDescription>Oxirgi 10 ta buyurtma</CardDescription>
                  </div>
                  <Link href="/orders" className="text-sm text-[#16a34a] font-medium hover:underline flex items-center gap-1">
                    Barchasi <ArrowRight size={14} />
                  </Link>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {recentOrders.length === 0 ? (
                    <div className="text-center py-12">
                      <ShoppingCart size={40} className="text-gray-200 mx-auto mb-3" />
                      <p className="text-gray-400">Buyurtmalar yo'q</p>
                      <p className="text-gray-300 text-sm">Demo Data tugmasini bosing</p>
                    </div>
                  ) : (
                    recentOrders.map((order) => (
                      <div key={order.id} className="flex items-center justify-between p-3 rounded-xl hover:bg-gray-50 transition-colors group">
                        <div className="flex items-center gap-3">
                          <Avatar className="w-9 h-9">
                            <AvatarFallback>
                              {order.first_name?.[0] ?? "U"}{order.last_name?.[0] ?? ""}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="text-sm font-semibold text-gray-900">
                              {order.first_name} {order.last_name}
                            </p>
                            <p className="text-xs text-gray-400">
                              #{order.order_number} · {formatTimeAgo(order.created_at)}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          <div className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border ${getStatusColor(order.status)}`}>
                            {getStatusLabel(order.status)}
                          </div>
                          <span className="text-sm font-bold text-gray-900">
                            {formatCurrency(order.total_amount)}
                          </span>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Top Products */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle>Top mahsulotlar</CardTitle>
                <CardDescription>Eng ko'p sotilganlar</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {(charts?.topProducts ?? []).length === 0 ? (
                    <div className="text-center py-8">
                      <Package size={32} className="text-gray-200 mx-auto mb-2" />
                      <p className="text-gray-400 text-sm">Ma'lumot yo'q</p>
                    </div>
                  ) : (
                    (charts?.topProducts ?? []).map((product, i) => (
                      <div key={i} className="flex items-center gap-3">
                        <div className={`w-8 h-8 rounded-xl flex items-center justify-center text-white text-sm font-bold shadow-sm ${
                          i === 0 ? "bg-yellow-500" :
                          i === 1 ? "bg-gray-400" :
                          i === 2 ? "bg-amber-600" :
                          "bg-gray-200 text-gray-600"
                        }`}>
                          {i + 1}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 truncate">{product.name}</p>
                          <div className="flex items-center gap-2 mt-0.5">
                            <span className="text-xs text-gray-400">{product.sold} ta sotildi</span>
                            <div className="w-full bg-gray-100 rounded-full h-1.5">
                              <div
                                className="bg-[#16a34a] h-1.5 rounded-full"
                                style={{ width: `${Math.min((product.sold / (charts?.topProducts[0]?.sold ?? 1)) * 100, 100)}%` }}
                              />
                            </div>
                          </div>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
