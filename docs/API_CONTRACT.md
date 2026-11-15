# API Contract SakuSkill (v1)

- **Base URL Lokal (Web / Desktop / iOS Simulator):** `http://localhost:3000/api/v1`
- **Base URL Android Emulator (Flutter):** `http://10.0.2.2:3000/api/v1`
- **Content-Type:** `application/json`

## 1. Standar Envelope JSON

### Response Sukses (`200 OK`, `201 Created`)
```json
{
  "success": true,
  "message": "Pesan keberhasilan dalam bahasa Indonesia",
  "data": {},
  "meta": {}
}
```

### Response Error (`400`, `401`, `403`, `404`, `422`, `500`, `503`)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Data masukan tidak valid. Periksa kembali kolom yang wajib diisi.",
    "details": [
      {
        "field": "query.radius_m",
        "message": "Number must be greater than or equal to 100"
      }
    ]
  }
}
```

## 2. Daftar Endpoint Awal (P0 Setup Baseline)

| Method | Path | Deskripsi | Query / Payload | Status Code |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/health` | Mengecek status server Express, koneksi PostgreSQL, dan ekstensi PostGIS. | Tidak ada | `200 OK`, `503 Service Unavailable` |
| `GET` | `/api/v1/listings` | Mencari listing jasa aktif dalam radius hyperlocal (PostGIS `ST_DWithin`). | Query opsional: `lat`, `lng`, `radius_m` (default `3000`), `tipe_penawaran` (`Berbayar` / `Barter` / `Berbayar dan Barter`) | `200 OK`, `422 Unprocessable Entity` |

---

## 3. Modul Transaksi & Rekening Bersama Escrow (Prioritas P0 — Demo MVP)

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

### 3.1. Buat Pesanan Baru & Kunci Dana Escrow (Checkout)
* **Method & Path:** `POST /api/v1/orders`
* **Deskripsi:** Klien melakukan pemesanan layanan. Sistem secara otomatis memotong saldo simulasi klien dan menahan dana pada rekening bersama (*Escrow status: Ditahan (Simulasi)*).
* **Headers:** `Content-Type: application/json`, `X-User-Id: <uuid_pembeli>` *(sementara sebelum JWT Auth live)*

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

### 3.2. Daftar Pesanan Pengguna (Tab Orders / Escrow Ledger)
* **Method & Path:** `GET /api/v1/orders/my-orders`
* **Deskripsi:** Mengambil riwayat pesanan aktif maupun selesai untuk akun pengguna. Mendukung konsep *Dual-Role* (pesanan sebagai pembeli atau sebagai penyedia jasa).
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

### 3.3. Rincian Detail Pesanan & Countdown Pengerjaan
* **Method & Path:** `GET /api/v1/orders/:order_id`
* **Deskripsi:** Memuat detail lengkap pesanan, instruksi brief, lampiran file awal dari klien, timer countdown pengerjaan, dan berkas serah terima akhir.

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

### 3.4. Penyedia Menyerahkan Hasil Pekerjaan (Deliverable Submission)
* **Method & Path:** `POST /api/v1/orders/:order_id/deliver`
* **Deskripsi:** Penyedia mengunggah tautan Google Drive berkas master, catatan penyerahan, dan gambar mockup tampilan hasil. Status pesanan berubah menjadi `Menunggu Konfirmasi`.

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

### 3.5. Klien Menyetujui Hasil & Mencairkan Dana Escrow (Release Fund)
* **Method & Path:** `PATCH /api/v1/orders/:order_id/release`
* **Deskripsi:** Klien memverifikasi berkas dan puas dengan pekerjaan. Sistem mencairkan dana dari penampungan Rekening Bersama ke saldo dompet penyedia.
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

### 3.6. Klien Mengajukan Permintaan Revisi
* **Method & Path:** `POST /api/v1/orders/:order_id/revise`
* **Deskripsi:** Klien meminta perbaikan hasil kerja. Status pesanan dikembalikan ke `Dikerjakan` dan kuota revisi berkurang 1.

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

## 4. Modul Mitigasi Risiko & Mediasi Admin (Prioritas P1 — Sprint Lanjutan)

Endpoint berikut disediakan sebagai acuan implementasi fitur lanjutan sesuai layar Figma *Screen 15B–15E* dan *Desktop Admin Dispute Courtroom*:

| Method | Endpoint | Peran Aktor | Deskripsi & Payload Utama |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/orders/:id/extension` | Penyedia | Mengajukan tambahan tenggat: `{ "tambahan_jam": 12, "alasan": "...", "progres_persen": 75 }`. |
| `PATCH` | `/api/v1/orders/:id/extension` | Klien | Merespons ajuan: `{ "keputusan": "DISETUJUI" \| "DITOLAK" }`. |
| `POST` | `/api/v1/orders/:id/cancel-overdue` | Klien | Batalkan pesanan terlambat sepihak: Dana escrow 100% otomatis di-refund ke saldo klien. |
| `POST` | `/api/v1/orders/:id/appeal` | Penyedia | Mengajukan banding sengketa jika progres $>70\%$: Status order menjadi `Dalam Sengketa`, dana dibekukan sementara. |
| `POST` | `/api/v1/admin/disputes/:id/verdict` | Super Admin | Eksekusi amar putusan mediasi: `{ "amar": "SPLIT_50_50" \| "REFUND_100" \| "RELEASE_100", "catatan": "..." }`. Dana escrow dibagi sesuai putusan. |
