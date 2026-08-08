import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { brands, products } from "@/db/schema";
import { sql, ilike, and, asc } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search") ?? "";

    const rows = await db
      .select({
        id: brands.id,
        name: brands.name,
        slug: brands.slug,
        description: brands.description,
        logo: brands.logo,
        website: brands.website,
        country: brands.country,
        isActive: brands.isActive,
        sortOrder: brands.sortOrder,
        createdAt: brands.createdAt,
        productCount: sql<number>`(SELECT COUNT(*)::int FROM products WHERE brand_id = ${brands.id})`,
      })
      .from(brands)
      .where(search ? ilike(brands.name, `%${search}%`) : undefined)
      .orderBy(asc(brands.name));

    return NextResponse.json({ brands: rows });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch brands" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, slug, description, logo, website, country } = body;

    const [brand] = await db
      .insert(brands)
      .values({
        name,
        slug: slug || name.toLowerCase().replace(/\s+/g, "-"),
        description, logo, website, country,
        isActive: true,
      })
      .returning();

    return NextResponse.json({ brand }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: "Failed to create brand" }, { status: 500 });
  }
}
