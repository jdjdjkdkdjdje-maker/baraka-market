import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { products, productImages, categories, brands, inventory } from "@/db/schema";
import { sql, eq, ilike, and, or, desc, asc, gte, lte } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") ?? "1");
    const limit = parseInt(searchParams.get("limit") ?? "20");
    const search = searchParams.get("search") ?? "";
    const categoryId = searchParams.get("categoryId");
    const brandId = searchParams.get("brandId");
    const status = searchParams.get("status");
    const sortBy = searchParams.get("sortBy") ?? "createdAt";
    const sortOrder = searchParams.get("sortOrder") ?? "desc";
    const offset = (page - 1) * limit;

    const conditions = [];
    if (search) {
      conditions.push(
        or(
          ilike(products.name, `%${search}%`),
          ilike(products.barcode, `%${search}%`),
          ilike(products.sku, `%${search}%`)
        )
      );
    }
    if (categoryId) conditions.push(eq(products.categoryId, parseInt(categoryId)));
    if (brandId) conditions.push(eq(products.brandId, parseInt(brandId)));
    if (status) conditions.push(eq(products.status, status as "active" | "inactive" | "out_of_stock" | "discontinued"));

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [{ count }] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(products)
      .where(whereClause);

    const rows = await db
      .select({
        id: products.id,
        name: products.name,
        slug: products.slug,
        price: products.price,
        oldPrice: products.oldPrice,
        discountPercent: products.discountPercent,
        status: products.status,
        barcode: products.barcode,
        sku: products.sku,
        isFeatured: products.isFeatured,
        isNew: products.isNew,
        totalSold: products.totalSold,
        averageRating: products.averageRating,
        reviewCount: products.reviewCount,
        categoryId: products.categoryId,
        brandId: products.brandId,
        createdAt: products.createdAt,
        categoryName: categories.name,
        brandName: brands.name,
        inventoryQty: inventory.quantity,
      })
      .from(products)
      .leftJoin(categories, eq(products.categoryId, categories.id))
      .leftJoin(brands, eq(products.brandId, brands.id))
      .leftJoin(inventory, eq(products.id, inventory.productId))
      .where(whereClause)
      .orderBy(sortOrder === "asc" ? asc(products.createdAt) : desc(products.createdAt))
      .limit(limit)
      .offset(offset);

    // Get primary image for each product
    const productIds = rows.map((r) => r.id);
    let images: Array<{ productId: number; url: string }> = [];
    if (productIds.length > 0) {
      images = await db
        .select({ productId: productImages.productId, url: productImages.url })
        .from(productImages)
        .where(
          and(
            sql`${productImages.productId} = ANY(${sql`ARRAY[${sql.join(productIds.map(id => sql`${id}`), sql`, `)}]::int[]`})`,
            eq(productImages.isPrimary, true)
          )
        );
    }
    const imageMap = new Map(images.map((img) => [img.productId, img.url]));

    const productsWithImages = rows.map((p) => ({
      ...p,
      primaryImage: imageMap.get(p.id) ?? null,
      price: parseFloat(String(p.price)),
      oldPrice: p.oldPrice ? parseFloat(String(p.oldPrice)) : null,
    }));

    return NextResponse.json({
      products: productsWithImages,
      total: count,
      page,
      limit,
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    console.error("Products GET error:", error);
    return NextResponse.json({ error: "Failed to fetch products" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      name, nameRu, nameEn, slug, description, categoryId, brandId,
      price, oldPrice, discountPercent, barcode, sku, weight, weightUnit,
      calories, manufacturer, countryOfOrigin, status, isFeatured, isNew,
      ingredients, costPrice,
    } = body;

    const [product] = await db
      .insert(products)
      .values({
        name, nameRu, nameEn,
        slug: slug || name.toLowerCase().replace(/\s+/g, "-"),
        description,
        categoryId: categoryId ? parseInt(categoryId) : null,
        brandId: brandId ? parseInt(brandId) : null,
        price: String(price),
        oldPrice: oldPrice ? String(oldPrice) : null,
        discountPercent: discountPercent ?? 0,
        barcode, sku, ingredients,
        weight: weight ? String(weight) : null,
        weightUnit: weightUnit ?? "g",
        calories: calories ? parseInt(calories) : null,
        manufacturer,
        countryOfOrigin,
        costPrice: costPrice ? String(costPrice) : null,
        status: status ?? "active",
        isFeatured: isFeatured ?? false,
        isNew: isNew ?? false,
      })
      .returning();

    // Create inventory record
    await db.insert(inventory).values({
      productId: product.id,
      quantity: body.quantity ?? 0,
      minQuantity: body.minQuantity ?? 10,
    });

    return NextResponse.json({ product }, { status: 201 });
  } catch (error) {
    console.error("Products POST error:", error);
    return NextResponse.json({ error: "Failed to create product" }, { status: 500 });
  }
}
