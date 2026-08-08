"use client";
import { useEffect, useState } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Truck, Star, Package, Wifi, WifiOff } from "lucide-react";

export default function CouriersPage() {
  const [couriers, setCouriers] = useState<Array<{
    id: number; user_id: number; vehicle_type: string; vehicle_number: string;
    is_online: boolean; is_available: boolean; total_deliveries: number;
    average_rating: number; first_name: string; last_name: string; phone: string;
  }>>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/couriers")
      .then(r => r.json())
      .then(data => { setCouriers(data.couriers ?? []); setLoading(false); });
  }, []);

  return (
    <AdminLayout title="Kuryerlar" subtitle={`${couriers.length} ta kuryer`}>
      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="rounded-2xl border bg-white p-5 animate-pulse h-40" />
          ))}
        </div>
      ) : couriers.length === 0 ? (
        <Card><CardContent className="py-20 text-center">
          <Truck size={48} className="text-gray-200 mx-auto mb-4" />
          <p className="text-gray-400 font-medium">Kuryerlar topilmadi</p>
          <p className="text-gray-300 text-sm">Demo Data tugmasini bosing</p>
        </CardContent></Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {couriers.map(courier => (
            <div key={courier.id} className="rounded-2xl border border-gray-100 bg-white p-5 hover:shadow-lg transition-all">
              <div className="flex items-center gap-3 mb-4">
                <Avatar className="w-12 h-12">
                  <AvatarFallback className="text-lg">
                    {courier.first_name?.[0]}{courier.last_name?.[0]}
                  </AvatarFallback>
                </Avatar>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-gray-900">{courier.first_name} {courier.last_name}</h3>
                    <div className={`w-2.5 h-2.5 rounded-full ${courier.is_online ? "bg-green-500" : "bg-gray-300"}`} />
                  </div>
                  <p className="text-sm text-gray-500">{courier.phone}</p>
                </div>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500 flex items-center gap-1.5">
                    <Truck size={14} /> Transport:
                  </span>
                  <span className="font-medium text-gray-900">
                    {courier.vehicle_type} {courier.vehicle_number && `· ${courier.vehicle_number}`}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500 flex items-center gap-1.5">
                    <Package size={14} /> Yetkazmalar:
                  </span>
                  <span className="font-medium text-gray-900">{courier.total_deliveries}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500 flex items-center gap-1.5">
                    <Star size={14} /> Reyting:
                  </span>
                  <span className="font-medium text-yellow-600">⭐ {courier.average_rating?.toFixed(1)}</span>
                </div>
              </div>
              <div className="mt-4 pt-3 border-t border-gray-50 flex items-center justify-between">
                <span className={`flex items-center gap-1.5 text-sm font-medium px-3 py-1 rounded-full ${courier.is_online ? "bg-green-100 text-green-700" : "bg-gray-100 text-gray-500"}`}>
                  {courier.is_online ? <Wifi size={13} /> : <WifiOff size={13} />}
                  {courier.is_online ? "Onlayn" : "Offlayn"}
                </span>
                <span className={`text-sm font-medium px-3 py-1 rounded-full ${courier.is_available ? "bg-blue-100 text-blue-700" : "bg-orange-100 text-orange-700"}`}>
                  {courier.is_available ? "Bo'sh" : "Band"}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </AdminLayout>
  );
}
