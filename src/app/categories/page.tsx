"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Search, Plus, Edit2, Trash2, Tag, RefreshCw, Package } from "lucide-react";
import { formatDate } from "@/lib/utils";

interface Category {
  id: number;
  parentId?: number;
  name: string;
  nameRu?: string;
  slug: string;
  description?: string;
  image?: string;
  icon?: string;
  color?: string;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
  productCount: number;
}

const EMPTY_FORM = {
  name: "", nameRu: "", nameEn: "", slug: "", description: "",
  icon: "", color: "#16a34a", sortOrder: 0,
};

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editCategory, setEditCategory] = useState<Category | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);

  const fetchCategories = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams(search ? { search } : {});
      const res = await fetch(`/api/categories?${params}`);
      const data = await res.json();
      setCategories(data.categories ?? []);
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => { fetchCategories(); }, [fetchCategories]);

  const openCreate = () => {
    setEditCategory(null);
    setForm(EMPTY_FORM);
    setDialogOpen(true);
  };

  const openEdit = (cat: Category) => {
    setEditCategory(cat);
    setForm({
      name: cat.name,
      nameRu: cat.nameRu ?? "",
      nameEn: "",
      slug: cat.slug,
      description: cat.description ?? "",
      icon: cat.icon ?? "",
      color: cat.color ?? "#16a34a",
      sortOrder: cat.sortOrder,
    });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const method = editCategory ? "PUT" : "POST";
      const url = editCategory ? `/api/categories/${editCategory.id}` : "/api/categories";
      await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      setDialogOpen(false);
      fetchCategories();
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Kategoriyani o'chirishni tasdiqlaysizmi?")) return;
    await fetch(`/api/categories/${id}`, { method: "DELETE" });
    fetchCategories();
  };

  const toggleActive = async (cat: Category) => {
    await fetch(`/api/categories/${cat.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...cat, isActive: !cat.isActive }),
    });
    fetchCategories();
  };

  const totalProducts = categories.reduce((sum, c) => sum + c.productCount, 0);

  return (
    <AdminLayout title="Kategoriyalar" subtitle={`${categories.length} ta kategoriya`}>
      {/* Toolbar */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Kategoriya nomi..."
            className="pl-9"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <Button onClick={openCreate}>
          <Plus size={16} />
          Yangi kategoriya
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="rounded-2xl border border-gray-100 bg-white p-4 text-center">
          <p className="text-2xl font-bold text-gray-900">{categories.length}</p>
          <p className="text-sm text-gray-500">Kategoriyalar</p>
        </div>
        <div className="rounded-2xl border border-gray-100 bg-white p-4 text-center">
          <p className="text-2xl font-bold text-[#16a34a]">{categories.filter(c => c.isActive).length}</p>
          <p className="text-sm text-gray-500">Faol</p>
        </div>
        <div className="rounded-2xl border border-gray-100 bg-white p-4 text-center">
          <p className="text-2xl font-bold text-blue-600">{totalProducts}</p>
          <p className="text-sm text-gray-500">Jami mahsulotlar</p>
        </div>
      </div>

      {/* Categories Grid */}
      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="rounded-2xl border border-gray-100 bg-white p-5 animate-pulse">
              <div className="w-12 h-12 bg-gray-100 rounded-2xl mb-3" />
              <div className="h-4 bg-gray-100 rounded w-2/3 mb-2" />
              <div className="h-3 bg-gray-100 rounded w-1/3" />
            </div>
          ))}
        </div>
      ) : categories.length === 0 ? (
        <Card>
          <CardContent className="py-20 text-center">
            <Tag size={48} className="text-gray-200 mx-auto mb-4" />
            <p className="text-gray-400 font-medium">Kategoriyalar topilmadi</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {categories.map(cat => (
            <div
              key={cat.id}
              className="rounded-2xl border border-gray-100 bg-white p-5 hover:shadow-lg transition-all duration-300 hover:-translate-y-0.5 group"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div
                    className="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl shadow-sm"
                    style={{ backgroundColor: (cat.color ?? "#16a34a") + "20" }}
                  >
                    {cat.icon ?? "📦"}
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900">{cat.name}</h3>
                    {cat.nameRu && <p className="text-xs text-gray-400">{cat.nameRu}</p>}
                  </div>
                </div>
                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(cat)} className="p-1.5 rounded-lg hover:bg-gray-100">
                    <Edit2 size={14} className="text-gray-500" />
                  </button>
                  <button onClick={() => handleDelete(cat.id)} className="p-1.5 rounded-lg hover:bg-red-50">
                    <Trash2 size={14} className="text-red-400" />
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1.5 text-sm">
                  <Package size={14} className="text-gray-400" />
                  <span className="font-semibold text-gray-900">{cat.productCount}</span>
                  <span className="text-gray-400">mahsulot</span>
                </div>
                <button
                  onClick={() => toggleActive(cat)}
                  className={`px-2.5 py-1 rounded-xl text-xs font-semibold border transition-colors ${
                    cat.isActive
                      ? "bg-green-100 text-green-700 border-green-200"
                      : "bg-gray-100 text-gray-600 border-gray-200"
                  }`}
                >
                  {cat.isActive ? "Faol" : "Nofaol"}
                </button>
              </div>

              <div className="mt-3 pt-3 border-t border-gray-50">
                <p className="text-xs text-gray-400">Slug: /{cat.slug}</p>
                <p className="text-xs text-gray-400 mt-0.5">Qo'shildi: {formatDate(cat.createdAt)}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>{editCategory ? "Kategoriyani tahrirlash" : "Yangi kategoriya"}</DialogTitle>
            <DialogDescription>Kategoriya ma'lumotlarini to'ldiring</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Nomi (UZ) *</label>
              <Input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="Kategoriya nomi" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Nomi (RU)</label>
              <Input value={form.nameRu} onChange={e => setForm(f => ({ ...f, nameRu: e.target.value }))} placeholder="Название" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Emoji icon</label>
                <Input value={form.icon} onChange={e => setForm(f => ({ ...f, icon: e.target.value }))} placeholder="🍎" />
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Rang</label>
                <div className="flex gap-2">
                  <input
                    type="color"
                    value={form.color}
                    onChange={e => setForm(f => ({ ...f, color: e.target.value }))}
                    className="w-10 h-10 rounded-lg cursor-pointer border border-gray-200"
                  />
                  <Input value={form.color} onChange={e => setForm(f => ({ ...f, color: e.target.value }))} placeholder="#16a34a" />
                </div>
              </div>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Tartib raqami</label>
              <Input
                type="number"
                value={String(form.sortOrder)}
                onChange={e => setForm(f => ({ ...f, sortOrder: parseInt(e.target.value) || 0 }))}
                placeholder="0"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Tavsif</label>
              <textarea
                className="w-full rounded-xl border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#16a34a] resize-none"
                rows={3}
                value={form.description}
                onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Kategoriya tavsifi..."
              />
            </div>
          </div>
          <DialogFooter className="mt-2 gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Bekor</Button>
            <Button onClick={handleSave} disabled={saving || !form.name}>
              {saving ? <RefreshCw size={14} className="animate-spin" /> : null}
              {editCategory ? "Saqlash" : "Yaratish"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}
