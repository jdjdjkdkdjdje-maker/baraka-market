"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Search, ShoppingCart, Eye, ChevronLeft, ChevronRight,
  MapPin, Phone, Package, Clock, CreditCard, Truck, CheckCircle,
  XCircle, AlertCircle, RefreshCw,
} from "lucide-react";
import { formatCurrency, getStatusColor, getStatusLabel, formatDateTime, formatTimeAgo } from "@/lib/utils";

interface Order {
  id: number;
  order_number: string;
  status: string;
  total_amount: number;
  subtotal: number;
  delivery_fee: number;
  discount_amount: number;
  payment_method: string;
  payment_status: string;
  delivery_address: string;
  created_at: string;
  first_name: string;
  last_name: string;
  phone: string;
  item_count: number;
}

interface OrderDetail {
  order: Record<string, unknown>;
  items: Array<{
    id: number;
    product_name: string;
    product_image: string;
    quantity: number;
    unit_price: number;
    total_price: number;
  }>;
  history: Array<{
    id: number;
    status: string;
    comment: string;
    created_at: string;
  }>;
}

const STATUS_OPTIONS = [
  { value: "all", label: "Barcha holatlar" },
  { value: "pending", label: "Kutilmoqda" },
  { value: "confirmed", label: "Tasdiqlandi" },
  { value: "preparing", label: "Tayyorlanmoqda" },
  { value: "ready", label: "Tayyor" },
  { value: "delivering", label: "Yetkazilmoqda" },
  { value: "delivered", label: "Yetkazildi" },
  { value: "cancelled", label: "Bekor qilindi" },
];

const STATUS_ICONS: Record<string, React.ReactNode> = {
  pending: <Clock size={14} className="text-yellow-500" />,
  confirmed: <CheckCircle size={14} className="text-blue-500" />,
  preparing: <Package size={14} className="text-purple-500" />,
  delivering: <Truck size={14} className="text-orange-500" />,
  delivered: <CheckCircle size={14} className="text-green-500" />,
  cancelled: <XCircle size={14} className="text-red-500" />,
};

const PAYMENT_LABELS: Record<string, string> = {
  cash: "Naqd", card: "Karta", payme: "Payme",
  click: "Click", wallet: "Hamyon", uzum: "Uzum",
};

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [selectedOrder, setSelectedOrder] = useState<OrderDetail | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [newStatus, setNewStatus] = useState("");

  const fetchOrders = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: String(page),
        limit: "15",
        ...(statusFilter && { status: statusFilter }),
      });
      const res = await fetch(`/api/orders?${params}`);
      const data = await res.json();
      setOrders(data.orders ?? []);
      setTotal(data.total ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter]);

  useEffect(() => { fetchOrders(); }, [fetchOrders]);

  const openDetail = async (orderId: number) => {
    setLoadingDetail(true);
    setDetailOpen(true);
    try {
      const res = await fetch(`/api/orders/${orderId}`);
      const data = await res.json();
      setSelectedOrder(data);
      setNewStatus(String(data.order.status));
    } finally {
      setLoadingDetail(false);
    }
  };

  const updateStatus = async () => {
    if (!selectedOrder || !newStatus) return;
    setUpdatingStatus(true);
    try {
      const orderId = selectedOrder.order.id as number;
      await fetch(`/api/orders/${orderId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });
      await openDetail(orderId);
      fetchOrders();
    } finally {
      setUpdatingStatus(false);
    }
  };

  return (
    <AdminLayout title="Buyurtmalar" subtitle={`Jami ${total} ta buyurtma`}>
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Buyurtma raqami, telefon..."
            className="pl-9"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <Select value={statusFilter} onValueChange={v => { setStatusFilter(v === "all" ? "" : v); setPage(1); }}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Holat" />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTIONS.map(opt => (
              <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Orders Table */}
      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="w-10 h-10 border-4 border-[#16a34a] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : orders.length === 0 ? (
            <div className="text-center py-20">
              <ShoppingCart size={48} className="text-gray-200 mx-auto mb-4" />
              <p className="text-gray-400 font-medium">Buyurtmalar topilmadi</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-50">
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-6 py-4">Buyurtma</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Mijoz</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Holat</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">To'lov</th>
                    <th className="text-right text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Summa</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Vaqt</th>
                    <th className="px-4 py-4"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {orders.map(order => (
                    <tr key={order.id} className="hover:bg-gray-50/50 transition-colors">
                      <td className="px-6 py-4">
                        <div>
                          <p className="text-sm font-bold text-gray-900">#{order.order_number}</p>
                          <p className="text-xs text-gray-400 mt-0.5">{order.item_count} ta mahsulot</p>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-2.5">
                          <Avatar className="w-8 h-8">
                            <AvatarFallback className="text-xs">
                              {order.first_name?.[0]}{order.last_name?.[0]}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="text-sm font-medium text-gray-900">
                              {order.first_name} {order.last_name}
                            </p>
                            <p className="text-xs text-gray-400">{order.phone}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1.5">
                          {STATUS_ICONS[order.status]}
                          <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border ${getStatusColor(order.status)}`}>
                            {getStatusLabel(order.status)}
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div>
                          <p className="text-sm text-gray-700">{PAYMENT_LABELS[order.payment_method] ?? order.payment_method}</p>
                          <span className={`text-xs px-1.5 py-0.5 rounded font-medium ${getStatusColor(order.payment_status)}`}>
                            {getStatusLabel(order.payment_status)}
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-right">
                        <p className="text-sm font-bold text-gray-900">{formatCurrency(order.total_amount)}</p>
                        {order.discount_amount > 0 && (
                          <p className="text-xs text-red-500">-{formatCurrency(order.discount_amount)}</p>
                        )}
                      </td>
                      <td className="px-4 py-4">
                        <p className="text-xs text-gray-500">{formatTimeAgo(order.created_at)}</p>
                      </td>
                      <td className="px-4 py-4">
                        <Button
                          variant="ghost"
                          size="icon-sm"
                          onClick={() => openDetail(order.id)}
                        >
                          <Eye size={16} />
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-gray-500">{total} ta buyurtma</p>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="icon-sm" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>
              <ChevronLeft size={16} />
            </Button>
            <span className="text-sm font-medium px-3">{page} / {totalPages}</span>
            <Button variant="outline" size="icon-sm" onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>
              <ChevronRight size={16} />
            </Button>
          </div>
        </div>
      )}

      {/* Order Detail Dialog */}
      <Dialog open={detailOpen} onOpenChange={setDetailOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Buyurtma tafsiloti</DialogTitle>
            <DialogDescription>
              {selectedOrder ? `#${String(selectedOrder.order.order_number)}` : ""}
            </DialogDescription>
          </DialogHeader>
          {loadingDetail ? (
            <div className="flex items-center justify-center py-12">
              <div className="w-8 h-8 border-4 border-[#16a34a] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : selectedOrder ? (
            <div className="space-y-5">
              {/* Customer info */}
              <div className="bg-gray-50 rounded-xl p-4">
                <h4 className="text-sm font-semibold text-gray-700 mb-3">Mijoz ma'lumotlari</h4>
                <div className="flex items-center gap-3">
                  <Avatar className="w-10 h-10">
                    <AvatarFallback>
                      {String(selectedOrder.order.first_name ?? "U")[0]}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-semibold text-gray-900">
                      {String(selectedOrder.order.first_name ?? "")} {String(selectedOrder.order.last_name ?? "")}
                    </p>
                    <p className="text-sm text-gray-500 flex items-center gap-1">
                      <Phone size={12} /> {String(selectedOrder.order.phone as string ?? "")}
                    </p>
                  </div>
                </div>
                {(selectedOrder.order.delivery_address as string | null) && (
                   <p className="text-sm text-gray-600 flex items-start gap-1.5 mt-2">
                     <MapPin size={14} className="text-gray-400 mt-0.5 shrink-0" />
                     {String(selectedOrder.order.delivery_address as string)}
                   </p>
                )}
              </div>

              {/* Order Items */}
              <div>
                <h4 className="text-sm font-semibold text-gray-700 mb-3">Buyurtma mahsulotlari</h4>
                <div className="space-y-3">
                  {selectedOrder.items.map(item => (
                    <div key={item.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                      <div className="w-12 h-12 bg-gray-200 rounded-xl overflow-hidden shrink-0">
                        {item.product_image ? (
                          <img src={item.product_image} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center">
                            <Package size={18} className="text-gray-400" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 truncate">{item.product_name}</p>
                        <p className="text-xs text-gray-400">{item.quantity} × {formatCurrency(item.unit_price)}</p>
                      </div>
                      <p className="text-sm font-bold text-gray-900">{formatCurrency(item.total_price)}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Order Summary */}
              <div className="bg-gray-50 rounded-xl p-4 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Mahsulotlar</span>
                  <span className="font-medium">{formatCurrency(Number(selectedOrder.order.subtotal))}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Yetkazib berish</span>
                  <span className="font-medium">{formatCurrency(Number(selectedOrder.order.delivery_fee))}</span>
                </div>
                {Number(selectedOrder.order.discount_amount) > 0 && (
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Chegirma</span>
                    <span className="font-medium text-red-500">-{formatCurrency(Number(selectedOrder.order.discount_amount))}</span>
                  </div>
                )}
                <div className="flex justify-between text-base font-bold pt-2 border-t border-gray-200">
                  <span>Jami</span>
                  <span className="text-[#16a34a]">{formatCurrency(Number(selectedOrder.order.total_amount))}</span>
                </div>
              </div>

              {/* Status History */}
              {selectedOrder.history.length > 0 && (
                <div>
                  <h4 className="text-sm font-semibold text-gray-700 mb-3">Holat tarixi</h4>
                  <div className="space-y-2">
                    {selectedOrder.history.map(h => (
                      <div key={h.id} className="flex items-start gap-3">
                        <div className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border ${getStatusColor(h.status)} shrink-0`}>
                          {getStatusLabel(h.status)}
                        </div>
                        <div>
                          {h.comment && <p className="text-sm text-gray-600">{h.comment}</p>}
                          <p className="text-xs text-gray-400">{formatDateTime(h.created_at)}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Update Status */}
              <div className="border-t border-gray-100 pt-4">
                <h4 className="text-sm font-semibold text-gray-700 mb-3">Holatni yangilash</h4>
                <div className="flex gap-3">
                  <Select value={newStatus} onValueChange={setNewStatus}>
                    <SelectTrigger className="flex-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {STATUS_OPTIONS.filter(o => o.value !== "all").map(opt => (
                        <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Button onClick={updateStatus} disabled={updatingStatus}>
                    {updatingStatus ? <RefreshCw size={14} className="animate-spin" /> : null}
                    Saqlash
                  </Button>
                </div>
              </div>
            </div>
          ) : null}
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}
