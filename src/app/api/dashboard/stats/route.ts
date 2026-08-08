import { NextResponse } from "next/server";
import { db } from "@/db";
import { users, orders, products, orderItems } from "@/db/schema";
import { sql, gte, eq } from "drizzle-orm";

export async function GET() {
  try {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    // Total users
    const [totalUsersResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(users)
      .where(eq(users.role, "customer"));

    // Users this month
    const [monthUsersResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(users)
      .where(gte(users.createdAt, startOfMonth));

    // Users last month
    const [lastMonthUsersResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(users)
      .where(
        sql`${users.createdAt} >= ${startOfLastMonth} AND ${users.createdAt} <= ${endOfLastMonth}`
      );

    // Total orders
    const [totalOrdersResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(orders);

    // Orders this month
    const [monthOrdersResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(orders)
      .where(gte(orders.createdAt, startOfMonth));

    // Revenue this month
    const [monthRevenueResult] = await db
      .select({ total: sql<number>`coalesce(sum(total_amount::numeric), 0)::float` })
      .from(orders)
      .where(
        sql`${orders.createdAt} >= ${startOfMonth} AND ${orders.status} != 'cancelled'`
      );

    // Revenue last month
    const [lastMonthRevenueResult] = await db
      .select({ total: sql<number>`coalesce(sum(total_amount::numeric), 0)::float` })
      .from(orders)
      .where(
        sql`${orders.createdAt} >= ${startOfLastMonth} AND ${orders.createdAt} <= ${endOfLastMonth} AND ${orders.status} != 'cancelled'`
      );

    // Total products
    const [totalProductsResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(products);

    // Active products
    const [activeProductsResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(products)
      .where(eq(products.status, "active"));

    // Pending orders
    const [pendingOrdersResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(orders)
      .where(eq(orders.status, "pending"));

    // Total revenue all time
    const [totalRevenueResult] = await db
      .select({ total: sql<number>`coalesce(sum(total_amount::numeric), 0)::float` })
      .from(orders)
      .where(sql`${orders.status} != 'cancelled'`);

    const totalUsers = totalUsersResult?.count ?? 0;
    const monthUsers = monthUsersResult?.count ?? 0;
    const lastMonthUsers = lastMonthUsersResult?.count ?? 0;
    const totalOrders = totalOrdersResult?.count ?? 0;
    const monthOrders = monthOrdersResult?.count ?? 0;
    const monthRevenue = monthRevenueResult?.total ?? 0;
    const lastMonthRevenue = lastMonthRevenueResult?.total ?? 0;
    const totalProducts = totalProductsResult?.count ?? 0;
    const activeProducts = activeProductsResult?.count ?? 0;
    const pendingOrders = pendingOrdersResult?.count ?? 0;
    const totalRevenue = totalRevenueResult?.total ?? 0;

    const userGrowth = lastMonthUsers > 0
      ? Math.round(((monthUsers - lastMonthUsers) / lastMonthUsers) * 100)
      : 100;
    const revenueGrowth = lastMonthRevenue > 0
      ? Math.round(((monthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100)
      : 100;

    return NextResponse.json({
      totalUsers,
      totalOrders,
      totalProducts,
      activeProducts,
      pendingOrders,
      totalRevenue,
      monthRevenue,
      monthOrders,
      monthUsers,
      userGrowth,
      revenueGrowth,
      averageOrderValue: monthOrders > 0 ? Math.round(monthRevenue / monthOrders) : 0,
    });
  } catch (error) {
    console.error("Dashboard stats error:", error);
    return NextResponse.json(
      { error: "Failed to fetch dashboard stats" },
      { status: 500 }
    );
  }
}
