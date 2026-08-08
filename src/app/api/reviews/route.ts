import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { reviews, users, products } from "@/db/schema";
import { sql, eq, desc, and } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") ?? "1");
    const limit = parseInt(searchParams.get("limit") ?? "20");
    const isApproved = searchParams.get("isApproved");
    const offset = (page - 1) * limit;

    const conditions = [];
    if (isApproved !== null && isApproved !== "") {
      conditions.push(eq(reviews.isApproved, isApproved === "true"));
    }

    const [{ count }] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(reviews)
      .where(conditions.length > 0 ? and(...conditions) : undefined);

    const rows = await db.execute(sql`
      SELECT 
        r.*,
        u.first_name, u.last_name, u.phone, u.avatar,
        p.name as product_name, p.price::float as product_price
      FROM reviews r
      LEFT JOIN users u ON r.user_id = u.id
      LEFT JOIN products p ON r.product_id = p.id
      ${isApproved !== null && isApproved !== "" ? sql`WHERE r.is_approved = ${isApproved === "true"}` : sql``}
      ORDER BY r.created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `);

    return NextResponse.json({
      reviews: rows.rows,
      total: count,
      page,
      limit,
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch reviews" }, { status: 500 });
  }
}
