# Frontend Mobile — Fondasi, Navigasi & Modul Discovery

Penanggung jawab: **Anggota 3 — Frontend Lead Developer**
Desain acuan: Figma *SakuSkill → Mobile Design* (`00 · Design system`, `01 · Home discovery`, `02 · Explore campus`).

---

## 1. Struktur kode (Clean Architecture, feature-first)

```text
mobile/lib/
├── main.dart                     # entry point → SakuSkillApp
├── app.dart                      # MaterialApp + tema + router + AppScope
├── core/
│   ├── config/app_config.dart    # base URL API, titik pusat kampus, opsi radius, tile OSM
│   ├── di/app_dependencies.dart  # composition root (DI manual) + AppScope
│   ├── navigation/
│   │   ├── app_router.dart       # AppRoutes (nama rute) + onGenerateRoute
│   │   └── main_shell.dart       # bottom navigation 5 tab (Home·Explore·Orders·Barter·Profil)
│   ├── theme/                    # AppColors, AppTypography, AppRadius/Spacing/Shadows, AppTheme
│   ├── utils/                    # geo.dart (GeoPoint + Haversine), formatters, debouncer
│   └── widgets/                  # SakuPill, InitialsAvatar, EmptyStateView, OfflineDataBanner, placeholder modul
└── features/
    ├── discovery/
    │   ├── domain/               # entities, repository (interface), usecases, ListingFilter
    │   ├── data/                 # model JSON, remote (REST) & local (data contoh) datasource, repository impl
    │   └── presentation/         # controller (ChangeNotifier) + scope, pages, widgets
    ├── escrow/presentation/      # placeholder tab Orders  → Anggota 4
    ├── barter/presentation/      # placeholder tab Barter  → Anggota 4
    └── auth/presentation/        # placeholder tab Profil  → Anggota 5
```

Aturan dependensi: `presentation → domain ← data`. Lapisan **domain tidak mengimpor Flutter UI maupun paket peta** (koordinat memakai `GeoPoint`, bukan `LatLng`).

## 2. Fitur yang selesai

| Fitur | File utama | Catatan |
| :--- | :--- | :--- |
| Navigasi utama 5 tab | `core/navigation/main_shell.dart` | `IndexedStack` + lazy build; pindah tab via `MainShell.goTo(context, MainTab.explore)` |
| Home Discovery | `pages/home_discovery_page.dart` | Header, sapaan, kolom cari, filter cepat, kategori, banner escrow, feed terdekat, pull-to-refresh, skeleton/empty/error |
| Pencarian | `pages/search_page.dart` | Debounce 300 ms, kata kunci multi-kata (AND), kategori, radius, Smart Barter |
| Kategori | `widgets/discovery_filters.dart` | Mengikuti seed `skills.kategori`: Desain, Jasa Teknis, Fotografi, Bimbingan Belajar |
| Filter radius | `RadiusSegmented`, `showRadiusSheet` | 500 m · 1 km · 2 km (default) · 3 km |
| Peta kampus | `pages/campus_map_page.dart` | `flutter_map` + tile OpenStreetMap, lingkaran radius (meter), marker talenta, kartu pratinjau, tombol recenter, atribusi OSM |
| Haversine | `core/utils/geo.dart` | Jarak dihitung ulang di klien dari titik asal → filter radius & urutan terdekat |
| Detail jasa | `pages/service_detail_page.dart` | Pintu masuk ke alur Escrow/Barter |

## 3. State management

- `DiscoveryController extends ChangeNotifier` — status (`initial/loading/success/failure`), filter, hasil, kategori, listing terpilih di peta.
- `DiscoveryScope` (`InheritedNotifier`) membagikan **satu** controller untuk Home dan Explore, sehingga radius/kategori/barter selalu sinkron antar-tab. Halaman pencarian membuat controller sendiri agar kata kunci tidak memengaruhi feed Home.
- Respons usang diabaikan (penanda `_requestId`), jadi ganti filter cepat-cepat tidak menampilkan hasil lama.
- Tidak menambah paket state management; cukup `ChangeNotifier` bawaan Flutter. Bila tim sepakat pindah ke Riverpod/Bloc, cukup ganti lapisan `presentation/controllers`.

## 4. Sumber data & fallback

`DiscoveryRepositoryImpl` memanggil `GET {API_BASE_URL}/listings?lat&lng&radius_m` (lihat `docs/API_CONTRACT.md`). Bila server tidak terjangkau/timeout, aplikasi memakai **data contoh di sekitar UIN SGD Cibiru** dan menampilkan banner kuning "Server belum terhubung". Kata kunci, kategori, Smart Barter dan radius diterapkan di klien (`ListingFilter`) untuk kedua sumber.

```bash
cd mobile
flutter pub get
flutter run                                   # coba API lokal, fallback otomatis
flutter run --dart-define=USE_MOCK_DATA=true  # paksa data contoh (demo)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1   # HP fisik
```

## 5. Kontrak untuk anggota lain

**Anggota 4 (Escrow & Smart Barter)** — rute sudah dicadangkan di `AppRoutes`; ganti builder placeholder di `app_router.dart`:

| Rute | Argumen | Dipicu dari |
| :--- | :--- | :--- |
| `AppRoutes.orderService` | `ServiceListing` | Tombol "Pesan Jasa" (detail & peta) |
| `AppRoutes.proposeBarter` | `ServiceListing` | Tombol "Ajak Barter" |

Tab **Orders** dan **Barter**: ganti `OrdersPlaceholderPage` / `BarterPlaceholderPage` di `main_shell.dart`.

**Anggota 5 (Backend & Data)** — mohon tambahkan koordinat ke query `findNearby` agar listing dari server tampil sebagai marker peta (saat ini hanya listing dengan koordinat yang dipetakan):

```sql
ST_Y(sl.lokasi::geometry) AS lat,
ST_X(sl.lokasi::geometry) AS lng,
```

Field opsional yang juga langsung terbaca bila tersedia: `prodi`, `patokan`, `rating`, `jumlah_ulasan`. Daftarkan repository baru di `core/di/app_dependencies.dart`. Nama pengguna di Home masih placeholder (`HomeDiscoveryPage._demoUserName`).

**Anggota 6 (AI)** — tombol "AI Price Estimator" di Home membuka `AppRoutes.priceEstimator`.

**Anggota 7 (QA)** — tes tersedia:

```bash
flutter analyze
flutter test
```

- `test/core/geo_and_formatters_test.dart` — Haversine (nilai referensi), format jarak & Rupiah.
- `test/features/discovery/listing_filter_test.dart` — radius, urutan terdekat, Smart Barter, kategori, kata kunci, parsing JSON.
- `test/widget_test.dart` — Home, filter barter, kategori, halaman pencarian (memakai `AppDependencies.offline()`, tanpa jaringan).

## 6. Konsistensi tema

Pakai token, jangan hardcode warna/ukuran di fitur:

```dart
AppColors.primary / .barter / .escrow / .integrity / .dispute
AppTypography.display / .heading / .subheading / .bodyLarge / .body / .caption
AppRadius.tagBr (4) / .inputBr (8) / .cardBr (14) / .pillBr
SakuPill(label: 'Bisa Barter', tone: SakuPillTone.barter)
```

Font desain (Plus Jakarta Sans) belum dibundel; letakkan file `.ttf` di `assets/fonts/`, daftarkan di `pubspec.yaml`, lalu set `fontFamily: AppTypography.fontFamily` di `AppTheme`.

## 7. Catatan

- Lokasi pengguna sementara = pusat kampus (`AppConfig.campusCenter`). Integrasi GPS (`geolocator`) bisa ditambahkan dengan mengganti `DiscoveryFilter.origin`.
- Tile OpenStreetMap wajib mencantumkan atribusi (sudah ada) dan User-Agent aplikasi (`AppConfig.osmUserAgent`).
