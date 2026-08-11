# Repository Pattern — TEXNO BOZOR

## Maqsad
UI va biznes logika ma'lumot manbasini bilmasligi kerak. Bugun SQLite, ertaga PostgreSQL — kod o'zgarmaydi.

## Interfeys vs Implementatsiya

| Interfeys | Lokal (Drift) | REST (PostgreSQL) |
|-----------|---------------|-------------------|
| ProductRepository | DriftProductRepository | ApiProductRepository |
| CategoryRepository | DriftCategoryRepository | ApiCategoryRepository |
| CartRepository | DriftCartRepository | ApiCartRepository |
| OrderRepository | DriftOrderRepository | ApiOrderRepository |
| UserRepository | DriftUserRepository | ApiUserRepository |
| FavoritesRepository | DriftFavoritesRepository | (lokal qoladi) |
| HistoryRepository | DriftHistoryRepository | (lokal qoladi) |

## Diagram

```
UI (ConsumerWidget)
   ↓ ref.watch(productRepositoryProvider)
RepositoryFactory
   ├─ isRemote==false → Drift* (SQLite)
   └─ isRemote==true  → Api* (dio + kesh → SQLite)
         ↓ ApiClient
      REST API → PostgreSQL
```

## Almashtirish

```dart
// Profil → Sozlamalar
await ref.read(backendConfigProvider.notifier).update(
  BackendConfig(mode: BackendMode.remote, baseUrl: 'https://api.texnobozor.uz/v1', token: '...'),
);
// Yoki .env
// API_MODE=remote
// API_BASE_URL=https://api.texnobozor.uz/v1
```

Qolgan ekranlar `ref.watch(productRepositoryProvider).watchAll()` deb chaqiraveradi — factory ichida qaysi implementatsiya ishlashi hal bo'ladi.

## Offline-first kesh

Api* lar yozishda: avval lokalga yozadi, keyin `fireAndForget(() => api.post(...))`
O'qishda: fon rejimida serverdan yangilaydi, UI esa darhol lokal keshdan to'ladi.

