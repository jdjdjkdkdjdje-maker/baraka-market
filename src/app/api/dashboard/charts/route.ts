import { NextResponse } from "next/server";
import { db } from "@/db";
import { orders, products, categories } from "@/db/schema";
import { sql, eq } from "drizzle-orm";

export async function GET() {
  try {
    // Revenue by last 7 days
    const revenueLast7Days = await db.execute(sql`
      SELECT 
        DATE(created_at) as date,
        COUNT(*)::int as orders,
        COALESCE(SUM(total_amount::numeric), 0)::float as revenue
      FROM orders
      WHERE created_at >= NOW() - INTERVAL '7 days'
        AND status != 'cancelled'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `);

    // Revenue by last 12 months
    const revenueByMonth = await db.execute(sql`
      SELECT 
        TO_CHAR(created_at, 'YYYY-MM') as month,
        TO_CHAR(created_at, 'Mon') as month_label,
        COUNT(*)::int as orders,
        COALESCE(SUM(total_amount::numeric), 0)::float as revenue
      FROM orders
      WHERE created_at >= NOW() - INTERVAL '12 months'
        AND status != 'cancelled'
      GROUP BY TO_CHAR(created_at, 'YYYY-MM'), TO_CHAR(created_at, 'Mon')
      ORDER BY month ASC
    `);

    // Orders by status
    const ordersByStatus = await db.execute(sql`
      SELECT 
        status,
        COUNT(*)::int as count
      FROM orders
      GROUP BY status
      ORDER BY count DESC
    `);

    // Top categories by revenue
    const topCategories = await db.execute(sql`
      SELECT 
        c.name,
        COUNT(DISTINCT o.id)::int as orders,
        COALESCE(SUM(oi.total_price::numeric), 0)::float as revenue
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.status != 'cancelled'
      GROUP BY c.name
      ORDER BY revenue DESC
      LIMIT 5
    `);

    // Top products by sales
    const topProducts = await db.execute(sql`
      SELECT 
        p.name,
        p.price::float,
        COALESCE(SUM(oi.quantity), 0)::int as sold,
        COALESCE(SUM(oi.total_price::numeric), 0)::float as revenue
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.status != 'cancelled'
      GROUP BY p.id, p.name, p.price
      ORDER BY sold DESC
      LIMIT 5
    `);

    // Payment methods distribution
    const paymentMethods = await db.execute(sql`
      SELECT 
        payment_method,
        COUNT(*)::int as count,
        COALESCE(SUM(total_amount::numeric), 0)::float as total
      FROM orders
      WHERE status != 'cancelled'
      GROUP BY payment_method
      ORDER BY count DESC
    `);

    // Users registration trend (last 7 days)
    const usersTrend = await db.execute(sql`
      SELECT 
        DATE(created_at) as date,
        COUNT(*)::int as count
      FROM users
      WHERE created_at >= NOW() - INTERVAL '7 days'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `);

    return NextResponse.json({
      revenueLast7Days: revenueLast7Days.rows,
      revenueByMonth: revenueByMonth.rows,
      ordersByStatus: ordersByStatus.rows,
      topCategories: topCategories.rows,
      topProducts: topProducts.rows,
      paymentMethods: paymentMethods.rows,
      usersTrend: usersTrend.rows,
    });
  } catch (error) {
    console.error("Dashboard charts error:", error);
    return NextResponse.json(
      { error: "Failed to fetch chart data" },
      { status: 500 }
    );
  }
}
