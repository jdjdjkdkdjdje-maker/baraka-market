"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import {
  Search, Users, Edit2, Trash2, ChevronLeft, ChevronRight,
  Phone, Mail, Star, ShoppingCart, Wallet, Crown,
} from "lucide-react";
import { formatCurrency, formatDate, formatTimeAgo } from "@/lib/utils";

interface User {
  id: number;
  phone: string;
  email?: string;
  firstName?: string;
  lastName?: string;
  avatar?: string;
  role: string;
  isActive: boolean;
  isVerified: boolean;
  bonusPoints: number;
  walletBalance: number;
  language?: string;
  lastLoginAt?: string;
  createdAt: string;
  orderCount: number;
  totalSpent: number;
}

const ROLE_COLORS: Record<string, string> = {
  super_admin: "bg-red-100 text-red-800 border-red-200",
  admin: "bg-purple-100 text-purple-800 border-purple-200",
  manager: "bg-blue-100 text-blue-800 border-blue-200",
  courier: "bg-orange-100 text-orange-800 border-orange-200",
  customer: "bg-green-100 text-green-800 border-green-200",
};

const ROLE_LABELS: Record<string, string> = {
  super_admin: "Super Admin",
  admin: "Admin",
  manager: "Manager",
  courier: "Kuryer",
  customer: "Mijoz",
};

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("");
  const [isActiveFilter, setIsActiveFilter] = useState("");

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: String(page),
        limit: "15",
        ...(search && { search }),
        ...(roleFilter && { role: roleFilter }),
        ...(isActiveFilter && { isActive: isActiveFilter }),
      });
      const res = await fetch(`/api/users?${params}`);
      const data = await res.json();
      setUsers(data.users ?? []);
      setTotal(data.total ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } finally {
      setLoading(false);
    }
  }, [page, search, roleFilter, isActiveFilter]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const toggleActive = async (userId: number, isActive: boolean) => {
    await fetch(`/api/users/${userId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: !isActive }),
    });
    fetchUsers();
  };

  const deleteUser = async (userId: number) => {
    if (!confirm("Foydalanuvchini o'chirishni tasdiqlaysizmi?")) return;
    await fetch(`/api/users/${userId}`, { method: "DELETE" });
    fetchUsers();
  };

  return (
    <AdminLayout title="Foydalanuvchilar" subtitle={`Jami ${total} ta foydalanuvchi`}>
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Ism, telefon, email..."
            className="pl-9"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <Select value={roleFilter} onValueChange={v => { setRoleFilter(v === "all" ? "" : v); setPage(1); }}>
          <SelectTrigger className="w-full sm:w-44">
            <SelectValue placeholder="Rol" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Barcha rollar</SelectItem>
            <SelectItem value="super_admin">Super Admin</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
            <SelectItem value="manager">Manager</SelectItem>
            <SelectItem value="courier">Kuryer</SelectItem>
            <SelectItem value="customer">Mijoz</SelectItem>
          </SelectContent>
        </Select>
        <Select value={isActiveFilter} onValueChange={v => { setIsActiveFilter(v === "all" ? "" : v); setPage(1); }}>
          <SelectTrigger className="w-full sm:w-44">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Barchasi</SelectItem>
            <SelectItem value="true">Faol</SelectItem>
            <SelectItem value="false">Bloklangan</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {[
          { label: "Jami mijozlar", value: total, icon: <Users size={20} />, color: "bg-blue-500" },
          { label: "Faol foydalanuvchilar", value: users.filter(u => u.isActive).length, icon: <Star size={20} />, color: "bg-green-500" },
          { label: "Bloklangan", value: users.filter(u => !u.isActive).length, icon: <Users size={20} />, color: "bg-red-500" },
          { label: "Bu sahifadagi", value: users.length, icon: <Users size={20} />, color: "bg-purple-500" },
        ].map(s => (
          <div key={s.label} className="rounded-2xl border border-gray-100 bg-white p-4 flex items-center gap-3">
            <div className={`w-10 h-10 ${s.color} rounded-xl flex items-center justify-center text-white shadow-sm`}>
              {s.icon}
            </div>
            <div>
              <p className="text-xl font-bold text-gray-900">{s.value}</p>
              <p className="text-xs text-gray-500">{s.label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Users Table */}
      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="w-10 h-10 border-4 border-[#16a34a] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : users.length === 0 ? (
            <div className="text-center py-20">
              <Users size={48} className="text-gray-200 mx-auto mb-4" />
              <p className="text-gray-400 font-medium">Foydalanuvchilar topilmadi</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-50">
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-6 py-4">Foydalanuvchi</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Rol</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Buyurtmalar</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Hamyon</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Bonus</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Status</th>
                    <th className="text-left text-xs font-semibold text-gray-400 uppercase tracking-wider px-4 py-4">Qo'shilgan</th>
                    <th className="px-4 py-4"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {users.map(user => (
                    <tr key={user.id} className="hover:bg-gray-50/50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <Avatar className="w-9 h-9">
                            <AvatarFallback className="text-sm">
                              {user.firstName?.[0] ?? user.phone[1]}
                              {user.lastName?.[0] ?? ""}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="text-sm font-semibold text-gray-900">
                              {user.firstName} {user.lastName}
                              {!user.firstName && <span className="text-gray-400">Noma'lum</span>}
                            </p>
                            <p className="text-xs text-gray-400 flex items-center gap-1">
                              <Phone size={10} /> {user.phone}
                            </p>
                            {user.email && (
                              <p className="text-xs text-gray-400 flex items-center gap-1">
                                <Mail size={10} /> {user.email}
                              </p>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold border ${ROLE_COLORS[user.role] ?? "bg-gray-100 text-gray-700"}`}>
                          {user.role === "super_admin" && <Crown size={10} />}
                          {ROLE_LABELS[user.role] ?? user.role}
                        </span>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1.5">
                          <ShoppingCart size={14} className="text-gray-400" />
                          <span className="text-sm font-medium text-gray-900">{user.orderCount}</span>
                          {user.totalSpent > 0 && (
                            <span className="text-xs text-gray-400">· {formatCurrency(user.totalSpent)}</span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1">
                          <Wallet size={14} className="text-green-500" />
                          <span className="text-sm font-medium text-gray-900">{formatCurrency(user.walletBalance ?? 0)}</span>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1">
                          <Star size={14} className="text-yellow-500" />
                          <span className="text-sm font-medium text-gray-900">{user.bonusPoints?.toLocaleString()} ball</span>
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <button
                          onClick={() => toggleActive(user.id, user.isActive)}
                          className={`px-3 py-1 rounded-full text-xs font-semibold border transition-colors ${
                            user.isActive
                              ? "bg-green-100 text-green-700 border-green-200 hover:bg-green-200"
                              : "bg-red-100 text-red-700 border-red-200 hover:bg-red-200"
                          }`}
                        >
                          {user.isActive ? "Faol" : "Bloklangan"}
                        </button>
                      </td>
                      <td className="px-4 py-4">
                        <p className="text-xs text-gray-500">{formatDate(user.createdAt)}</p>
                      </td>
                      <td className="px-4 py-4">
                        <Button
                          variant="ghost"
                          size="icon-sm"
                          onClick={() => deleteUser(user.id)}
                          className="text-red-400 hover:text-red-600 hover:bg-red-50"
                        >
                          <Trash2 size={15} />
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-gray-500">{total} ta foydalanuvchi</p>
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
    </AdminLayout>
  );
}
