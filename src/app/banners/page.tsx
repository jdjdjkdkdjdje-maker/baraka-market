"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Plus, Edit2, Trash2, Image, RefreshCw, Eye, EyeOff } from "lucide-react";
import { formatDate } from "@/lib/utils";

interface Banner {
  id: number;
  title: string;
  titleRu?: string;
  subtitle?: string;
  image: string;
  link?: string;
  type: string;
  sortOrder: number;
  isActive: boolean;
  startsAt?: string;
  endsAt?: string;
  createdAt: string;
}

const TYPE_LABELS: Record<string, string> = {
  main: "Asosiy", category: "Kategoriya", promo: "Aksiya", brand: "Brend",
};

const EMPTY_FORM = {
  title: "", titleRu: "", subtitle: "", image: "", link: "",
  type: "main", sortOrder: 0, isActive: true, startsAt: "", endsAt: "",
};

export default function BannersPage() {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editBanner, setEditBanner] = useState<Banner | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);

  const fetchBanners = useCallback(async () => {
    setLoading(true);
    const res = await fetch("/api/banners");
    const data = await res.json();
    setBanners(data.banners ?? []);
    setLoading(false);
  }, []);

  useEffect(() => { fetchBanners(); }, [fetchBanners]);

  const openCreate = () => {
    setEditBanner(null);
    setForm(EMPTY_FORM);
    setDialogOpen(true);
  };

  const openEdit = (banner: Banner) => {
    setEditBanner(banner);
    setForm({
      title: banner.title, titleRu: banner.titleRu ?? "", subtitle: banner.subtitle ?? "",
      image: banner.image, link: banner.link ?? "", type: banner.type,
      sortOrder: banner.sortOrder, isActive: banner.isActive,
      startsAt: banner.startsAt ? banner.startsAt.slice(0, 16) : "",
      endsAt: banner.endsAt ? banner.endsAt.slice(0, 16) : "",
    });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const method = editBanner ? "PUT" : "POST";
      const url = editBanner ? `/api/banners/${editBanner.id}` : "/api/banners";
      await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      setDialogOpen(false);
      fetchBanners();
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Bannerni o'chirish?")) return;
    await fetch(`/api/banners/${id}`, { method: "DELETE" });
    fetchBanners();
  };

  const toggleActive = async (banner: Banner) => {
    await fetch(`/api/banners/${banner.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: !banner.isActive }),
    });
    fetchBanners();
  };

  return (
    <AdminLayout title="Bannerlar" subtitle={`${banners.length} ta banner`}>
      <div className="flex justify-between items-center mb-6">
        <div className="flex gap-2">
          {Object.entries(TYPE_LABELS).map(([key, label]) => (
            <span key={key} className="px-3 py-1 text-xs font-medium bg-gray-100 text-gray-600 rounded-full">
              {label}: {banners.filter(b => b.type === key).length}
            </span>
          ))}
        </div>
        <Button onClick={openCreate}><Plus size={16} />Yangi banner</Button>
      </div>

      {loading ? (
        <div className="space-y-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="rounded-2xl border bg-white h-32 animate-pulse" />
          ))}
        </div>
      ) : banners.length === 0 ? (
        <Card><CardContent className="py-20 text-center">
          <Image size={48} className="text-gray-200 mx-auto mb-4" />
          <p className="text-gray-400">Bannerlar topilmadi</p>
        </CardContent></Card>
      ) : (
        <div className="space-y-4">
          {banners.map(banner => (
            <div key={banner.id} className={`rounded-2xl border bg-white overflow-hidden hover:shadow-lg transition-all group ${!banner.isActive ? "opacity-60" : ""}`}>
              <div className="flex">
                {/* Image Preview */}
                <div className="w-64 h-32 shrink-0 bg-gray-100 relative overflow-hidden">
                  <img
                    src={banner.image}
                    alt={banner.title}
                    className="w-full h-full object-cover"
                    onError={e => { e.currentTarget.src = "https://placehold.co/300x150/e5e7eb/9ca3af?text=Banner"; }}
                  />
                  <div className="absolute top-2 left-2">
                    <span className="bg-black/60 text-white text-xs px-2 py-0.5 rounded-lg backdrop-blur-sm">
                      {TYPE_LABELS[banner.type] ?? banner.type}
                    </span>
                  </div>
                </div>

                {/* Content */}
                <div className="flex-1 p-5 flex items-center justify-between">
                  <div>
                    <h3 className="font-bold text-gray-900 text-lg">{banner.title}</h3>
                    {banner.titleRu && <p className="text-sm text-gray-400">{banner.titleRu}</p>}
                    {banner.subtitle && <p className="text-sm text-gray-600 mt-1">{banner.subtitle}</p>}
                    <div className="flex items-center gap-4 mt-2">
                      {banner.link && (
                        <p className="text-xs text-blue-500 truncate max-w-xs">🔗 {banner.link}</p>
                      )}
                      <p className="text-xs text-gray-400">Tartib: #{banner.sortOrder}</p>
                      {banner.endsAt && (
                        <p className="text-xs text-gray-400">Muddat: {formatDate(banner.endsAt)}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <button
                      onClick={() => toggleActive(banner)}
                      className={`p-2 rounded-xl transition-colors ${banner.isActive ? "bg-green-100 text-green-600 hover:bg-green-200" : "bg-gray-100 text-gray-500 hover:bg-gray-200"}`}
                    >
                      {banner.isActive ? <Eye size={16} /> : <EyeOff size={16} />}
                    </button>
                    <button onClick={() => openEdit(banner)} className="p-2 rounded-xl hover:bg-gray-100">
                      <Edit2 size={16} className="text-gray-500" />
                    </button>
                    <button onClick={() => handleDelete(banner.id)} className="p-2 rounded-xl hover:bg-red-50">
                      <Trash2 size={16} className="text-red-400" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editBanner ? "Bannerni tahrirlash" : "Yangi banner"}</DialogTitle>
            <DialogDescription>Banner ma'lumotlarini kiriting</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Sarlavha (UZ) *</label>
                <Input value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} placeholder="Banner sarlavhasi" />
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Sarlavha (RU)</label>
                <Input value={form.titleRu} onChange={e => setForm(f => ({ ...f, titleRu: e.target.value }))} placeholder="Заголовок" />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Qo'shimcha matn</label>
              <Input value={form.subtitle} onChange={e => setForm(f => ({ ...f, subtitle: e.target.value }))} placeholder="Kichik matn" />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Rasm URL *</label>
              <Input value={form.image} onChange={e => setForm(f => ({ ...f, image: e.target.value }))} placeholder="https://..." />
              {form.image && (
                <img src={form.image} alt="" className="mt-2 h-20 w-full object-cover rounded-xl" onError={e => { e.currentTarget.style.display = "none"; }} />
              )}
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Havola (URL)</label>
              <Input value={form.link} onChange={e => setForm(f => ({ ...f, link: e.target.value }))} placeholder="/products/category/1" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Turi</label>
                <Select value={form.type} onValueChange={v => setForm(f => ({ ...f, type: v }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="main">Asosiy</SelectItem>
                    <SelectItem value="category">Kategoriya</SelectItem>
                    <SelectItem value="promo">Aksiya</SelectItem>
                    <SelectItem value="brand">Brend</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Tartib</label>
                <Input type="number" value={String(form.sortOrder)} onChange={e => setForm(f => ({ ...f, sortOrder: parseInt(e.target.value) || 0 }))} />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Boshlanish</label>
                <Input type="datetime-local" value={form.startsAt} onChange={e => setForm(f => ({ ...f, startsAt: e.target.value }))} />
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Tugash</label>
                <Input type="datetime-local" value={form.endsAt} onChange={e => setForm(f => ({ ...f, endsAt: e.target.value }))} />
              </div>
            </div>
          </div>
          <DialogFooter className="mt-2 gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Bekor</Button>
            <Button onClick={handleSave} disabled={saving || !form.title || !form.image}>
              {saving ? <RefreshCw size={14} className="animate-spin" /> : null}
              {editBanner ? "Saqlash" : "Yaratish"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}
