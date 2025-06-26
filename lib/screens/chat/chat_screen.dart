// lib/screens/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/id_share_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isIdExchangeApproved = false;
  bool _hasRequestedExchange = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser != null) {
      _chatService.markAsRead(widget.chatRoomId, currentUser.uid);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) return;

    final success = await _chatService.sendMessage(
      chatRoomId: widget.chatRoomId,
      senderId: currentUser.uid,
      type: 'text',
      text: _messageController.text.trim(),
    );

    if (success) {
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _requestIdExchange() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) return;

    // 確認ダイアログを表示
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ID交換申請'),
        content: const Text('相手にID交換を申請しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('申請する'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _chatService.requestIdExchange(
        chatRoomId: widget.chatRoomId,
        requesterId: currentUser.uid,
        receiverId: widget.otherUserId,
      );

      if (success && mounted) {
        setState(() {
          _hasRequestedExchange = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID交換を申請しました'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _showIdShareDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    
    if (userData == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => IdShareDialog(
        userData: userData,
        onShare: (type, id) async {
          final currentUser = authProvider.user;
          if (currentUser == null) return;

          await _chatService.sendMessage(
            chatRoomId: widget.chatRoomId,
            senderId: currentUser.uid,
            type: 'idShare',
            text: '$typeを共有しました',
            idData: {
              'type': type,
              'id': id,
            },
          );
          
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          // ID交換申請ボタン
          if (!_isIdExchangeApproved && !_hasRequestedExchange)
            TextButton(
              onPressed: _requestIdExchange,
              child: const Text('ID交換を申請'),
            ),
        ],
      ),
      body: Column(
        children: [
          // チャットルーム情報を監視
          StreamBuilder<ChatRoomModel?>(
            stream: _chatService.getChatRoomStream(widget.chatRoomId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final chatRoom = snapshot.data!;
                final isApproved = chatRoom.idExchangeStatus[currentUser?.uid] == true &&
                    chatRoom.idExchangeStatus[widget.otherUserId] == true;
                
                if (isApproved != _isIdExchangeApproved) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _isIdExchangeApproved = isApproved;
                    });
                  });
                }
              }
              return const SizedBox.shrink();
            },
          ),
          
          // メッセージリスト
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'メッセージはまだありません',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      userName: isMe 
                          ? (authProvider.userData?['username'] ?? 'あなた')
                          : widget.otherUserName,
                    );
                  },
                );
              },
            ),
          ),
          
          // メッセージ入力欄
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // ID共有ボタン（ID交換承認後のみ表示）
                    if (_isIdExchangeApproved)
                      IconButton(
                        icon: const Icon(Icons.share),
                        color: AppTheme.primaryColor,
                        onPressed: _showIdShareDialog,
                      ),
                    
                    // テキスト入力フィールド
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'メッセージを入力...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // 送信ボタン
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        color: Colors.white,
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}