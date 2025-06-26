// lib/widgets/friend_request_button.dart

import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../models/friend_model.dart';

class FriendRequestButton extends StatefulWidget {
  final String userId;
  final String userName;
  final String userPhotoUrl;

  const FriendRequestButton({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
  }) : super(key: key);

  @override
  State<FriendRequestButton> createState() => _FriendRequestButtonState();
}

class _FriendRequestButtonState extends State<FriendRequestButton> {
  final FriendService _friendService = FriendService();
  bool _isLoading = false;
  bool _isFriend = false;
  FriendRequestStatus? _requestStatus;

  @override
  void initState() {
    super.initState();
    _checkFriendStatus();
  }

  Future<void> _checkFriendStatus() async {
    // 自分自身の場合は何もしない
    if (_friendService.currentUserId == widget.userId) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isFriend = await _friendService.isFriend(widget.userId);
      final requestStatus = await _friendService.getFriendRequestStatus(widget.userId);

      if (mounted) {
        setState(() {
          _isFriend = isFriend;
          _requestStatus = requestStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _isLoading = true);

    try {
      await _friendService.sendFriendRequest(
        toUserId: widget.userId,
        toUserName: widget.userName,
        toUserPhotoUrl: widget.userPhotoUrl,
      );

      if (mounted) {
        setState(() {
          _requestStatus = FriendRequestStatus.pending;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンド申請を送信しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _removeFriend() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンド解除'),
        content: Text('${widget.userName}さんをフレンドから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await _friendService.removeFriend(widget.userId);

        if (mounted) {
          setState(() {
            _isFriend = false;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('フレンドを削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 自分自身の場合は何も表示しない
    if (_friendService.currentUserId == widget.userId) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 既にフレンドの場合
    if (_isFriend) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'フレンド',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 100, 0, 0),
                items: [
                  PopupMenuItem(
                    value: 'remove',
                    child: const Text('フレンド解除'),
                    onTap: _removeFriend,
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    // 申請中の場合
    if (_requestStatus == FriendRequestStatus.pending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
        child: const Text(
          '申請中',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // フレンドでも申請中でもない場合
    return ElevatedButton.icon(
      onPressed: _sendFriendRequest,
      icon: const Icon(Icons.person_add),
      label: const Text('フレンド申請'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}