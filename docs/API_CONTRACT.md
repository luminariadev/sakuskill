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
