# Changelog

Semua perubahan penting BalokKosong dicatat di dokumen ini.

Format versi aplikasi adalah `MAJOR.MINOR.PATCH+BUILD`.

## [Unreleased]

Belum ada perubahan setelah kandidat Build 1.

## [1.0.0+1] - 2026-07-27

### Added

- Mesin puzzle Flutter native dengan 10 level.
- Balok I, L, T, dan bentuk kompleks untuk level lanjutan.
- Mode Santai dan Tantangan dengan energy.
- Tutorial empat halaman, petunjuk, timer, skor, bintang, dan batas kesalahan.
- Login Email dan Google, sinkronisasi Firebase, profil, serta pemulihan progres.
- Token, kupon, toko, tema premium, custom background, dan rewarded ads.
- Help & Feedback, FAQ, kebijakan privasi, dan ketentuan penggunaan.
- Musik pembuka, musik permainan, efek geser, benturan, dan kemenangan.
- Sistem pengelolaan build melalui GitHub, changelog, build history, dan tag.
- Akses developer penuh khusus akun Google `ah.subhan@gmail.com`.

### Changed

- Pengguna yang masih login mendapat layar Welcome lalu langsung masuk Pilih Mode.
- Lanjutkan, Dari Level 1, Santai, dan Tantangan dapat memulai permainan.
- Grid hanya gratis untuk Level 1–3.
- Tampilan aplikasi menggunakan palet ungu dan layout mobile penuh.
- Versi dan nomor build di Pengaturan dibaca otomatis dari aplikasi terpasang.

### Fixed

- Startup tidak lagi tertahan ketika sinkronisasi Firestore lambat.
- Level baru selalu dimulai dari Level 1 untuk pemain baru.
- Panah kanan hanya membuka level yang sudah berhak dimainkan.
- Pemain dapat kembali maju sampai level tertinggi yang pernah dibuka.
- Arah gerak balok mengikuti sisi terpanjang.
- Volume musik dan efek permainan diseimbangkan.
- Logout membersihkan data akun lokal tanpa menghapus data Firebase.
- Logout membuat ulang halaman login dan tidak lagi meninggalkan route akun lama.
- Feedback hanya tersedia setelah login dan memakai identitas akun otomatis.
