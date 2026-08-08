import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { coupons } from "@/db/schema";
import { sql, ilike, desc } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search") ?? "";

    const rows = await db
      .select()
      .from(coupons)
      .where(search ? ilike(coupons.code, `%${search}%`) : undefined)
      .orderBy(desc(coupons.createdAt));

    return NextResponse.json({ coupons: rows });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch coupons" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const [coupon] = await db
      .insert(coupons)
      .values({
        code: body.code.toUpperCase(),
        name: body.name,
        description: body.description,
        discountType: body.discountType,
        discountValue: String(body.discountValue),
        minOrderAmount: body.minOrderAmount ? String(body.minOrderAmount) : null,
        maxDiscountAmount: body.maxDiscountAmount ? String(body.maxDiscountAmount) : null,
        usageLimit: body.usageLimit ? parseInt(body.usageLimit) : null,
        usageLimitPerUser: body.usageLimitPerUser ?? 1,
        isActive: body.isActive ?? true,
        startsAt: body.startsAt ? new Date(body.startsAt) : null,
        endsAt: body.endsAt ? new Date(body.endsAt) : null,
      })
      .returning();
    return NextResponse.json({ coupon }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: "Failed to create coupon" }, { status: 500 });
  }
}
