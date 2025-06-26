// lib/widgets/post/post_card.dart

import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PostCard extends StatelessWidget {
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

  Color _getGenderColor(String gender) {
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
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
                    backgroundColor: _getGenderColor(post['gender']).withOpacity(0.2),
                    child: Text(
                      post['username'][0],
                      style: TextStyle(
                        color: _getGenderColor(post['gender']),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
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
                              post['username'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '@${post['displayId']}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
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
                                color: _getGenderColor(post['gender']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                post['gender'],
                                style: TextStyle(
                                  color: _getGenderColor(post['gender']),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${post['prefecture']} • ${post['ageGroup']}',
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
                    _getTimeAgo(createdAt),
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
                post['message'],
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
                  if (onDelete != null || onReport != null)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: AppTheme.textTertiary,
                      ),
                      onSelected: (value) {
                        if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        } else if (value == 'report' && onReport != null) {
                          onReport!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onDelete != null)
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
                        if (onReport != null)
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
                  
                  // ID交換ボタン
                  TextButton.icon(
                    onPressed: onExchange,
                    icon: const Icon(
                      Icons.swap_horiz,
                      size: 20,
                    ),
                    label: const Text('チャットする'),
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
          ),
        ),
      ),
    );
  }
}