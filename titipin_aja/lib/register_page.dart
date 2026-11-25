
import 'package:flutter/material.dart';
import 'api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final konfirmasiPasswordController = TextEditingController();

  String role = 'pelanggan';

  bool loading = false;
  bool obscurePassword = true;
  bool obscureKonfirmasi = true;

  final Color hijau = const Color(0xFF1F7A5A);
  final Color kuning = const Color(0xFFF5B700);

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    konfirmasiPasswordController.dispose();
    super.dispose();
  }

  Future<void> daftar() async {
    if (namaController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        konfirmasiPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom wajib diisi.'),
        ),
      );
      return;
    }

    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 8 karakter.'),
        ),
      );
      return;
    }

    if (passwordController.text !=
        konfirmasiPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password tidak sama.'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await ApiService.register(
        name: namaController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        passwordConfirmation: konfirmasiPasswordController.text,
        role: role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke login setelah berhasil mendaftar.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget inputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool password = false,
    bool konfirmasi = false,
  }) {
    final obscure = konfirmasi
        ? obscureKonfirmasi
        : obscurePassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: password && obscure,
          keyboardType: label == 'Email'
              ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: hijau),
            suffixIcon: password
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        if (konfirmasi) {
                          obscureKonfirmasi = !obscureKonfirmasi;
                        } else {
                          obscurePassword = !obscurePassword;
                        }
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAF9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hijau),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Text('Buat Akun'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    size: 48,
                    color: hijau,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Daftar TitipinAja',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buat akun untuk mulai menggunakan layanan kami.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 28),

                  inputField(
                    label: 'Nama lengkap',
                    hint: 'Masukkan nama lengkap',
                    controller: namaController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 18),

                  inputField(
                    label: 'Email',
                    hint: 'Masukkan email',
                    controller: emailController,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 18),

                  inputField(
                    label: 'Password',
                    hint: 'Minimal 8 karakter',
                    controller: passwordController,
                    icon: Icons.lock_outline,
                    password: true,
                  ),
                  const SizedBox(height: 18),

                  inputField(
                    label: 'Konfirmasi password',
                    hint: 'Ulangi password',
                    controller: konfirmasiPasswordController,
                    icon: Icons.lock_reset,
                    password: true,
                    konfirmasi: true,
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Daftar sebagai',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAF9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pelanggan',
                        child: Text('Pelanggan'),
                      ),
                      DropdownMenuItem(
                        value: 'penyedia',
                        child: Text('Penyedia'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => role = value);
                      }
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : daftar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijau,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Sudah punya akun? Masuk',
                      style: TextStyle(
                        color: hijau,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
