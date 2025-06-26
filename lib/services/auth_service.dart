// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 現在のユーザー
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // メールアドレスとパスワードで新規登録
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Firebase Authでユーザー作成
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestoreにユーザー情報を保存
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'username': username,
          'displayId': username, // 内部管理用（非公開）
          'profileImageUrl': '',
          'bio': '',
          'gender': '',
          'prefecture': '',
          'ageGroup': '',
          'hobbies': [],
          // SNS IDs（すべて非公開）
          'lineId': '',
          'tiktokId': '',
          'kakaoTalkId': '',
          'instagramId': '',
          'telegramId': '',
          'signalId': '',
          'phoneNumber': '',
          'contactEmail': '', // 連絡用メール（ログインメールとは別）
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'reportCount': 0,
          'level': 1,
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('登録エラー: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // メールアドレスとパスワードでログイン
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('ログインエラー: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('ログアウトエラー: $e');
      throw 'ログアウトに失敗しました';
    }
  }

  // パスワードリセットメール送信
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('パスワードリセットエラー: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    }
  }

  // ユーザー情報を取得
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('ユーザー情報取得エラー: $e');
      return null;
    }
  }

  // ユーザー情報を更新
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      // ドキュメントが存在するか確認
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        // 存在する場合は更新
        await _firestore.collection('users').doc(uid).update(data);
      } else {
        // 存在しない場合は作成
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(uid).set(data);
      }
    } catch (e) {
      print('ユーザー情報更新エラー: $e');
      throw 'ユーザー情報の更新に失敗しました';
    }
  }

  // エラーハンドリング
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'パスワードが弱すぎます（6文字以上必要）';
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'user-not-found':
        return 'ユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'too-many-requests':
        return '試行回数が多すぎます。しばらく待ってから再試行してください';
      default:
        return '認証エラーが発生しました: ${e.message}';
    }
  }
}