import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), pass = TextEditingController();
  bool busy = false;

  Future<void> _go(bool signUp) async {
    setState(() => busy = true);
    try {
      final a = Supabase.instance.client.auth;
      if (signUp) {
        await a.signUp(email: email.text.trim(), password: pass.text);
      } else {
        await a.signInWithPassword(email: email.text.trim(), password: pass.text);
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Orbitask', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('ให้ทุกวิชาโคจรอยู่ในมือคุณ'),
                const SizedBox(height: 28),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'อีเมล')),
                const SizedBox(height: 12),
                TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่าน')),
                const SizedBox(height: 20),
                FilledButton(onPressed: busy ? null : () => _go(false), child: const Text('เข้าสู่ระบบ')),
                TextButton(onPressed: busy ? null : () => _go(true), child: const Text('สมัครสมาชิก')),
              ]),
            ),
          ),
        ),
      );
}
