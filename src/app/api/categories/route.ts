import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { categories, products } from "@/db/schema";
import { sql, eq, ilike, and, desc, asc, isNull } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search") ?? "";
    const parentOnly = searchParams.get("parentOnly") === "true";

    const conditions = [];
    if (search) conditions.push(ilike(categories.name, `%${search}%`));
    if (parentOnly) conditions.push(isNull(categories.parentId));

    const rows = await db
      .select({
        id: categories.id,
        parentId: categories.parentId,
        name: categories.name,
        nameRu: categories.nameRu,
        slug: categories.slug,
        description: categories.description,
        image: categories.image,
        icon: categories.icon,
        color: categories.color,
        sortOrder: categories.sortOrder,
        isActive: categories.isActive,
        createdAt: categories.createdAt,
        productCount: sql<number>`(SELECT COUNT(*)::int FROM products WHERE category_id = ${categories.id})`,
      })
      .from(categories)
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(asc(categories.sortOrder), asc(categories.name));

    return NextResponse.json({ categories: rows });
  } catch (error) {
    console.error("Categories GET error:", error);
    return NextResponse.json({ error: "Failed to fetch categories" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, nameRu, nameEn, slug, description, parentId, image, icon, color, sortOrder } = body;

    const [category] = await db
      .insert(categories)
      .values({
        name, nameRu, nameEn,
        slug: slug || name.toLowerCase().replace(/\s+/g, "-"),
        description,
        parentId: parentId ? parseInt(parentId) : null,
        image, icon, color,
        sortOrder: sortOrder ?? 0,
        isActive: true,
      })
      .returning();

    return NextResponse.json({ category }, { status: 201 });
  } catch (error) {
    console.error("Categories POST error:", error);
    return NextResponse.json({ error: "Failed to create category" }, { status: 500 });
  }
}
