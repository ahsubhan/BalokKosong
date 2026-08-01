# Notifikasi status Google Play

Workflow `.github/workflows/play-release-telegram.yml` memeriksa Build 10 pada
track Closed Testing `alpha` setiap 10 menit. Telegram hanya diberi tahu satu
kali ketika rilis tersedia untuk tester atau tidak disetujui.

## GitHub Actions secrets

- `TELEGRAM_BOT_TOKEN`: token bot BalokKosong Release Alert.
- `TELEGRAM_CHAT_ID`: tujuan percakapan pribadi Telegram.
- `PLAY_SERVICE_ACCOUNT_JSON`: kunci JSON service account Google Play.

Bot dan dua secret Telegram dibuat pada 1 Agustus 2026. Kredensial Google Play
harus memiliki akses baca aplikasi BalokKosong dan scope Android Publisher.

## Penanda notifikasi

Setelah pesan berhasil dikirim, workflow membuat tag berikut agar pesan tidak
terkirim berulang kali:

- `notifications/play-build-10-available`
- `notifications/play-build-10-not-approved`
