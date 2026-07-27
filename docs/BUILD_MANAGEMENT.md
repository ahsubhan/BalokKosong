# Cara Mengelola Build BalokKosong

## Sistem yang digunakan

Gunakan **GitHub sebagai sumber utama**:

- kode disimpan di branch dan `main`;
- perubahan diperiksa melalui Pull Request;
- isi build dicatat di `CHANGELOG.md` dan `docs/BUILD_HISTORY.md`;
- kandidat rilis dikunci memakai Git tag;
- App Store Connect dan Google Play Console hanya menerima hasil build tersebut.

Dengan pola ini, satu nomor build selalu bisa dilacak kembali ke kode, fitur,
perbaikan, hasil tes, dan status distribusinya.

## Format nomor versi

BalokKosong memakai format:

```text
1.0.0+1
│ │ │  └─ Build: naik pada setiap file yang dikirim ke iOS/Android
│ │ └──── Patch: perbaikan bug
│ └────── Minor: fitur baru yang kompatibel
└──────── Major: perubahan besar
```

Contoh:

- `1.0.0+1` — build pertama.
- `1.0.0+2` — build internal berikutnya, versi publik belum berubah.
- `1.0.1+3` — rilis perbaikan bug.
- `1.1.0+4` — rilis dengan fitur baru, misalnya bahasa English.

Nomor setelah tanda `+` tidak boleh digunakan ulang, termasuk jika build gagal
atau ditolak store. Untuk memudahkan, gunakan nomor build yang sama pada iOS dan
Android.

## Alur setiap build

1. Tentukan isi build: feature, fix, atau keduanya.
2. Naikkan versi/build pada `flutter/pubspec.yaml`.
3. Pindahkan perubahan dari bagian `Unreleased` ke versi baru di `CHANGELOG.md`.
4. Tambahkan satu baris ke `docs/BUILD_HISTORY.md`.
5. Jalankan `flutter analyze` dan seluruh tes.
6. Commit dan push melalui Pull Request.
7. Setelah PR masuk `main`, buat Git tag, misalnya `v1.0.0-build.2`.
8. Build iOS/Android dari commit bertag tersebut.
9. Catat status: Internal, Approved, atau Released.

## Cara paling mudah meminta Codex

Anda cukup menulis:

```text
Siapkan build internal berikutnya.
Jenis: fix.
Isi: perbaikan tombol mode dan logout.
Target: iPhone dan Android.
```

Codex akan:

- memilih nomor versi/build berikutnya;
- memperbarui changelog dan riwayat build;
- menjalankan semua tes;
- membuat PR dan meminta persetujuan sebelum publikasi jika diperlukan;
- membuat tag setelah kode final masuk `main`;
- memberi perintah pull/build yang tepat untuk Mac atau Windows.

## Menyiapkan nomor build dengan PowerShell

Dari folder utama repositori:

```powershell
.\tool\prepare_build.ps1 -Bump build -Summary "Perbaikan internal" 
```

Perintah tersebut hanya menampilkan preview. Untuk benar-benar mengubah file:

```powershell
.\tool\prepare_build.ps1 -Bump build -Summary "Perbaikan internal" -Apply
```

Nilai `-Bump`:

- `build`: hanya menaikkan build, contoh `1.0.0+1` → `1.0.0+2`;
- `patch`: bug fix, contoh `1.0.0+1` → `1.0.1+2`;
- `minor`: fitur baru, contoh `1.0.0+1` → `1.1.0+2`;
- `major`: perubahan besar, contoh `1.0.0+1` → `2.0.0+2`.

## Git tag dan pemulihan

Tag dibuat setelah build disetujui:

```powershell
git tag -a v1.0.0-build.1 -m "BalokKosong 1.0.0 build 1"
git push origin v1.0.0-build.1
```

Jika suatu saat ada masalah, kode build tersebut dapat diperiksa tanpa menebak:

```powershell
git show v1.0.0-build.1
```

Jangan menghapus atau memindahkan tag yang sudah pernah digunakan untuk build.

## Checklist sebelum store

- Versi dan build pada aplikasi sudah benar.
- `CHANGELOG.md` dan `BUILD_HISTORY.md` sudah sesuai.
- Semua tes lulus.
- Login, logout, restore purchase, token, dan Firebase diuji di perangkat asli.
- Screenshot, deskripsi, kebijakan privasi, dan Data Safety sudah sesuai.
- Build sudah diuji melalui TestFlight dan Google Play Internal Testing.
- Git tag sudah dibuat dari commit yang sama dengan file yang diunggah.

