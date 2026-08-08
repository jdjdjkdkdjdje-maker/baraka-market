"use client";
import { useState } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import {
  Settings, Store, Truck, CreditCard, Bell, Shield, Globe, CheckCircle
} from "lucide-react";

export default function SettingsPage() {
  const [saved, setSaved] = useState(false);
  const [generalForm, setGeneralForm] = useState({
    siteName: "Baraka Market",
    sitePhone: "+998 71 200 20 20",
    siteEmail: "info@barakamarket.uz",
    siteAddress: "Toshkent sh., Chilonzor tumani",
    workingHours: "09:00 - 23:00",
  });
  const [deliveryForm, setDeliveryForm] = useState({
    deliveryFee: "15000",
    freeThreshold: "200000",
    minOrderAmount: "30000",
    maxDeliveryRadius: "30",
    estimatedTime: "60",
  });
  const [bonusForm, setBonusForm] = useState({
    bonusRate: "1",
    pointsPerSum: "100",
    minRedeemPoints: "500",
    expiryDays: "365",
  });

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <AdminLayout title="Sozlamalar" subtitle="Tizim sozlamalari va konfiguratsiyalari">
      <Tabs defaultValue="general">
        <TabsList className="mb-6">
          <TabsTrigger value="general" className="gap-2"><Store size={14} />Umumiy</TabsTrigger>
          <TabsTrigger value="delivery" className="gap-2"><Truck size={14} />Yetkazib berish</TabsTrigger>
          <TabsTrigger value="bonus" className="gap-2"><CreditCard size={14} />Bonus</TabsTrigger>
          <TabsTrigger value="notifications" className="gap-2"><Bell size={14} />Bildirishnomalar</TabsTrigger>
          <TabsTrigger value="security" className="gap-2"><Shield size={14} />Xavfsizlik</TabsTrigger>
        </TabsList>

        {/* General */}
        <TabsContent value="general">
          <Card>
            <CardHeader>
              <CardTitle>Umumiy sozlamalar</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Sayt nomi</label>
                  <Input value={generalForm.siteName} onChange={e => setGeneralForm(f => ({ ...f, siteName: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Telefon raqam</label>
                  <Input value={generalForm.sitePhone} onChange={e => setGeneralForm(f => ({ ...f, sitePhone: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Email</label>
                  <Input type="email" value={generalForm.siteEmail} onChange={e => setGeneralForm(f => ({ ...f, siteEmail: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Manzil</label>
                  <Input value={generalForm.siteAddress} onChange={e => setGeneralForm(f => ({ ...f, siteAddress: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Ish vaqti</label>
                  <Input value={generalForm.workingHours} onChange={e => setGeneralForm(f => ({ ...f, workingHours: e.target.value }))} />
                </div>
              </div>
              <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                {saved && (
                  <div className="flex items-center gap-2 text-green-600 text-sm font-medium">
                    <CheckCircle size={16} />
                    Saqlandi!
                  </div>
                )}
                <Button onClick={handleSave} className="ml-auto">Saqlash</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Delivery */}
        <TabsContent value="delivery">
          <Card>
            <CardHeader>
              <CardTitle>Yetkazib berish sozlamalari</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Yetkazib berish narxi (UZS)</label>
                  <Input type="number" value={deliveryForm.deliveryFee} onChange={e => setDeliveryForm(f => ({ ...f, deliveryFee: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Bepul yetkazish chegarasi (UZS)</label>
                  <Input type="number" value={deliveryForm.freeThreshold} onChange={e => setDeliveryForm(f => ({ ...f, freeThreshold: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Minimal buyurtma (UZS)</label>
                  <Input type="number" value={deliveryForm.minOrderAmount} onChange={e => setDeliveryForm(f => ({ ...f, minOrderAmount: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Taxminiy vaqt (daqiqa)</label>
                  <Input type="number" value={deliveryForm.estimatedTime} onChange={e => setDeliveryForm(f => ({ ...f, estimatedTime: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Maksimal radius (km)</label>
                  <Input type="number" value={deliveryForm.maxDeliveryRadius} onChange={e => setDeliveryForm(f => ({ ...f, maxDeliveryRadius: e.target.value }))} />
                </div>
              </div>
              <div className="flex justify-end pt-4 border-t border-gray-100">
                <Button onClick={handleSave}>Saqlash</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Bonus */}
        <TabsContent value="bonus">
          <Card>
            <CardHeader>
              <CardTitle>Bonus ball tizimi</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="bg-green-50 border border-green-100 rounded-xl p-4 text-sm text-green-700">
                💡 Har {bonusForm.pointsPerSum} UZS sarflash uchun {bonusForm.bonusRate} ball beriladi
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Ball koeffitsienti</label>
                  <Input type="number" value={bonusForm.bonusRate} onChange={e => setBonusForm(f => ({ ...f, bonusRate: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Har necha UZS uchun</label>
                  <Input type="number" value={bonusForm.pointsPerSum} onChange={e => setBonusForm(f => ({ ...f, pointsPerSum: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Minimal yechish (ball)</label>
                  <Input type="number" value={bonusForm.minRedeemPoints} onChange={e => setBonusForm(f => ({ ...f, minRedeemPoints: e.target.value }))} />
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-700 mb-1.5 block">Amal qilish muddati (kun)</label>
                  <Input type="number" value={bonusForm.expiryDays} onChange={e => setBonusForm(f => ({ ...f, expiryDays: e.target.value }))} />
                </div>
              </div>
              <div className="flex justify-end pt-4 border-t border-gray-100">
                <Button onClick={handleSave}>Saqlash</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Notifications */}
        <TabsContent value="notifications">
          <Card>
            <CardHeader><CardTitle>Bildirishnoma sozlamalari</CardTitle></CardHeader>
            <CardContent>
              <div className="space-y-4">
                {[
                  { label: "Yangi buyurtma kelganda xabarlash", enabled: true },
                  { label: "Buyurtma holati o'zgarganda mijozga xabarlash", enabled: true },
                  { label: "Kam qolgan mahsulotlar haqida xabarlash", enabled: true },
                  { label: "Yangi sharh kelganda xabarlash", enabled: false },
                  { label: "Kupon muddati tugashidan 1 kun oldin xabarlash", enabled: true },
                ].map(item => (
                  <div key={item.label} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                    <span className="text-sm text-gray-700">{item.label}</span>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" defaultChecked={item.enabled} className="sr-only peer" />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#16a34a]"></div>
                    </label>
                  </div>
                ))}
              </div>
              <div className="flex justify-end mt-4">
                <Button onClick={handleSave}>Saqlash</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Security */}
        <TabsContent value="security">
          <Card>
            <CardHeader><CardTitle>Xavfsizlik sozlamalari</CardTitle></CardHeader>
            <CardContent>
              <div className="space-y-4">
                {[
                  { label: "Ikki faktorli autentifikatsiya (2FA)", enabled: false },
                  { label: "IP asosida kirish cheklovi", enabled: false },
                  { label: "Faolsiz sessiyalarni avtomatik yopish (30 daqiqa)", enabled: true },
                  { label: "Admin kirishlarini jurnal qilish", enabled: true },
                  { label: "Shubhali faollik haqida xabarlash", enabled: true },
                ].map(item => (
                  <div key={item.label} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                    <span className="text-sm text-gray-700">{item.label}</span>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" defaultChecked={item.enabled} className="sr-only peer" />
                      <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#16a34a]"></div>
                    </label>
                  </div>
                ))}
              </div>
              <div className="flex justify-end mt-4">
                <Button onClick={handleSave}>Saqlash</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </AdminLayout>
  );
}
