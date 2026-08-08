"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Activity, ChevronLeft, ChevronRight } from "lucide-react";
import { formatDateTime } from "@/lib/utils";

interface Log {
  id: number;
  type: string;
  module: string;
  description: string;
  metadata?: Record<string, unknown>;
  ip_address?: string;
  created_at: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  role?: string;
}

const TYPE_COLORS: Record<string, string> = {
  create: "bg-green-100 text-green-700",
  update: "bg-blue-100 text-blue-700",
  delete: "bg-red-100 text-red-700",
  login: "bg-purple-100 text-purple-700",
  logout: "bg-gray-100 text-gray-700",
  view: "bg-yellow-100 text-yellow-700",
};

const TYPE_ICONS: Record<string, string> = {
  create: "➕", update: "✏️", delete: "🗑️", login: "🔐", logout: "🚪", view: "👁️",
};

export default function ActivityLogsPage() {
  const [logs, setLogs] = useState<Log[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);

  const fetchLogs = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: String(page), limit: "30" });
      const res = await fetch(`/api/activity-logs?${params}`);
      const data = await res.json();
      setLogs(data.logs ?? []);
      setTotal(data.total ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => { fetchLogs(); }, [fetchLogs]);

  return (
    <AdminLayout title="Faollik jurnali" subtitle={`${total} ta yozuv`}>
      <Card>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <div className="w-10 h-10 border-4 border-[#16a34a] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : logs.length === 0 ? (
            <div className="text-center py-16">
              <Activity size={40} className="text-gray-200 mx-auto mb-3" />
              <p className="text-gray-400">Jurnal yozuvlari topilmadi</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-50">
              {logs.map(log => (
                <div key={log.id} className="flex items-start gap-4 px-6 py-4 hover:bg-gray-50/50 transition-colors">
                  {/* User Avatar */}
                  <Avatar className="w-9 h-9 shrink-0 mt-0.5">
                    <AvatarFallback className="text-sm">
                      {log.first_name?.[0] ?? "S"}{log.last_name?.[0] ?? ""}
                    </AvatarFallback>
                  </Avatar>

                  {/* Log Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center flex-wrap gap-2 mb-1">
                      <span className="text-sm font-semibold text-gray-900">
                        {log.first_name} {log.last_name ?? "Sistema"}
                      </span>
                      {log.role && (
                        <span className="text-xs text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">
                          {log.role}
                        </span>
                      )}
                      <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${TYPE_COLORS[log.type] ?? "bg-gray-100 text-gray-600"}`}>
                        {TYPE_ICONS[log.type] ?? ""} {log.type}
                      </span>
                      <span className="text-xs text-gray-400 bg-gray-50 px-2 py-0.5 rounded-full">
                        {log.module}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600">{log.description}</p>
                    <div className="flex items-center gap-3 mt-1">
                      <p className="text-xs text-gray-400">{formatDateTime(log.created_at)}</p>
                      {log.ip_address && (
                        <p className="text-xs text-gray-400 font-mono">IP: {log.ip_address}</p>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-gray-500">{total} ta yozuv</p>
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
