# Changelog

Semua perubahan penting BalokKosong dicatat di dokumen ini.

Format versi aplikasi adalah `MAJOR.MINOR.PATCH+BUILD`.

## [Unreleased]

Belum ada perubahan setelah kandidat Build 8.

## [1.0.3+8] - 2026-07-31

### Fixed

- Google Login pada build Closed Testing kini mengenali sertifikat lama dan
  sertifikat aktif Google Play App Signing.
- Konfigurasi OAuth Android disinkronkan ulang dari Firebase.
- Google Sign-In memakai server client ID secara eksplisit dan hanya
  diinisialisasi satu kali selama aplikasi berjalan.

## [1.0.3+6] - 2026-07-30

### Changed

- Musik gameplay diputar stabil pada volume 50% tanpa berubah saat balok
  digeret.
- Efek suara geret diperkuat agar tetap jelas di atas musik latar.
- Ukuran informasi Score, Level, Waktu, dan Sisa Salah dibuat responsif.
- Ukuran empat tombol permainan dibuat responsif dengan jarak yang konsisten
  pada berbagai ukuran HP Android.

### Fixed

- HUD tidak lagi terlalu kecil pada perangkat Android dengan rasio atau skala
  tampilan tertentu.
- Musik latar tidak lagi mengecil atau terputus sesaat ketika efek geret
  dimainkan.

## [1.0.3+5] - 2026-07-29

### Changed

- Kontrol geret dan area sentuh disempurnakan untuk Android dan iPhone.
- Cara Bermain tersedia setelah pembuka dan dari halaman permainan.
- Footer permainan memakai empat aksi: Pause, Petunjuk, Cara Bermain, dan
  Pengaturan.
- Volume musik gameplay dan suara kemenangan diseimbangkan.
- Tampilan Help & Feedback dirapikan.

## [1.0.2+3] - 2026-07-28

### Fixed

- Tombol Masuk dengan Email membuka halaman login secara konsisten pada
  perangkat Android closed testing.
- Halaman login Email menyediakan jalur langsung menuju pendaftaran akun baru.

## [1.0.1+2] - 2026-07-27

### Changed

- Setiap level memiliki 5 kesempatan salah yang kembali penuh saat level
  dimulai atau diulang.
- Pemain Tamu mendapat 3 token awal satu kali, sedangkan akun Email atau Google
  mendapat bonus 10 token satu kali.
- Area sentuh dan sensitivitas geret Android ditingkatkan.

### Fixed

- Startup Android tetap membuka aplikasi jika inisialisasi audio atau notifikasi
  gagal pada perangkat tertentu.
- Build release Android tidak lagi menghapus kelas database WorkManager yang
  dibutuhkan sebelum Flutter dimulai.
- Musik permainan dilanjutkan dengan konsisten setelah efek geret dan saat naik
  level.
- Pemilihan latar Custom mendukung gambar dari Google Photos dan penyedia album
  Android.
- Alur Main sebagai Tamu langsung membuka Pilih Mode tanpa kembali sesaat ke
  halaman login.

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
