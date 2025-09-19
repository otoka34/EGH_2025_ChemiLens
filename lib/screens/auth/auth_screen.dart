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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      _showSnackBar('ログアウトしました');
      // フォームをクリア
      _emailController.clear();
      _passwordController.clear();
    } catch (e) {
      _showSnackBar('ログアウトに失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user != null && user.emailVerified) {
            // ログイン済み状態の表示
            return _buildLoggedInView(user);
          } else {
            // ログインフォームの表示
            return _buildLoginForm();
          }
        },
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(currentIndex: 4),
    );
  }

  Widget _buildLoggedInView(User user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.account_circle, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'ログイン済み',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ログイン中のアカウント:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? '不明',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('ログアウト'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
    );

    return Column(
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
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
        Expanded(
          // Wrap existing Padding with Expanded
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 60.0,
            ), // Adjusted padding
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
                  ElevatedButton(
                    onPressed: _register,
                    style: _buttonStyle,
                    child: const Text('ユーザー登録'),
                  ),
                  const SizedBox(height: 8),
                  // Login Button
                  ElevatedButton(
                    onPressed: _signIn,
                    style: _buttonStyle,
                    child: const Text('ログイン'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
