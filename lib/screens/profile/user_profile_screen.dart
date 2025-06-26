// lib/screens/profile/user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../widgets/friend_request_button.dart';
import '../../models/friend_model.dart';
import '../../services/friend_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  
  const UserProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FriendService _friendService = FriendService();
  
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  bool isFriend = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkFriendStatus();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();
      if (mounted) {
        setState(() {
          userData = doc.data() ?? {};
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFriendStatus() async {
    final result = await _friendService.isFriend(widget.userId);
    if (mounted) {
      setState(() {
        isFriend = result;
      });
    }
  }

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

  Widget _buildContactInfo() {
    final contactInfo = userData['contactInfo'];
    if (contactInfo == null) return const SizedBox.shrink();

    final contact = ContactInfo.fromMap(contactInfo);
    final visibleContacts = <Widget>[];

    // LINE ID
    if (contact.lineId != null && contact.lineId!.isNotEmpty) {
      if (contact.lineVisibility == ContactVisibility.public ||
          (contact.lineVisibility == ContactVisibility.friendsOnly && isFriend)) {
        visibleContacts.add(_buildContactItem('LINE', contact.lineId!));
      }
    }

    // Instagram ID
    if (contact.instagramId != null && contact.instagramId!.isNotEmpty) {
      if (contact.instagramVisibility == ContactVisibility.public ||
          (contact.instagramVisibility == ContactVisibility.friendsOnly && isFriend)) {
        visibleContacts.add(_buildContactItem('Instagram', contact.instagramId!));
      }
    }

    // 他の連絡先も同様に追加...

    if (visibleContacts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            '連絡先',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...visibleContacts,
        ],
      ),
    );
  }

  Widget _buildContactItem(String type, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getContactIcon(type),
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getContactIcon(String type) {
    switch (type) {
      case 'LINE':
        return Icons.chat_bubble_outline;
      case 'Instagram':
        return Icons.camera_alt_outlined;
      case 'TikTok':
        return Icons.music_note_outlined;
      case 'Email':
        return Icons.email_outlined;
      case 'Phone':
        return Icons.phone_outlined;
      default:
        return Icons.contact_page_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(userData['username'] ?? 'ユーザープロフィール'),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // アバター
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
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
                  
                  // フレンド申請ボタン
                  FriendRequestButton(
                    userId: widget.userId,
                    userName: userData['username'] ?? '名無し',
                    userPhotoUrl: userData['photoUrl'] ?? '',
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // チャットボタン
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: チャット画面へ遷移
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('チャット機能は開発中です'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('チャットする'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                    ),
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
                ],
              ),
            ),
            
            // 連絡先情報（公開設定に基づいて表示）
            _buildContactInfo(),
            
            // 趣味・興味
            if (userData['hobbies']?.isNotEmpty == true)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      '趣味・興味',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (userData['hobbies'] as List).map((hobby) {
                        return Chip(
                          label: Text(
                            hobby,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        );
                      }).toList(),
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