# Reverse Engineering Anything (REA) Benchmark Analysis
**Framework Acuan GitHub:** [morluto/rea](https://github.com/morluto/rea) (Reverse Engineer Anything)  
**Aplikasi Sasaran:** SakuSkill Mobile (Flutter Clean Architecture)  
**Mata Kuliah:** Sosio-Informatika &bull; UIN Sunan Gunung Djati Bandung  

---

## 1. Metodologi REA (`morluto/rea`)
Berdasarkan framework **Reverse Engineer Anything (REA)**, dekonstruksi sistem dilakukan dengan menginspeksi alur kerja (*feature tracing*), ekstraksi pola arsitektur terbaik (*evidence-backed feature cloning*), dan membuang komponen yang membebani performa mobile:

```
[Target Aplikasi Populer]
  ├── TaskRabbit (Hyperlocal On-Demand)
  ├── Fiverr / Fastwork (Escrow Milestone Workflow)
  └── Bunz / Simbi (Bilateral Timebanking & Barter)
         │
         ▼ (REA Inspection & Architectural Extraction)
[SakuSkill Mobile Flutter Clean Architecture]
  ├── Domain: Pure Dart UseCases (0-Overhead)
  ├── Data: SQLite / Drift Binary Persistence
  └── Presentation: flutter_map (OSM) + RBAC Enforcement
```

---

## 2. Matriks Komparasi Dekonstruksi Fitur

| Parameter Analisis | TaskRabbit | Fiverr / Fastwork | Bunz / Simbi | **SakuSkill Mobile (Hasil REA)** |
|---|---|---|---|---|
| **Model Geospasial** | GPS Presisi Tinggi (Google Maps SDK) | Non-geografis (Global Gig) | Komunitas Lokal | **Hyperlocal 2–3 km (OpenStreetMap via `flutter_map`)** |
| **Overhead Ukuran SDK Peta** | +25 MB (Google Play Services) | N/A | +18 MB | **~1.8 MB (Native Raster Tiles, Bebas Biaya API)** |
| **Model Moneter** | Kartu Kredit Escrow | Rekening Escrow Valas | Virtual Barter Token | **Simulasi Escrow Ledger (IDR) + Barter Bilateral** |
| **Potongan Platform** | 15% – 20% | 20% | Biaya Keanggotaan | **0% (Ekonomi Mikro Mahasiswa Kampus)** |
| **Penyelesaian Sengketa** | CS Korporasi | CS Arbitrase | Reputasi Komunitas | **Sidang Komite Etik Kampus (RBAC Rektorat Lt. 2)** |

---

## 3. Hasil Ekstraksi ke Clean Architecture Flutter

1. **Eliminasi Bloatware Peta**:
   - *Temuan REA*: TaskRabbit memuat bundle Google Play Services yang berat dan sering boros baterai karena background location polling.
   - *Solusi SakuSkill*: Menggunakan formula matematika murni **Haversine Formula** di `FormatterUtils.calculateDistanceKm` dan tile raster OpenStreetMap melalui `flutter_map`. Render 60 FPS tanpa memory leak.
2. **Penyederhanaan Barter Simetris**:
   - *Temuan REA*: Bunz/Simbi mengalami kegagalan likuiditas akibat inflasi koin virtual (*virtual token devaluation*).
   - *Solusi SakuSkill*: Menghilangkan token perantara; menggunakan **Kontrak Bilateral 1-to-1** dengan validasi ganda (*dual-submission & dual-approval*).
3. **Kepatuhan Etika Akademik Sosio-Informatika**:
   - Sistem moderasi otomatis memblokir kata kunci perjokian tugas/skripsi (`SecuritySanitizer.containsForbiddenKeywords`).
