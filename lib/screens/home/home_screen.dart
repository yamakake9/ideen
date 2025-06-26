import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../services/chat_service.dart';
import '../../models/post_model.dart';
import '../../widgets/post/post_card.dart';
import '../chat/chat_screen.dart';import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/post_service.dart';
import '../../models/post_model.dart';
import '../../widgets/post/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final PostService _postService = PostService();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showCreatePostDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '新規投稿',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'どんな人と繋がりたいですか？',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('メッセージを入力してください'),
                          backgroundColor: AppTheme.warningColor,
                        ),
                      );
                      return;
                    }

                    // 投稿を作成
                    final postId = await _postService.createPost(
                      userId: authProvider.user!.uid,
                      username: authProvider.userData?['username'] ?? '名無し',
                      displayId: authProvider.user!.uid, // 内部IDとして使用（非表示）
                      message: _messageController.text.trim(),
                      userProfile: authProvider.userData ?? {},
                    );

                    if (postId != null && mounted) {
                      _messageController.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('投稿しました！'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('投稿に失敗しました'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                  child: const Text('投稿する'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Ideen'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 通知画面へ
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _postService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'まだ投稿がありません',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '最初の投稿をしてみましょう！',
                    style: TextStyle(color: AppTheme.textTertiary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // StreamBuilderが自動的に更新するので、ここでは何もしない
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PostCard(
                    post: post.toFirestore()..['id'] = post.id,
                    createdAt: post.createdAt,
                    onTap: () {
                      // TODO: 詳細画面へ
                    },
                    onExchange: () async {
                      // チャット画面へ遷移
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final currentUser = authProvider.user;
                      final currentUserData = authProvider.userData;
                      
                      if (currentUser == null || currentUserData == null) return;
                      
                      // チャットルームを作成または取得
                      final chatRoomId = await _chatService.createOrGetChatRoom(
                        userId1: currentUser.uid,
                        userId2: post.userId,
                        user1Data: currentUserData,
                        user2Data: {
                          'username': post.username,
                          'profileImageUrl': '',
                        },
                      );
                      
                      if (chatRoomId != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatRoomId: chatRoomId,
                              otherUserId: post.userId,
                              otherUserName: post.username,
                            ),
                          ),
                        );
                      }
                    },
                    onDelete: post.userId == authProvider.user?.uid
                        ? () async {
                            final success = await _postService.deletePost(post.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('投稿を削除しました'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          }
                        : null,
                    onReport: post.userId != authProvider.user?.uid
                        ? () async {
                            final success = await _postService.reportPost(post.id);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('投稿を通報しました'),
                                  backgroundColor: AppTheme.warningColor,
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}