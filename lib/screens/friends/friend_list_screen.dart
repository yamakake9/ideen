// lib/screens/friends/friend_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/friend_model.dart';
import '../../services/friend_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendService _friendService = FriendService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'フレンド一覧'),
            Tab(
              child: StreamBuilder<List<FriendRequest>>(
                stream: _friendService.getReceivedFriendRequests(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('受信'),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const Tab(text: '申請中'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // フレンド一覧タブ
          _buildFriendsList(),
          // 受信タブ
          _buildReceivedRequests(),
          // 申請中タブ
          _buildSentRequests(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<Friend>>(
      stream: _friendService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('エラー: ${snapshot.error}'),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'フレンドがいません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ユーザーを検索してフレンド申請を送りましょう',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _FriendListTile(
              friend: friend,
              onRemove: () => _removeFriend(friend),
            );
          },
        );
      },
    );
  }

  Widget _buildReceivedRequests() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendService.getReceivedFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('エラー: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '新しいフレンド申請はありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _ReceivedRequestTile(
              request: request,
              onAccept: () => _acceptRequest(request),
              onReject: () => _rejectRequest(request),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequests() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendService.getSentFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('エラー: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '申請中のリクエストはありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _SentRequestTile(
              request: request,
              onCancel: () => _cancelRequest(request),
            );
          },
        );
      },
    );
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンド解除'),
        content: Text('${friend.friendName}さんをフレンドから削除しますか？'),
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
      try {
        await _friendService.removeFriend(friend.friendId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('フレンドを削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    try {
      await _friendService.acceptFriendRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンド申請を承認しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      await _friendService.rejectFriendRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンド申請を拒否しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _cancelRequest(FriendRequest request) async {
    try {
      await _friendService.cancelFriendRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンド申請をキャンセルしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }
}

// フレンドリストタイル
class _FriendListTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onRemove;

  const _FriendListTile({
    Key? key,
    required this.friend,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend.friendPhotoUrl.isNotEmpty
            ? CachedNetworkImageProvider(friend.friendPhotoUrl)
            : null,
        child: friend.friendPhotoUrl.isEmpty
            ? Text(friend.friendName.isNotEmpty ? friend.friendName[0] : '?')
            : null,
      ),
      title: Text(friend.friendName),
      subtitle: Text('フレンドになった日: ${_formatDate(friend.createdAt)}'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'remove') {
            onRemove();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'remove',
            child: Text('フレンド解除'),
          ),
        ],
      ),
      onTap: () {
        // TODO: プロフィール画面へ遷移
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

// 受信リクエストタイル
class _ReceivedRequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ReceivedRequestTile({
    Key? key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: request.fromUserPhotoUrl.isNotEmpty
            ? CachedNetworkImageProvider(request.fromUserPhotoUrl)
            : null,
        child: request.fromUserPhotoUrl.isEmpty
            ? Text(request.fromUserName.isNotEmpty ? request.fromUserName[0] : '?')
            : null,
      ),
      title: Text(request.fromUserName),
      subtitle: Text('申請日: ${_formatDate(request.createdAt)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: onAccept,
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: onReject,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

// 送信リクエストタイル
class _SentRequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onCancel;

  const _SentRequestTile({
    Key? key,
    required this.request,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 送信リクエストでは相手の情報が必要なので、
    // 実際の実装では相手のユーザー情報を取得する必要があります
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: const Text('申請中'),
      subtitle: Text('申請日: ${_formatDate(request.createdAt)}'),
      trailing: TextButton(
        onPressed: onCancel,
        child: const Text('キャンセル'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}