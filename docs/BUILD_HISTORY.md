# Riwayat Build BalokKosong

Dokumen ini menjawab: fitur atau perbaikan apa terdapat pada build tertentu?

| Versi | Build | Tanggal | Jenis | Ringkasan | Status | Git |
|---|---:|---|---|---|---|---|
<!-- NEXT_BUILD_ROW -->
| 1.0.4 | 13 | 2026-08-04 | Critical Fix | App otomatis pause dan seluruh audio berhenti saat masuk background; musik hanya lanjut setelah tombol play ditekan | Closed Testing candidate | `d08a56b` |
| 1.0.4 | 12 | 2026-08-04 | Critical Fix | Salah pilih balok dan kesalahan palsu saat drag diperbaiki; getaran bump diperkuat | Closed Testing (in review) | `44c245c` |
| 1.0.3 | 11 | 2026-08-01 | Critical Fix | Musik menang dua kali, getaran benturan, dan kontrol geret tepi Android diperkuat | Closed Testing (in review) | `1ddefc9` |
| 1.0.3 | 10 | 2026-08-01 | Critical Fix | Nomor build sudah pernah digunakan di Play Console; tidak dirilis | Rejected | `febd119` |
| 1.0.3 | 9 | 2026-08-01 | UX/Fix | Onboarding, audio kemenangan, efek bump/3D, tutorial, dan gesture tepi Android disempurnakan | Closed Testing (in review) | `13472c4` |
| 1.0.3 | 8 | 2026-07-31 | Fix | Google Login Closed Testing diperbaiki dengan sertifikat Play App Signing lama dan aktif | Closed Testing (in review) | `111eb27` |
| 1.0.3 | 7 | 2026-07-31 | Fix | Nomor build sudah pernah digunakan di Play Console; tidak dirilis | Rejected | `8af155a` |
| 1.0.3 | 6 | 2026-07-30 | Fix | HUD responsif lintas perangkat, musik gameplay steady 50%, dan efek geret lebih jelas | Tested | `develop` |
| 1.0.3 | 5 | 2026-07-29 | Fix | Kontrol sentuh, Cara Bermain, footer permainan, audio, dan Help & Feedback disempurnakan | Closed Testing | `2231c29` |
| 1.0.3 | 4 | 2026-07-28 | Fix | Penyempurnaan onboarding, kontrol sentuh, audio gameplay, dan layout permainan | Tested | `20eea6b` |
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
