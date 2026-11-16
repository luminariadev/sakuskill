# API Contract SakuSkill (v1.1 — Auth, Profile, Gigs CRUD & Discovery)

- **Base URL Lokal (Web / Desktop / iOS Simulator):** `http://localhost:3000/api/v1`
- **Base URL Android Emulator (Flutter):** `http://10.0.2.2:3000/api/v1`
- **Content-Type:** `application/json`
- **Header Autentikasi (untuk endpoint terproteksi):** `Authorization: Bearer <token>`

---

## 1. Standar Envelope JSON (Konsisten di Seluruh Endpoint)

### A. Format Response Sukses (`200 OK`, `201 Created`)
```json
{
  "success": true,
  "message": "Pesan keberhasilan dalam bahasa Indonesia",
  "data": {},
  "meta": {}
}
```

### B. Format Response Error (`400`, `401`, `403`, `404`, `409`, `422`, `500`, `503`)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Data masukan tidak valid. Periksa kembali kolom yang wajib diisi.",
    "details": [
      {
        "field": "body.judul",
        "message": "Judul minimal 5 karakter."
      }
    ]
  }
}
```

### C. Daftar Kode Error Aplikasi (`error.code`)
| HTTP Status | `error.code` | Kondisi Pemicu |
| :--- | :--- | :--- |
| `400` | `INVALID_CATEGORY_OR_SKILL` | `skill_id` atau `kategori` tidak ada pada master `skills`. |
| `400` | `GIG_HAS_ACTIVE_TRANSACTIONS` | Mencoba menghapus permanen gig yang masih terikat pesanan/barter aktif (FR-21). |
| `401` | `UNAUTHORIZED` | Header `Authorization: Bearer <token>` tidak disertakan. |
| `401` | `INVALID_CREDENTIALS` | Email atau kata sandi salah saat login (FR-05). |
| `401` | `INVALID_OR_EXPIRED_TOKEN` | Token JWT rusak atau sudah melewati masa berlaku. |
| `401` | `TOKEN_REVOKED` | Token sudah dicabut melalui endpoint `POST /auth/logout` (FR-06). |
| `403` | `FORBIDDEN_NOT_OWNER` | Pengguna mencoba mengubah/menghapus gig milik pengguna lain (FR-07). |
| `403` | `ADMIN_PERMISSION_REQUIRED` | Pengguna non-admin mengakses fitur moderasi/verifikasi Administrator. |
| `404` | `GIG_NOT_FOUND` / `USER_NOT_FOUND` | Data gig atau pengguna tidak ditemukan. |
| `409` | `EMAIL_ALREADY_EXISTS` | Email sudah terdaftar saat registrasi (FR-02). |
| `422` | `VALIDATION_ERROR` | Field wajib kosong, panjang teks kurang/lebih, atau harga negatif. |

---

## 2. Modul Autentikasi (`/api/v1/auth`)

### 2.1 Register Akun Baru
- **Endpoint:** `POST /api/v1/auth/register`
- **Auth:** Publik
- **Catatan Multi-Kapabilitas:** Setiap akun yang mendaftar otomatis dapat membeli jasa (Pelanggan) sekaligus menerbitkan gigs (Penyedia Jasa).
- **Request Body:**
```json
{
  "nama": "Arya Fabio Ismail",
  "email": "arya@uinsgd.ac.id",
  "kata_sandi": "PasswordAman123!",
  "deskripsi_profil": "Mahasiswa Teknik Informatika UIN SGD Bandung"
}
```
- **Response `201 Created`:**
```json
{
  "success": true,
  "message": "Registrasi akun berhasil.",
  "data": {
    "user": {
      "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "nama": "Arya Fabio Ismail",
      "email": "arya@uinsgd.ac.id",
      "peran": "Penyedia Jasa",
      "status_verifikasi": "Belum Terverifikasi",
      "deskripsi_profil": "Mahasiswa Teknik Informatika UIN SGD Bandung",
      "dibuat_pada": "2026-11-14T08:00:00.000Z",
      "capabilities": {
        "can_buy_services": true,
        "can_publish_gigs": true,
        "is_admin": false
      }
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 2.2 Login
- **Endpoint:** `POST /api/v1/auth/login`
- **Auth:** Publik
- **Request Body:**
```json
{
  "email": "arya@uinsgd.ac.id",
  "kata_sandi": "PasswordAman123!"
}
```
- **Response `200 OK`:** Sama dengan struktur `data` pada Register (`user` beserta `capabilities` dan `token`).

### 2.3 Logout & Pencabutan Token (Revocation)
- **Endpoint:** `POST /api/v1/auth/logout`
- **Auth:** Wajib (`Bearer <token>`)
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Berhasil keluar (logout). Sesi telah diakhiri.",
  "data": null
}
```

---

## 3. Modul Profil & Pengguna (`/api/v1/users` atau `/api/v1/profile`)

### 3.1 Get Profil Milik Sendiri
- **Endpoint:** `GET /api/v1/users/me` (atau `GET /api/v1/profile/me`)
- **Auth:** Wajib (`Bearer <token>`)
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Data profil berhasil dimuat.",
  "data": {
    "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "nama": "Arya Fabio Ismail",
    "email": "arya@uinsgd.ac.id",
    "peran": "Penyedia Jasa",
    "status_verifikasi": "Belum Terverifikasi",
    "deskripsi_profil": "Mahasiswa Teknik Informatika UIN SGD Bandung",
    "rata_rata_rating": 4.85,
    "jumlah_ulasan": 7,
    "keterampilan": [
      {
        "skill_id": 1,
        "nama_keterampilan": "Instalasi OS & Perbaikan Laptop",
        "kategori": "Jasa Teknis"
      }
    ],
    "portofolio": [],
    "dibuat_pada": "2026-11-14T08:00:00.000Z",
    "capabilities": {
      "can_buy_services": true,
      "can_publish_gigs": true,
      "is_admin": false
    }
  }
}
```

### 3.2 Update Profil & Keterampilan Milik Sendiri
- **Endpoint:** `PUT /api/v1/users/me` (atau `PATCH /api/v1/users/me`)
- **Auth:** Wajib (`Bearer <token>`)
- **Request Body:**
```json
{
  "nama": "Arya Fabio Ismail",
  "deskripsi_profil": "Melayani servis laptop, instalasi Linux, dan setup jaringan di Cibiru.",
  "skill_ids": [1, 2]
}
```
- **Response `200 OK`:** Mengembalikan objek profil terbaru.

### 3.3 Get Profil Publik Penyedia Jasa
- **Endpoint:** `GET /api/v1/users/:id`
- **Auth:** Publik
- **Response `200 OK`:** Mengembalikan profil publik (tanpa alamat email pribadi) beserta daftar `keterampilan`, `portofolio`, `rata_rata_rating`, dan `jumlah_ulasan`.

---

## 4. Modul Gigs / Service Listings CRUD & Discovery (`/api/v1/gigs` atau `/api/v1/listings`)

### 4.1 Daftar Master Kategori & Keterampilan
- **Endpoint:** `GET /api/v1/gigs/categories`
- **Auth:** Publik
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Daftar kategori dan keterampilan berhasil dimuat.",
  "data": {
    "categories": ["Akademik & Dokumen", "Bimbingan Belajar", "Desain", "Fotografi", "Jasa Teknis"],
    "skills": [
      {
        "skill_id": 1,
        "nama_keterampilan": "Instalasi OS & Perbaikan Laptop",
        "kategori": "Jasa Teknis"
      }
    ]
  }
}
```

### 4.2 Create Gig Baru
- **Endpoint:** `POST /api/v1/gigs` (atau `POST /api/v1/listings`)
- **Auth:** Wajib (`Bearer <token>`)
- **Aturan Validasi:**
  - `judul`: wajib, 5–200 karakter.
  - `deskripsi`: wajib, 20–5000 karakter.
  - `skill_id` atau `kategori`: wajib diisi salah satu.
  - `harga`: wajib, angka `>= 0` (isi `0` jika murni `Barter`).
  - `latitude` (`-90` s.d. `90`) & `longitude` (`-180` s.d. `180`): wajib.
  - `tipe_penawaran`: `'Berbayar'` | `'Barter'` | `'Berbayar dan Barter'`.
  - `deskripsi_imbalan_barter`: wajib minimal 5 karakter apabila `tipe_penawaran` mengandung `Barter`.
  - `status`: `'Aktif'` | `'Nonaktif'` (default: `'Aktif'`).
- **Request Body:**
```json
{
  "judul": "Jasa Instalasi Dual-Boot Linux & Optimasi Laptop",
  "deskripsi": "Melayani instalasi distribusi Linux berdampingan dengan Windows tanpa hapus data, lengkap dengan konfigurasi driver untuk mahasiswa UIN SGD.",
  "skill_id": 1,
  "harga": 50000,
  "latitude": -6.9315,
  "longitude": 107.7180,
  "tipe_penawaran": "Berbayar dan Barter",
  "deskripsi_imbalan_barter": "Barter dengan desain poster acara himpunan atau fotografi.",
  "status": "Aktif"
}
```
- **Response `201 Created`:** Mengembalikan objek detail gig yang baru dibuat.

### 4.3 Discovery & Pencarian Gigs (Hyperlocal + Filter)
- **Endpoint:** `GET /api/v1/gigs` (atau `GET /api/v1/listings`)
- **Auth:** Publik
- **Query Parameters (Seluruhnya Opsional):**
  - `q` atau `search`: Kata kunci pada judul, deskripsi, atau keterampilan.
  - `kategori`: Nama kategori (misal `Jasa Teknis`, `Desain`).
  - `skill_id`: Filter ID keterampilan spesifik.
  - `tipe_penawaran`: `Berbayar` | `Barter` | `Berbayar dan Barter`.
  - `min_harga` & `max_harga`: Filter rentang harga.
  - `min_rating`: Filter rata-rata rating minimal penyedia (`1` s.d. `5`).
  - `lat` & `lng`: Titik acuan pencarian (default: Kampus UIN SGD `-6.9311, 107.7175`).
  - `radius_m`: Radius pencarian dalam meter (default: `3000`).
  - `use_radius`: `true` (default, hanya dalam radius PostGIS) atau `false` (tampilkan semua jarak).
  - `sort_by`: `jarak` (default) | `harga_asc` | `harga_desc` | `rating` | `terbaru`.
  - `page` (default `1`) & `limit` (default `20`).
- **Contoh Request:** `GET /api/v1/gigs?q=Linux&kategori=Jasa%20Teknis&radius_m=3000&sort_by=jarak`
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Daftar listing jasa berhasil dimuat.",
  "data": [
    {
      "listing_id": "d290f1ee-6c54-4b01-90e6-d701748f0851",
      "penyedia_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "skill_id": 1,
      "judul": "Jasa Instalasi Dual-Boot Linux & Optimasi Laptop",
      "deskripsi": "Melayani instalasi distribusi Linux...",
      "harga": "50000.00",
      "tipe_penawaran": "Berbayar dan Barter",
      "deskripsi_imbalan_barter": "Barter dengan desain poster acara himpunan atau fotografi.",
      "status": "Aktif",
      "latitude": -6.9315,
      "longitude": 107.718,
      "jarak_km": 0.07,
      "nama_penyedia": "Arya Fabio Ismail",
      "verifikasi_penyedia": "Belum Terverifikasi",
      "nama_keterampilan": "Instalasi OS & Perbaikan Laptop",
      "kategori": "Jasa Teknis",
      "rata_rata_rating": 0,
      "jumlah_ulasan": 0,
      "dibuat_pada": "2026-11-14T08:15:00.000Z"
    }
  ],
  "meta": {
    "titik_acuan": { "lat": -6.9311, "lng": 107.7175 },
    "radius_meter": 3000,
    "use_radius": true,
    "sort_by": "jarak",
    "page": 1,
    "limit": 20,
    "total_loaded": 1
  }
}
```

### 4.4 Get Daftar Gigs Milik Sendiri (Kelola Gigs)
- **Endpoint:** `GET /api/v1/gigs/me`
- **Auth:** Wajib (`Bearer <token>`)
- **Deskripsi:** Menampilkan seluruh gig milik pengguna yang sedang login, baik yang berstatus `Aktif` maupun `Nonaktif`.

### 4.5 Get Detail Gig
- **Endpoint:** `GET /api/v1/gigs/:id`
- **Auth:** Publik (atau sertakan `Bearer <token>` jika pemilik ingin meninjau gig miliknya yang berstatus `Nonaktif`).
- **Response `200 OK`:** Mengembalikan seluruh atribut gig ditambah array `portofolio_penyedia` dan `ulasan_terbaru`.

### 4.6 Update Gig (Validasi Pemilik)
- **Endpoint:** `PUT /api/v1/gigs/:id` atau `PATCH /api/v1/gigs/:id`
- **Auth:** Wajib (`Bearer <token>` — Hanya pemilik gig yang diizinkan; pengguna lain otomatis ditolak dengan `403 FORBIDDEN_NOT_OWNER`).
- **Request Body (Kirim field yang ingin diubah):**
```json
{
  "harga": 45000,
  "status": "Aktif"
}
```

### 4.7 Ubah Status Publikasi Gig (`Aktif` / `Nonaktif`)
- **Endpoint:** `PATCH /api/v1/gigs/:id/status`
- **Auth:** Wajib (`Bearer <token>` — Validasi pemilik)
- **Request Body:**
```json
{
  "status": "Nonaktif"
}
```

### 4.8 Delete Gig (Validasi Pemilik & Proteksi Transaksi Aktif)
- **Endpoint:** `DELETE /api/v1/gigs/:id`
- **Auth:** Wajib (`Bearer <token>` — Validasi pemilik)
- **Response `200 OK`:**
```json
{
  "success": true,
  "message": "Gig / listing jasa berhasil dihapus.",
  "data": null
}
```

---

## 5. Endpoint Khusus Administrator (Permission Terpisah)

- `PATCH /api/v1/users/:id/verification` — Mengubah `status_verifikasi` pengguna (`'Terverifikasi'` | `'Ditolak'`).
- `PATCH /api/v1/gigs/:id/moderation` — Menyembunyikan/memulihkan gig (`'Disembunyikan Moderasi'` | `'Aktif'`).

---

## 6. Modul Transaksi & Rekening Bersama Escrow (Prioritas P0 — Demo MVP)

Modul ini mengimplementasikan alur transaksi pesanan berbayar bergaransi Rekening Bersama (*Escrow*) sesuai rancangan Figma (*Screen 10 s/d 14B & Screen 17 s/d 18*).

```text
[Klien: Checkout] ──> Status: 'Dibayar' & Escrow: 'Ditahan (Simulasi)'
        │
        ▼
[Penyedia: Deliver] ──> Status: 'Menunggu Konfirmasi' (Kirim Link Drive & Mockup)
        │
        ├──> [Klien: Revise] ──> Status: 'Dikerjakan' (Sisa revisi berkurang)
        │
        └──> [Klien: Release] ──> Status: 'Selesai' & Escrow: 'Dilepas (Simulasi)'
```

---

### 6.1. Buat Pesanan Baru & Kunci Dana Escrow (Checkout)
* **Method & Path:** `POST /api/v1/orders`
* **Deskripsi:** Klien melakukan pemesanan layanan. Sistem secara otomatis memotong saldo simulasi klien dan menahan dana pada rekening bersama (*Escrow status: Ditahan (Simulasi)*).
* **Headers:** `Authorization: Bearer <token_pembeli>`

#### Request Body:
```json
{
  "listing_id": "4a7c1b52-9f33-4f9e-a892-d610b64d30a1",
  "deskripsi_kebutuhan": "Desain Spanduk Katering Berkah Cibiru Ukuran 3x1 m, warna hijau kuning, lampiran foto ayam bakar.",
  "harga_disepakati": 50000,
  "durasi_hari": 3,
  "catatan_klien": "Mohon nomor WhatsApp dibuat besar dan format warna CMYK siap cetak."
}
```

#### Response Sukses (`201 Created`):
```json
{
  "success": true,
  "message": "Pesanan berhasil dibuat. Dana Rp 50.000 telah diamankan di Rekening Bersama (Escrow).",
  "data": {
    "order_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "kode_pesanan": "SK-2026-091",
    "listing_id": "4a7c1b52-9f33-4f9e-a892-d610b64d30a1",
    "judul_layanan": "Desain Spanduk Katering Berkah Cibiru (3x1 m)",
    "pembeli_id": "b8a1c9e2-4f33-4f9e-a892-d610b64d3001",
    "penyedia_id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
    "nama_penyedia": "Salma Nur Oktavia",
    "harga_disepakati": 50000,
    "tenggat": "2026-11-18T10:00:00.000Z",
    "status_pesanan": "Dibayar",
    "pembayaran": {
      "payment_id": "e7b1a2c3-d4e5-4f6a-8b9c-0d1e2f3a4b5c",
      "jumlah_pembayaran": 50000,
      "status_pembayaran": "Terverifikasi",
      "status_dana_simulasi": "Ditahan (Simulasi)"
    },
    "stepper_tahap": 1,
    "label_stepper": "Dana Terkunci di Escrow"
  }
}
```

---

### 6.2. Daftar Pesanan Pengguna (Tab Orders / Escrow Ledger)
* **Method & Path:** `GET /api/v1/orders/my-orders`
* **Deskripsi:** Mengambil riwayat pesanan aktif maupun selesai untuk akun pengguna. Mendukung konsep *Dual-Role* (pesanan sebagai pembeli atau sebagai penyedia jasa).
* **Headers:** `Authorization: Bearer <token>`
* **Query Params:**
  * `peran`: `pembeli` (default) atau `penyedia`
  * `status`: `aktif`, `selesai`, `semua` (opsional)

#### Response Sukses (`200 OK`):
```json
{
  "success": true,
  "message": "Daftar pesanan berhasil dimuat",
  "data": [
    {
      "order_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "kode_pesanan": "SK-2026-091",
      "judul_layanan": "Desain Spanduk Katering Berkah Cibiru (3x1 m)",
      "lawan_transaksi": {
        "user_id": "c1f2e3d4-5a6b-7c8d-9e0f-1a2b3c4d5e6f",
        "nama": "Salma Nur Oktavia",
        "peran": "Penyedia Jasa",
        "jurusan": "Teknik Informatika"
      },
      "harga": 50000,
      "tenggat": "2026-11-18T10:00:00.000Z",
      "sisa_waktu_label": "1 Hari 12 Jam Lagi",
      "status_pesanan": "Dikerjakan",
      "status_escrow": "Ditahan (Simulasi)",
      "stepper_tahap": 2,
      "ada_bukti_serah_terima": false
    }
  ],
  "meta": {
    "total_aktif": 1,
    "total_dana_tertahan": 50000
  }
}
```

---

### 6.3. Rincian Detail Pesanan & Countdown Pengerjaan
* **Method & Path:** `GET /api/v1/orders/:order_id`
* **Deskripsi:** Memuat detail lengkap pesanan, instruksi brief, lampiran file awal dari klien, timer countdown pengerjaan, dan berkas serah terima akhir.
* **Headers:** `Authorization: Bearer <token>`

#### Response Sukses (`200 OK`):
```json
{
  "success": true,
  "message": "Detail pesanan berhasil diambil",
  "data": {
    "order_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "kode_pesanan": "SK-2026-091",
    "status_pesanan": "Menunggu Konfirmasi",
    "status_escrow": "Ditahan (Simulasi)",
    "harga": 50000,
    "brief": {
      "deskripsi": "Desain Spanduk Katering Berkah Cibiru Ukuran 3x1 m",
      "catatan": "Warna hijau kuning cerah, nomor WhatsApp besar, lampiran foto ayam bakar.",
      "lampiran_klien": "https://sakuskill.storage/brief/Foto_Ayam_Bakar.jpg"
    },
    "sla": {
      "tenggat": "2026-11-18T10:00:00.000Z",
      "detik_tersisa": 16335,
      "is_terlambat": false
    },
    "deliverable": {
      "tautan_berkas": "https://drive.google.com/salma/spanduk-berkah-cibiru-final.pdf",
      "catatan_penyedia": "Halo Pak Dimas, desain spanduk ukuran 3x1 m sudah selesai format CMYK siap cetak.",
      "mockup_url": "https://sakuskill.storage/deliverables/mockup-spanduk-cibiru.png",
      "dikirim_pada": "2026-11-15T14:30:00.000Z"
    },
    "revisi": {
      "batas_maksimal": 2,
      "telah_digunakan": 0,
      "sisa_kesempatan": 2
    },
    "stepper_tahap": 3,
    "label_stepper": "Bukti Pekerjaan Dikirim (Menunggu Verifikasi Klien)"
  }
}
```

---

### 6.4. Penyedia Menyerahkan Hasil Pekerjaan (Deliverable Submission)
* **Method & Path:** `POST /api/v1/orders/:order_id/deliver`
* **Deskripsi:** Penyedia mengunggah tautan Google Drive berkas master, catatan penyerahan, dan gambar mockup tampilan hasil. Status pesanan berubah menjadi `Menunggu Konfirmasi`.
* **Headers:** `Authorization: Bearer <token_penyedia>`

#### Request Body:
```json
{
  "tautan_berkas": "https://drive.google.com/salma/spanduk-berkah-cibiru-final.pdf",
  "catatan_penyedia": "Halo Pak Dimas, desain spanduk ukuran 3x1 m sudah selesai format CMYK siap cetak. Nomor WhatsApp dan foto menu sudah disesuaikan.",
  "mockup_url": "https://sakuskill.storage/deliverables/mockup-spanduk-cibiru.png",
  "konfirmasi_kesesuaian_brief": true
}
```

#### Response Sukses (`200 OK`):
```json
{
  "success": true,
  "message": "Hasil pekerjaan berhasil dikirim ke klien. Menunggu verifikasi pelepasan dana.",
  "data": {
    "order_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "status_pesanan": "Menunggu Konfirmasi",
    "stepper_tahap": 3
  }
}
```

---

### 6.5. Klien Menyetujui Hasil & Mencairkan Dana Escrow (Release Fund)
* **Method & Path:** `PATCH /api/v1/orders/:order_id/release`
* **Deskripsi:** Klien memverifikasi berkas dan puas dengan pekerjaan. Sistem mencairkan dana dari penampungan Rekening Bersama ke saldo dompet penyedia.
* **Headers:** `Authorization: Bearer <token_pembeli>`
* **Payload:** Tidak wajib (opsional memberikan rating awal bintang 1–5).

#### Response Sukses (`200 OK`):
```json
{
  "success": true,
  "message": "Pekerjaan disetujui! Dana Rp 50.000 telah berhasil dicairkan ke saldo Salma Nur Oktavia.",
  "data": {
    "order_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "status_pesanan": "Selesai",
    "status_escrow": "Dilepas (Simulasi)",
    "dana_dicairkan": 50000,
    "penerima": "Salma Nur Oktavia",
    "diselesaikan_pada": "2026-11-15T15:45:00.000Z",
    "stepper_tahap": 4,
    "label_stepper": "Selesai & Dana Berhasil Dicairkan"
  }
}
```

---

### 6.6. Klien Mengajukan Permintaan Revisi
* **Method & Path:** `POST /api/v1/orders/:order_id/revise`
* **Deskripsi:** Klien meminta perbaikan hasil kerja. Status pesanan dikembalikan ke `Dikerjakan` dan kuota revisi berkurang 1.
* **Headers:** `Authorization: Bearer <token_pembeli>`

#### Request Body:
```json
{
  "catatan_revisi": "Tolong warna latar spanduk dibuat sedikit lebih cerah, dan ukuran nomor WhatsApp diperbesar 20%."
}
```

#### Response Sukses (`200 OK`):
```json
{
  "success": true,
  "message": "Permintaan revisi telah diteruskan ke penyedia jasa.",
  "data": {
    "order_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "status_pesanan": "Dikerjakan",
    "sisa_revisi": 1
  }
}
```

---

## 7. Modul Mitigasi Risiko & Mediasi Admin (Prioritas P1 — Sprint Lanjutan)

Endpoint berikut disediakan sebagai acuan implementasi fitur lanjutan sesuai layar Figma *Screen 15B–15E* dan *Desktop Admin Dispute Courtroom*:

| Method | Endpoint | Peran Aktor | Deskripsi & Payload Utama |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/orders/:id/extension` | Penyedia | Mengajukan tambahan tenggat: `{ "tambahan_jam": 12, "alasan": "...", "progres_persen": 75 }`. |
| `PATCH` | `/api/v1/orders/:id/extension` | Klien | Merespons ajuan: `{ "keputusan": "DISETUJUI" \| "DITOLAK" }`. |
| `POST` | `/api/v1/orders/:id/cancel-overdue` | Klien | Batalkan pesanan terlambat sepihak: Dana escrow 100% otomatis di-refund ke saldo klien. |
| `POST` | `/api/v1/orders/:id/appeal` | Penyedia | Mengajukan banding sengketa jika progres $>70\%$: Status order menjadi `Dalam Sengketa`, dana dibekukan sementara. |
| `POST` | `/api/v1/admin/disputes/:id/verdict` | Super Admin | Eksekusi amar putusan mediasi: `{ "amar": "SPLIT_50_50" \| "REFUND_100" \| "RELEASE_100", "catatan": "..." }`. Dana escrow dibagi sesuai putusan. |
