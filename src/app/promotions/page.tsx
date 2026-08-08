"use client";
import { useEffect, useState } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Percent } from "lucide-react";
import { formatCurrency, formatDate } from "@/lib/utils";

export default function PromotionsPage() {
  return (
    <AdminLayout title="Aksiyalar" subtitle="Mahsulot aksiyalari va chegirmalari">
      <Card>
        <CardContent className="py-20 text-center">
          <Percent size={48} className="text-gray-200 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-400">Aksiyalar moduli</h3>
          <p className="text-gray-300 text-sm mt-2">Bu bo'lim tez orada ishga tushiriladi</p>
          <div className="mt-6 grid grid-cols-1 sm:grid-cols-3 gap-4 max-w-md mx-auto text-left">
            {[
              { emoji: "🏷️", title: "Flash Sale", desc: "Cheklangan vaqtli chegirmalar" },
              { emoji: "🎁", title: "Bundle", desc: "To'plamli sotish" },
              { emoji: "💰", title: "Cashback", desc: "Qaytarib berish aksiyasi" },
            ].map(item => (
              <div key={item.title} className="bg-gray-50 rounded-2xl p-4 text-center">
                <div className="text-2xl mb-2">{item.emoji}</div>
                <p className="text-sm font-semibold text-gray-700">{item.title}</p>
                <p className="text-xs text-gray-400 mt-1">{item.desc}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </AdminLayout>
  );
}
