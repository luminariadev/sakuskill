# K-02 — Daftar teks "dana ditahan" yang perlu disesuaikan

> Status: **menunggu keputusan UI/UX + PM** (dan Anggota 8 untuk aspek etika). Belum ada teks layar yang diubah.
> Acuan: PRD §11 K-02, SKPL §2.1 / FR-58 / FR-59 / NFR-23, AC-Escrow-01.
> Usulan copy terpusat: `mobile/lib/core/copy/escrow_sim_copy.dart` (`EscrowSimCopy`).
> Audit: 16 Nov 2026, branch `feat/fe-core-m1`.

**Masalahnya.** SakuSkill hanya mencatat status dana secara simulasi; pembayaran diproses payment gateway. Teks di bawah menyiratkan sistem benar-benar menahan, mengunci, membekukan, atau meneruskan uang, dan sebagian status dana tampil tanpa keterangan simulasi (melanggar FR-59/AC-Escrow-01).

Kolom *Terkait K-01*: teks tentang saldo dompet/penarikan ikut bergantung pada keputusan K-01 (Dompet → Ringkasan Transaksi).

## Milik Anggota 3 (Frontend Lead)

| Lokasi | Teks sekarang | Masalah | Usulan (`EscrowSimCopy`) |
| :--- | :--- | :--- | :--- |
| `features/discovery/presentation/widgets/home_sections.dart:166` | "Dana Aman Rekening Bersama Escrow" | Menyiratkan rekening penampung nyata | `bannerTitle` |
| `features/discovery/presentation/widgets/home_sections.dart:175` | "Uang Anda ditahan sistem secara aman dan HANYA dicairkan setelah…" | Klaim penahanan uang | `bannerBody` |
| `features/auth/presentation/pages/welcome_page.dart:41` | "Dana Aman Rekening Bersama Escrow" | Sama | `bannerTitle` atau poin keunggulan lain |
| `features/auth/presentation/pages/register_page.dart:139` | "…Ketentuan Layanan Rekening Bersama Escrow & Sistem Transaksi…" | Nama layanan menyiratkan escrow nyata | "Ketentuan Layanan & Sistem Transaksi SakuSkill" |
| `features/discovery/presentation/widgets/home_sections.dart:47` | "Saldo dompet Rp …" (header Beranda) | Terkait K-01 | Tunggu K-01 |
| `core/widgets/saku_surfaces.dart:382` | Langkah "Dana Ditahan → … → Dana Dilepas" (`MilestoneSteps`) | Label tanpa "(Simulasi)" | Pakai label `EscrowSimStatus` |

## Milik Anggota 4 (Escrow & Barter) — hanya diinformasikan, tidak diubah Anggota 3

| Lokasi | Teks sekarang | Masalah | Usulan |
| :--- | :--- | :--- | :--- |
| `features/escrow/presentation/pages/escrow_payment_page.dart:33` | "Pembayaran Rekening Bersama" | Rekening penampung nyata | `paymentTitle` |
| `…/escrow_payment_page.dart:72` | Metode "Saldo Dompet SakuSkill" | Terkait K-01 | Hapus opsi (usulan PRD K-01) |
| `…/escrow_payment_page.dart:89–90` | "Ditahan Simulasi di Penampungan SakuSkill. Dana HANYA diteruskan ke Salma…" | "Penampungan", "diteruskan" | `heldNote` |
| `…/escrow_payment_page.dart:96` | "Bayar & Kunci Dana di Escrow (Rp …)" | "Kunci dana" | `payCta(amount)` |
| `features/escrow/presentation/pages/order_tracking_page.dart:85` | "…Anda telah diamankan di Rekening Bersama Escrow…" | Klaim penahanan | `heldNote` |
| `…/order_tracking_page.dart:99` | Timeline "Dana Diamankan Escrow" | Tanpa "(Simulasi)" | "Dana: Ditahan (Simulasi)" |
| `features/escrow/presentation/pages/workroom_page.dart:51` | "DANA DITAHAN SIMULASI" | Label bebas, bukan enum | `StatusPill(EscrowSimStatus.held)` + `disclaimerShort` |
| `…/workroom_page.dart:60` | "Dana Rp … ditahan aman di escrow…" | Klaim penahanan | `heldNote` |
| `features/escrow/presentation/pages/review_work_page.dart:122` | "Dana baru dilepas setelah Anda konfirmasi." | "Dilepas" tanpa simulasi | "Status dana berubah menjadi Dilepas (Simulasi) setelah Anda konfirmasi." |
| `features/escrow/presentation/pages/order_done_page.dart:52` | "STATUS DANA: DILEPAS SIMULASI" | Label bebas | `StatusPill(EscrowSimStatus.released)` |
| `…/order_done_page.dart:58` | "Dana telah diteruskan ke Saldo Dompet …" | Klaim penyaluran + K-01 | `releasedNote(provider)` |
| `features/escrow/presentation/pages/late_status_page.dart:24, 151` | "Batalkan Pesanan & Tarik Dana 100%" | "Tarik dana" (refund nyata = OD-05/06) | Tunggu OD-05/06 |
| `…/late_status_page.dart:54` | "Saldo Dompet SakuSkill Anda — Dapat ditarik ke bank kapan saja" | K-01 | Tunggu K-01 |
| `features/activity/presentation/pages/activity_page.dart:33` | "DANA DITAHAN SIMULASI" | Label bebas | `StatusPill(EscrowSimStatus.held)` |
| `…/activity_page.dart:184, 193` | "Dana Ditahan di Escrow", "Tarik Saldo ke Rekening Bank" | K-01 | Tunggu K-01 |
| `features/wallet/presentation/pages/wallet_page.dart:73, 79` | "Dana Ditahan di Escrow", "Tarik Saldo ke Rekening / E-Wallet" | K-01 | Tunggu K-01 |
| `features/complaint/presentation/pages/complaint_page.dart:72, 89` | "Dana dibekukan", "membekukan dana transaksi … di rekening escrow" | Klaim pembekuan uang | `complaintNote` |
| `features/escrow/presentation/escrow_models.dart:12` | Komentar "membayar ke Rekening Bersama" | Hanya komentar | Sesuaikan saat refactor |

## Di luar `mobile/`

- `docs/API_CONTRACT.md` (develop, `5ae2e50`): "Sistem secara otomatis memotong saldo simulasi klien dan menahan dana pada rekening bersama" — perlu disesuaikan Anggota 5 bersama keputusan K-01/K-02.

## Langkah setelah disetujui

1. UI/UX/PM menyetujui atau mengubah teks di `EscrowSimCopy`.
2. Anggota 3 mengganti teks di bagiannya; Anggota 4 di bagiannya (cukup impor `EscrowSimCopy` dan `StatusPill`).
3. Tambah widget test: setiap layar yang menampilkan status dana juga menampilkan `EscrowSimCopy.disclaimer` (AC-Escrow-01).
