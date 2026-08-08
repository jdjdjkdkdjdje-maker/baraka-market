"use client";
import { useState } from "react";
import { Menu, Bell, Search, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

interface HeaderProps {
  onMenuClick: () => void;
  title: string;
  subtitle?: string;
}

export default function Header({ onMenuClick, title, subtitle }: HeaderProps) {
  const [seeding, setSeeding] = useState(false);
  const [seedMsg, setSeedMsg] = useState("");

  const handleSeed = async () => {
    if (!confirm("Ma'lumotlar bazasini test ma'lumotlar bilan to'ldirish uchun \"OK\" tugmasini bosing. Bu mavjud ma'lumotlarni o'chiradi!")) return;
    setSeeding(true);
    setSeedMsg("");
    try {
      const res = await fetch("/api/seed", { method: "POST" });
      const data = await res.json();
      if (data.success) {
        setSeedMsg("✅ Muvaffaqiyatli! Sahifani yangilang.");
        setTimeout(() => window.location.reload(), 1500);
      } else {
        setSeedMsg("❌ Xato: " + data.error);
      }
    } catch {
      setSeedMsg("❌ Server xatosi");
    } finally {
      setSeeding(false);
    }
  };

  return (
    <header className="sticky top-0 z-30 bg-white/80 backdrop-blur-xl border-b border-gray-100 px-6 py-4">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <button
            onClick={onMenuClick}
            className="lg:hidden p-2 rounded-xl hover:bg-gray-100 text-gray-500 transition-colors"
          >
            <Menu size={20} />
          </button>
          <div>
            <h1 className="text-xl font-bold text-gray-900">{title}</h1>
            {subtitle && <p className="text-xs text-gray-500 mt-0.5">{subtitle}</p>}
          </div>
        </div>

        <div className="flex items-center gap-3">
          {/* Seed button for demo */}
          <div className="flex items-center gap-2">
            {seedMsg && <span className="text-xs text-gray-600">{seedMsg}</span>}
            <Button
              variant="outline"
              size="sm"
              onClick={handleSeed}
              disabled={seeding}
              className="hidden sm:flex gap-1.5"
            >
              <RefreshCw size={14} className={seeding ? "animate-spin" : ""} />
              {seeding ? "Yuklanyapti..." : "Demo Data"}
            </Button>
          </div>

          {/* Notifications */}
          <button className="relative p-2.5 rounded-xl hover:bg-gray-100 text-gray-500 transition-colors">
            <Bell size={20} />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full ring-2 ring-white"></span>
          </button>

          {/* Admin Avatar */}
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 bg-gradient-to-br from-[#16a34a] to-[#059669] rounded-xl flex items-center justify-center shadow-md shadow-green-200 cursor-pointer">
              <span className="text-white text-sm font-bold">A</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
