# SakuSkill Mobile

[![CI/CD Pipeline](https://github.com/luminariadev/sakuskill/actions/workflows/ci.yml/badge.svg)](https://github.com/luminariadev/sakuskill/actions/workflows/ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture-4CAF50?logo=dart)](./ARCHITECTURE.md)
[![Security Audit](https://img.shields.io/badge/Security-Strix_Compliant-673AB7)](./SECURITY.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

> **Marketplace Keahlian Mikro Mahasiswa & Smart Barter Kampus Terintegrasi AI**  
> *Studi Kasus & Implementasi: UIN Sunan Gunung Djati Bandung (Kampus 1 Cibiru)*

---

## 📖 Deskripsi Proyek

**SakuSkill** adalah platform digital peer-to-peer terverifikasi yang dirancang untuk memberdayakan mahasiswa dalam menawarkan layanan teknis dan kreatif (IT Support, Desain Grafis, Fotografi & Videografi, Mentoring Keahlian, dan Dukungan Acara Kampus).

Platform ini mengintegrasikan:
1. **Peta Hyperlocal Kampus**: Penemuan talenta mahasiswa di sekitar lingkungan kampus Cibiru dalam radius nyata.
2. **Escrow Payment Ledger**: Jaminan keamanan transaksi dana mahasiswa yang hanya dicairkan setelah bukti pengerjaan disetujui.
3. **Smart Barter Bilateral**: Mekanisme tukar keahlian non-tunai (skill-for-skill) antar mahasiswa dengan validasi bilateral.
4. **AI Price Estimator**: Rekomendasi tarif adil dan transparan berbasis LLM Cloud (Groq Cloud API / 9router) dengan fallback algoritma deterministik.
5. **Guardrail Anti-Joki**: Filter integritas akademik yang melarang keras perjokian tugas kuliah, skripsi, maupun ujian.

---

## 🏛 Clean Architecture Overview

Aplikasi dibangun dengan prinsip **Clean Architecture (Pure Dart Domain)** untuk memastikan kode modular, mudah diuji (*testable*), dan bebas dari ketergantungan framework UI:

```
lib/
├── core/
│   ├── constants/campus_constants.dart      # Koordinat Cibiru, Kategori, Base Tarif
│   ├── errors/failures.dart                 # Failure Domain Model
│   ├── security/rbac_matrix.dart            # Matrix Otorisasi Peran (Client, Provider, Admin)
│   ├── security/url_sanitizer.dart          # HTTPS Validator & Guardrail Anti-Joki
│   ├── theme/app_theme.dart                 # Emerald Green Theme & Typography
│   └── utils/currency_formatter.dart        # Format Rupiah & Formula Haversine
├── features/
│   ├── services/                            # Modul Discovery Layanan & Map
│   │   ├── domain/entities/                 # UserEntity, ServiceItem
│   │   └── presentation/                    # Pages, Providers, Widgets (ServiceCard, Map)
│   ├── escrow/                              # Modul Escrow Ledger Pembayaran Aman
│   │   ├── domain/entities/                 # EscrowOrder State Machine
│   │   └── presentation/pages/              # EscrowOrdersPage
│   ├── barter/                              # Modul Smart Barter Bilateral
│   │   ├── domain/entities/                 # BarterContract Dual Deliverable
│   │   └── presentation/pages/              # BarterHubPage
│   ├── ai_estimator/                        # Modul Rekomendasi Tarif AI Mahasiswa
│   │   ├── domain/usecases/                 # Pure Dart: CalculateAIPriceUseCase
│   │   ├── data/datasources/                # NineRouterAIService (Groq Cloud LLM)
│   │   └── presentation/widgets/            # AIEstimatorSheet
│   └── admin/                               # Modul Mediasi Komite Etik Kampus
│       ├── domain/entities/                 # DisputeTicket
│       └── presentation/pages/              # AdminDisputeHearingPage (RBAC Gate)
└── main.dart                                # Entrypoint MultiProvider & MaterialApp
```

---

## ⚙️ DevOps & CI/CD Pipeline

Proyek ini menerapkan standar **DevSecOps** modern dengan GitHub Actions:

* **Static Code Analysis (`flutter analyze`)**: Memastikan kepatuhan linter, tipe data ketat, dan nol peringatan kode.
* **Automated Testing (`flutter test --coverage`)**: Pengujian otomatis 100% lulus untuk domain logic, guardrail anti-joki, dan widget UI.
* **Continuous Integration**: Pengecekan otomatis pada setiap `push` dan `pull_request` ke cabang `main`.
* **Automated Build Artifacts**: Kompilasi file Android APK Debug yang dapat diunduh langsung dari GitHub Actions artifact.
* **Automated Release**: Publikasi otomatis file release APK saat tag `v*` dibuat.

---

## 🚀 Memulai (Quickstart)

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.24+ / Channel stable)
- [Android SDK / Studio](https://developer.android.com/studio) atau VS Code
- Git

### Instalasi & Menjalankan Aplikasi
```bash
# 1. Clone repository
git clone https://github.com/luminariadev/sakuskill.git
cd sakuskill

# 2. Ambil dependensi Flutter
flutter pub get

# 3. Jalankan analisis statis & pengujian
flutter analyze
flutter test

# 4. Jalankan aplikasi pada perangkat / emulator
flutter run
```

### Konfigurasi AI Estimator (Opsional)
Untuk mengaktifkan model LLM Cloud Groq secara langsung saat build/run:
```bash
flutter run --dart-define=ROUTER_API_KEY=gsk_your_groq_api_key
```
*Catatan: API Key juga dapat dimasukkan atau diganti secara langsung melalui antarmuka aplikasi dengan menekan ikon `<···>` pada sheet AI Price Estimator.*

---

## 🛠️ Otomatisasi Perintah (Makefile)

Tersedia `Makefile` untuk mempermudah eksekusi tugas pengembangan:

```bash
make setup          # Mengunduh dependensi pub
make analyze        # Menjalankan static analysis
make test           # Menjalankan seluruh unit & widget test
make coverage       # Menghasilkan laporan coverage (coverage/lcov.info)
make build-apk      # Mengompilasi APK debug
make build-release  # Mengompilasi APK release
make clean          # Membersihkan cache build
```

---

## 🧪 Testing & Verifikasi Keamanan

Pengujian unit dan widget mencakup:
1. **Anti-Joki Guardrail**: Memastikan penolakan otomatis terhadap kata kunci pelanggaran akademik (*joki skripsi, joki tugas, buatkan makalah*).
2. **URL Sanitizer**: Memastikan URL deliverable aman dan hanya menerima skema `http://` dan `https://`.
3. **RBAC Authorization**: Memastikan isolasi hak akses antara mahasiswa umum, penyedia jasa, dan admin etik kampus.
4. **AI Price Estimator Fallback**: Menjamin kontinuitas fungsi rekomendasi harga baik saat terhubung ke Cloud LLM maupun saat offline.

Jalankan pengujian dengan perintah:
```bash
flutter test
```

---

## 📄 Lisensi & Kontribusi

Proyek ini dilisensikan di bawah [MIT License](./LICENSE).  
Kontribusi dan pengembangan kode mengikuti panduan di [CONTRIBUTING.md](./CONTRIBUTING.md).
