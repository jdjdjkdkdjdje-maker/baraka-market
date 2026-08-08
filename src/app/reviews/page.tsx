"use client";
import { useEffect, useState, useCallback } from "react";
import AdminLayout from "@/components/layout/AdminLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Star, CheckCircle, XCircle, Trash2, ChevronLeft, ChevronRight } from "lucide-react";
import { formatTimeAgo } from "@/lib/utils";

interface Review {
  id: number;
  rating: number;
  comment?: string;
  is_approved: boolean;
  is_verified: boolean;
  helpful_count: number;
  created_at: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  product_name?: string;
  product_price?: number;
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [approvedFilter, setApprovedFilter] = useState("");

  const fetchReviews = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: String(page), limit: "15", ...(approvedFilter && { isApproved: approvedFilter }) });
      const res = await fetch(`/api/reviews?${params}`);
      const data = await res.json();
      setReviews(data.reviews ?? []);
      setTotal(data.total ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } finally {
      setLoading(false);
    }
  }, [page, approvedFilter]);

  useEffect(() => { fetchReviews(); }, [fetchReviews]);

  const approve = async (id: number, approved: boolean) => {
    await fetch(`/api/reviews/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isApproved: approved }),
    });
    fetchReviews();
  };

  const deleteReview = async (id: number) => {
    if (!confirm("Sharhni o'chirish?")) return;
    await fetch(`/api/reviews/${id}`, { method: "DELETE" });
    fetchReviews();
  };

  const pendingCount = reviews.filter(r => !r.is_approved).length;

  return (
    <AdminLayout title="Sharhlar" subtitle={`Jami ${total} ta sharh`}>
      <div className="flex items-center justify-between mb-6">
        <div className="flex gap-3">
          <Select value={approvedFilter} onValueChange={v => { setApprovedFilter(v === "all" ? "" : v); setPage(1); }}>
            <SelectTrigger className="w-48">
              <SelectValue placeholder="Barcha sharhlar" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Barcha sharhlar</SelectItem>
              <SelectItem value="true">Tasdiqlangan</SelectItem>
              <SelectItem value="false">Kutilayotgan</SelectItem>
            </SelectContent>
          </Select>
        </div>
        {pendingCount > 0 && (
          <div className="flex items-center gap-2 bg-yellow-50 border border-yellow-200 text-yellow-700 px-3 py-1.5 rounded-xl text-sm font-medium">
            <span>⏳ {pendingCount} ta sharh kutilmoqda</span>
          </div>
        )}
      </div>

      {loading ? (
        <div className="space-y-4">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="rounded-2xl border bg-white p-5 animate-pulse h-28" />
          ))}
        </div>
      ) : reviews.length === 0 ? (
        <Card><CardContent className="py-20 text-center">
          <Star size={48} className="text-gray-200 mx-auto mb-4" />
          <p className="text-gray-400">Sharhlar topilmadi</p>
        </CardContent></Card>
      ) : (
        <div className="space-y-3">
          {reviews.map(review => (
            <div key={review.id} className={`rounded-2xl border bg-white p-5 hover:shadow-md transition-shadow ${!review.is_approved ? "border-yellow-200 bg-yellow-50/30" : ""}`}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3 flex-1">
                  <Avatar className="w-10 h-10 shrink-0">
                    <AvatarFallback className="text-sm">
                      {review.first_name?.[0] ?? "U"}{review.last_name?.[0] ?? ""}
                    </AvatarFallback>
                  </Avatar>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center flex-wrap gap-2 mb-1">
                      <span className="font-semibold text-gray-900 text-sm">
                        {review.first_name} {review.last_name}
                      </span>
                      <span className="text-xs text-gray-400">{review.phone}</span>
                      {review.is_verified && (
                        <span className="text-xs text-green-600 bg-green-50 px-1.5 py-0.5 rounded-full">✓ Tasdiqlangan xaridor</span>
                      )}
                    </div>
                    <div className="flex items-center gap-1 mb-2">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star
                          key={i}
                          size={14}
                          className={i < review.rating ? "text-yellow-400 fill-yellow-400" : "text-gray-200 fill-gray-200"}
                        />
                      ))}
                      <span className="text-xs text-gray-400 ml-1">{review.rating}/5</span>
                    </div>
                    {review.product_name && (
                      <p className="text-xs text-blue-600 mb-1.5">📦 {review.product_name}</p>
                    )}
                    {review.comment && (
                      <p className="text-sm text-gray-700 leading-relaxed">{review.comment}</p>
                    )}
                    <p className="text-xs text-gray-400 mt-2">{formatTimeAgo(review.created_at)}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  {!review.is_approved ? (
                    <Button
                      size="sm"
                      onClick={() => approve(review.id, true)}
                      className="bg-green-500 hover:bg-green-600 text-white gap-1.5"
                    >
                      <CheckCircle size={14} />
                      Tasdiqlash
                    </Button>
                  ) : (
                    <button
                      onClick={() => approve(review.id, false)}
                      className="p-2 rounded-xl hover:bg-yellow-50 text-yellow-500"
                    >
                      <XCircle size={16} />
                    </button>
                  )}
                  <button
                    onClick={() => deleteReview(review.id)}
                    className="p-2 rounded-xl hover:bg-red-50 text-red-400"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-gray-500">{total} ta sharh</p>
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
