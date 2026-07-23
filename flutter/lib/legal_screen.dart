import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_service.dart';

enum LegalDocument { terms, privacy }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  static const _updated = '23 Juli 2026';

  @override
  Widget build(BuildContext context) {
    final isTerms = document == LegalDocument.terms;
    final sections = isTerms ? _terms : _privacy;
    return Scaffold(
      backgroundColor: const Color(0xff130522),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          isTerms ? 'KETENTUAN PENGGUNAAN' : 'KEBIJAKAN PRIVASI',
          style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
          children: [
            Text(
              'Berlaku sejak dan terakhir diperbarui: $_updated',
              style: const TextStyle(
                color: Color(0xffd8a5ff),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isTerms
                  ? 'Ketentuan ini mengatur penggunaan aplikasi dan layanan game BALOK KOSONG (“Aplikasi”). Dengan menggunakan Aplikasi, Anda menyatakan telah membaca dan menyetujui ketentuan ini.'
                  : 'Kebijakan ini menjelaskan bagaimana BALOK KOSONG mengumpulkan, menggunakan, menyimpan, dan melindungi informasi ketika Anda menggunakan Aplikasi.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < sections.length; index++) ...[
              _LegalSection(
                number: index + 1,
                title: sections[index].title,
                body: sections[index].body,
              ),
              const SizedBox(height: 18),
            ],
            _DeletionRequestCard(),
          ],
        ),
      ),
    );
  }

  static const _terms = [
    (
      title: 'Kelayakan dan akun',
      body:
          'Anda dapat bermain sebagai Tamu atau menggunakan metode masuk yang tersedia. Anda bertanggung jawab menjaga keamanan akun dan aktivitas yang terjadi melalui akun Anda. Informasi yang diberikan harus benar dan tidak boleh digunakan untuk menyamar sebagai orang lain. Data Tamu hanya tersimpan pada perangkat dan dapat hilang jika Aplikasi dihapus atau datanya dibersihkan.',
    ),
    (
      title: 'Lisensi penggunaan',
      body:
          'Kami memberikan lisensi terbatas, pribadi, tidak eksklusif, tidak dapat dialihkan, dan dapat dicabut untuk menggunakan Aplikasi bagi keperluan hiburan nonkomersial. Hak atas nama, desain, perangkat lunak, grafis, suara, dan konten BALOK KOSONG tetap dimiliki oleh pengembang atau pemberi lisensinya.',
    ),
    (
      title: 'Aturan permainan',
      body:
          'Skor, level, token, energy, petunjuk, tema, dan item virtual merupakan bagian dari sistem permainan. Anda dilarang memanipulasi permainan, mengeksploitasi bug, menggunakan bot atau perangkat lunak curang, mengganggu layanan, mencoba mengakses sistem tanpa izin, atau melakukan tindakan yang merugikan pemain lain maupun layanan.',
    ),
    (
      title: 'Item virtual, iklan, dan pembelian',
      body:
          'Token, energy, hadiah, dan item virtual tidak memiliki nilai uang tunai dan tidak dapat ditukar menjadi uang. Iklan berhadiah hanya ditampilkan setelah Anda memilihnya. Pembelian dalam aplikasi akan diproses oleh Google Play atau Apple App Store dan tunduk pada ketentuan serta kebijakan pengembalian dana masing-masing toko. Harga dan paket dapat berubah sebelum transaksi dikonfirmasi.',
    ),
    (
      title: 'Layanan pihak ketiga',
      body:
          'Fitur tertentu dapat menggunakan layanan pihak ketiga, termasuk penyedia login, Firebase/Google Cloud, jaringan iklan, Google Play, dan Apple App Store. Penggunaan layanan tersebut juga tunduk pada ketentuan dan kebijakan privasi penyedia terkait.',
    ),
    (
      title: 'Ketersediaan dan perubahan',
      body:
          'Kami dapat memperbarui, menambah, mengubah, menangguhkan, atau menghentikan sebagian fitur untuk pemeliharaan, keamanan, kepatuhan, atau peningkatan permainan. Kami berupaya menjaga progres pemain, tetapi tidak menjamin Aplikasi selalu tersedia tanpa gangguan atau kesalahan.',
    ),
    (
      title: 'Penangguhan dan penghentian',
      body:
          'Akses dapat dibatasi atau dihentikan apabila pengguna melanggar ketentuan, melakukan kecurangan, menyalahgunakan layanan, atau menimbulkan risiko keamanan. Anda dapat berhenti menggunakan Aplikasi kapan saja dan dapat meminta penghapusan akun beserta data terkait.',
    ),
    (
      title: 'Tanggung jawab',
      body:
          'Aplikasi disediakan sebagaimana adanya sejauh diizinkan hukum. Kami tidak bertanggung jawab atas kerugian tidak langsung, kehilangan progres lokal akibat penghapusan aplikasi, gangguan perangkat, atau kegagalan layanan pihak ketiga. Ketentuan ini tidak mengurangi hak konsumen yang wajib diberikan berdasarkan hukum.',
    ),
    (
      title: 'Hukum dan perubahan ketentuan',
      body:
          'Ketentuan ini ditafsirkan berdasarkan hukum yang berlaku di Republik Indonesia, tanpa mengurangi perlindungan wajib di wilayah tempat pengguna berada. Perubahan material akan diberitahukan melalui Aplikasi atau halaman resmi dan berlaku sejak tanggal yang dicantumkan.',
    ),
  ];

  static const _privacy = [
    (
      title: 'Informasi yang kami kumpulkan',
      body:
          'Jika Anda masuk, kami dapat menerima nama, alamat email, foto profil, dan pengenal akun dari Google, Apple, atau Facebook sesuai izin yang Anda berikan. Kami juga memproses data permainan seperti skor, level, bintang, token, energy, tema, pilihan mode, pengaturan, pembelian, dan waktu bermain. Jika Anda mengirim feedback, kami menyimpan isi pesan tersebut.',
    ),
    (
      title: 'Data teknis dan iklan',
      body:
          'Versi rilis dapat memproses informasi teknis seperti jenis perangkat, sistem operasi, versi aplikasi, alamat IP, pengenal instalasi, log kesalahan, performa, serta interaksi iklan untuk keamanan, diagnostik, analitik, dan penayangan iklan. Data yang benar-benar dikumpulkan bergantung pada fitur dan SDK yang aktif pada versi Aplikasi yang Anda gunakan.',
    ),
    (
      title: 'Mode Tamu',
      body:
          'Dalam Mode Tamu, progres dan pengaturan disimpan secara lokal pada perangkat. Data tersebut tidak disinkronkan ke perangkat lain dan dapat terhapus ketika Aplikasi dihapus, penyimpanan dibersihkan, atau perangkat diganti. Login diperlukan jika Anda ingin sinkronisasi progres.',
    ),
    (
      title: 'Tujuan penggunaan data',
      body:
          'Data digunakan untuk menyediakan akun dan gameplay, menyinkronkan progres, memulihkan pembelian, menghitung skor dan hadiah, menyimpan preferensi, menampilkan iklan yang dipilih, mencegah penipuan dan kecurangan, menangani dukungan, memperbaiki gangguan, serta memenuhi kewajiban hukum.',
    ),
    (
      title: 'Penyedia layanan dan pembagian data',
      body:
          'Kami tidak menjual data pribadi. Data dapat diproses oleh penyedia yang membantu menjalankan Aplikasi, seperti Firebase/Google Cloud untuk autentikasi dan penyimpanan, Google Play dan Apple App Store untuk transaksi, penyedia login, serta AdMob atau jaringan iklan ketika fitur iklan diaktifkan. Mereka memproses data berdasarkan kebijakan dan perjanjian layanan masing-masing.',
    ),
    (
      title: 'Penyimpanan dan keamanan',
      body:
          'Data akun dan progres disimpan selama akun aktif atau selama diperlukan untuk menyediakan layanan. Kami menggunakan langkah keamanan yang wajar, termasuk koneksi terenkripsi dan kontrol akses. Tidak ada metode penyimpanan atau pengiriman elektronik yang sepenuhnya bebas risiko.',
    ),
    (
      title: 'Pilihan dan hak Anda',
      body:
          'Anda dapat mematikan musik atau grid, menolak iklan berhadiah dengan tidak memilihnya, bermain sebagai Tamu, dan meminta akses, koreksi, atau penghapusan data pribadi. Beberapa hak dapat berbeda sesuai wilayah. Kami dapat meminta verifikasi identitas sebelum memproses permintaan.',
    ),
    (
      title: 'Penghapusan akun dan data',
      body:
          'Pengguna yang membuat atau menghubungkan akun dapat mengajukan penghapusan melalui tombol “Ajukan penghapusan akun” di bawah. Permintaan dikirim untuk ditinjau dalam waktu paling lama 24 jam. Penghapusan mencakup akun dan data terkait, kecuali data tertentu wajib dipertahankan untuk kewajiban hukum, keamanan, pencegahan penipuan, atau penyelesaian transaksi. Data lokal Mode Tamu dapat dihapus melalui pengaturan perangkat atau dengan menghapus Aplikasi.',
    ),
    (
      title: 'Anak-anak',
      body:
          'Aplikasi tidak ditujukan untuk mengumpulkan data pribadi anak secara sengaja tanpa persetujuan yang diwajibkan hukum. Jika orang tua atau wali meyakini seorang anak memberikan data pribadi tanpa izin yang semestinya, permintaan penghapusan dapat diajukan melalui tombol di bawah.',
    ),
    (
      title: 'Transfer dan perubahan kebijakan',
      body:
          'Penyedia layanan dapat memproses data di negara lain dengan perlindungan yang sesuai. Kebijakan ini dapat diperbarui ketika fitur, penyedia, atau aturan berubah. Perubahan material akan diberitahukan melalui Aplikasi atau halaman resmi, disertai tanggal pembaruan terbaru.',
    ),
  ];
}

class _DeletionRequestCard extends StatefulWidget {
  const _DeletionRequestCard();

  @override
  State<_DeletionRequestCard> createState() => _DeletionRequestCardState();
}

class _DeletionRequestCardState extends State<_DeletionRequestCard> {
  bool _submitting = false;
  bool _loggingOut = false;
  bool _checkingSession = true;
  bool _hasSession = false;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await FirebaseService.instance.initialize();
    if (!mounted) return;
    setState(() {
      _hasSession = FirebaseService.instance.user != null;
      _checkingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff28113f),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Akun', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
          _checkingSession
              ? 'Memeriksa status akun…'
              : _hasSession
              ? 'Logout tidak menghapus skor, progres, token, atau riwayat permainan.'
              : 'Masuk dengan akun atau Main sebagai Tamu untuk mengaktifkan pengaturan akun.',
          style: const TextStyle(color: Colors.white70, height: 1.45),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: !_hasSession || _loggingOut ? null : _logout,
            icon: _loggingOut
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(_loggingOut ? 'Keluar…' : 'Logout'),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),
        const Text(
          'Penghapusan akun',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Permintaan ditinjau paling lama 24 jam. Setelah disetujui, akun, '
          'skor, progres, token, inventaris, dan seluruh riwayat permainan '
          'akan dihapus permanen.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: !_hasSession || _submitting || _requestSent
                ? null
                : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(
              _submitting
                  ? 'Mengirim permintaan…'
                  : _requestSent
                  ? 'Permintaan sudah dikirim'
                  : 'Ajukan penghapusan akun',
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout dari akun?'),
        content: const Text(
          'Anda akan kembali ke halaman utama. Skor, level, token, tema, '
          'dan riwayat permainan tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await FirebaseService.instance.signOut();
      if (!mounted) return;
      setState(() {
        _hasSession = false;
        _loggingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout berhasil. Data permainan tetap tersimpan.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout belum berhasil. Silakan coba kembali.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajukan penghapusan akun?'),
        content: const Text(
          'Permintaan akan dikirim untuk ditinjau. Akun belum langsung dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      await FirebaseService.instance.submitAccountDeletionRequest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permintaan terkirim dan akan ditinjau dalam waktu paling lama 24 jam.',
          ),
        ),
      );
      setState(() => _requestSent = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permintaan belum terkirim. Periksa internet lalu coba lagi.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff211035),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. $title',
          style: const TextStyle(
            color: Color(0xffe4c5ff),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
