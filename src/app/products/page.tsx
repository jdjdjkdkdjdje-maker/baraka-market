"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import {
  Search, Plus, Edit2, Trash2, Package, Star,
  ChevronLeft, ChevronRight, RefreshCw,
} from "lucide-react";
import { formatCurrency, getStatusColor, getStatusLabel } from "@/lib/utils";

interface Product {
  id: number;
  name: string;
  slug: string;
  price: number;
  oldPrice?: number;
  discountPercent: number;
  status: string;
  barcode?: string;
  sku?: string;
  isFeatured: boolean;
  isNew: boolean;
  totalSold: number;
  averageRating?: number;
  reviewCount: number;
  categoryId?: number;
  brandId?: number;
  categoryName?: string;
  brandName?: string;
  inventoryQty?: number;
  primaryImage?: string;
  createdAt: string;
}

interface Category { id: number; name: string; }
interface Brand { id: number; name: string; }

const EMPTY_FORM = {
  name: "", nameRu: "", description: "", price: "", oldPrice: "",
  categoryId: "", brandId: "", barcode: "", sku: "", weight: "",
  calories: "", manufacturer: "", countryOfOrigin: "", status: "active",
  isFeatured: false, isNew: false, ingredients: "", quantity: "100",
};

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [brands, setBrands] = useState<Brand[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [editProduct, setEditProduct] = useState<Product | null>(null);
  const [deleteId, setDeleteId] = useState<number | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);

  const fetchCategories = async () => {
    const res = await fetch("/api/categories");
    const data = await res.json();
    setCategories(data.categories ?? []);
  };

  const fetchBrands = async () => {
    const res = await fetch("/api/brands");
    const data = await res.json();
    setBrands(data.brands ?? []);
  };

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: String(page),
        limit: "15",
        ...(search && { search }),
        ...(statusFilter && { status: statusFilter }),
        ...(categoryFilter && { categoryId: categoryFilter }),
      });
      const res = await fetch(`/api/products?${params}`);
      const data = await res.json();
      setProducts(data.products ?? []);
      setTotal(data.total ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } finally {
      setLoading(false);
    }
  }, [page, search, statusFilter, categoryFilter]);

  useEffect(() => { fetchProducts(); }, [fetchProducts]);
  useEffect(() => { fetchCategories(); fetchBrands(); }, []);

  const openCreate = () => {
    setEditProduct(null);
    setForm(EMPTY_FORM);
    setDialogOpen(true);
  };

  const openEdit = (product: Product) => {
    setEditProduct(product);
    setForm({
      name: product.name,
      nameRu: "",
      description: "",
      price: String(product.price),
      oldPrice: product.oldPrice ? String(product.oldPrice) : "",
      categoryId: product.categoryId ? String(product.categoryId) : "",
      brandId: product.brandId ? String(product.brandId) : "",
      barcode: product.barcode ?? "",
      sku: product.sku ?? "",
      weight: "",
      calories: "",
      manufacturer: "",
      countryOfOrigin: "",
      status: product.status,
      isFeatured: product.isFeatured,
      isNew: product.isNew,
      ingredients: "",
      quantity: String(product.inventoryQty ?? 0),
    } as typeof EMPTY_FORM);
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const method = editProduct ? "PUT" : "POST";
      const url = editProduct ? `/api/products/${editProduct.id}` : "/api/products";
      await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...form,
          price: parseFloat(form.price),
          oldPrice: form.oldPrice ? parseFloat(form.oldPrice) : null,
          discountPercent: form.oldPrice && form.price
            ? Math.round(((parseFloat(form.oldPrice) - parseFloat(form.price)) / parseFloat(form.oldPrice)) * 100)
            : 0,
        }),
      });
      setDialogOpen(false);
      fetchProducts();
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    await fetch(`/api/products/${deleteId}`, { method: "DELETE" });
    setDeleteDialogOpen(false);
    setDeleteId(null);
    fetchProducts();
  };

  return (
    <AdminLayout title="Mahsulotlar" subtitle={`Jami ${total} ta mahsulot`}>
      {/* Toolbar */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Mahsulot nomi, barkod, SKU..."
            className="pl-9"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <Select value={statusFilter} onValueChange={(v) => { setStatusFilter(v === "all" ? "" : v); setPage(1); }}>
          <SelectTrigger className="w-full sm:w-44">
            <SelectValue placeholder="Holat" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Barcha holatlar</SelectItem>
            <SelectItem value="active">Faol</SelectItem>
            <SelectItem value="inactive">Nofaol</SelectItem>
            <SelectItem value="out_of_stock">Tugagan</SelectItem>
            <SelectItem value="discontinued">To'xtatilgan</SelectItem>
          </SelectContent>
        </Select>
        <Select value={categoryFilter} onValueChange={(v) => { setCategoryFilter(v === "all" ? "" : v); setPage(1); }}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Kategoriya" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Barcha kategoriyalar</SelectItem>
            {categories.map(c => (
              <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Button onClick={openCreate} className="shrink-0">
          <Plus size={16} />
          Yangi mahsulot
        </Button>
      </div>

      {/* Products Grid */}
      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="rounded-2xl border border-gray-100 bg-white p-4 animate-pulse">
              <div className="w-full h-40 bg-gray-100 rounded-xl mb-3" />
              <div className="h-4 bg-gray-100 rounded w-3/4 mb-2" />
              <div className="h-3 bg-gray-100 rounded w-1/2" />
            </div>
          ))}
        </div>
      ) : products.length === 0 ? (
        <Card>
          <CardContent className="py-20 text-center">
            <Package size={48} className="text-gray-200 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-400">Mahsulotlar topilmadi</h3>
            <p className="text-gray-300 text-sm mt-1">Demo Data tugmasini bosib ma'lumot yuklan</p>
          </CardContent>
        </Card>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 mb-6">
            {products.map((product) => (
              <div
                key={product.id}
                className="rounded-2xl border border-gray-100 bg-white overflow-hidden hover:shadow-lg transition-all duration-300 hover:-translate-y-0.5 group"
              >
                {/* Product Image */}
                <div className="relative h-44 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
                  {product.primaryImage ? (
                    <img
                      src={product.primaryImage}
                      alt={product.name}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center">
                      <Package size={40} className="text-gray-200" />
                    </div>
                  )}
                  {/* Badges */}
                  <div className="absolute top-2 left-2 flex flex-col gap-1">
                    {product.discountPercent > 0 && (
                      <span className="bg-red-500 text-white text-xs font-bold px-2 py-0.5 rounded-lg">
                        -{product.discountPercent}%
                      </span>
                    )}
                    {product.isNew && (
                      <span className="bg-blue-500 text-white text-xs font-bold px-2 py-0.5 rounded-lg">
                        YANGI
                      </span>
                    )}
                    {product.isFeatured && (
                      <span className="bg-yellow-500 text-white text-xs font-bold px-2 py-0.5 rounded-lg">
                        ⭐ TOP
                      </span>
                    )}
                  </div>
                  {/* Status */}
                  <div className="absolute top-2 right-2">
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded-lg border ${getStatusColor(product.status)}`}>
                      {getStatusLabel(product.status)}
                    </span>
                  </div>
                  {/* Actions overlay */}
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                    <button
                      onClick={() => openEdit(product)}
                      className="p-2 bg-white rounded-xl hover:bg-gray-100 transition-colors shadow-md"
                    >
                      <Edit2 size={16} className="text-gray-700" />
                    </button>
                    <button
                      onClick={() => { setDeleteId(product.id); setDeleteDialogOpen(true); }}
                      className="p-2 bg-white rounded-xl hover:bg-red-50 transition-colors shadow-md"
                    >
                      <Trash2 size={16} className="text-red-500" />
                    </button>
                  </div>
                </div>

                {/* Product Info */}
                <div className="p-4">
                  <p className="text-xs text-[#16a34a] font-medium mb-1">{product.categoryName ?? "Kategoriyasiz"}</p>
                  <h3 className="text-sm font-bold text-gray-900 leading-tight line-clamp-2 mb-2">{product.name}</h3>
                  <div className="flex items-center gap-1 mb-3">
                    {product.brandName && (
                      <span className="text-xs text-gray-400 bg-gray-50 px-2 py-0.5 rounded-lg">{product.brandName}</span>
                    )}
                    {product.averageRating && product.averageRating > 0 && (
                      <span className="ml-auto flex items-center gap-0.5 text-xs text-yellow-600 font-medium">
                        <Star size={11} fill="currentColor" />
                        {product.averageRating?.toFixed(1)}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="text-base font-bold text-gray-900">{formatCurrency(product.price)}</span>
                      {product.oldPrice && (
                        <span className="text-xs text-gray-400 line-through ml-2">{formatCurrency(product.oldPrice)}</span>
                      )}
                    </div>
                    <div className="text-xs text-gray-400">
                      <span className={product.inventoryQty !== undefined && product.inventoryQty <= 20 ? "text-red-500 font-semibold" : ""}>
                        {product.inventoryQty ?? 0} dona
                      </span>
                    </div>
                  </div>
                  <div className="mt-2 pt-2 border-t border-gray-50 flex items-center justify-between text-xs text-gray-400">
                    <span>{product.totalSold} ta sotildi</span>
                    <span>{product.reviewCount} sharh</span>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Pagination */}
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-500">
              {((page - 1) * 15) + 1}–{Math.min(page * 15, total)} / {total} ta mahsulot
            </p>
            <div className="flex items-center gap-2">
              <Button
                variant="outline" size="icon-sm"
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page === 1}
              >
                <ChevronLeft size={16} />
              </Button>
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                const p = i + 1;
                return (
                  <Button
                    key={p}
                    variant={page === p ? "default" : "outline"}
                    size="icon-sm"
                    onClick={() => setPage(p)}
                  >
                    {p}
                  </Button>
                );
              })}
              <Button
                variant="outline" size="icon-sm"
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
              >
                <ChevronRight size={16} />
              </Button>
            </div>
          </div>
        </>
      )}

      {/* Create/Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editProduct ? "Mahsulotni tahrirlash" : "Yangi mahsulot qo'shish"}</DialogTitle>
            <DialogDescription>Mahsulot ma'lumotlarini to'ldiring</DialogDescription>
          </DialogHeader>
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Nomi (UZ) *</label>
              <Input
                value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder="Mahsulot nomi"
              />
            </div>
            <div className="col-span-2">
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Nomi (RU)</label>
              <Input
                value={form.nameRu}
                onChange={e => setForm(f => ({ ...f, nameRu: e.target.value }))}
                placeholder="Название продукта"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Narx (UZS) *</label>
              <Input
                type="number"
                value={form.price}
                onChange={e => setForm(f => ({ ...f, price: e.target.value }))}
                placeholder="15000"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Eski narx (UZS)</label>
              <Input
                type="number"
                value={form.oldPrice}
                onChange={e => setForm(f => ({ ...f, oldPrice: e.target.value }))}
                placeholder="20000"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Kategoriya</label>
              <Select value={form.categoryId} onValueChange={v => setForm(f => ({ ...f, categoryId: v }))}>
                <SelectTrigger><SelectValue placeholder="Kategoriya tanlang" /></SelectTrigger>
                <SelectContent>
                  {categories.map(c => (
                    <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Brend</label>
              <Select value={form.brandId} onValueChange={v => setForm(f => ({ ...f, brandId: v }))}>
                <SelectTrigger><SelectValue placeholder="Brend tanlang" /></SelectTrigger>
                <SelectContent>
                  {brands.map(b => (
                    <SelectItem key={b.id} value={String(b.id)}>{b.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Barkod</label>
              <Input value={form.barcode} onChange={e => setForm(f => ({ ...f, barcode: e.target.value }))} placeholder="1234567890123" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">SKU</label>
              <Input value={form.sku} onChange={e => setForm(f => ({ ...f, sku: e.target.value }))} placeholder="PROD-001" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Og'irligi (g)</label>
              <Input type="number" value={form.weight} onChange={e => setForm(f => ({ ...f, weight: e.target.value }))} placeholder="500" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Kaloriya</label>
              <Input type="number" value={form.calories} onChange={e => setForm(f => ({ ...f, calories: e.target.value }))} placeholder="250" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Ishlab chiqaruvchi</label>
              <Input value={form.manufacturer} onChange={e => setForm(f => ({ ...f, manufacturer: e.target.value }))} placeholder="Company Ltd" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Davlat</label>
              <Input value={form.countryOfOrigin} onChange={e => setForm(f => ({ ...f, countryOfOrigin: e.target.value }))} placeholder="Uzbekistan" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Sklad miqdori</label>
              <Input type="number" value={form.quantity} onChange={e => setForm(f => ({ ...f, quantity: e.target.value }))} placeholder="100" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Holat</label>
              <Select value={form.status} onValueChange={v => setForm(f => ({ ...f, status: v }))}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="active">Faol</SelectItem>
                  <SelectItem value="inactive">Nofaol</SelectItem>
                  <SelectItem value="out_of_stock">Tugagan</SelectItem>
                  <SelectItem value="discontinued">To'xtatilgan</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="col-span-2">
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Tavsif</label>
              <textarea
                className="w-full rounded-xl border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#16a34a] resize-none"
                rows={3}
                value={form.description}
                onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Mahsulot tavsifi..."
              />
            </div>
            <div className="col-span-2 flex items-center gap-6">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={form.isFeatured}
                  onChange={e => setForm(f => ({ ...f, isFeatured: e.target.checked }))}
                  className="w-4 h-4 accent-[#16a34a] rounded"
                />
                <span className="text-sm text-gray-700">Featured mahsulot</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={form.isNew}
                  onChange={e => setForm(f => ({ ...f, isNew: e.target.checked }))}
                  className="w-4 h-4 accent-[#16a34a] rounded"
                />
                <span className="text-sm text-gray-700">Yangi mahsulot</span>
              </label>
            </div>
          </div>
          <DialogFooter className="mt-4 gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Bekor qilish</Button>
            <Button onClick={handleSave} disabled={saving || !form.name || !form.price}>
              {saving ? <RefreshCw size={16} className="animate-spin" /> : null}
              {editProduct ? "Saqlash" : "Qo'shish"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Mahsulotni o'chirish</DialogTitle>
            <DialogDescription>Bu amalni ortga qaytarib bo'lmaydi. Mahsulot butunlay o'chiriladi.</DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>Bekor qilish</Button>
            <Button variant="destructive" onClick={handleDelete}>O'chirish</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}
