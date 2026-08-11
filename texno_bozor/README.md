# TEXNO BOZOR — Flutter Android ilovasi

**TEXNO BOZOR** — offline-first elektronika marketplace ilovasi. Butunlay
noldan Flutter + Dart'da yozilgan, Android telefonga `.apk` sifatida
o'rnatiladi.

> Server, VPS, PostgreSQL, NestJS, Nginx, domen — **hech biri kerak emas**.
> Barcha ma'lumot telefonning o'zida (SQLite) saqlanadi. Internet faqat
> TEXNO AI ning onlayn rejimi uchun (ixtiyoriy) kerak.

## Bo'limlar

| Bo'lim | Nima qiladi | Internet |
|---|---|---|
| Bosh sahifa | Bannerlar, kategoriyalar, chegirmalar, ommabop/yangi mahsulotlar, yaqinda ko'rilganlar | ❌ |
| Katalog | 28 kategoriya, filtr (narx/brend/reyting/ombor/chegirma), 6 xil saralash | ❌ |
| Qidiruv | Lokal qidiruv: nom, brend, kategoriya, xususiyatlar ("RTX 4060") + tarix | ❌ |
| Mahsulot | Rasm, narx/chegirma, ombor, xususiyatlar jadvali, sharhlar, o'xshashlar | ❌ |
| Savat | Qo'shish/o'chirish/miqdor, swipe bilan o'chirish, bepul yetkazish hisobi | ❌ |
| Buyurtmalar | Manzil → yetkazish → to'lov → status kuzatuvi, bekor qilish | ❌ |
| Sevimlilar | ❤️ bilan saqlash, ilova yopilsa ham qoladi | ❌ |
| Profil | Ism, telefon, email, manzil, statistika, sozlamalar | ❌ |
| Kompyuter yig'ish | PC Builder: soket, xotira, korpus, PSU, sovutgich mosligini avtomatik tekshiradi | ❌ |
| TEXNO AI | Mahsulot tanlash yordamchisi (onlayn API yoki qurilma ichidagi rejim) | ⚠️ ixtiyoriy |

## Texnologiyalar

- **Flutter + Dart** — UI va biznes logika
- **Riverpod** — holat boshqaruvi
- **sqflite (SQLite)** — lokal ma'lumotlar bazasi
- **http** — TEXNO AI va ixtiyoriy REST rejimi uchun
- **Repository pattern + RepositoryFactory** — ma'lumot manbasini almashtirish

## Arxitektura — Repository pattern

Ekranlar hech qachon bazaga yoki tarmoqqa to'g'ridan-to'g'ri murojaat
qilmaydi. Ular faqat abstrakt interfeyslarni biladi:

```
ProductRepository · CategoryRepository · CartRepository · OrderRepository
UserRepository · FavoritesRepository · ReviewRepository · HistoryRepository
PcBuildRepository · ChatRepository
```

Har birining ikkita implementatsiyasi bor:

| Implementatsiya | Manba | Fayl |
|---|---|---|
| `Local*Repository` | Telefondagi SQLite | `lib/data/repositories/local/` |
| `Api*Repository` | REST API + PostgreSQL | `lib/data/repositories/api/` |

Tanlov **bitta joyda** — `RepositoryFactory` da amalga oshadi:

```dart
// Server manzili bo'sh  -> SQLite (offline)
RepositoryFactory(db: db);

// Server manzili bor    -> REST API (+ avtomatik offline fallback)
RepositoryFactory(db: db, config: ApiConfig(baseUrl: 'https://api.example.uz/v1'));
```

Server rejimida ham ilova offline-first qoladi: API javob bermasa, so'rov
avtomatik lokal bazaga tushadi va foydalanuvchi buni sezmaydi. UI kodining
birorta qatori ham o'zgarmaydi — repository implementatsiyasini keyinchalik
almashtirish shu tarzda ta'minlangan.

Serverga o'tish uchun kod o'zgartirish shart emas: ilova ichida
**Profil → Sozlamalar → Ma'lumot manbai** bo'limiga server manzilini kiritish
kifoya.

### Kutilayotgan REST endpointlar

```
GET    /products?category=&search=&brands=&minPrice=&maxPrice=&sort=
GET    /products/:id
GET    /products/:id/similar
GET    /products/brands
GET    /products/price-range
GET    /categories            GET /categories/counts
GET    /cart                  POST /cart    PUT /cart/:id    DELETE /cart/:id
GET    /orders                POST /orders  PATCH /orders/:id
GET    /users/me              PUT /users/me
GET    /health
```

## Loyiha tuzilmasi

```
lib/
├── core/
│   ├── theme/          # Dark premium tema (AppColors, AppTheme)
│   ├── router/         # AppShell (pastki menyu) + AppRouter
│   ├── utils/          # Format (narx, sana, telefon)
│   ├── widgets/        # ProductCard, EmptyState, RatingStars va h.k.
│   └── providers.dart  # Riverpod provayderlari
├── data/
│   ├── local/          # SQLite sxemasi + katalog seed (116 mahsulot)
│   ├── models/         # Product, Cart, Order, AppUser, PcBuild...
│   ├── remote/         # ApiClient, ApiConfig
│   ├── repositories/   # Interfeyslar + local/ + api/ + RepositoryFactory
│   └── services/       # AiService (onlayn + oflayn rejim)
├── features/           # home, catalog, search, product, cart, checkout,
│                       # orders, favorites, profile, pc_builder, texno_ai
└── main.dart
```

## APK olish

### 1. GitHub Actions (eng oson — hech narsa o'rnatish shart emas)

`texno_bozor/**` ichidagi har bir push avtomatik build qiladi:

```bash
gh run watch                                  # jarayonni kuzatish
gh run download <RUN_ID> -n texno-bozor-apk   # APK ni yuklab olish
```

Tayyor APK **Releases** bo'limiga ham chiqadi — telefondan to'g'ridan-to'g'ri
yuklab olish mumkin.

### 2. Lokal build

```bash
cd texno_bozor
flutter pub get
flutter test              # testlar
flutter analyze           # statik tahlil
flutter build apk --release
# Natija: build/app/outputs/flutter-apk/app-release.apk
```

## Telefonga o'rnatish

1. APK faylni telefonga yuklab oling
2. Faylni oching — "Noma'lum manbalar" so'ralsa ruxsat bering
3. O'rnatish tugagach ilova ishga tushadi va katalog avtomatik yuklanadi

Ilova birinchi ochilishida SQLite bazasi yaratiladi va 28 kategoriya,
116 mahsulot, 270+ sharh yoziladi. Shundan keyin internet umuman kerak emas.

## TEXNO AI sozlash

AI ikki rejimda ishlaydi:

- **Oflayn (standart)** — qurilma ichidagi yordamchi. Byudjet ("15 mln",
  "500 ming") va kategoriyani tushunadi, bazadan mos mahsulotlarni tanlaydi.
  Internet kerak emas.
- **Onlayn** — OpenAI-uyg'un API. Kalit **Profil → Sozlamalar → TEXNO AI**
  bo'limiga kiritiladi (yoki build vaqtida
  `--dart-define=TEXNO_AI_API_KEY=...`).

API kalit hech qachon kodga yozilmaydi va repositoryga tushmaydi.

## Testlar

```bash
flutter test
```

Qamrov: repositorylar (mahsulot, savat, buyurtma, sevimlilar, profil, tarix,
sharh, yig'ilma, chat), PC Builder moslik qoidalari, AI byudjet/kategoriya
tahlili, modellar va formatlash, RepositoryFactory almashtiruvi va offline
fallback.
