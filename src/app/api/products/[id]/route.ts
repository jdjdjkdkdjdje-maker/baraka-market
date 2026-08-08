import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { products, productImages, categories, brands, inventory, reviews } from "@/db/schema";
import { eq, sql } from "drizzle-orm";

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const productId = parseInt(id);

    const [product] = await db
      .select({
        id: products.id,
        name: products.name,
        nameRu: products.nameRu,
        nameEn: products.nameEn,
        slug: products.slug,
        description: products.description,
        ingredients: products.ingredients,
        barcode: products.barcode,
        sku: products.sku,
        price: products.price,
        oldPrice: products.oldPrice,
        discountPercent: products.discountPercent,
        costPrice: products.costPrice,
        weight: products.weight,
        weightUnit: products.weightUnit,
        calories: products.calories,
        manufacturer: products.manufacturer,
        countryOfOrigin: products.countryOfOrigin,
        expiryDays: products.expiryDays,
        status: products.status,
        isFeatured: products.isFeatured,
        isNew: products.isNew,
        isOrganic: products.isOrganic,
        totalSold: products.totalSold,
        totalViews: products.totalViews,
        averageRating: products.averageRating,
        reviewCount: products.reviewCount,
        tags: products.tags,
        categoryId: products.categoryId,
        brandId: products.brandId,
        createdAt: products.createdAt,
        updatedAt: products.updatedAt,
        categoryName: categories.name,
        brandName: brands.name,
        inventoryQty: inventory.quantity,
        reservedQty: inventory.reservedQuantity,
        minQuantity: inventory.minQuantity,
      })
      .from(products)
      .leftJoin(categories, eq(products.categoryId, categories.id))
      .leftJoin(brands, eq(products.brandId, brands.id))
      .leftJoin(inventory, eq(products.id, inventory.productId))
      .where(eq(products.id, productId));

    if (!product) {
      return NextResponse.json({ error: "Product not found" }, { status: 404 });
    }

    const images = await db
      .select()
      .from(productImages)
      .where(eq(productImages.productId, productId))
      .orderBy(productImages.sortOrder);

    return NextResponse.json({
      product: {
        ...product,
        price: parseFloat(String(product.price)),
        oldPrice: product.oldPrice ? parseFloat(String(product.oldPrice)) : null,
        images,
      },
    });
  } catch (error) {
    console.error("Product GET error:", error);
    return NextResponse.json({ error: "Failed to fetch product" }, { status: 500 });
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const productId = parseInt(id);
    const body = await request.json();

    const updateData: Partial<typeof products.$inferInsert> = {};
    const fields = [
      "name", "nameRu", "nameEn", "slug", "description", "ingredients",
      "barcode", "sku", "discountPercent", "weightUnit", "calories",
      "manufacturer", "countryOfOrigin", "expiryDays", "status",
      "isFeatured", "isNew", "isOrganic", "tags", "metaTitle", "metaDescription",
    ] as const;

    for (const field of fields) {
      if (field in body) {
        (updateData as Record<string, unknown>)[field] = body[field];
      }
    }

    if ("price" in body) updateData.price = String(body.price);
    if ("oldPrice" in body) updateData.oldPrice = body.oldPrice ? String(body.oldPrice) : null;
    if ("costPrice" in body) updateData.costPrice = body.costPrice ? String(body.costPrice) : null;
    if ("weight" in body) updateData.weight = body.weight ? String(body.weight) : null;
    if ("categoryId" in body) updateData.categoryId = body.categoryId ? parseInt(body.categoryId) : null;
    if ("brandId" in body) updateData.brandId = body.brandId ? parseInt(body.brandId) : null;
    updateData.updatedAt = new Date();

    const [updated] = await db
      .update(products)
      .set(updateData)
      .where(eq(products.id, productId))
      .returning();

    if (!updated) {
      return NextResponse.json({ error: "Product not found" }, { status: 404 });
    }

    // Update inventory if provided
    if ("quantity" in body || "minQuantity" in body) {
      await db
        .update(inventory)
        .set({
          quantity: body.quantity ?? undefined,
          minQuantity: body.minQuantity ?? undefined,
          updatedAt: new Date(),
        })
        .where(eq(inventory.productId, productId));
    }

    return NextResponse.json({ product: updated });
  } catch (error) {
    console.error("Product PUT error:", error);
    return NextResponse.json({ error: "Failed to update product" }, { status: 500 });
  }
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const productId = parseInt(id);

    await db.delete(products).where(eq(products.id, productId));

    return NextResponse.json({ message: "Product deleted successfully" });
  } catch (error) {
    console.error("Product DELETE error:", error);
    return NextResponse.json({ error: "Failed to delete product" }, { status: 500 });
  }
}
