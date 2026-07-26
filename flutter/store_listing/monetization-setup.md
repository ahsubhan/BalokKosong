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

Konfigurasi AdMob produksi BalokKosong:

- Android App ID: `ca-app-pub-5653870627581625~6699714213`
- Android Rewarded: `ca-app-pub-5653870627581625/8185974718`
- iOS App ID: `ca-app-pub-5653870627581625~8739554199`
- iOS Rewarded: `ca-app-pub-5653870627581625/4605968146`

App ID produksi sudah terpasang pada `AndroidManifest.xml` dan `Info.plist`.
Build release otomatis memakai rewarded ID produksi di atas. Nilainya masih
dapat diganti saat build jika diperlukan:

```text
flutter build appbundle --release \
  --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-5653870627581625/8185974718

flutter build ipa --release \
  --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-5653870627581625/4605968146
```

Jangan memakai unit iklan produksi saat development. Google mewajibkan penggunaan unit test selama pengembangan.

## Sebelum rilis

- Aktifkan produk token dan selesaikan perjanjian pembayaran/tax/banking.
- Uji pembelian dengan license tester Google Play dan Sandbox tester Apple.
- Terapkan validasi receipt/token pembelian di backend sebelum ekonomi token dibuka secara luas.
- Lengkapi UMP/consent iklan sesuai negara target.
- Perbarui deklarasi Ads, Data safety, dan App Privacy.
- Pastikan kebijakan privasi menyebut Google Play, App Store, dan AdMob.
