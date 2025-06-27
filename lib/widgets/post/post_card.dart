// lib/widgets/post/post_card.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../services/chat_service.dart';
import '../../services/friend_service.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onExchange;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const PostCard({
    super.key,
    required this.post,
    required this.createdAt,
    this.onTap,
    this.onExchange,
    this.onDelete,
    this.onReport,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ChatService _chatService = ChatService();
  final FriendService _friendService = FriendService();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  bool _hasChatHistory = false;
  bool _isFriend = false;
  bool _hasPendingRequest = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    if (currentUserId == null || widget.post['userId'] == currentUserId) {
      setState(() => _isLoadingStatus = false);
      return;
    }

    try {
      // チャット履歴の確認
      final chatHistory = await _chatService.hasChatHistory(
        currentUserId!,
        widget.post['userId'],
      );
      
      // フレンド状態の確認
      final friendStatus = await _friendService.isFriend(widget.post['userId']);
      
      // フレンドリクエストの確認
      final pendingRequest = await _friendService.hasPendingRequest(
        currentUserId!,
        widget.post['userId'],
      );

      if (mounted) {
        setState(() {
          _hasChatHistory = chatHistory;
          _isFriend = friendStatus;
          _hasPendingRequest = pendingRequest;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      print('Error checking user status: $e');
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    if (currentUserId == null) return;

    try {
      // フレンドリクエストを送信
      await _friendService.sendFriendRequest(
        toUserId: widget.post['userId'],
        toUserName: widget.post['username'],
      );

      if (mounted) {
        setState(() => _hasPendingRequest = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('フレンド申請を送信しました'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('フレンド申請の送信に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  Color _getGenderColor(String? gender) {
    switch (gender) {
      case '男性':
        return Colors.blue;
      case '女性':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnPost = currentUserId == widget.post['userId'];
    
    // デバッグログ
    print('PostCard - Full post data: ${widget.post}');
    print('PostCard - userProfile: ${widget.post['userProfile']}');
    print('PostCard - photoUrl: ${widget.post['userProfile']?['photoUrl']}');
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  // アバター
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getGenderColor(widget.post['gender']).withOpacity(0.2),
                    backgroundImage: widget.post['userProfile']?['photoUrl'] != null && 
                                     widget.post['userProfile']['photoUrl'].toString().isNotEmpty
                        ? NetworkImage(widget.post['userProfile']['photoUrl'])
                        : null,
                    child: widget.post['userProfile']?['photoUrl'] == null || 
                           widget.post['userProfile']['photoUrl'].toString().isEmpty
                        ? Text(
                            (widget.post['username'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              color: _getGenderColor(widget.post['gender']),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // ユーザー情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.post['username'] ?? '名無し',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_isFriend) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'フレンド',
                                  style: TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getGenderColor(widget.post['gender']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.post['gender'] ?? '未設定',
                                style: TextStyle(
                                  color: _getGenderColor(widget.post['gender']),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.post['prefecture'] ?? '未設定'} • ${widget.post['ageGroup'] ?? '未設定'}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 時間
                  Text(
                    _getTimeAgo(widget.createdAt),
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // メッセージ
              Text(
                widget.post['message'] ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              
              // アクションボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 削除・通報ボタン
                  if (widget.onDelete != null || widget.onReport != null)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: AppTheme.textTertiary,
                      ),
                      onSelected: (value) {
                        if (value == 'delete' && widget.onDelete != null) {
                          widget.onDelete!();
                        } else if (value == 'report' && widget.onReport != null) {
                          widget.onReport!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (widget.onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppTheme.errorColor),
                                SizedBox(width: 8),
                                Text('削除'),
                              ],
                            ),
                          ),
                        if (widget.onReport != null)
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.flag, color: AppTheme.warningColor),
                                SizedBox(width: 8),
                                Text('通報'),
                              ],
                            ),
                          ),
                      ],
                    )
                  else
                    const SizedBox(width: 40),
                  
                  // アクションボタン群
                  if (!isOwnPost) ...[
                    if (_isLoadingStatus)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // フレンド申請ボタン
                          if (!_isFriend && !_hasPendingRequest)
                            TextButton.icon(
                              onPressed: _sendFriendRequest,
                              icon: const Icon(
                                Icons.person_add,
                                size: 18,
                              ),
                              label: const Text('フレンド申請'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.secondaryColor,
                                backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            )
                          else if (_hasPendingRequest && !_isFriend)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '申請中',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(width: 8),
                          
                          // チャット/アプローチボタン
                          TextButton.icon(
                            onPressed: widget.onExchange,
                            icon: Icon(
                              _hasChatHistory ? Icons.chat_bubble : Icons.waving_hand,
                              size: 18,
                            ),
                            label: Text(_hasChatHistory ? 'チャットする' : 'アプローチする'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}