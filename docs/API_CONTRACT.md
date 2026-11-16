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
