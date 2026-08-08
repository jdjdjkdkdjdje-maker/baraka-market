"use client";
import { useEffect, useState } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import {
  AreaChart, Area, BarChart, Bar, LineChart, Line,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from "recharts";
import { BarChart3, TrendingUp, ShoppingCart, Package, DollarSign, Users } from "lucide-react";
import { formatCurrency } from "@/lib/utils";

interface ChartData {
  revenueLast7Days: Array<{ date: string; orders: number; revenue: number }>;
  revenueByMonth: Array<{ month: string; month_label: string; orders: number; revenue: number }>;
  ordersByStatus: Array<{ status: string; count: number }>;
  topCategories: Array<{ name: string; orders: number; revenue: number }>;
  topProducts: Array<{ name: string; price: number; sold: number; revenue: number }>;
}

export default function ReportsPage() {
  const [charts, setCharts] = useState<ChartData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/dashboard/charts")
      .then(r => r.json())
      .then(data => { setCharts(data); setLoading(false); });
  }, []);

  return (
    <AdminLayout title="Hisobotlar" subtitle="Savdo va moliya hisobotlari">
      {loading ? (
        <div className="flex items-center justify-center h-96">
          <div className="w-12 h-12 border-4 border-[#16a34a] border-t-transparent rounded-full animate-spin" />
        </div>
      ) : (
        <div className="space-y-6">
          {/* Revenue Trend */}
          <Card>
            <CardHeader>
              <CardTitle>Daromad tendentsiyasi (12 oy)</CardTitle>
              <CardDescription>Oylik savdo va buyurtmalar soni</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={320}>
                <AreaChart data={charts?.revenueByMonth ?? []}>
                  <defs>
                    <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#16a34a" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#16a34a" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="ordersGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="month_label" tick={{ fontSize: 12, fill: "#9ca3af" }} />
                  <YAxis yAxisId="revenue" orientation="left" tickFormatter={v => `${(v/1000000).toFixed(1)}M`} tick={{ fontSize: 12, fill: "#9ca3af" }} />
                  <YAxis yAxisId="orders" orientation="right" tick={{ fontSize: 12, fill: "#9ca3af" }} />
                  <Tooltip
                    formatter={(value, name) => [
                      name === "revenue" ? formatCurrency(Number(value)) : String(value),
                      name === "revenue" ? "Daromad" : "Buyurtmalar"
                    ]}
                    contentStyle={{ borderRadius: "12px" }}
                  />
                  <Legend />
                  <Area yAxisId="revenue" type="monotone" dataKey="revenue" name="revenue" stroke="#16a34a" strokeWidth={3} fill="url(#revenueGrad)" />
                  <Area yAxisId="orders" type="monotone" dataKey="orders" name="orders" stroke="#3b82f6" strokeWidth={2} fill="url(#ordersGrad)" />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Top Categories */}
            <Card>
              <CardHeader>
                <CardTitle>Top kategoriyalar</CardTitle>
                <CardDescription>Daromad bo'yicha eng yaxshi kategoriyalar</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <BarChart data={charts?.topCategories ?? []} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                    <XAxis type="number" tickFormatter={v => `${(v/1000000).toFixed(1)}M`} tick={{ fontSize: 11, fill: "#9ca3af" }} />
                    <YAxis type="category" dataKey="name" tick={{ fontSize: 11, fill: "#6b7280" }} width={100} />
                    <Tooltip formatter={(v) => [formatCurrency(Number(v)), "Daromad"]} contentStyle={{ borderRadius: "12px" }} />
                    <Bar dataKey="revenue" fill="#16a34a" radius={[0, 8, 8, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Top Products Table */}
            <Card>
              <CardHeader>
                <CardTitle>Top mahsulotlar</CardTitle>
                <CardDescription>Eng ko'p sotilgan mahsulotlar</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {(charts?.topProducts ?? []).map((p, i) => (
                    <div key={i} className="flex items-center gap-3">
                      <div className={`w-8 h-8 rounded-xl flex items-center justify-center text-sm font-bold text-white ${
                        i === 0 ? "bg-yellow-500" : i === 1 ? "bg-gray-400" : i === 2 ? "bg-amber-600" : "bg-gray-200 text-gray-600"
                      }`}>{i + 1}</div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 truncate">{p.name}</p>
                        <div className="flex items-center gap-3 mt-0.5">
                          <span className="text-xs text-gray-400">{p.sold} ta</span>
                          <div className="flex-1 bg-gray-100 rounded-full h-1.5">
                            <div className="bg-[#16a34a] h-1.5 rounded-full" style={{ width: `${(p.sold / (charts?.topProducts[0]?.sold ?? 1)) * 100}%` }} />
                          </div>
                        </div>
                      </div>
                      <span className="text-sm font-bold text-gray-900 shrink-0">{formatCurrency(p.revenue)}</span>
                    </div>
                  ))}
                  {(charts?.topProducts ?? []).length === 0 && (
                    <div className="text-center py-8 text-gray-400">
                      <Package size={32} className="mx-auto mb-2 text-gray-200" />
                      <p>Ma'lumot yo'q</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* 7 Day Trend */}
          <Card>
            <CardHeader>
              <CardTitle>Oxirgi 7 kun</CardTitle>
              <CardDescription>Kunlik savdo ko'rsatkichlari</CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={charts?.revenueLast7Days ?? []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="date" tickFormatter={(v) => { const d = new Date(v); return `${d.getDate()}/${d.getMonth() + 1}`; }} tick={{ fontSize: 12, fill: "#9ca3af" }} />
                  <YAxis tickFormatter={v => `${(v/1000).toFixed(0)}K`} tick={{ fontSize: 12, fill: "#9ca3af" }} />
                  <Tooltip formatter={(v) => [formatCurrency(Number(v)), "Daromad"]} contentStyle={{ borderRadius: "12px" }} />
                  <Line type="monotone" dataKey="revenue" stroke="#16a34a" strokeWidth={3} dot={{ fill: "#16a34a", r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>
      )}
    </AdminLayout>
  );
}
