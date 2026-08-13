import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// Firebase Authentication ile gerçek giriş/kayıt ekranı. E-posta + şifre
/// kullanır. Aynı ekran hem "Giriş Yap" hem "Hesap Oluştur" modunu
/// destekler, aralarında küçük bir metin butonuyla geçilir.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignUp = false;
  bool isLoading = false;
  String? errorMessage;
  bool obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty)) {
      setState(() => errorMessage = 'Lütfen tüm alanları doldur.');
      return;
    }

    if (isSignUp && password != confirmPassword) {
      setState(() => errorMessage = 'Şifreler birbiriyle eşleşmiyor.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final error = isSignUp
        ? await AuthService.signUp(email: email, password: password, displayName: name)
        : await AuthService.signIn(email: email, password: password);

    if (!mounted) return;

    setState(() {
      isLoading = false;
      errorMessage = error;
    });

    if (error == null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSignUp ? 'Hesap Oluştur' : 'Giriş Yap'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSignUp
                  ? 'Hesabını oluştur, ilerlemen ve liderlik tablosu sıralaman her cihazda seninle gelsin.'
                  : 'E-posta ve şifrenle giriş yap.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 22),
            if (isSignUp) ...[
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Adın',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Şifre (en az 6 karakter)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            if (isSignUp) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordController,
                obscureText: obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Şifre (Tekrar)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isSignUp ? 'Hesap Oluştur' : 'Giriş Yap',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        isSignUp = !isSignUp;
                        errorMessage = null;
                      });
                    },
              child: Text(
                isSignUp ? 'Zaten hesabın var mı? Giriş yap' : 'Hesabın yok mu? Hesap oluştur',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
