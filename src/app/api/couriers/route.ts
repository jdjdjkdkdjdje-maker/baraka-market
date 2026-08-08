import { NextResponse } from "next/server";
import { db } from "@/db";
import { couriers, users } from "@/db/schema";
import { sql } from "drizzle-orm";

export async function GET() {
  try {
    const rows = await db.execute(sql`
      SELECT 
        c.*,
        u.first_name, u.last_name, u.phone, u.avatar, u.is_active
      FROM couriers c
      JOIN users u ON c.user_id = u.id
      ORDER BY c.total_deliveries DESC
    `);
    return NextResponse.json({ couriers: rows.rows });
  } catch (error) {
    return NextResponse.json({ error: "Failed to fetch couriers" }, { status: 500 });
  }
}
