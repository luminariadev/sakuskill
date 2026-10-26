# Strix AI Security Audit & Penetration Testing Report
**Platform Acuan GitHub:** [usestrix/strix](https://github.com/usestrix/strix) (Autonomous AI Penetration Testing)  
**Aplikasi Sasaran:** SakuSkill Mobile (Flutter Native)  
**Standar Keamanan:** OWASP Mobile Top 10 (M1-M10) + Sosio-Informatika Ethics  

---

## 1. Profil Pengujian Otomatis Strix AI

Strix menguji permukaan serangan (*attack surface*) SakuSkill secara dinamis menggunakan orkestrasi agen otonom:

```
[Strix AI Penetration Agent]
  ├── Test 1: Broken Access Control (RBAC Bypass di Halaman Admin)
  ├── Test 2: Insecure Deliverable URL Injection (Stored XSS)
  ├── Test 3: Escrow Ledger Double-Spend / Premature Release
  └── Test 4: Academic Anti-Joki Evasion Attack
```

---

## 2. Hasil Audit & Bukti Mitigasi Kode

### A. M1: Broken Object Level Authorization (RBAC Gate)
- **Vektor Uji Strix**: Akun Mahasiswa Klien (`CLIENT` Farhan) mencoba membuka rute mediasi sengketa atau memanggil fungsi eksekusi dana `resolveDispute()`.
- **Hasil Uji**: **BLOCKED (HTTP 403 / Access Denied)**.
- **Implementasi**: Widget `AdminDisputeHearingPage` memeriksa `currentUser.role == UserRole.campusAdmin`. Jika peran tidak sesuai, sistem menampilkan layar penolakan dan memblokir seluruh manipulasi data.

### B. M3: Insecure Communication & XSS Injection via Deliverables
- **Vektor Uji Strix**: Penyedia menyusupkan tautan berbahaya: `javascript:alert(1)` atau `data:text/html,...` pada kolom bukti pengerjaan.
- **Hasil Uji**: **BLOCKED (Validation Error)**.
- **Implementasi**: `SecuritySanitizer.isValidSecureUrl(proofUrl)` memverifikasi bahwa URL wajib diawali protokol aman `https://` atau `http://`.

### C. M8: Security Misconfiguration & State Machine Race Conditions
- **Vektor Uji Strix**: Klien mencoba mencairkan dana saat pesanan masih berada pada status `escrowLocked` (sebelum penyedia menyerahkan hasil kerja).
- **Hasil Uji**: **REJECTED (State Machine Exception)**.
- **Implementasi**: `AppStateProvider.completeEscrowOrder()` mensyaratkan status wajib bernilai `EscrowStatus.workSubmitted`.

### D. Penegakan Etika Akademik Anti-Joki
- **Vektor Uji Strix**: Upaya mempublikasikan listing dengan deskripsi tersembunyi "joki tugas kalkulus / joki skripsi".
- **Hasil Uji**: **BLOCKED**.
- **Implementasi**: Filter `SecuritySanitizer.containsForbiddenKeywords` menolak pendaftaran jasa secara seketika.
