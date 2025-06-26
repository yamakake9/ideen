// lib/models/chat_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// チャットルームモデル
class ChatRoomModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, bool> idExchangeStatus; // ID交換承認状態
  final Map<String, DateTime> readStatus; // 既読状態

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.participantData,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    required this.idExchangeStatus,
    required this.readStatus,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantData: data['participantData'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      idExchangeStatus: Map<String, bool>.from(data['idExchangeStatus'] ?? {}),
      readStatus: Map<String, DateTime>.from(
        (data['readStatus'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as Timestamp).toDate()),
        ),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantData': participantData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'idExchangeStatus': idExchangeStatus,
      'readStatus': readStatus.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
    };
  }
}

// メッセージモデル
class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String type; // text, image, video, location, system, idShare
  final String? text;
  final String? mediaUrl;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? idData; // 送信されたID情報
  final DateTime createdAt;
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.location,
    this.idData,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? 'text',
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      location: data['location'],
      idData: data['idData'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'location': location,
      'idData': idData,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
    };
  }
}

// ID交換リクエストモデル
class IdExchangeRequestModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final String chatRoomId;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final DateTime? respondedAt;

  IdExchangeRequestModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.chatRoomId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory IdExchangeRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IdExchangeRequestModel(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'receiverId': receiverId,
      'chatRoomId': chatRoomId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }
}