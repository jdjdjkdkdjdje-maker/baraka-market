"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Search, Plus, Edit2, Trash2, Ticket, RefreshCw, Copy, CheckCheck } from "lucide-react";
import { formatCurrency, formatDate } from "@/lib/utils";

interface Coupon {
  id: number;
  code: string;
  name: string;
  description?: string;
  discountType: string;
  discountValue: string;
  minOrderAmount?: string;
  maxDiscountAmount?: string;
  usageLimit?: number;
  usageLimitPerUser: number;
  usedCount: number;
  isActive: boolean;
  startsAt?: string;
  endsAt?: string;
  createdAt: string;
}

const EMPTY_FORM = {
  code: "", name: "", description: "", discountType: "percentage",
  discountValue: "", minOrderAmount: "", maxDiscountAmount: "",
  usageLimit: "", usageLimitPerUser: "1", isActive: true,
  startsAt: "", endsAt: "",
};

export default function CouponsPage() {
  const [coupons, setCoupons] = useState<Coupon[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editCoupon, setEditCoupon] = useState<Coupon | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [copied, setCopied] = useState<string | null>(null);

  const fetchCoupons = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams(search ? { search } : {});
      const res = await fetch(`/api/coupons?${params}`);
      const data = await res.json();
      setCoupons(data.coupons ?? []);
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => { fetchCoupons(); }, [fetchCoupons]);

  const copyCode = (code: string) => {
    navigator.clipboard.writeText(code);
    setCopied(code);
    setTimeout(() => setCopied(null), 2000);
  };

  const openCreate = () => {
    setEditCoupon(null);
    const randomCode = "BARAKA" + Math.random().toString(36).substring(2, 6).toUpperCase();
    setForm({ ...EMPTY_FORM, code: randomCode });
    setDialogOpen(true);
  };

  const openEdit = (coupon: Coupon) => {
    setEditCoupon(coupon);
    setForm({
      code: coupon.code, name: coupon.name, description: coupon.description ?? "",
      discountType: coupon.discountType, discountValue: coupon.discountValue,
      minOrderAmount: coupon.minOrderAmount ?? "", maxDiscountAmount: coupon.maxDiscountAmount ?? "",
      usageLimit: coupon.usageLimit ? String(coupon.usageLimit) : "",
      usageLimitPerUser: String(coupon.usageLimitPerUser),
      isActive: coupon.isActive,
      startsAt: coupon.startsAt ? coupon.startsAt.slice(0, 16) : "",
      endsAt: coupon.endsAt ? coupon.endsAt.slice(0, 16) : "",
    });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const method = editCoupon ? "PUT" : "POST";
      const url = editCoupon ? `/api/coupons/${editCoupon.id}` : "/api/coupons";
      await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      setDialogOpen(false);
      fetchCoupons();
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm("Kuponni o'chirish?")) return;
    await fetch(`/api/coupons/${id}`, { method: "DELETE" });
    fetchCoupons();
  };

  return (
    <AdminLayout title="Kuponlar" subtitle={`${coupons.length} ta kupon`}>
      <div className="flex gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <Input placeholder="Kupon kodi..." className="pl-9" value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <Button onClick={openCreate}><Plus size={16} />Yangi kupon</Button>
      </div>

      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="rounded-2xl border bg-white p-5 animate-pulse h-40" />
          ))}
        </div>
      ) : coupons.length === 0 ? (
        <Card><CardContent className="py-20 text-center">
          <Ticket size={48} className="text-gray-200 mx-auto mb-4" />
          <p className="text-gray-400">Kuponlar topilmadi</p>
        </CardContent></Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {coupons.map(coupon => {
            const isExpired = coupon.endsAt && new Date(coupon.endsAt) < new Date();
            const usagePct = coupon.usageLimit ? Math.round((coupon.usedCount / coupon.usageLimit) * 100) : 0;
            return (
              <div key={coupon.id} className={`rounded-2xl border bg-white overflow-hidden hover:shadow-lg transition-all duration-300 hover:-translate-y-0.5 group ${!coupon.isActive || isExpired ? "opacity-60" : ""}`}>
                {/* Coupon Header */}
                <div className="bg-gradient-to-r from-[#16a34a] to-[#059669] p-4 text-white">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <button
                          onClick={() => copyCode(coupon.code)}
                          className="font-mono font-bold text-lg tracking-wider hover:opacity-80 flex items-center gap-1.5"
                        >
                          {coupon.code}
                          {copied === coupon.code ? <CheckCheck size={14} /> : <Copy size={14} />}
                        </button>
                      </div>
                      <p className="text-white/80 text-sm">{coupon.name}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-black">
                        {coupon.discountType === "percentage"
                          ? `${coupon.discountValue}%`
                          : formatCurrency(parseFloat(coupon.discountValue))}
                      </p>
                      <p className="text-xs text-white/70">chegirma</p>
                    </div>
                  </div>
                </div>

                {/* Coupon Body */}
                <div className="p-4">
                  <div className="space-y-1.5 mb-3">
                    {coupon.minOrderAmount && (
                      <p className="text-xs text-gray-500">
                        Min. buyurtma: <span className="font-semibold text-gray-700">{formatCurrency(parseFloat(coupon.minOrderAmount))}</span>
                      </p>
                    )}
                    {coupon.endsAt && (
                      <p className={`text-xs ${isExpired ? "text-red-500" : "text-gray-500"}`}>
                        Muddati: <span className="font-semibold">{formatDate(coupon.endsAt)}</span>
                        {isExpired && " (Tugagan)"}
                      </p>
                    )}
                    {coupon.usageLimit && (
                      <div>
                        <div className="flex justify-between text-xs text-gray-500 mb-1">
                          <span>Foydalanildi: {coupon.usedCount}/{coupon.usageLimit}</span>
                          <span>{usagePct}%</span>
                        </div>
                        <div className="h-1.5 bg-gray-100 rounded-full">
                          <div className="h-full bg-[#16a34a] rounded-full" style={{ width: `${usagePct}%` }} />
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="flex items-center justify-between pt-3 border-t border-gray-50">
                    <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                      !coupon.isActive || isExpired
                        ? "bg-gray-100 text-gray-600"
                        : "bg-green-100 text-green-700"
                    }`}>
                      {!coupon.isActive ? "Nofaol" : isExpired ? "Muddati o'tgan" : "Faol"}
                    </span>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button onClick={() => openEdit(coupon)} className="p-1.5 rounded-lg hover:bg-gray-100">
                        <Edit2 size={13} className="text-gray-500" />
                      </button>
                      <button onClick={() => handleDelete(coupon.id)} className="p-1.5 rounded-lg hover:bg-red-50">
                        <Trash2 size={13} className="text-red-400" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editCoupon ? "Kuponni tahrirlash" : "Yangi kupon yaratish"}</DialogTitle>
            <DialogDescription>Kupon ma'lumotlarini to'ldiring</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Kodi *</label>
                <Input value={form.code} onChange={e => setForm(f => ({ ...f, code: e.target.value.toUpperCase() }))} placeholder="BARAKA10" className="font-mono" />
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Chegirma turi</label>
                <Select value={form.discountType} onValueChange={v => setForm(f => ({ ...f, discountType: v }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="percentage">Foiz (%)</SelectItem>
                    <SelectItem value="fixed">Miqdor (UZS)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1.5 block">Nomi *</label>
              <Input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="10% chegirma" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Chegirma qiymati *</label>
                <Input type="number" value={form.discountValue} onChange={e => setForm(f => ({ ...f, discountValue: e.target.value }))} placeholder={form.discountType === "percentage" ? "10" : "25000"} />
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Min. buyurtma (UZS)</label>
                <Input type="number" value={form.minOrderAmount} onChange={e => setForm(f => ({ ...f, minOrderAmount: e.target.value }))} placeholder="50000" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">Foydalanish limiti</label>
                <Input type="number" value={form.usageLimit} onChange={e => setForm(f => ({ ...f, usageLimit: e.target.value }))} placeholder="100" />
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 mb-1.5 block">1 foydalanuvchi uchun</label>
                <Input type="number" value={form.usageLimitPerUser} onChange={e => setForm(f => ({ ...f, usageLimitPerUser: e.target.value }))} placeholder="1" />
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
            <label className="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" checked={form.isActive} onChange={e => setForm(f => ({ ...f, isActive: e.target.checked }))} className="w-4 h-4 accent-[#16a34a]" />
              <span className="text-sm text-gray-700">Faol</span>
            </label>
          </div>
          <DialogFooter className="mt-2 gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Bekor</Button>
            <Button onClick={handleSave} disabled={saving || !form.code || !form.name || !form.discountValue}>
              {saving ? <RefreshCw size={14} className="animate-spin" /> : null}
              {editCoupon ? "Saqlash" : "Yaratish"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  );
}
