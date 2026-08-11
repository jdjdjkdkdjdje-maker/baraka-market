# TEXNO BOZOR — Flutter APK

**TEXNO BOZOR** — offline-first elektronika marketplace ilovasi. Flutter + Dart
asosida qurilgan, Android telefonga o'rnatiladigan `.apk` sifatida tarqatiladi.

> Server, VPS, PostgreSQL, NestJS — hech biri kerak emas. Barcha asosiy
> funksiyalar telefonning o'zida ishlaydi. Internet faqat **TEXNO AI** uchun kerak.

## Imkoniyatlar

| Bo'lim | Tavsif | Internet |
|---|---|---|
| Bosh sahifa | Bannerlar, kategoriyalar, mashhur/yangi/chegirmadagi mahsulotlar, brendlar | ❌ kerak emas |
| Katalog | 26 kategoriya, filtr (narx/brend/reyting), 6 xil saralash | ❌ |
| Qidiruv | Lokal qidiruv: nom, brend, model, kategoriya (masalan: "RTX 5070") | ❌ |
| Mahsulot | Rasmlar, narx/chegirma, sharhlar, xususiyatlar, o'xshashlar | ❌ |
| Savat | Qo'shish/o'chirish/miqdor, ilova yopilsa ham saqlanadi | ❌ |
| Buyurtmalar | Manzil → yetkazish → to'lov (Click/Payme/Uzcard/Humo/Naqd, test rejim) → statuslar | ❌ |
| Sevimlilar | Lokal saqlanadi | ❌ |
| Profil | Ism, telefon, avatar, manzil, sozlamalar | ❌ |
| Kompyuter yig'ish | PC Builder: socket/RAM/PSU/korpus/sovutgich mosligini avtomatik tekshiradi | ❌ |
| TEXNO AI | Mahsulot tanlash bo'yicha AI yordamchi (faqat lokal bazadagi mahsulotlar bilan) | ✅ ha |

## Texnologiyalar

- **Flutter + Dart**, state management: **Riverpod**, navigatsiya: **GoRouter**
- **SQLite + Drift** (lokal baza, drift codegen bilan)
- **Dio** (TEXNO AI so'rovlari va ixtiyoriy REST rejimi uchun)
- **flutter_secure_storage** (AI API kaliti va server tokeni xavfsiz saqlanadi)
- **Repository pattern + RepositoryFactory** — REST API + PostgreSQL'ga o'tish
  bitta sozlama bilan (UI kodi o'zgarmaydi)

## Tuzilma

```
lib/
├── core/
│   ├── theme/       # Dark premium tema
│   ├── router/      # GoRouter + pastki menyu (5 tab)
│   ├── constants/   # Konstantalar, kategoriya ikonlari
│   ├── utils/       # Format, specs parser
│   └── widgets/     # Umumiy widgetlar (ProductCard va h.k.)
├── data/
│   ├── database/    # Drift sxema + katalog seed
│   ├── models/      # Enumlar, CartEntry, ProductFilter va h.k.
│   ├── remote/      # REST qatlami: ApiClient, ApiMappers, BackendConfig
│   ├── repositories/# Interfeyslar + Drift impl. + api/ (REST impl.) + RepositoryFactory
│   └── services/    # AuthService, PaymentService, AiService, Connectivity
├── features/        # home, catalog, search, product, cart, checkout,
│                    # orders, favorites, profile, pc_builder, texno_ai, auth, splash
└── main.dart
```

## APK build qilish

Eng oson yo'l — GitHub Actions (repo'dagi `.github/workflows/build-apk.yml`):

```bash
git push origin arena/019ff0b8-baraka-market   # workflow avtomatik ishga tushadi
gh run watch                                    # jarayonni kuzatish
gh run download <RUN_ID> -n texno-bozor-apk     # APK ni yuklab olish
```

Lokal build (Flutter SDK + Android SDK kerak):

```bash
cd texno_bozor
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift codegen
flutter build apk --release
# Natija: build/app/outputs/flutter-apk/app-release.apk
```

## TEXNO AI sozlash

API kaliti **hech qachon kodga yozilmaydi**. Variantlar (ustuvorlik tartibida):

1. Ilova ichida: **Profil → Sozlamalar → AI API kaliti** (Secure Storage'da saqlanadi)
2. `.env` fayl: `TEXNO_AI_API_KEY=...` (build vaqtida asset sifatida o'qiladi)
3. Build flag: `flutter build apk --dart-define=TEXNO_AI_API_KEY=...`

OpenAI-uyg'un istalgan endpoint ishlaydi:

```
TEXNO_AI_BASE_URL=https://api.openai.com/v1
TEXNO_AI_MODEL=gpt-4o-mini
```

AI javoblari faqat lokal bazadagi mahsulotlarga asoslanadi (grounding) —
mavjud bo'lmagan mahsulot yoki narx o'ylab topilmaydi.

## Serverga tayyor arxitektura

Sukut bo'yicha barcha ma'lumot Drift (SQLite)'da — server umuman kerak emas.
Lekin REST qatlami **allaqachon yozilgan**, shuning uchun kelajakda server
ulansa kod qayta yozilmaydi:

- `lib/data/repositories/api/` — `ProductRepository`, `CategoryRepository`,
  `CartRepository`, `OrderRepository`, `UserRepository` interfeyslarining
  REST implementatsiyalari (offline-first: javob lokal bazaga keshlanadi,
  internet yo'q bo'lsa keshdan o'qiladi).
- `RepositoryFactory` (`lib/data/repositories/repository_factory.dart`) —
  rejimga qarab Drift yoki REST implementatsiyani qaytaradi. Ekranlar faqat
  abstrakt interfeyslar bilan ishlaydi, ya'ni **UI kodi o'zgarmaydi**.
- Yoqish: **Profil → Sozlamalar → Ma'lumot manbai → Server**, so'ng
  base URL (masalan `https://api.texnobozor.uz/v1`) va token. "Tekshirish"
  tugmasi `GET /health` ni chaqiradi. `.env` yoki `--dart-define` orqali ham:
  `API_MODE=remote`, `API_BASE_URL=...`, `API_TOKEN=...`.
- Sevimlilar, qidiruv tarixi, sharhlar va PC yig'ilmalar server rejimida ham
  qurilma ichida qoladi.

Kutilayotgan endpointlar:

```
GET    /health
GET    /products            GET /products/:id     GET /products?search=
GET    /products/brands     GET /categories
GET    /cart                POST /cart            PATCH|DELETE /cart/:productId
DELETE /cart                PUT  /cart
GET    /orders              GET /orders/:id       POST /orders
PATCH  /orders/:id/status
GET    /users/me            POST /users           PATCH|DELETE /users/me
```

Javob `[...]` yoki `{data: [...]}` / `{items: [...]}` / `{results: [...]}`
ko'rinishida bo'lishi mumkin — `ApiMappers` ikkalasini ham tushunadi,
maydon nomlari `camelCase` va `snake_case` bo'lsa ham.

Qolgan qadamlar: `AuthService` → OTP/SMS autentifikatsiya,
`PaymentService` → real Click/Payme gatewaylari.

## Testlar

```bash
cd texno_bozor
flutter test
```

- `test/pricing_test.dart` — narx, chegirma, yetkazish, formatlash
- `test/repositories_test.dart` — katalog, savat, buyurtma, sevimlilar, profil
- `test/compatibility_test.dart` — PC Builder moslik qoidalari
- `test/api_mappers_test.dart` — JSON ↔ model konvertatsiyasi
- `test/repository_factory_test.dart` — Lokal/Server rejim almashinuvi
