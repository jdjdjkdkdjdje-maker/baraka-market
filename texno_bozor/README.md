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
- **Dio** (faqat TEXNO AI so'rovlari uchun)
- **flutter_secure_storage** (AI API kaliti xavfsiz saqlanadi)
- **Repository pattern** — keyinchalik REST API + PostgreSQL'ga o'tish oson

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
│   ├── database/    # Drift sxema + demo katalog seed
│   ├── models/      # Enumlar, CartEntry, ProductFilter va h.k.
│   ├── repositories/# Product/Cart/Order/User/Favorites/Review/... (abstraksiya + Drift impl.)
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

Hozir barcha ma'lumot Drift (SQLite)'da. Keyinchalik server ulansa:

- `ProductRepository`, `CartRepository`, `OrderRepository`, `UserRepository`
  va boshqalarning **REST implementatsiyasi** yoziladi va `providers.dart`da
  almashtiriladi — UI kodi o'zgarmaydi.
- `AuthService` → OTP/SMS autentifikatsiya.
- `PaymentService` → real Click/Payme gatewaylari.
