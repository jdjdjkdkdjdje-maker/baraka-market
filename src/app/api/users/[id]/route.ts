import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { users, orders, addresses, reviews } from "@/db/schema";
import { eq, sql, desc } from "drizzle-orm";

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const userId = parseInt(id);

    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId));

    if (!user) return NextResponse.json({ error: "User not found" }, { status: 404 });

    const userAddresses = await db.select().from(addresses).where(eq(addresses.userId, userId));

    const userOrders = await db
      .select({
        id: orders.id,
        orderNumber: orders.orderNumber,
        status: orders.status,
        totalAmount: orders.totalAmount,
        createdAt: orders.createdAt,
      })
      .from(orders)
      .where(eq(orders.userId, userId))
      .orderBy(desc(orders.createdAt))
      .limit(10);

    return NextResponse.json({
      user: {
        ...user,
        walletBalance: parseFloat(String(user.walletBalance)),
      },
      addresses: userAddresses,
      recentOrders: userOrders,
    });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch user" }, { status: 500 });
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const userId = parseInt(id);
    const body = await request.json();

    const [updated] = await db
      .update(users)
      .set({
        firstName: body.firstName,
        lastName: body.lastName,
        email: body.email,
        role: body.role,
        isActive: body.isActive,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId))
      .returning();

    return NextResponse.json({ user: updated });
  } catch (error) {
    return NextResponse.json({ error: "Failed to update user" }, { status: 500 });
  }
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await db.delete(users).where(eq(users.id, parseInt(id)));
    return NextResponse.json({ message: "User deleted" });
  } catch (error) {
    return NextResponse.json({ error: "Failed to delete user" }, { status: 500 });
  }
}
