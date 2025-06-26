// lib/services/friend_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーID取得
  String? get currentUserId => _auth.currentUser?.uid;

  /// フレンド申請を送信
  Future<void> sendFriendRequest({
    required String toUserId,
    required String toUserName,
    required String toUserPhotoUrl,
  }) async {
    if (currentUserId == null) throw Exception('ログインしていません');
    if (currentUserId == toUserId) throw Exception('自分自身にフレンド申請はできません');

    // 既存の申請チェック
    final existingRequest = await _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: currentUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('既に申請済みです');
    }

    // 相手からの申請チェック
    final reverseRequest = await _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (reverseRequest.docs.isNotEmpty) {
      // 相手から申請が来ている場合は自動的に承認
      await acceptFriendRequest(reverseRequest.docs.first.id);
      return;
    }

    // 既にフレンドかチェック
    final existingFriend = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: currentUserId)
        .where('friendId', isEqualTo: toUserId)
        .get();

    if (existingFriend.docs.isNotEmpty) {
      throw Exception('既にフレンドです');
    }

    // 現在のユーザー情報取得
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    
    final currentUserData = currentUserDoc.data() ?? {};

    // フレンド申請作成
    await _firestore.collection('friendRequests').add({
      'fromUserId': currentUserId,
      'toUserId': toUserId,
      'fromUserName': currentUserData['displayName'] ?? '名無し',
      'fromUserPhotoUrl': currentUserData['photoUrl'] ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// フレンド申請を承認
  Future<void> acceptFriendRequest(String requestId) async {
    if (currentUserId == null) throw Exception('ログインしていません');

    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) throw Exception('申請が見つかりません');

    final request = FriendRequest.fromFirestore(requestDoc);

    if (request.toUserId != currentUserId) {
      throw Exception('この申請を承認する権限がありません');
    }

    if (request.status != FriendRequestStatus.pending) {
      throw Exception('この申請は既に処理されています');
    }

    // バッチ処理で実行
    final batch = _firestore.batch();

    // 申請ステータスを更新
    batch.update(requestDoc.reference, {
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 双方向のフレンド関係を作成
    // 1. 申請者 → 承認者
    final friend1Ref = _firestore.collection('friends').doc();
    batch.set(friend1Ref, {
      'userId': request.fromUserId,
      'friendId': request.toUserId,
      'friendName': await _getUserName(request.toUserId),
      'friendPhotoUrl': await _getUserPhotoUrl(request.toUserId),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. 承認者 → 申請者
    final friend2Ref = _firestore.collection('friends').doc();
    batch.set(friend2Ref, {
      'userId': request.toUserId,
      'friendId': request.fromUserId,
      'friendName': request.fromUserName,
      'friendPhotoUrl': request.fromUserPhotoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// フレンド申請を拒否
  Future<void> rejectFriendRequest(String requestId) async {
    if (currentUserId == null) throw Exception('ログインしていません');

    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) throw Exception('申請が見つかりません');

    final request = FriendRequest.fromFirestore(requestDoc);

    if (request.toUserId != currentUserId) {
      throw Exception('この申請を拒否する権限がありません');
    }

    await requestDoc.reference.update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// フレンド申請をキャンセル
  Future<void> cancelFriendRequest(String requestId) async {
    if (currentUserId == null) throw Exception('ログインしていません');

    final requestDoc = await _firestore
        .collection('friendRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) throw Exception('申請が見つかりません');

    final request = FriendRequest.fromFirestore(requestDoc);

    if (request.fromUserId != currentUserId) {
      throw Exception('この申請をキャンセルする権限がありません');
    }

    await requestDoc.reference.update({
      'status': 'canceled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// フレンド関係を解除
  Future<void> removeFriend(String friendId) async {
    if (currentUserId == null) throw Exception('ログインしていません');

    // バッチ処理で双方向の関係を削除
    final batch = _firestore.batch();

    // 自分 → 相手
    final myFriend = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: currentUserId)
        .where('friendId', isEqualTo: friendId)
        .get();

    for (var doc in myFriend.docs) {
      batch.delete(doc.reference);
    }

    // 相手 → 自分
    final theirFriend = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: friendId)
        .where('friendId', isEqualTo: currentUserId)
        .get();

    for (var doc in theirFriend.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// フレンド一覧を取得
  Stream<List<Friend>> getFriends() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friends')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friend.fromFirestore(doc))
            .toList());
  }

  /// 受信したフレンド申請一覧を取得
  Stream<List<FriendRequest>> getReceivedFriendRequests() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromFirestore(doc))
            .toList());
  }

  /// 送信したフレンド申請一覧を取得
  Stream<List<FriendRequest>> getSentFriendRequests() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromFirestore(doc))
            .toList());
  }

  /// ユーザーがフレンドかどうかチェック
  Future<bool> isFriend(String userId) async {
    if (currentUserId == null) return false;

    final result = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: currentUserId)
        .where('friendId', isEqualTo: userId)
        .get();

    return result.docs.isNotEmpty;
  }

  /// フレンド申請のステータスを取得
  Future<FriendRequestStatus?> getFriendRequestStatus(String userId) async {
    if (currentUserId == null) return null;

    // 送信した申請をチェック
    final sentRequest = await _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: currentUserId)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (sentRequest.docs.isNotEmpty) {
      return FriendRequestStatus.pending;
    }

    // 受信した申請をチェック
    final receivedRequest = await _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: userId)
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (receivedRequest.docs.isNotEmpty) {
      return FriendRequestStatus.pending;
    }

    return null;
  }

  // ヘルパーメソッド
  Future<String> _getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['displayName'] ?? '名無し';
  }

  Future<String> _getUserPhotoUrl(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['photoUrl'] ?? '';
  }
}