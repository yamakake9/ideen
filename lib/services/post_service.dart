// lib/services/post_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

  // 投稿を作成
  Future<String?> createPost({
    required String userId,
    required String username,
    required String displayId,
    required String message,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final now = DateTime.now();
      
      // PostModelに合わせてデータを作成
      final postData = {
        'id': docRef.id,
        'userId': userId,
        'username': username,
        'displayId': displayId,
        'gender': userProfile['gender'] ?? '未設定',
        'prefecture': userProfile['prefecture'] ?? '未設定',
        'ageGroup': userProfile['ageGroup'] ?? '未設定',
        'message': message,
        'userProfile': {
          'photoUrl': userProfile['photoUrl'] ?? '',
          'bio': userProfile['bio'] ?? '',
        },
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isActive': true,
      };

      await docRef.set(postData);
      return docRef.id;
    } catch (e) {
      print('投稿作成エラー: $e');
      return null;
    }
  }

  // 投稿一覧を取得（リアルタイム）
  Stream<List<Map<String, dynamic>>> getPostsStream({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['isActive'] != false)
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
                'createdAt': (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              })
          .toList();
    });
  }

  // 投稿一覧を取得（一回限り）
  Future<List<PostModel>> getPosts({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .where((doc) => doc.data()['isActive'] != false)
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('投稿取得エラー: $e');
      return [];
    }
  }

  // ユーザーの投稿を取得
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .where((doc) => doc.data()['isActive'] != false)
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('ユーザー投稿取得エラー: $e');
      return [];
    }
  }

  // 投稿を削除（論理削除）
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('投稿削除エラー: $e');
      return false;
    }
  }

  // 投稿を通報
  Future<bool> reportPost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'reportCount': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('投稿通報エラー: $e');
      return false;
    }
  }
}