import { NextResponse } from "next/server";
import { db } from "@/db";
import { orders, users } from "@/db/schema";
import { sql, desc } from "drizzle-orm";

export async function GET() {
  try {
    const recentOrders = await db.execute(sql`
      SELECT 
        o.id,
        o.order_number,
        o.status,
        o.total_amount::float,
        o.payment_method,
        o.payment_status,
        o.created_at,
        u.first_name,
        u.last_name,
        u.phone,
        u.avatar
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      ORDER BY o.created_at DESC
      LIMIT 10
    `);

    return NextResponse.json({ orders: recentOrders.rows });
  } catch (error) {
    console.error("Recent orders error:", error);
    return NextResponse.json(
      { error: "Failed to fetch recent orders" },
      { status: 500 }
    );
  }
}
