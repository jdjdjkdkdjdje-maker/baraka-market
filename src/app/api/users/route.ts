import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { users } from "@/db/schema";
import { sql, eq, ilike, and, or, desc } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") ?? "1");
    const limit = parseInt(searchParams.get("limit") ?? "20");
    const search = searchParams.get("search") ?? "";
    const role = searchParams.get("role");
    const isActive = searchParams.get("isActive");
    const offset = (page - 1) * limit;

    const conditions = [];
    if (search) {
      conditions.push(
        or(
          ilike(users.firstName, `%${search}%`),
          ilike(users.lastName, `%${search}%`),
          ilike(users.phone, `%${search}%`),
          ilike(users.email, `%${search}%`)
        )
      );
    }
    if (role) conditions.push(eq(users.role, role as "super_admin" | "admin" | "manager" | "courier" | "customer"));
    if (isActive !== null && isActive !== "") conditions.push(eq(users.isActive, isActive === "true"));

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [{ count }] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(users)
      .where(whereClause);

    const rows = await db
      .select({
        id: users.id,
        phone: users.phone,
        email: users.email,
        firstName: users.firstName,
        lastName: users.lastName,
        avatar: users.avatar,
        role: users.role,
        isActive: users.isActive,
        isVerified: users.isVerified,
        bonusPoints: users.bonusPoints,
        walletBalance: users.walletBalance,
        language: users.language,
        lastLoginAt: users.lastLoginAt,
        createdAt: users.createdAt,
        orderCount: sql<number>`(SELECT COUNT(*)::int FROM orders WHERE user_id = ${users.id})`,
        totalSpent: sql<number>`COALESCE((SELECT SUM(total_amount::numeric) FROM orders WHERE user_id = ${users.id} AND status = 'delivered'), 0)::float`,
      })
      .from(users)
      .where(whereClause)
      .orderBy(desc(users.createdAt))
      .limit(limit)
      .offset(offset);

    return NextResponse.json({
      users: rows,
      total: count,
      page,
      limit,
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    console.error("Users GET error:", error);
    return NextResponse.json({ error: "Failed to fetch users" }, { status: 500 });
  }
}
