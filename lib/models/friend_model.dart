// lib/models/friend_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// フレンドリクエストの状態
enum FriendRequestStatus {
  pending,   // 申請中
  accepted,  // 承認済み
  rejected,  // 拒否済み
  canceled,  // キャンセル済み
}

/// フレンドリクエストモデル
class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String fromUserPhotoUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.fromUserPhotoUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Firestoreからのデータ変換
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserPhotoUrl: data['fromUserPhotoUrl'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString() == 'FriendRequestStatus.${data['status']}',
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
        ? (data['updatedAt'] as Timestamp).toDate() 
        : null,
    );
  }

  // Firestoreへのデータ変換
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

/// フレンド関係モデル
class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String friendName;
  final String friendPhotoUrl;
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendName,
    required this.friendPhotoUrl,
    required this.createdAt,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      id: doc.id,
      userId: data['userId'] ?? '',
      friendId: data['friendId'] ?? '',
      friendName: data['friendName'] ?? '',
      friendPhotoUrl: data['friendPhotoUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendId': friendId,
      'friendName': friendName,
      'friendPhotoUrl': friendPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// 連絡先の公開範囲
enum ContactVisibility {
  public,      // 全員に公開
  friendsOnly, // フレンドのみ公開
  private,     // 公開しない
}

/// 連絡先情報モデル
class ContactInfo {
  final String? lineId;
  final String? instagramId;
  final String? xId; // X (Twitter)
  final String? tiktokId;
  final String? discordId;
  final String? kakaoTalkId;
  final String? telegramId;
  final String? signalId;
  final String? phoneNumber;
  final String? email;
  
  // 各連絡先の公開設定
  final ContactVisibility lineVisibility;
  final ContactVisibility instagramVisibility;
  final ContactVisibility xVisibility;
  final ContactVisibility tiktokVisibility;
  final ContactVisibility discordVisibility;
  final ContactVisibility kakaoVisibility;
  final ContactVisibility telegramVisibility;
  final ContactVisibility signalVisibility;
  final ContactVisibility phoneVisibility;
  final ContactVisibility emailVisibility;

  ContactInfo({
    this.lineId,
    this.instagramId,
    this.xId,
    this.tiktokId,
    this.discordId,
    this.kakaoTalkId,
    this.telegramId,
    this.signalId,
    this.phoneNumber,
    this.email,
    this.lineVisibility = ContactVisibility.private,
    this.instagramVisibility = ContactVisibility.private,
    this.xVisibility = ContactVisibility.private,
    this.tiktokVisibility = ContactVisibility.private,
    this.discordVisibility = ContactVisibility.private,
    this.kakaoVisibility = ContactVisibility.private,
    this.telegramVisibility = ContactVisibility.private,
    this.signalVisibility = ContactVisibility.private,
    this.phoneVisibility = ContactVisibility.private,
    this.emailVisibility = ContactVisibility.private,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> data) {
    return ContactInfo(
      lineId: data['lineId'],
      instagramId: data['instagramId'],
      xId: data['xId'],
      tiktokId: data['tiktokId'],
      discordId: data['discordId'],
      kakaoTalkId: data['kakaoTalkId'],
      telegramId: data['telegramId'],
      signalId: data['signalId'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      lineVisibility: _parseVisibility(data['lineVisibility']),
      instagramVisibility: _parseVisibility(data['instagramVisibility']),
      xVisibility: _parseVisibility(data['xVisibility']),
      tiktokVisibility: _parseVisibility(data['tiktokVisibility']),
      discordVisibility: _parseVisibility(data['discordVisibility']),
      kakaoVisibility: _parseVisibility(data['kakaoVisibility']),
      telegramVisibility: _parseVisibility(data['telegramVisibility']),
      signalVisibility: _parseVisibility(data['signalVisibility']),
      phoneVisibility: _parseVisibility(data['phoneVisibility']),
      emailVisibility: _parseVisibility(data['emailVisibility']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lineId': lineId,
      'instagramId': instagramId,
      'xId': xId,
      'tiktokId': tiktokId,
      'discordId': discordId,
      'kakaoTalkId': kakaoTalkId,
      'telegramId': telegramId,
      'signalId': signalId,
      'phoneNumber': phoneNumber,
      'email': email,
      'lineVisibility': lineVisibility.toString().split('.').last,
      'instagramVisibility': instagramVisibility.toString().split('.').last,
      'xVisibility': xVisibility.toString().split('.').last,
      'tiktokVisibility': tiktokVisibility.toString().split('.').last,
      'discordVisibility': discordVisibility.toString().split('.').last,
      'kakaoVisibility': kakaoVisibility.toString().split('.').last,
      'telegramVisibility': telegramVisibility.toString().split('.').last,
      'signalVisibility': signalVisibility.toString().split('.').last,
      'phoneVisibility': phoneVisibility.toString().split('.').last,
      'emailVisibility': emailVisibility.toString().split('.').last,
    };
  }

  static ContactVisibility _parseVisibility(String? value) {
    if (value == null) return ContactVisibility.private;
    return ContactVisibility.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ContactVisibility.private,
    );
  }
}