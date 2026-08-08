import { NextResponse } from "next/server";
import { db } from "@/db";
import {
  users, categories, brands, products, productImages, inventory,
  orders, orderItems, orderStatusHistory, banners, coupons, promotions,
  reviews, activityLogs, settings, couriers,
} from "@/db/schema";
import { sql } from "drizzle-orm";

export async function POST() {
  try {
    // Clear tables in order
    await db.execute(sql`TRUNCATE TABLE activity_logs, reviews, order_status_history, order_items, orders, cart_items, wishlists, recently_viewed, search_history, otp_codes, refresh_tokens, couriers, addresses, coupon_usage, coupons, promotion_products, promotions, banners, inventory, product_images, related_products, products, brands, categories, notifications, wallet_transactions, bonus_transactions, gift_cards, returns, chat_messages, settings, role_permissions, user_roles, roles, permissions, users RESTART IDENTITY CASCADE`);

    // Insert Users
    const insertedUsers = await db.insert(users).values([
      { phone: "+998901234567", email: "admin@barakamarket.uz", firstName: "Admin", lastName: "Baraka", role: "super_admin", isActive: true, isVerified: true, bonusPoints: 0, walletBalance: "0" },
      { phone: "+998901234568", email: "manager@barakamarket.uz", firstName: "Aziz", lastName: "Karimov", role: "manager", isActive: true, isVerified: true, bonusPoints: 0, walletBalance: "0" },
      { phone: "+998901234569", email: "courier1@barakamarket.uz", firstName: "Bobur", lastName: "Yusupov", role: "courier", isActive: true, isVerified: true, bonusPoints: 0, walletBalance: "0" },
      { phone: "+998901234570", email: "customer1@gmail.com", firstName: "Malika", lastName: "Toshmatova", role: "customer", isActive: true, isVerified: true, bonusPoints: 1250, walletBalance: "50000" },
      { phone: "+998901234571", email: "customer2@gmail.com", firstName: "Jasur", lastName: "Nazarov", role: "customer", isActive: true, isVerified: true, bonusPoints: 800, walletBalance: "25000" },
      { phone: "+998901234572", email: "customer3@gmail.com", firstName: "Zulfiya", lastName: "Rahimova", role: "customer", isActive: true, isVerified: true, bonusPoints: 2100, walletBalance: "100000" },
      { phone: "+998901234573", email: "customer4@gmail.com", firstName: "Sherzod", lastName: "Mirzayev", role: "customer", isActive: false, isVerified: false, bonusPoints: 0, walletBalance: "0" },
      { phone: "+998901234574", email: "customer5@gmail.com", firstName: "Gulnora", lastName: "Hasanova", role: "customer", isActive: true, isVerified: true, bonusPoints: 450, walletBalance: "15000" },
    ]).returning();

    // Insert Couriers
    await db.insert(couriers).values([
      { userId: insertedUsers[2].id, vehicleType: "motorcycle", vehicleNumber: "01A123BC", isOnline: true, isAvailable: true, totalDeliveries: 127, averageRating: 4.8 },
    ]);

    // Insert Categories
    const insertedCategories = await db.insert(categories).values([
      { name: "Oziq-ovqat", nameRu: "Продукты питания", slug: "oziq-ovqat", icon: "🥗", color: "#22c55e", sortOrder: 1, isActive: true },
      { name: "Ichimliklar", nameRu: "Напитки", slug: "ichimliklar", icon: "🥤", color: "#3b82f6", sortOrder: 2, isActive: true },
      { name: "Nonvoylik", nameRu: "Хлебобулочные", slug: "nonvoylik", icon: "🍞", color: "#f59e0b", sortOrder: 3, isActive: true },
      { name: "Sut mahsulotlari", nameRu: "Молочные продукты", slug: "sut-mahsulotlari", icon: "🥛", color: "#06b6d4", sortOrder: 4, isActive: true },
      { name: "Go'sht va baliq", nameRu: "Мясо и рыба", slug: "gosht-baliq", icon: "🥩", color: "#ef4444", sortOrder: 5, isActive: true },
      { name: "Meva va sabzavot", nameRu: "Фрукты и овощи", slug: "meva-sabzavot", icon: "🍎", color: "#84cc16", sortOrder: 6, isActive: true },
      { name: "Shirinliklar", nameRu: "Сладости", slug: "shirinliklar", icon: "🍫", color: "#d97706", sortOrder: 7, isActive: true },
      { name: "Uy kimyosi", nameRu: "Бытовая химия", slug: "uy-kimyosi", icon: "🧴", color: "#8b5cf6", sortOrder: 8, isActive: true },
      { name: "Shaxsiy gigiena", nameRu: "Личная гигиена", slug: "shaxsiy-gigiena", icon: "🧼", color: "#ec4899", sortOrder: 9, isActive: true },
      { name: "Bolalar mahsulotlari", nameRu: "Детские товары", slug: "bolalar", icon: "👶", color: "#f97316", sortOrder: 10, isActive: true },
    ]).returning();

    // Insert Brands
    const insertedBrands = await db.insert(brands).values([
      { name: "Nestle", slug: "nestle", country: "Switzerland", isActive: true },
      { name: "Coca-Cola", slug: "coca-cola", country: "USA", isActive: true },
      { name: "Pepsi", slug: "pepsi", country: "USA", isActive: true },
      { name: "Unilever", slug: "unilever", country: "Netherlands", isActive: true },
      { name: "Baraka", slug: "baraka", country: "Uzbekistan", isActive: true },
      { name: "Hayot", slug: "hayot", country: "Uzbekistan", isActive: true },
      { name: "Toshkent Non", slug: "toshkent-non", country: "Uzbekistan", isActive: true },
      { name: "Samsung", slug: "samsung", country: "South Korea", isActive: true },
      { name: "P&G", slug: "pg", country: "USA", isActive: true },
      { name: "Danone", slug: "danone", country: "France", isActive: true },
    ]).returning();

    // Insert Products
    const insertedProducts = await db.insert(products).values([
      { name: "Coca-Cola 1.5L", nameRu: "Кока-Кола 1.5Л", slug: "coca-cola-1-5l", categoryId: insertedCategories[1].id, brandId: insertedBrands[1].id, price: "15000", oldPrice: "18000", discountPercent: 17, description: "Klassik Coca-Cola ichimlik", weight: "1500", weightUnit: "ml", calories: 189, manufacturer: "Coca-Cola Company", countryOfOrigin: "USA", barcode: "5449000000996", sku: "CC-001", status: "active", isFeatured: true, isNew: false, totalSold: 1250, averageRating: 4.7, reviewCount: 89 },
      { name: "Pepsi 1L", nameRu: "Пепси 1Л", slug: "pepsi-1l", categoryId: insertedCategories[1].id, brandId: insertedBrands[2].id, price: "12000", oldPrice: null, discountPercent: 0, description: "Original Pepsi Cola", weight: "1000", weightUnit: "ml", calories: 125, manufacturer: "PepsiCo", countryOfOrigin: "USA", barcode: "0012000001086", sku: "PP-001", status: "active", totalSold: 980, averageRating: 4.5, reviewCount: 67 },
      { name: "Nestle KitKat 4 Fingers", nameRu: "Нестле КитКат 4 Пальца", slug: "kitkat-4-fingers", categoryId: insertedCategories[6].id, brandId: insertedBrands[0].id, price: "8500", oldPrice: "10000", discountPercent: 15, description: "Shokoladli vafli", weight: "41.5", weightUnit: "g", calories: 218, manufacturer: "Nestle", countryOfOrigin: "Switzerland", barcode: "7613035806756", sku: "NS-001", status: "active", isFeatured: true, totalSold: 2100, averageRating: 4.9, reviewCount: 156 },
      { name: "Toshkent Non Oq", nameRu: "Ташкентский Белый Хлеб", slug: "toshkent-non-oq", categoryId: insertedCategories[2].id, brandId: insertedBrands[6].id, price: "5000", oldPrice: null, discountPercent: 0, description: "Yangi pishirilgan Toshkent noni", weight: "700", weightUnit: "g", calories: 265, manufacturer: "Toshkent Non", countryOfOrigin: "Uzbekistan", barcode: "4607032831049", sku: "TN-001", status: "active", totalSold: 3400, averageRating: 4.6, reviewCount: 203 },
      { name: "Danone Activia Yogurt 290g", nameRu: "Данон Активиа Йогурт 290г", slug: "danone-activia-290g", categoryId: insertedCategories[3].id, brandId: insertedBrands[9].id, price: "18000", oldPrice: "22000", discountPercent: 18, description: "Probiotik yogurt", weight: "290", weightUnit: "g", calories: 87, proteins: "4.5", fats: "2.5", carbohydrates: "12", manufacturer: "Danone", countryOfOrigin: "France", barcode: "3033491174039", sku: "DN-001", status: "active", isFeatured: true, totalSold: 780, averageRating: 4.8, reviewCount: 112 },
      { name: "Ariel Avtomatik 3kg", nameRu: "Ариэль Автоматик 3кг", slug: "ariel-3kg", categoryId: insertedCategories[7].id, brandId: insertedBrands[8].id, price: "85000", oldPrice: "95000", discountPercent: 11, description: "Kir yuvish kukuni", weight: "3000", weightUnit: "g", manufacturer: "P&G", countryOfOrigin: "Germany", barcode: "4015400407478", sku: "AR-001", status: "active", totalSold: 456, averageRating: 4.7, reviewCount: 78 },
      { name: "Hayot Sut 1L", nameRu: "Хаёт Молоко 1Л", slug: "hayot-sut-1l", categoryId: insertedCategories[3].id, brandId: insertedBrands[5].id, price: "14000", oldPrice: null, discountPercent: 0, description: "Tabiiy sigir suti 3.2%", weight: "1000", weightUnit: "ml", calories: 52, proteins: "2.8", fats: "3.2", carbohydrates: "4.7", manufacturer: "Hayot", countryOfOrigin: "Uzbekistan", barcode: "4607004720017", sku: "HY-001", status: "active", isNew: true, totalSold: 1890, averageRating: 4.5, reviewCount: 134 },
      { name: "Baraka Suvsiz Suv 5L", nameRu: "Барака Минеральная Вода 5Л", slug: "baraka-suv-5l", categoryId: insertedCategories[1].id, brandId: insertedBrands[4].id, price: "20000", oldPrice: "25000", discountPercent: 20, description: "Tabiiy mineral suv", weight: "5000", weightUnit: "ml", calories: 0, manufacturer: "Baraka", countryOfOrigin: "Uzbekistan", barcode: "4607120023001", sku: "BK-001", status: "active", isFeatured: true, totalSold: 2670, averageRating: 4.6, reviewCount: 189 },
      { name: "Pringles Original 165g", nameRu: "Принглс Оригинал 165г", slug: "pringles-original-165g", categoryId: insertedCategories[6].id, brandId: insertedBrands[0].id, price: "35000", oldPrice: "40000", discountPercent: 13, description: "Kartoshka chips", weight: "165", weightUnit: "g", calories: 536, manufacturer: "Kellogg's", countryOfOrigin: "USA", barcode: "5053990148781", sku: "PR-001", status: "active", totalSold: 890, averageRating: 4.8, reviewCount: 67 },
      { name: "Lipton Black Tea 100 bags", nameRu: "Липтон Черный Чай 100 пакетиков", slug: "lipton-black-tea-100", categoryId: insertedCategories[1].id, brandId: insertedBrands[3].id, price: "45000", oldPrice: "52000", discountPercent: 13, description: "Qora choy paketlari", weight: "200", weightUnit: "g", calories: 1, manufacturer: "Unilever", countryOfOrigin: "Sri Lanka", barcode: "8718114312355", sku: "LP-001", status: "active", totalSold: 1230, averageRating: 4.7, reviewCount: 98 },
      { name: "Go'sht Manti (замороженный) 1kg", slug: "gosht-manti-1kg", categoryId: insertedCategories[4].id, brandId: insertedBrands[4].id, price: "65000", oldPrice: "75000", discountPercent: 13, description: "Mol go'shtidan tayyorlangan manti", weight: "1000", weightUnit: "g", calories: 218, proteins: "12", fats: "8", carbohydrates: "25", manufacturer: "Baraka Foods", countryOfOrigin: "Uzbekistan", barcode: "4607120023002", sku: "BK-002", status: "active", totalSold: 567, averageRating: 4.4, reviewCount: 45 },
      { name: "Olma Fuji 1kg", nameRu: "Яблоко Фуджи 1кг", slug: "olma-fuji-1kg", categoryId: insertedCategories[5].id, price: "22000", oldPrice: null, discountPercent: 0, description: "Yangi Fuji olma", weight: "1000", weightUnit: "g", calories: 52, countryOfOrigin: "Uzbekistan", barcode: "2000000000001", sku: "FR-001", status: "active", isNew: true, totalSold: 2100, averageRating: 4.6, reviewCount: 78 },
      { name: "Head & Shoulders Shampoo 400ml", slug: "head-shoulders-400ml", categoryId: insertedCategories[8].id, brandId: insertedBrands[8].id, price: "55000", oldPrice: "65000", discountPercent: 15, description: "Anti-qo'tirli shampun", weight: "400", weightUnit: "ml", manufacturer: "P&G", countryOfOrigin: "Poland", barcode: "4015400533436", sku: "HS-001", status: "active", totalSold: 345, averageRating: 4.5, reviewCount: 56 },
      { name: "Pampers Baby-Dry S3 (6-10kg) 44pcs", slug: "pampers-s3-44pcs", categoryId: insertedCategories[9].id, brandId: insertedBrands[8].id, price: "120000", oldPrice: "140000", discountPercent: 14, description: "Bolalar uchun quruq taqinchoq", weight: "900", weightUnit: "g", manufacturer: "P&G", countryOfOrigin: "Germany", barcode: "4015400558125", sku: "PA-001", status: "active", isFeatured: true, totalSold: 678, averageRating: 4.9, reviewCount: 234 },
      { name: "Nestea Ice Tea Limon 1.5L", slug: "nestea-ice-tea-1-5l", categoryId: insertedCategories[1].id, brandId: insertedBrands[0].id, price: "18000", oldPrice: "20000", discountPercent: 10, description: "Limonli muzli choy", weight: "1500", weightUnit: "ml", calories: 56, manufacturer: "Nestle", countryOfOrigin: "Poland", barcode: "5900334004635", sku: "NT-001", status: "active", totalSold: 890, averageRating: 4.6, reviewCount: 123 },
    ]).returning();

    // Insert Product Images
    const imageData = insertedProducts.flatMap((p, i) => [
      { productId: p.id, url: `https://picsum.photos/seed/product${p.id}a/800/800`, isPrimary: true, sortOrder: 0 },
      { productId: p.id, url: `https://picsum.photos/seed/product${p.id}b/800/800`, isPrimary: false, sortOrder: 1 },
    ]);
    await db.insert(productImages).values(imageData);

    // Insert Inventory
    const inventoryData = insertedProducts.map((p, i) => ({
      productId: p.id,
      quantity: Math.floor(Math.random() * 500) + 50,
      reservedQuantity: Math.floor(Math.random() * 20),
      minQuantity: 20,
      maxQuantity: 1000,
      warehouseLocation: `A${Math.floor(i / 5) + 1}-${(i % 5) + 1}`,
    }));
    await db.insert(inventory).values(inventoryData);

    // Insert Banners
    await db.insert(banners).values([
      { title: "Yangi Mahsulotlar!", titleRu: "Новые товары!", subtitle: "Eng yangi va sifatli mahsulotlar", image: "https://picsum.photos/seed/banner1/1200/400", type: "main", sortOrder: 1, isActive: true },
      { title: "Yozgi Chegirmalar", titleRu: "Летние скидки", subtitle: "50% gacha chegirma", image: "https://picsum.photos/seed/banner2/1200/400", type: "promo", sortOrder: 2, isActive: true },
      { title: "Baraka Premium", titleRu: "Барака Премиум", subtitle: "Eng sifatli mahsulotlar kolleksiyasi", image: "https://picsum.photos/seed/banner3/1200/400", type: "brand", sortOrder: 3, isActive: true },
      { title: "Meva va Sabzavotlar", titleRu: "Фрукты и Овощи", subtitle: "Yangi va tabiiy mahsulotlar", image: "https://picsum.photos/seed/banner4/1200/400", type: "category", sortOrder: 4, isActive: true },
    ]);

    // Insert Coupons
    await db.insert(coupons).values([
      { code: "BARAKA10", name: "10% chegirma", description: "Birinchi buyurtmaga 10% chegirma", discountType: "percentage", discountValue: "10", minOrderAmount: "50000", usageLimit: 1000, usageLimitPerUser: 1, usedCount: 234, isActive: true },
      { code: "YANGI2024", name: "Yangi yil chegirmasi", description: "25,000 UZS chegirma", discountType: "fixed", discountValue: "25000", minOrderAmount: "150000", usageLimit: 500, usageLimitPerUser: 1, usedCount: 89, isActive: true },
      { code: "PREMIUM20", name: "Premium chegirma", description: "Premium mahsulotlarga 20% chegirma", discountType: "percentage", discountValue: "20", minOrderAmount: "200000", maxDiscountAmount: "50000", usageLimit: 100, usageLimitPerUser: 2, usedCount: 45, isActive: true },
    ]);

    // Insert Orders
    const orderStatuses = ["pending", "confirmed", "preparing", "ready", "delivering", "delivered", "cancelled"] as const;
    const paymentMethods = ["cash", "card", "payme", "click"] as const;
    const insertedOrders = [];

    for (let i = 0; i < 20; i++) {
      const customer = insertedUsers[3 + (i % 5)];
      const status = orderStatuses[i % orderStatuses.length];
      const paymentMethod = paymentMethods[i % paymentMethods.length];
      const subtotal = (Math.floor(Math.random() * 300000) + 50000);
      const deliveryFee = 15000;
      const total = subtotal + deliveryFee;
      const createdAt = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000);

      const [order] = await db.insert(orders).values({
        orderNumber: `BM${Date.now().toString().slice(-8)}${i.toString().padStart(3, "0")}`,
        userId: customer.id,
        status,
        subtotal: String(subtotal),
        deliveryFee: String(deliveryFee),
        discountAmount: "0",
        totalAmount: String(total),
        paymentMethod,
        paymentStatus: status === "delivered" ? "paid" : "pending",
        deliveryAddress: "Toshkent sh., Chilonzor tumani, 9-mavze, 5-uy",
        deliveryLatitude: 41.2995,
        deliveryLongitude: 69.2401,
        estimatedDeliveryAt: new Date(createdAt.getTime() + 90 * 60 * 1000),
        createdAt,
      }).returning();
      insertedOrders.push(order);

      // Insert order items
      const itemCount = Math.floor(Math.random() * 4) + 1;
      for (let j = 0; j < itemCount; j++) {
        const product = insertedProducts[j % insertedProducts.length];
        const qty = Math.floor(Math.random() * 3) + 1;
        const unitPrice = parseFloat(String(product.price));
        await db.insert(orderItems).values({
          orderId: order.id,
          productId: product.id,
          productName: product.name,
          productImage: `https://picsum.photos/seed/product${product.id}a/400/400`,
          quantity: qty,
          unitPrice: String(unitPrice),
          totalPrice: String(unitPrice * qty),
          discountAmount: "0",
        });
      }

      // Insert status history
      await db.insert(orderStatusHistory).values({
        orderId: order.id,
        status,
        comment: `Buyurtma ${status} holatiga o'tkazildi`,
      });
    }

    // Insert Reviews
    const reviewData = insertedProducts.slice(0, 8).flatMap((p, i) => [
      { productId: p.id, userId: insertedUsers[3].id, rating: 5, comment: "Juda yaxshi mahsulot! Tavsiya qilaman.", isApproved: true, isVerified: true, helpfulCount: 12 },
      { productId: p.id, userId: insertedUsers[4].id, rating: 4, comment: "Yaxshi, lekin narxi biroz yuqori.", isApproved: true, isVerified: true, helpfulCount: 5 },
    ]);
    await db.insert(reviews).values(reviewData);

    // Insert Settings
    await db.insert(settings).values([
      { key: "site.name", value: "Baraka Market" },
      { key: "site.phone", value: "+998 71 200 20 20" },
      { key: "site.email", value: "info@barakamarket.uz" },
      { key: "delivery.fee", value: "15000" },
      { key: "delivery.free_threshold", value: "200000" },
      { key: "bonus.rate", value: "1" },
      { key: "bonus.points_per_sum", value: "100" },
      { key: "order.min_amount", value: "30000" },
    ]);

    // Insert Activity Logs
    await db.insert(activityLogs).values([
      { userId: insertedUsers[0].id, type: "login", module: "auth", description: "Admin tizimga kirdi", ipAddress: "192.168.1.1" },
      { userId: insertedUsers[0].id, type: "create", module: "products", description: "Yangi mahsulot qo'shildi: Coca-Cola 1.5L", ipAddress: "192.168.1.1" },
      { userId: insertedUsers[1].id, type: "update", module: "orders", description: "Buyurtma holati yangilandi", ipAddress: "192.168.1.2" },
      { userId: insertedUsers[0].id, type: "create", module: "categories", description: "Yangi kategoriya yaratildi", ipAddress: "192.168.1.1" },
      { userId: insertedUsers[1].id, type: "login", module: "auth", description: "Manager tizimga kirdi", ipAddress: "192.168.1.3" },
    ]);

    return NextResponse.json({
      success: true,
      message: "Database seeded successfully!",
      counts: {
        users: insertedUsers.length,
        categories: insertedCategories.length,
        brands: insertedBrands.length,
        products: insertedProducts.length,
        orders: insertedOrders.length,
      },
    });
  } catch (error) {
    console.error("Seed error:", error);
    return NextResponse.json(
      { error: "Failed to seed database", details: String(error) },
      { status: 500 }
    );
  }
}
