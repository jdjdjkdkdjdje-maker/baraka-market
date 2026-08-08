import { NextRequest, NextResponse } from "next/server";
import { db } from "@/db";
import { activityLogs, users } from "@/db/schema";
import { sql, desc } from "drizzle-orm";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") ?? "1");
    const limit = parseInt(searchParams.get("limit") ?? "50");
    const offset = (page - 1) * limit;

    const rows = await db.execute(sql`
      SELECT 
        al.*,
        u.first_name, u.last_name, u.phone, u.avatar, u.role
      FROM activity_logs al
      LEFT JOIN users u ON al.user_id = u.id
      ORDER BY al.created_at DESC
      LIMIT ${limit} OFFSET ${offset}
    `);

    const [{ count }] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(activityLogs);

    return NextResponse.json({
      logs: rows.rows,
      total: count,
      page,
      limit,
      totalPages: Math.ceil(count / limit),
    });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch activity logs" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const [log] = await db
      .insert(activityLogs)
      .values({
        userId: body.userId,
        type: body.type,
        module: body.module,
        description: body.description,
        metadata: body.metadata,
        ipAddress: body.ipAddress,
        userAgent: body.userAgent,
      })
      .returning();
    return NextResponse.json({ log }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: "Failed to create log" }, { status: 500 });
  }
}
