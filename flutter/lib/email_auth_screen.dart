import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'firebase_service.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EmailAuthScaffold(
    title: 'MASUK DENGAN EMAIL',
    subtitle: 'Gunakan akun yang sudah terverifikasi.',
    children: [
      _AuthField(
        controller: emailController,
        label: 'Alamat email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
      ),
      const SizedBox(height: 12),
      _AuthField(
        controller: passwordController,
        label: 'Password',
        icon: Icons.lock_outline_rounded,
        obscureText: obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _login(),
        suffixIcon: IconButton(
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      const SizedBox(height: 18),
      _SubmitButton(
        label: loading ? 'Memproses…' : 'MASUK',
        loading: loading,
        onPressed: _login,
      ),
    ],
  );

  Future<void> _login() async {
    if (loading) return;
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Alamat email dan password wajib diisi.');
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_friendlyAuthError(error));
    } catch (_) {
      if (mounted) _showMessage('Login belum berhasil. Silakan coba kembali.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class EmailRegistrationScreen extends StatefulWidget {
  const EmailRegistrationScreen({super.key});

  @override
  State<EmailRegistrationScreen> createState() =>
      _EmailRegistrationScreenState();
}

class _EmailRegistrationScreenState extends State<EmailRegistrationScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EmailAuthScaffold(
    title: 'MENDAFTAR',
    subtitle: 'Buat akun untuk menyinkronkan progres dan hadiah.',
    children: [
      _AuthField(
        controller: nameController,
        label: 'Nama',
        icon: Icons.person_outline_rounded,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
      ),
      const SizedBox(height: 12),
      _AuthField(
        controller: emailController,
        label: 'Alamat email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newUsername],
      ),
      const SizedBox(height: 12),
      _AuthField(
        controller: passwordController,
        label: 'Password (minimal 6 karakter)',
        icon: Icons.lock_outline_rounded,
        obscureText: obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        onSubmitted: (_) => _register(),
        suffixIcon: IconButton(
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Kami akan mengirim tautan verifikasi. Klik tautan tersebut sebelum login.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
      ),
      const SizedBox(height: 18),
      _SubmitButton(
        label: loading ? 'Mengirim…' : 'KIRIM VERIFIKASI',
        loading: loading,
        onPressed: _register,
      ),
    ],
  );

  Future<void> _register() async {
    if (loading) return;
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Nama, alamat email, dan password wajib diisi.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password minimal 6 karakter.');
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseService.instance.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xff24103c),
          icon: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xffd8a5ff),
            size: 48,
          ),
          title: const Text(
            'Periksa email Anda',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Tautan verifikasi telah dikirim ke $email. Klik tautan tersebut, '
            'lalu kembali ke aplikasi dan login.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('MENGERTI'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_friendlyAuthError(error));
    } catch (_) {
      if (mounted) {
        _showMessage('Pendaftaran belum berhasil. Silakan coba kembali.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _EmailAuthScaffold extends StatelessWidget {
  const _EmailAuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff130522),
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              decoration: BoxDecoration(
                color: const Color(0xff210b39),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xff70419b)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xffd8a5ff),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    obscureText: obscureText,
    enableSuggestions: !obscureText,
    autocorrect: !obscureText,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: .05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_rounded),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff9147df),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

String _friendlyAuthError(FirebaseAuthException error) => switch (error.code) {
  'email-not-verified' =>
    'Email belum diverifikasi. Klik tautan verifikasi di email, lalu login kembali.',
  'email-already-in-use' => 'Alamat email sudah terdaftar.',
  'invalid-email' => 'Format alamat email tidak benar.',
  'weak-password' => 'Password terlalu lemah. Gunakan minimal 6 karakter.',
  'wrong-password' ||
  'invalid-credential' => 'Email atau password tidak sesuai.',
  'user-not-found' => 'Akun dengan email tersebut belum terdaftar.',
  'network-request-failed' => 'Periksa koneksi internet lalu coba kembali.',
  _ => error.message ?? 'Proses belum berhasil. Silakan coba kembali.',
};
