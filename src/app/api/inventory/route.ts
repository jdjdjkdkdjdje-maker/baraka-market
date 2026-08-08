import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { inventory, products, categories } from "@/db/schema";
import { sql, eq, lte, ilike } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") ?? "1");
    const limit = parseInt(searchParams.get("limit") ?? "20");
    const lowStock = searchParams.get("lowStock") === "true";
    const search = searchParams.get("search") ?? "";
    const offset = (page - 1) * limit;

    const rows = await db.execute(sql`
      SELECT 
        i.id,
        i.product_id,
        i.quantity,
        i.reserved_quantity,
        i.min_quantity,
        i.max_quantity,
        i.warehouse_location,
        i.updated_at,
        p.name as product_name,
        p.barcode,
        p.sku,
        p.price::float,
        p.status as product_status,
        c.name as category_name,
        (i.quantity - i.reserved_quantity) as available_quantity,
        CASE WHEN i.quantity <= i.min_quantity THEN true ELSE false END as is_low_stock
      FROM inventory i
      JOIN products p ON i.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      ${lowStock ? sql`WHERE i.quantity <= i.min_quantity` : sql``}
      ${search ? sql`${lowStock ? sql`AND` : sql`WHERE`} p.name ILIKE ${`%${search}%`}` : sql``}
      ORDER BY i.quantity ASC
      LIMIT ${limit} OFFSET ${offset}
    `);

    const [{ count }] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(inventory);

    const [{ lowStockCount }] = await db
      .select({ lowStockCount: sql<number>`count(*)::int` })
      .from(inventory)
      .where(lte(inventory.quantity, inventory.minQuantity));

    return NextResponse.json({
      inventory: rows.rows,
      total: count,
      lowStockCount,
      page,
      limit,
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch inventory" }, { status: 500 });
  }
}

export async function PUT(request: NextRequest) {
  try {
    const body = await request.json();
    const { productId, quantity, minQuantity, warehouseLocation } = body;

    const [updated] = await db
      .update(inventory)
      .set({
        quantity: quantity !== undefined ? parseInt(quantity) : undefined,
        minQuantity: minQuantity !== undefined ? parseInt(minQuantity) : undefined,
        warehouseLocation,
        updatedAt: new Date(),
      })
      .where(eq(inventory.productId, parseInt(productId)))
      .returning();

    return NextResponse.json({ inventory: updated });
  } catch (error) {
    return NextResponse.json({ error: "Failed to update inventory" }, { status: 500 });
  }
}
