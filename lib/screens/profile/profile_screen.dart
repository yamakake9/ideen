// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import '../../models/friend_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '未設定' : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(String label, String value, IconData icon, {bool isLink = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '未設定' : value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLink ? AppTheme.primaryColor : null,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<Widget>> _buildPublicContactInfo(BuildContext context, Map<String, dynamic> userData) async {
    final contactInfo = userData['contactInfo'];
    if (contactInfo == null) return [];

    final contact = ContactInfo.fromMap(contactInfo);
    final visibleContacts = <Widget>[];

    // Helper function to add contact row
    void addContactRow(String label, String? value, IconData icon, ContactVisibility visibility, {bool isLink = false, String? prefix}) {
      if (value != null && value.isNotEmpty && visibility == ContactVisibility.public) {
        final displayValue = prefix != null ? '$prefix$value' : value;
        visibleContacts.add(
          Padding(
            padding: EdgeInsets.only(bottom: visibleContacts.isNotEmpty ? 16 : 0),
            child: _buildContactRow(label, displayValue, icon, isLink: isLink),
          ),
        );
      }
    }

    // コミュニケーション系
    addContactRow('LINE ID', contact.lineId, Icons.chat_bubble_outline, contact.lineVisibility);
    addContactRow('Telegram', contact.telegramId, Icons.send, contact.telegramVisibility);
    addContactRow('Signal', contact.signalId, Icons.security, contact.signalVisibility);
    addContactRow('KakaoTalk', contact.kakaoTalkId, Icons.message, contact.kakaoVisibility);
    
    // SNS・発信系
    addContactRow('Instagram', contact.instagramId, Icons.camera_alt_outlined, contact.instagramVisibility, isLink: true, prefix: '@');
    addContactRow('TikTok', contact.tiktokId, Icons.music_video, contact.tiktokVisibility, isLink: true, prefix: '@');
    addContactRow('X (Twitter)', contact.xId, Icons.tag, contact.xVisibility, isLink: true, prefix: '@');
    
    // ビジネス・その他
    addContactRow('メールアドレス', contact.email, Icons.email_outlined, contact.emailVisibility);
    addContactRow('電話番号', contact.phoneNumber, Icons.phone_outlined, contact.phoneVisibility);
    addContactRow('Discord', contact.discordId, Icons.headset_mic_outlined, contact.discordVisibility);

    return visibleContacts;
  }

  Future<List<Widget>> _buildFriendsOnlyContactInfo(BuildContext context, Map<String, dynamic> userData) async {
    final contactInfo = userData['contactInfo'];
    if (contactInfo == null) return [];

    final contact = ContactInfo.fromMap(contactInfo);
    final visibleContacts = <Widget>[];

    // Helper function to add contact row
    void addContactRow(String label, String? value, IconData icon, ContactVisibility visibility, {bool isLink = false, String? prefix}) {
      if (value != null && value.isNotEmpty && visibility == ContactVisibility.friendsOnly) {
        final displayValue = prefix != null ? '$prefix$value' : value;
        visibleContacts.add(
          Padding(
            padding: EdgeInsets.only(bottom: visibleContacts.isNotEmpty ? 16 : 0),
            child: _buildContactRow(label, displayValue, icon, isLink: isLink),
          ),
        );
      }
    }

    // コミュニケーション系
    addContactRow('LINE ID', contact.lineId, Icons.chat_bubble_outline, contact.lineVisibility);
    addContactRow('Telegram', contact.telegramId, Icons.send, contact.telegramVisibility);
    addContactRow('Signal', contact.signalId, Icons.security, contact.signalVisibility);
    addContactRow('KakaoTalk', contact.kakaoTalkId, Icons.message, contact.kakaoVisibility);
    
    // SNS・発信系
    addContactRow('Instagram', contact.instagramId, Icons.camera_alt_outlined, contact.instagramVisibility, isLink: true, prefix: '@');
    addContactRow('TikTok', contact.tiktokId, Icons.music_video, contact.tiktokVisibility, isLink: true, prefix: '@');
    addContactRow('X (Twitter)', contact.xId, Icons.tag, contact.xVisibility, isLink: true, prefix: '@');
    
    // ビジネス・その他
    addContactRow('メールアドレス', contact.email, Icons.email_outlined, contact.emailVisibility);
    addContactRow('電話番号', contact.phoneNumber, Icons.phone_outlined, contact.phoneVisibility);
    addContactRow('Discord', contact.discordId, Icons.headset_mic_outlined, contact.discordVisibility);

    return visibleContacts;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};
    
    // デバッグ用
    print('Profile Screen - photoUrl: ${userData['photoUrl']}');
    print('Profile Screen - username: ${userData['username']}');
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // プロフィールヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // アバター
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty
                        ? Image.network(
                            userData['photoUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Image load error: $error');
                              return Center(
                                child: Text(
                                  userData['username']?.isNotEmpty == true
                                      ? userData['username'][0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              userData['username']?.isNotEmpty == true
                                  ? userData['username'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ユーザー名
                  Text(
                    userData['username'] ?? '名前未設定',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 自己紹介
                  if (userData['bio']?.isNotEmpty == true) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userData['bio'],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 編集ボタン
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('プロフィールを編集'),
                  ),
                ],
              ),
            ),
            
            // 基本情報
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '基本情報',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    '性別',
                    userData['gender'] ?? '未設定',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    '都道府県',
                    userData['prefecture'] ?? '未設定',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    '年齢層',
                    userData['ageGroup'] ?? '未設定',
                    Icons.cake_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'メールアドレス',
                    authProvider.user?.email ?? '',
                    Icons.email_outlined,
                  ),
                  
                  // 趣味・興味を基本情報内に追加
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.interests_outlined, size: 20, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        '趣味・興味',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  userData['hobbies']?.isNotEmpty == true
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (userData['hobbies'] as List).map((hobby) {
                            return Chip(
                              label: Text(
                                hobby,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            );
                          }).toList(),
                        )
                      : Text(
                          '趣味・興味が設定されていません',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                ],
              ),
            ),
            
            // 全員に公開中の連絡先情報
            FutureBuilder<List<Widget>>(
              future: _buildPublicContactInfo(context, userData),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.public,
                            size: 20,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '全員に公開中の連絡先情報',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...snapshot.data!,
                    ],
                  ),
                );
              },
            ),
            
            // フレンドに公開中の連絡先情報
            FutureBuilder<List<Widget>>(
              future: _buildFriendsOnlyContactInfo(context, userData),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 20,
                            color: Colors.orange[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'フレンドに公開中の連絡先情報',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...snapshot.data!,
                    ],
                  ),
                );
              },
            ),
            
            // アクション
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ログアウトボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('ログアウト'),
                            content: const Text('本当にログアウトしますか？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('キャンセル'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await authProvider.signOut();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorColor,
                                ),
                                child: const Text('ログアウト'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('ログアウト'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}