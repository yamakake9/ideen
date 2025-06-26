// lib/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String displayId;
  final String gender;
  final String prefecture;
  final String ageGroup;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int reportCount;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayId,
    required this.gender,
    required this.prefecture,
    required this.ageGroup,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.reportCount = 0,
  });

  // Firestoreのドキュメントから変換
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      displayId: data['displayId'] ?? '',
      gender: data['gender'] ?? '未設定',
      prefecture: data['prefecture'] ?? '未設定',
      ageGroup: data['ageGroup'] ?? '未設定',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      reportCount: data['reportCount'] ?? 0,
    );
  }

  // Firestoreに保存するためのMap変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'displayId': displayId,
      'gender': gender,
      'prefecture': prefecture,
      'ageGroup': ageGroup,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'reportCount': reportCount,
    };
  }

  // copyWith メソッド
  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? displayId,
    String? gender,
    String? prefecture,
    String? ageGroup,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? reportCount,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayId: displayId ?? this.displayId,
      gender: gender ?? this.gender,
      prefecture: prefecture ?? this.prefecture,
      ageGroup: ageGroup ?? this.ageGroup,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      reportCount: reportCount ?? this.reportCount,
    );
  }
}