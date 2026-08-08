"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Progress } from "@/components/ui/progress";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Search, Warehouse, AlertTriangle, ChevronLeft, ChevronRight, Edit2, RefreshCw, Package } from "lucide-react";
import { formatCurrency, formatDate } from "@/lib/utils";

interface InventoryItem {
  id: number;
  product_id: number;
  product_name: string;
  barcode: string;
  sku: string;
  price: number;
  product_status: string;
  category_name: string;
  quantity: number;
  reserved_quantity: number;
  min_quantity: number;
  max_quantity: number;
  available_quantity: number;
  warehouse_location: string;
  updated_at: string;
  is_low_stock: boolean;
}

export default function InventoryPage() {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [total, setTotal] = useState(0);
  const [lowStockCount, setLowStockCount] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [lowStock, setLowStock] = useState(false);
  const [editItem, setEditItem] = useState<InventoryItem | null>(null);
  const [editQty, setEditQty] = useState("");
  const [editMin, setEditMin] = useState("");
  const [saving, setSaving] = useState(false);

  const fetchInventory = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: String(page),
        limit: "15",
        ...(search && { search }),
        ...(lowStock && { lowStock: "true" }),
      });
      const res = await fetch(`/api/inventory?${params}`);
      const data = await res.json();
      setItems(data.inventory ?? []);
      setTotal(data.total ?? 0);
      setLowStockCount(data.lowStockCount ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } finally {
      setLoading(false);
    }
  }, [page, search, lowStock]);

  useEffect(() => { fetchInventory(); }, [fetchInventory]);

  const handleUpdate = async () => {
    if (!editItem) return;
    setSaving(true);
    try {
      await fetch("/api/inventory", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productId: editItem.product_id,
          quantity: parseInt(editQty),
          minQuantity: parseInt(editMin),
        }),
      });
      setEditItem(null);
      fetchInventory();
    } finally {
      setSaving(false);
    }
  };

  return (
    <AdminLayout title="Ombor" subtitle={`${total} ta mahsulot kuzatilmoqda`}>
      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="rounded-2xl border border-gray-100 bg-white p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-[#16a34a] rounded-xl flex items-center justify-center shadow-sm shadow-green-200">
            <Warehouse size={20} className="text-white" />
          </div>
          <div>
            <p className="text-xl font-bold text-gray-900">{total}</p>
            <p className="text-xs text-gray-500">Jami mahsulotlar</p>
          </div>
        </div>
        <div className="rounded-2xl border border-red-100 bg-red-50 p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-red-500 rounded-xl flex items-center justify-center shadow-sm">
            <AlertTriangle size={20} className="text-white" />
          </div>
          <div>
            <p className="text-xl font-bold text-red-700">{lowStockCount}</p>
            <p className="text-xs text-red-500">Kam qolgan</p>
          </div>
        </div>
        <div className="rounded-2xl border border-gray-100 bg-white p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-blue-500 rounded-xl flex items-center justify-center shadow-sm">
            <Package size={20} className="text-white" />
          </div>
          <div>
            <p className="text-xl font-bold text-gray-900">{items.reduce((sum, i) => sum + i.quantity, 0)}</p>
            <p className="text-xs text-gray-500">Bu sahifadagi jami</p>
          </div>
        </div>
        <div className="rounded-2xl border border-gray-100 bg-white p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-orange-500 rounded-xl flex items-center justify-center shadow-sm">
            <Package size={20} className="text-white" />
          </div>
          <div>
            <p className="text-xl font-bold text-gray-900">{items.reduce((sum, i) => sum + i.reserved_quantity, 0)}</p>
            <p className="text-xs text-gray-500">Rezerv qilingan</p>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Mahsulot nomi, barkod..."
            className="pl-9"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <button
          onClick={() => { setLowStock(!lowStock); setPage(1); }}
          className={`px-4 py-2.5 rounded-xl text-sm font-medium border transition-all ${
            lowStock
              ? "bg-red-500 text-white border-red-500 shadow-md"
              : "bg-white text-gray-700 border-gray-200 hover:border-red-300"
          }`}
        >
          <AlertTriangle size={14} className="inline mr-1.5" />
          Kam qolganlar ({lowStockCount})
        </button>
      </div>

      {/* Inventory Table */}
      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <div className="w-10 h-10 border-4 border-[#16a34a] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : items.length === 0 ? (
            <div className="text-center py-16">
              <Warehouse size={40} className="text-gray-200 mx-auto mb-3" />
              <p className="text-gray-400">Ma'lumot topilmadi</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-50">
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase px-6 py-4">Mahsulot</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase px-4 py-4">Kategoriya</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase px-4 py-4">Miqdor</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase px-4 py-4">Holat</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase px-4 py-4">Joylashuv</th>
                    <th className="text-right text-xs font-semibold text-gray-400 uppercase px-4 py-4">Narx</th>
                    <th className="px-4 py-4"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {items.map(item => {
                    const maxQ = item.max_quantity || Math.max(item.quantity, 100);
                    const pct = Math.min(Math.round((item.quantity / maxQ) * 100), 100);
                    return (
                      <tr key={item.id} className={`hover:bg-gray-50/50 transition-colors ${item.is_low_stock ? "bg-red-50/30" : ""}`}>
                        <td className="px-6 py-4">
                          <div>
                            <p className="text-sm font-semibold text-gray-900 line-clamp-1">{item.product_name}</p>
                            <p className="text-xs text-gray-400 mt-0.5">
                              {item.sku && <span className="mr-2">SKU: {item.sku}</span>}
                              {item.barcode && <span>BC: {item.barcode}</span>}
                            </p>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <span className="text-sm text-gray-600">{item.category_name ?? "—"}</span>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex flex-col gap-1.5 min-w-[120px]">
                            <div className="flex items-center justify-between">
                              <span className={`text-sm font-bold ${item.is_low_stock ? "text-red-600" : "text-gray-900"}`}>
                                {item.quantity}
                              </span>
                              <span className="text-xs text-gray-400">/ min: {item.min_quantity}</span>
                            </div>
                            <Progress value={pct} className={item.is_low_stock ? "[&>div]:bg-red-500" : ""} />
                            {item.reserved_quantity > 0 && (
                              <p className="text-xs text-orange-500">{item.reserved_quantity} ta rezerv</p>
                            )}
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-1.5">
                            {item.is_low_stock && <AlertTriangle size={14} className="text-red-500" />}
                            <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold border ${
                              item.is_low_stock
                                ? "bg-red-100 text-red-700 border-red-200"
                                : item.quantity === 0
                                  ? "bg-gray-100 text-gray-600 border-gray-200"
                                  : "bg-green-100 text-green-700 border-green-200"
                            }`}>
                              {item.quantity === 0 ? "Tugagan" : item.is_low_stock ? "Kam qolgan" : "Mavjud"}
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-4">
                          <span className="text-sm text-gray-500 bg-gray-50 px-2 py-0.5 rounded-lg font-mono text-xs">
                            {item.warehouse_location ?? "—"}
                          </span>
                        </td>
                        <td className="px-4 py-4 text-right">
                          <span className="text-sm font-semibold text-gray-900">{formatCurrency(item.price)}</span>
                        </td>
                        <td className="px-4 py-4">
                          <Button
                            variant="ghost"
                            size="icon-sm"
                            onClick={() => {
                              setEditItem(item);
                              setEditQty(String(item.quantity));
                              setEditMin(String(item.min_quantity));
                            }}
                          >
                            <Edit2 size={15} />
                          </Button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-gray-500">{total} ta yozuv</p>
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

      {/* Edit Dialog */}
      <Dialog open={!!editItem} onOpenChange={() => setEditItem(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Zaxirani yangilash</DialogTitle>
            <DialogDescription>{editItem?.product_name}</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Miqdor (dona)</label>
              <Input type="number" value={editQty} onChange={e => setEditQty(e.target.value)} />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Minimal miqdor</label>
              <Input type="number" value={editMin} onChange={e => setEditMin(e.target.value)} />
            </div>
          </div>
          <DialogFooter className="mt-2 gap-2">
            <Button variant="outline" onClick={() => setEditItem(null)}>Bekor</Button>
            <Button onClick={handleUpdate} disabled={saving}>
              {saving ? <RefreshCw size={14} className="animate-spin" /> : null}
              Saqlash
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}
