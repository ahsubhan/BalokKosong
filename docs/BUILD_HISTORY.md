# Riwayat Build BalokKosong

Dokumen ini menjawab: fitur atau perbaikan apa terdapat pada build tertentu?

| Versi | Build | Tanggal | Jenis | Ringkasan | Status | Git |
|---|---:|---|---|---|---|---|
<!-- NEXT_BUILD_ROW -->
| 1.0.2 | 3 | 2026-07-28 | Fix | Memperbaiki navigasi login Email dan menambahkan jalur pendaftaran dari halaman login | Tested | `develop` |
| 1.0.1 | 2 | 2026-07-27 | Fix | Startup Android tahan gagal, audio dan geret Android stabil, tema Custom dari Google Photos, bonus token, serta 5 kesalahan per level | Tested | `152c9b3` |
| 1.0.0 | 1 | 2026-07-27 | Baseline | MVP lengkap sebelum rilis store: puzzle 10 level, akun, Firebase, token, audio, tema, feedback, akses developer, build management, dan perbaikan stabilitas | Development | `main` |

## Arti status

- **Draft**: kode masih dikerjakan.
- **Tested**: analisis dan tes otomatis sudah lulus.
- **Internal**: sudah dikirim ke TestFlight atau Google Play Internal Testing.
- **Approved**: sudah disetujui untuk produksi.
- **Released**: sudah tersedia untuk pengguna umum.
- **Rejected**: build tidak digunakan; nomor build tetap tidak boleh dipakai ulang.

## Catatan Build 1

Build 1 adalah baseline pra-rilis. Rincian lengkapnya terdapat di
[`CHANGELOG.md`](../CHANGELOG.md). Setelah Build 1 dikirim ke salah satu store,
setiap file instalasi berikutnya wajib menggunakan nomor build yang lebih tinggi.
