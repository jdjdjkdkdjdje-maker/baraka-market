import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { categories } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await request.json();

    const [updated] = await db
      .update(categories)
      .set({
        name: body.name,
        nameRu: body.nameRu,
        nameEn: body.nameEn,
        description: body.description,
        image: body.image,
        icon: body.icon,
        color: body.color,
        sortOrder: body.sortOrder,
        isActive: body.isActive,
        updatedAt: new Date(),
      })
      .where(eq(categories.id, parseInt(id)))
      .returning();

    return NextResponse.json({ category: updated });
  } catch (error) {
    return NextResponse.json({ error: "Failed to update category" }, { status: 500 });
  }
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await db.delete(categories).where(eq(categories.id, parseInt(id)));
    return NextResponse.json({ message: "Category deleted" });
  } catch (error) {
    return NextResponse.json({ error: "Failed to delete category" }, { status: 500 });
  }
}
