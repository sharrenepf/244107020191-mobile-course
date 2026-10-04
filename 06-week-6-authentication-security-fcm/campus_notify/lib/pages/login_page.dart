import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: 'mahasiswa@polinema.ac.id');
  final _password = TextEditingController(text: '123456');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi'),
            ),
            const SizedBox(height: 12),
            if (auth.hasError)
              Text(
                auth.error.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: auth.isLoading
                  ? null
                  : () => ref
                      .read(authStateProvider.notifier)
                      .login(_email.text.trim(), _password.text),
              child: Text(auth.isLoading ? 'Memproses...' : 'Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}
