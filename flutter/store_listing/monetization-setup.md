# Setup Monetisasi BalokKosong

## Produk token

Buat produk **consumable** dengan ID yang sama persis pada kedua store:

- Product ID: `balokkosong_tokens_30`
- Nama: `30 Token BalokKosong`
- Jenis: Consumable / dapat dibeli kembali
- Hadiah: 30 token

Aktifkan produknya di:

- Google Play Console → Monetize → Products → In-app products
- App Store Connect → BalokKosong → In-App Purchases

Harga ditampilkan otomatis dari masing-masing store. Pembelian consumable tidak dipulihkan oleh App Store/Google Play; saldo token disimpan oleh BalokKosong dan disinkronkan ke Firebase untuk pengguna yang login.

## AdMob rewarded ad

Konfigurasi saat ini memakai App ID dan ad unit test resmi Google. Sebelum mengirim build produksi:

1. Tambahkan aplikasi Android dan iOS BalokKosong di AdMob.
2. Buat masing-masing satu unit iklan **Rewarded**.
3. Ganti App ID test pada:
   - `android/app/src/main/AndroidManifest.xml`
   - `ios/Runner/Info.plist`
4. Build produksi dengan ID rewarded milik BalokKosong:

```text
flutter build appbundle --release \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY

flutter build ipa --release \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
```

Jangan memakai unit iklan produksi saat development. Google mewajibkan penggunaan unit test selama pengembangan.

## Sebelum rilis

- Aktifkan produk token dan selesaikan perjanjian pembayaran/tax/banking.
- Uji pembelian dengan license tester Google Play dan Sandbox tester Apple.
- Terapkan validasi receipt/token pembelian di backend sebelum ekonomi token dibuka secara luas.
- Lengkapi UMP/consent iklan sesuai negara target.
- Perbarui deklarasi Ads, Data safety, dan App Privacy.
- Pastikan kebijakan privasi menyebut Google Play, App Store, dan AdMob.
