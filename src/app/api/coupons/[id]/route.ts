import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { coupons } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();
    const [updated] = await db
      .update(coupons)
      .set({ ...body, updatedAt: new Date() })
      .where(eq(coupons.id, parseInt(id)))
      .returning();
    return NextResponse.json({ coupon: updated });
  } catch (error) {
    return NextResponse.json({ error: "Failed to update coupon" }, { status: 500 });
  }
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await db.delete(coupons).where(eq(coupons.id, parseInt(id)));
    return NextResponse.json({ message: "Coupon deleted" });
  } catch (error) {
    return NextResponse.json({ error: "Failed to delete coupon" }, { status: 500 });
  }
}
