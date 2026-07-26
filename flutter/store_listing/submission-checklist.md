# Checklist Pengajuan BalokKosong

## Aset yang sudah disiapkan

- 3 konsep gambar preview Google Play, 1080 × 1920
- 3 konsep gambar preview App Store, 1290 × 2796
- Feature graphic Google Play, 1024 × 500
- Ikon Google Play, 512 × 512
- Video preview potret untuk Google Play dan App Store
- Deskripsi singkat, deskripsi lengkap, subtitle, kata kunci, dan catatan rilis

## Data yang masih harus dilengkapi di akun store

- Akun organisasi/developer menampilkan nama **ahmadss**
- Nomor telepon dan alamat developer yang valid
- URL dukungan yang aktif
- URL kebijakan privasi yang aktif
- URL penghapusan akun yang aktif
- Negara distribusi dan harga aplikasi
- Kategori **Games / Puzzle**
- Kuesioner rating usia/konten
- Deklarasi iklan
- Formulir Google Play **Data safety**
- Formulir Apple **App Privacy**
- Informasi akses reviewer jika ada bagian aplikasi yang terkunci
- Kontak App Review dan catatan pengujian
- Video Google Play diunggah ke YouTube sebagai video publik atau tidak tercantum, iklan dimatikan, lalu URL-nya dimasukkan ke Play Console

## Build produksi

- Android App Bundle (`.aab`) bertanda tangan produksi
- Google Play App Signing diaktifkan
- Arsip iOS dibuat dengan bundle ID produksi dan profil distribusi
- Proyek iOS saat ini menargetkan iPhone dan iPad. Siapkan screenshot iPad, atau ubah target menjadi iPhone saja sebelum pengajuan
- Versi dan build number unik
- Firebase produksi terhubung untuk Android dan iOS
- Login email dan Google diuji pada build release
- Tautan verifikasi email membuka alur yang benar
- Penghapusan akun benar-benar menghapus akun beserta data terkait
- Produk token, pembelian, pemulihan pembelian, dan iklan menggunakan layanan produksi—bukan simulasi
- Notifikasi iOS/Android diuji dengan kredensial produksi
- Crash test, pengujian perangkat nyata, dan pengujian koneksi lambat selesai

## Draft deklarasi privasi untuk ditinjau

BalokKosong dapat memproses nama, alamat email, ID pengguna, progres level, skor, bintang, riwayat pembelian, isi feedback, serta informasi teknis aplikasi/perangkat yang diperlukan untuk autentikasi, sinkronisasi, dukungan, keamanan, dan pemulihan pembelian. Data yang benar-benar dikumpulkan harus disamakan dengan konfigurasi Firebase, Google Sign-In, layanan pembelian, notifikasi, analitik, dan iklan pada build produksi.

Jangan mengirim formulir Data safety atau App Privacy sebelum daftar SDK dan aliran data pada build final diaudit.
