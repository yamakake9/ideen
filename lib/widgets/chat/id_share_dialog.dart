// lib/widgets/chat/id_share_dialog.dart

import 'package:flutter/material.dart';
import '../../config/theme.dart';

class IdShareDialog extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Function(String type, String id) onShare;

  const IdShareDialog({
    super.key,
    required this.userData,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final availableIds = <Map<String, String>>[];

    // 登録されているIDを確認
    if (userData['lineId']?.isNotEmpty == true) {
      availableIds.add({'type': 'LINE ID', 'id': userData['lineId'], 'icon': 'chat'});
    }
    if (userData['tiktokId']?.isNotEmpty == true) {
      availableIds.add({'type': 'TikTok ID', 'id': userData['tiktokId'], 'icon': 'music_video'});
    }
    if (userData['kakaoTalkId']?.isNotEmpty == true) {
      availableIds.add({'type': 'KakaoTalk ID', 'id': userData['kakaoTalkId'], 'icon': 'message'});
    }
    if (userData['instagramId']?.isNotEmpty == true) {
      availableIds.add({'type': 'Instagram', 'id': userData['instagramId'], 'icon': 'photo_camera'});
    }
    if (userData['telegramId']?.isNotEmpty == true) {
      availableIds.add({'type': 'Telegram', 'id': userData['telegramId'], 'icon': 'send'});
    }
    if (userData['signalId']?.isNotEmpty == true) {
      availableIds.add({'type': 'Signal ID', 'id': userData['signalId'], 'icon': 'security'});
    }
    if (userData['phoneNumber']?.isNotEmpty == true) {
      availableIds.add({'type': '電話番号', 'id': userData['phoneNumber'], 'icon': 'phone'});
    }
    if (userData['contactEmail']?.isNotEmpty == true) {
      availableIds.add({'type': '連絡用メールアドレス', 'id': userData['contactEmail'], 'icon': 'email'});
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
            '連絡先を共有',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '共有する連絡先を選択してください',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          if (availableIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '共有できる連絡先がありません',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: プロフィール編集画面へ遷移
                      },
                      child: const Text('プロフィールで設定する'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...availableIds.map((idData) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    // 確認ダイアログを表示
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('${idData['type']}を送信'),
                        content: Text(
                          '本当に「${idData['id']}」を相手に送信しますか？',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('送信しない'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('送信する'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      onShare(idData['type']!, idData['id']!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIconData(idData['icon']!),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                idData['type']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                idData['id']!,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.send,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'chat':
        return Icons.chat;
      case 'music_video':
        return Icons.music_video;
      case 'message':
        return Icons.message;
      case 'photo_camera':
        return Icons.photo_camera;
      case 'send':
        return Icons.send;
      case 'security':
        return Icons.security;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      default:
        return Icons.share;
    }
  }
}