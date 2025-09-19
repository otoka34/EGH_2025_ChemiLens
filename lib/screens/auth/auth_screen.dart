import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:team_25_app/widgets/common_bottom_navigation_bar.dart';

import '../../services/firebase_auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('メールアドレスとパスワードを入力してください');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await _authService.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _showSnackBar('確認メールを送信しました。メールを確認してアカウントを有効化してください。');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackBar('このアカウントは既に存在します。ログインしてください。');
      } else if (e.code == 'weak-password') {
        _showSnackBar('パスワードは6文字以上で設定してください。');
      } else {
        _showSnackBar('登録エラー: ${e.message}');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('メールアドレスとパスワードを入力してください');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (user != null && !user.emailVerified) {
        _showSnackBar('メールの認証が完了していません。受信箱を確認してください。');
        // ログインは成功しているが、メイン画面には遷移させない
      }
      // ログイン成功かつメール認証済の場合、後ほどここで画面遷移を実装します
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        _showSnackBar('アカウントがありません。ユーザー登録をお願いします。');
      } else {
        _showSnackBar('ログインエラー: ${e.message}');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン / 新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 8),
            // Password Input
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'パスワード',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Register Button
              ElevatedButton(onPressed: _register, child: const Text('ユーザー登録')),
              const SizedBox(height: 8),
              // Login Button
              ElevatedButton(onPressed: _signIn, child: const Text('ログイン')),
            ],
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(currentIndex: 4),
    );
  }
}
