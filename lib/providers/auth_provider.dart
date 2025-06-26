// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  // 初期化
  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        // ユーザーがログインしている場合、ユーザー情報を取得
        _userData = await _authService.getUserData(user.uid);
        
        // ユーザードキュメントが存在しない場合は作成
        if (_userData == null) {
          final defaultData = {
            'uid': user.uid,
            'email': user.email ?? '',
            'username': user.email?.split('@')[0] ?? 'ユーザー',
            'displayId': user.uid,
            'profileImageUrl': '',
            'bio': '',
            'gender': '未設定',
            'prefecture': '未設定',
            'ageGroup': '未設定',
            'hobbies': [],
            // SNS IDs（すべて非公開）
            'lineId': '',
            'tiktokId': '',
            'kakaoTalkId': '',
            'instagramId': '',
            'telegramId': '',
            'signalId': '',
            'phoneNumber': '',
            'contactEmail': '',
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
            'isActive': true,
            'reportCount': 0,
            'level': 1,
          };
          
          try {
            await _authService.updateUserData(user.uid, defaultData);
            _userData = defaultData;
          } catch (e) {
            print('ユーザードキュメント作成エラー: $e');
          }
        }
      } else {
        _userData = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // 新規登録
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.registerWithEmail(
        email: email,
        password: password,
        username: username,
      );

      if (userCredential != null) {
        _user = userCredential.user;
        _userData = await _authService.getUserData(_user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return userCredential != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ログイン
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        _user = userCredential.user;
        _userData = await _authService.getUserData(_user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return userCredential != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _userData = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // パスワードリセット
  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authService.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ユーザー情報更新
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;

    try {
      _errorMessage = null;
      await _authService.updateUserData(_user!.uid, data);
      _userData = await _authService.getUserData(_user!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}