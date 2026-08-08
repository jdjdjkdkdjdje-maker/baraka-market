import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { banners } from "@/db/schema";
import { asc, desc } from "drizzle-orm";

export async function GET() {
  try {
    const rows = await db
      .select()
      .from(banners)
      .orderBy(asc(banners.sortOrder), desc(banners.createdAt));
    return NextResponse.json({ banners: rows });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch banners" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const [banner] = await db
      .insert(banners)
      .values({
        title: body.title,
        titleRu: body.titleRu,
        subtitle: body.subtitle,
        image: body.image || "https://placehold.co/1200x400",
        mobileImage: body.mobileImage,
        link: body.link,
        type: body.type ?? "main",
        sortOrder: body.sortOrder ?? 0,
        isActive: body.isActive ?? true,
        startsAt: body.startsAt ? new Date(body.startsAt) : null,
        endsAt: body.endsAt ? new Date(body.endsAt) : null,
      })
      .returning();
    return NextResponse.json({ banner }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: "Failed to create banner" }, { status: 500 });
  }
}
