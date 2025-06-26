// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // チャットルームを作成または取得
  Future<String?> createOrGetChatRoom({
    required String userId1,
    required String userId2,
    required Map<String, dynamic> user1Data,
    required Map<String, dynamic> user2Data,
  }) async {
    try {
      // 既存のチャットルームを検索
      final existingRoom = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in existingRoom.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(userId2)) {
          return doc.id;
        }
      }

      // 新規チャットルームを作成
      final chatRoomRef = _firestore.collection('chatRooms').doc();
      final now = DateTime.now();

      final chatRoom = ChatRoomModel(
        id: chatRoomRef.id,
        participants: [userId1, userId2],
        participantData: {
          userId1: {
            'username': user1Data['username'],
            'profileImageUrl': user1Data['profileImageUrl'] ?? '',
          },
          userId2: {
            'username': user2Data['username'],
            'profileImageUrl': user2Data['profileImageUrl'] ?? '',
          },
        },
        createdAt: now,
        updatedAt: now,
        idExchangeStatus: {
          userId1: false,
          userId2: false,
        },
        readStatus: {},
      );

      await chatRoomRef.set(chatRoom.toFirestore());

      // 初期メッセージを送信
      await sendSystemMessage(
        chatRoomId: chatRoomRef.id,
        text: 'チャットが開始されました',
      );

      await sendSystemMessage(
        chatRoomId: chatRoomRef.id,
        text: '''⚠️ ID交換は自己責任です。詳しくは《利用上の注意》をご覧ください。
事前にやりとりを重ね、相手をよく確認してから交換しましょう。
最初は自己紹介や雑談など、安心できる会話をおすすめします😊''',
      );

      return chatRoomRef.id;
    } catch (e) {
      print('チャットルーム作成エラー: $e');
      return null;
    }
  }

  // メッセージを送信
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String type,
    String? text,
    String? mediaUrl,
    Map<String, dynamic>? location,
    Map<String, dynamic>? idData,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        id: messageRef.id,
        chatRoomId: chatRoomId,
        senderId: senderId,
        type: type,
        text: text,
        mediaUrl: mediaUrl,
        location: location,
        idData: idData,
        createdAt: DateTime.now(),
      );

      await messageRef.set(message.toFirestore());

      // チャットルームの最終メッセージを更新
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': text ?? '[画像]',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('メッセージ送信エラー: $e');
      return false;
    }
  }

  // システムメッセージを送信
  Future<bool> sendSystemMessage({
    required String chatRoomId,
    required String text,
  }) async {
    return await sendMessage(
      chatRoomId: chatRoomId,
      senderId: 'system',
      type: 'system',
      text: text,
    );
  }

  // メッセージのストリームを取得
  Stream<List<MessageModel>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  // チャットルームのストリームを取得
  Stream<ChatRoomModel?> getChatRoomStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return ChatRoomModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // ID交換を申請
  Future<bool> requestIdExchange({
    required String chatRoomId,
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      // リクエストを作成
      final requestRef = _firestore.collection('idExchangeRequests').doc();
      
      final request = IdExchangeRequestModel(
        id: requestRef.id,
        requesterId: requesterId,
        receiverId: receiverId,
        chatRoomId: chatRoomId,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await requestRef.set(request.toFirestore());

      // システムメッセージを送信
      await sendSystemMessage(
        chatRoomId: chatRoomId,
        text: 'ID交換が申請されました',
      );

      return true;
    } catch (e) {
      print('ID交換申請エラー: $e');
      return false;
    }
  }

  // ID交換リクエストに応答
  Future<bool> respondToIdExchange({
    required String requestId,
    required String chatRoomId,
    required bool accept,
  }) async {
    try {
      // リクエストを更新
      await _firestore.collection('idExchangeRequests').doc(requestId).update({
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (accept) {
        // 承認の場合、チャットルームのステータスを更新
        final requestDoc = await _firestore
            .collection('idExchangeRequests')
            .doc(requestId)
            .get();
        
        final request = IdExchangeRequestModel.fromFirestore(requestDoc);
        
        await _firestore.collection('chatRooms').doc(chatRoomId).update({
          'idExchangeStatus.${request.requesterId}': true,
          'idExchangeStatus.${request.receiverId}': true,
        });

        // システムメッセージを送信
        await sendSystemMessage(
          chatRoomId: chatRoomId,
          text: '双方がID交換を承諾しました',
        );
      }

      return true;
    } catch (e) {
      print('ID交換応答エラー: $e');
      return false;
    }
  }

  // ユーザーのID交換リクエストを取得
  Stream<List<IdExchangeRequestModel>> getIdExchangeRequests(String userId) {
    return _firestore
        .collection('idExchangeRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IdExchangeRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  // チャットルーム一覧を取得
  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList();
    });
  }

  // 既読を更新
  Future<void> markAsRead(String chatRoomId, String userId) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'readStatus.$userId': FieldValue.serverTimestamp(),
    });
  }
}