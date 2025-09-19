import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ユーザーの認証状態を監視するストリーム
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 現在のユーザーを取得します。
  User? get currentUser => _auth.currentUser;

  /// メールアドレスとパスワードでサインインする
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// メールアドレスとパスワードで新規ユーザーを作成する。
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        // 作成したユーザーに確認メールを送信
        await user.sendEmailVerification();
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// サインアウトする
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
