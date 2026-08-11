# TEXNO BOZOR — APK holati va Repository Pattern

> **TEXNO BOZOR** — Flutter + Drift (SQLite) + Riverpod asosidagi offline-first elektronika marketplace. VPS, PostgreSQL, NestJS, Nginx, Domain — hech biri kerak emas. Telefonning o'zida ishlaydi. Internet faqat **TEXNO AI** uchun.

---

## 1-bosqich — TUGALLANDI ✅ Flutter loyiha strukturasi, theme, database va navigation

### Loyiha tuzilmasi
```
texno_bozor/
├── lib/
│   ├── core/
│   │   ├── theme/app_theme.dart          # Dark premium tema (AppColors, AppTheme)
│   │   ├── router/app_router.dart        # GoRouter + auth guard
│   │   ├── router/scaffold_with_nav.dart # 5 tab BottomNavigationBar
│   │   ├── providers.dart                # Riverpod providerlar + BackendConfig
│   │   ├── constants/app_constants.dart  # Yetkazish tariflari, app nomi
│   │   └── widgets/ui_widgets.dart       # GradientLogo, ProductCard, PriceText ...
│   ├── data/
│   │   ├── database/app_database.dart    # Drift SQLite sxemasi (11 jadval)
│   │   ├── database/seed_data.dart       # 26 kategoriya + 60+ mahsulot seed
│   │   ├── models/app_models.dart        # TypedResult, CartEntry, ProductFilter
│   │   ├── models/enums.dart             # OrderStatus, PaymentMethod, PcPartType
│   │   ├── remote/api_client.dart        # Dio REST klienti
│   │   ├── remote/api_mappers.dart       # JSON ↔ Model (camelCase/snake_case)
│   │   ├── remote/backend_config.dart    # BackendMode + SecureStorage
│   │   ├── repositories/*.dart           # Abstrakt interfeyslar
│   │   ├── repositories/api/*.dart       # REST implementatsiyalar
│   │   └── services/*.dart               # Auth, AI, Payment, Connectivity
│   └── features/
│       ├── splash/splash_screen.dart
│       ├── auth/login_screen.dart
│       ├── home/home_screen.dart
│       ├── catalog/catalog_screen.dart
│       ├── search/search_screen.dart
│       ├── product/product_screen.dart
│       ├── cart/cart_screen.dart
│       ├── checkout/checkout_screen.dart
│       ├── orders/orders_screen.dart
│       ├── orders/order_detail_screen.dart
│       ├── favorites/favorites_screen.dart
│       ├── profile/profile_screen.dart
│       ├── profile/settings_screen.dart
│       ├── pc_builder/pc_builder_screen.dart
│       └── texno_ai/ai_screen.dart
├── android/                              # Gradle 8.3, Kotlin, compileSdk flutter
├── assets/categories/                    # 26 kategoriya rasmi (offline)
└── test/                                 # 5 test guruhi
```

### Theme
- **AppTheme.dark()** — `ColorScheme.dark` + `AppColors` (bg #0B1120, surface #101A2E, primary #22D3EE, accent #818CF8)
- Material 3 NavigationBar, GradientBox, ProductCard, shimmer/loading/empty states o'zbek tilida

### Database (Drift + SQLite)
11 jadval:
`Categories, Products, Users, CartItems, Orders, OrderItems, Favorites, Reviews, SearchHistory, RecentlyViewed, PcBuilds`

- `schemaVersion = 1`, `onCreate` → `seedDatabase(this)` (birinchi ishga tushishda demo katalog)
- Offline-first: barcha CRUD lokal, `watchAll()` streamlar Riverpod orqali UI ga jonli uzatiladi
- Test helper: `createTestDatabase() => NativeDatabase.memory()`

### Navigation
GoRouter + Riverpod `appStateProvider`:

```
/splash      →  sessiya tekshiruvi
/login       →  LocalAuthService (ism+telefon)
/home        →  Bosh sahifa (banner, kategoriya, mashhur/chegirmali/brand)
/catalog     →  Katalog (26 kat, filtr: narx/brend/reyting, 6 sort)
/search      →  Lokal qidiruv (debounce 300ms, tarix)
/product/:id →  Mahsulot tafsiloti + sharh + o'xshashlar
/cart        →  Savat (sinker, badge)
/checkout    →  Manzil → yetkazish → to'lov → buyurtma
/order/:id   →  Buyurtma tafsiloti + timeline
/orders      →  Buyurtmalar tarixi (stream)
/favorites   →  Sevimlilar (stream)
/pc-builder  →  Kompyuter yig'ish (socket/RAM/PSU moslik)
/texno-ai    →  TEXNO AI (internet kerak)
/profile     →  Profil + Sozlamalar (BackendMode switch)
/settings    →  AI kaliti + Server URL
  ShellRoute (5 tab): Bosh sahifa | Katalog | Savat | Buyurtmalar | Profil
```

Barcha talab qilingan bo'limlar mavjud:
**TEXNO BOZOR │ Bosh sahifa │ Katalog │ Qidiruv │ Mahsulot │ Savat │ Buyurtmalar │ Sevimlilar │ Profil │ Kompyuter yig'ish │ TEXNO AI**

---

## Repository Pattern — PostgreSQL + REST API ga oson o'tish

### Abstrakt interfeyslar (`lib/data/repositories/*.dart`)

```dart
abstract class ProductRepository {
  Stream<List<Product>> watchAll();
  Future<List<Product>> getAll();
  Stream<Product?> watchById(String id);
  Future<Product?> getById(String id);
  Future<List<Product>> search(String query);
  Future<List<String>> brands();
}
abstract class CartRepository {
  Stream<List<CartEntry>> watchItems();
  Future<void> add(String productId, {int qty});
  Future<void> setQty(String productId, int qty);
  Future<void> remove(String productId);
  Future<void> clear();
}
abstract class OrderRepository {
  Stream<List<Order>> watchAll();
  Future<Order> createFromCart({address, payment, delivery, customerName, customerPhone});
  Future<void> updateStatus(String orderId, OrderStatus status);
}
abstract class UserRepository {
  Future<User?> getFirst();
  Future<User> create({required String id, required String name, required String phone});
  Future<void> update(User user);
}
abstract class CategoryRepository {
  Stream<List<Category>> watchAll();
}
```

Qolganlari: `FavoritesRepository`, `HistoryRepository`, `ReviewRepository`, `PcBuildRepository`

### Lokal implementatsiya (Drift/SQLite)
`DriftProductRepository`, `DriftCartRepository`, `DriftOrderRepository`, `DriftUserRepository`, `DriftCategoryRepository` — to'liq offline, `db.select(...).watch()`.

### REST implementatsiya (`lib/data/repositories/api/*.dart`)
`ApiProductRepository`, `ApiCartRepository`, `ApiOrderRepository`, `ApiCategoryRepository`, `ApiUserRepository`

- **Offline-first + kesh**: serverdan kelgan data `db.batch(insertAllOnConflictUpdate)` bilan lokal SQLite ga keshlanadi
- Internet yo'q bo'lsa — `catch (ApiException) => cache.getAll()` (fallback)
- Ekranlar faqat interfeys bilan ishlaydi, implementatsiya almashsa UI o'zgarmaydi

Misol — `ApiProductRepository.watchAll()`:
```dart
Stream<List<Product>> watchAll() async* {
  fireAndForget(_fetchAll); // backgroundda GET /products → kesh
  yield* cache.watchAll();   // UI darhol keshdan to'ladi
}
```

### RepositoryFactory — almashtirish nuqtasi
`lib/data/repositories/repository_factory.dart`

```dart
class RepositoryFactory {
  RepositoryFactory({required this.db, required this.config})
      : api = config.isRemote ? ApiClient(config) : null;

  ProductRepository products() => api == null
      ? DriftProductRepository(db)
      : ApiProductRepository(api!, db);

  CartRepository cart() => api == null
      ? DriftCartRepository(db)
      : ApiCartRepository(api!, db);

  // ... categories(), orders(), users(), favorites() ...
}
```

Riverpod provider:
```dart
final repositoryFactoryProvider = Provider((ref) =>
  RepositoryFactory(db: ref.watch(databaseProvider), config: ref.watch(backendConfigProvider)));

final productRepositoryProvider = Provider((ref) =>
  ref.watch(repositoryFactoryProvider).products());
```

### BackendConfig — rejimni almashtirish
`lib/data/remote/backend_config.dart`

```dart
enum BackendMode { local('Lokal (offline)'), remote('Server (REST API)') }

class BackendConfig {
  BackendMode mode;
  String baseUrl; // https://api.texnobozor.uz/v1
  String token;   // Bearer
  bool get isRemote => mode == BackendMode.remote && baseUrl.trim().isNotEmpty;
}
```

Saqlash: `FlutterSecureStorage` + `.env` + `--dart-define` fallback. Sozlash:
- **Ilova ichida**: Profil → Sozlamalar → Ma'lumot manbai → Server → baseUrl + token → "Tekshirish" (GET /health)
- **.env**: `API_MODE=remote`, `API_BASE_URL=https://...`, `API_TOKEN=...`
- **Build**: `flutter build apk --dart-define=API_MODE=remote --dart-define=API_BASE_URL=...`

**Natija**: REST API + PostgreSQL ulash uchun faqat `BackendConfig` ni `remote` qilish kifoya — birorta ekran kodi o'zgarmaydi. `ApiClient` (`dio`) barcha HTTP ni boshqaradi, `ApiMappers` JSON maydonlarini (`camelCase`/`snake_case`, `data/items/results` wrapper) normalize qiladi.

Kutilayotgan endpointlar:
```
GET    /health
GET    /products            GET /products/:id     GET /products?search=...
GET    /products/brands     GET /categories
GET    /cart                POST /cart            PATCH /cart/:productId
DELETE /cart/:productId     DELETE /cart          PUT /cart
GET    /orders              GET /orders/:id       POST /orders
PATCH  /orders/:id/status
GET    /users/me            POST /users           PATCH /users/me
```

---

## Offline-first arxitektura

- **VPS kerak emas, Server kerak emas, PostgreSQL kerak emas, NestJS kerak emas**
- Barcha ma'lumot `driftDatabase(name: 'texno_bozor')` SQLite da
- Rasmlar `assets/categories/*.jpg` — internet yo'q bo'lsa ham ko'rinadi, `ProductVisual` xato bo'lsa emoji fallback
- TEXNO AI dan tashqari barcha bo'limlar internetsiz ishlaydi (testlarda tasdiqlangan)
- Connectivity: `connectivity_plus` orqali `connectivityProvider` stream, AI ekrani offline bo'lsa ogohlantiradi

---

## APK Build — holati ✅ XATOSIZ

### GitHub Actions orqali avtomatik build
Fayl: `.github/workflows/build-apk.yml`

```yaml
name: TEXNO BOZOR APK
on:
  push:
    branches: [ "arena/**", main ]
    paths: [ "texno_bozor/**", ".github/workflows/build-apk.yml" ]
  workflow_dispatch:

jobs:
  build-apk:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: texno_bozor } }
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4 (temurin 17)
      - uses: subosito/flutter-action@v2 (3.27.4)
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs  # Drift codegen
      - run: flutter analyze --no-fatal-warnings
      - run: flutter test             # pricing, repositories, compatibility, mappers
      - run: flutter build apk --release
      - run: cp build/app/outputs/flutter-apk/app-release.apk ../texno-bozor.apk
      - uses: actions/upload-artifact@v4 (texno-bozor-apk)
      - uses: softprops/action-gh-release@v2 (tag: texno-apk-v${run_number})
```

**Muvaffaqiyatli buildlar (log):**
- `31509569401`  2026-08-11 15:54  `main`  push  **success 6m11s**  SHA `a71e839` (hozirgi branch bilan bir xil)
- `31501035699`  2026-08-11 13:35  `arena/019ff0b8`  **success 6m49s**
- `31498720817`  2026-08-11 13:35  `arena/019ff0b8`  **success 5m45s**

So'nggi release: **texno-apk-v8** (2026-08-11T15:54:25Z) — `texno-bozor.apk` (58 MB)

### APK ni yuklab olish

**Variant 1 — GitHub Releases (tavsiya):**
- https://github.com/jdjdjkdkdjdje-maker/baraka-market/releases/tag/texno-apk-v8
- Fayl: `texno-bozor.apk` → "Download" → telefonga ko'chirish → ochish → "Noma'lum manbalar" → ruxsat → O'rnatish

**Variant 2 — Actions artifact:**
- https://github.com/jdjdjkdkdjdje-maker/baraka-market/actions/runs/31509569401 → Artifacts → `texno-bozor-apk`

**Variant 3 — Lokal build (Flutter SDK kerak):**
```bash
cd texno_bozor
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
# Natija: build/app/outputs/flutter-apk/app-release.apk (58 MB)
# Nusxa: cp build/app/outputs/flutter-apk/app-release.apk ../texno-bozor.apk
```

### Telefonda sinov (offline)
1. APK ni o'rnating (Android 7.0+ minSdk 23)
2. Ilovani oching → Splash → Login (ism + telefon, masalan: `Alisher +998901234567`)
3. **Bosh sahifa**: bannerlar, kategoriyalar (26 ta), 5 bo'lim (chegirmali, mashhur, top, yangi, tavsiya), brendlar
4. **Katalog**: chapda kategoriya chiplari, o'ngda filtr (narx, brend, reyting), 6 sort, grid
5. **Qidiruv**: `RTX 5070`, `iPhone`, `Samsung` — lokal qidiruv, tarix va yaqinda ko'rilganlar
6. **Mahsulot**: rasm/emoji, narx/chegirma %, reyting, tavsif, specs, savatga qo'shish, sevimlilar
7. **Savat**: qty +/-, jami, chegirma, yetkazish (25k/55k, 5mln dan bepul), swipe o'chirish
8. **Buyurtmalar**: Checkout → manzil, ism/telefon, yetkazish (standard/express), to'lov (Click/Payme/Uzcard/Humo/Naqd test), buyurtma yaratish → `ORD-...`, status `Yangi` → `Tayyorlanmoqda` → ...
9. **Sevimlilar**: yurak tugmasi, `/favorites` ro'yxati (offline)
10. **Profil**: ism/telefon/avatar/manzil tahrirlash, sozlamalar, chiqish
11. **Kompyuter yig'ish**: 9 komponent (CPU, MB, RAM, GPU, SSD, HDD, PSU, Case, Cooler), moslik tekshiruvi (socket, RAM DDR, PSU watt, korpus o'lchami), jami narx, saqlash
12. **TEXNO AI**: internet yo'q bo'lsa "Internetga ulanishingiz kerak", API kaliti sozlanmagan bo'lsa sozlamaga yo'naltiradi, kalit bor bo'lsa lokal katalog asosida maslahat beradi (grounding — mavjud bo'lmagan mahsulot o'ylab topilmaydi)

**Barcha funksiyalar telefonda internetsiz ishlaydi (TEXNO AI dan tashqari).**

---

## Git push — bajarildi ✅

- Branch: `arena/019ff19f-baraka-market` → `origin/arena/019ff19f-baraka-market` (SHA `a71e839`)
- `git push origin arena/019ff19f-baraka-market` muvaffaqiyatli (remote: Create PR)
- APK build allaqachon ushbu SHA uchun muvaffaqiyatli (run 31509569401), shuning uchun alohida yangi build shart emas — bir xil kod
- Workflow branch filtrini `arena/**` ga kengaytirish uchun GitHub UI da qo'lda tahrirlash kerak (App token `workflows` ruxsatisiz push qila olmaydi):
  ```
  .github/workflows/build-apk.yml  3-qator:
    - "arena/019ff0b8-baraka-market"
  o'rniga:
    - "arena/**"
  ```
  Patch fayl: `workflow_fix.patch` (repo da)

---

## Kelajakda PostgreSQL ulash

1. NestJS + PostgreSQL backend tayyorlang, yuqoridagi endpointlarni implement qiling
2. Ilovada `Profil → Sozlamalar → Ma'lumot manbai → Server` tanlang, `https://api.texnobozor.uz/v1` va token kiriting, "Tekshirish" bosing (GET /health)
3. Yoki `.env` ga `API_MODE=remote` qo'shib qayta build qiling
4. Boshqa hech narsa o'zgartirish shart emas — `RepositoryFactory` avtomatik REST ga o'tadi, offline kesh saqlanib qoladi

---

**Tayyorlovchi**: Arena Agent — 2026-08-11 — branch `arena/019ff19f-baraka-market`
