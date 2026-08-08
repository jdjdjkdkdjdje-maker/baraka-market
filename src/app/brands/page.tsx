"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Search, Plus, Edit2, Trash2, Award, RefreshCw, Package, Globe } from "lucide-react";
import { formatDate } from "@/lib/utils";

interface Brand {
  id: number;
  name: string;
  slug: string;
  description?: string;
  logo?: string;
  website?: string;
  country?: string;
  isActive: boolean;
  sortOrder: number;
  createdAt: string;
  productCount: number;
}

const EMPTY_FORM = { name: "", description: "", logo: "", website: "", country: "" };

export default function BrandsPage() {
  const [brands, setBrands] = useState<Brand[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editBrand, setEditBrand] = useState<Brand | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);

  const fetchBrands = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams(search ? { search } : {});
      const res = await fetch(`/api/brands?${params}`);
      const data = await res.json();
      setBrands(data.brands ?? []);
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => { fetchBrands(); }, [fetchBrands]);

  const openCreate = () => {
    setEditBrand(null);
    setForm(EMPTY_FORM);
    setDialogOpen(true);
  };

  const openEdit = (brand: Brand) => {
    setEditBrand(brand);
    setForm({ name: brand.name, description: brand.description ?? "", logo: brand.logo ?? "", website: brand.website ?? "", country: brand.country ?? "" });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const method = editBrand ? "PUT" : "POST";
      const url = editBrand ? `/api/brands/${editBrand.id}` : "/api/brands";
      await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      setDialogOpen(false);
      fetchBrands();
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Brendni o'chirishni tasdiqlaysizmi?")) return;
    await fetch(`/api/brands/${id}`, { method: "DELETE" });
    fetchBrands();
  };

  return (
    <AdminLayout title="Brendlar" subtitle={`${brands.length} ta brend`}>
      <div className="flex gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Brend nomi..."
            className="pl-9"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <Button onClick={openCreate}><Plus size={16} />Yangi brend</Button>
      </div>

      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="rounded-2xl border border-gray-100 bg-white p-5 animate-pulse">
              <div className="w-full h-20 bg-gray-100 rounded-xl mb-3" />
              <div className="h-4 bg-gray-100 rounded w-2/3 mb-2" />
              <div className="h-3 bg-gray-100 rounded w-1/3" />
            </div>
          ))}
        </div>
      ) : brands.length === 0 ? (
        <Card><CardContent className="py-20 text-center">
          <Award size={48} className="text-gray-200 mx-auto mb-4" />
          <p className="text-gray-400">Brendlar topilmadi</p>
        </CardContent></Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {brands.map(brand => (
            <div key={brand.id} className="rounded-2xl border border-gray-100 bg-white p-5 hover:shadow-lg transition-all duration-300 hover:-translate-y-0.5 group">
              {/* Logo */}
              <div className="h-20 bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl flex items-center justify-center mb-4 overflow-hidden">
                {brand.logo ? (
                  <img src={brand.logo} alt={brand.name} className="max-h-16 max-w-full object-contain" />
                ) : (
                  <div className="text-3xl font-black text-gray-200">{brand.name[0]}</div>
                )}
              </div>

              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-bold text-gray-900">{brand.name}</h3>
                  {brand.country && (
                    <p className="text-xs text-gray-400 flex items-center gap-1 mt-0.5">
                      <Globe size={10} /> {brand.country}
                    </p>
                  )}
                </div>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(brand)} className="p-1.5 rounded-lg hover:bg-gray-100">
                    <Edit2 size={13} className="text-gray-500" />
                  </button>
                  <button onClick={() => handleDelete(brand.id)} className="p-1.5 rounded-lg hover:bg-red-50">
                    <Trash2 size={13} className="text-red-400" />
                  </button>
                </div>
              </div>

              <div className="mt-3 pt-3 border-t border-gray-50 flex items-center justify-between">
                <div className="flex items-center gap-1 text-sm">
                  <Package size={13} className="text-gray-400" />
                  <span className="font-semibold text-gray-900">{brand.productCount}</span>
                  <span className="text-gray-400 text-xs">mahsulot</span>
                </div>
                <span className={`px-2 py-0.5 rounded-lg text-xs font-medium ${brand.isActive ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-600"}`}>
                  {brand.isActive ? "Faol" : "Nofaol"}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>{editBrand ? "Brendni tahrirlash" : "Yangi brend"}</DialogTitle>
            <DialogDescription>Brend ma'lumotlarini kiriting</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Nomi *</label>
              <Input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="Brend nomi" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Mamlakat</label>
              <Input value={form.country} onChange={e => setForm(f => ({ ...f, country: e.target.value }))} placeholder="Uzbekistan" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Veb-sayt</label>
              <Input value={form.website} onChange={e => setForm(f => ({ ...f, website: e.target.value }))} placeholder="https://example.com" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Logo URL</label>
              <Input value={form.logo} onChange={e => setForm(f => ({ ...f, logo: e.target.value }))} placeholder="https://..." />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Tavsif</label>
              <textarea
                className="w-full rounded-xl border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#16a34a] resize-none"
                rows={2}
                value={form.description}
                onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Brend haqida..."
              />
            </div>
          </div>
          <DialogFooter className="mt-2 gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Bekor</Button>
            <Button onClick={handleSave} disabled={saving || !form.name}>
              {saving ? <RefreshCw size={14} className="animate-spin" /> : null}
              {editBrand ? "Saqlash" : "Yaratish"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}
