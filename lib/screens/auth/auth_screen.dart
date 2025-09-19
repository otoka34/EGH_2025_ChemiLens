import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/widgets/common_bottom_navigation_bar.dart';

import '../../services/firebase_auth_service.dart';
import '/widgets/common_app_bar.dart'; // Add this import

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
      } else if (user != null && user.emailVerified) {
        // ログイン成功かつメール認証済みの場合
        _showSnackBar('ログインに成功しました！');
        // 少し遅延してからメイン画面（履歴画面）へ遷移
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.go('/history');
          }
        });
      }
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
    final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Slightly rounded corners
      ),
      textStyle: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
    );

    return Scaffold(
      appBar: const CommonAppBar(), // Use CommonAppBar
      body: Column( // Wrap existing body content in a Column
        children: [
          // New title in the body
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20.0, bottom: 20.0), // Adjusted padding
              child: Text(
                'ログイン / 新規登録', // Changed title text
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
          Expanded( // Wrap existing Padding with Expanded
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0), // Adjusted padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Adjusted alignment
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
                  const SizedBox(height: 40), // Increased spacing
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // Register Button
                    ElevatedButton(onPressed: _register, style: _buttonStyle, child: const Text('ユーザー登録')),
                    const SizedBox(height: 8),
                    // Login Button
                    ElevatedButton(onPressed: _signIn, style: _buttonStyle, child: const Text('ログイン')),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavigationBar(currentIndex: 4),
    );
  }
}
