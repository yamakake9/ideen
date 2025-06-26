// lib/screens/profile/contact_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/friend_model.dart';

class ContactEditScreen extends StatefulWidget {
  const ContactEditScreen({super.key});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  
  // テキストコントローラー
  final _lineIdController = TextEditingController();
  final _instagramIdController = TextEditingController();
  final _xIdController = TextEditingController();
  final _tiktokIdController = TextEditingController();
  final _discordIdController = TextEditingController();
  final _kakaoIdController = TextEditingController();
  final _telegramIdController = TextEditingController();
  final _signalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  // 公開設定
  ContactVisibility _lineVisibility = ContactVisibility.private;
  ContactVisibility _instagramVisibility = ContactVisibility.private;
  ContactVisibility _xVisibility = ContactVisibility.private;
  ContactVisibility _tiktokVisibility = ContactVisibility.private;
  ContactVisibility _discordVisibility = ContactVisibility.private;
  ContactVisibility _kakaoVisibility = ContactVisibility.private;
  ContactVisibility _telegramVisibility = ContactVisibility.private;
  ContactVisibility _signalVisibility = ContactVisibility.private;
  ContactVisibility _phoneVisibility = ContactVisibility.private;
  ContactVisibility _emailVisibility = ContactVisibility.private;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  @override
  void dispose() {
    _lineIdController.dispose();
    _instagramIdController.dispose();
    _xIdController.dispose();
    _tiktokIdController.dispose();
    _discordIdController.dispose();
    _kakaoIdController.dispose();
    _telegramIdController.dispose();
    _signalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadContactInfo() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      
      if (data != null && data['contactInfo'] != null) {
        final contactInfo = ContactInfo.fromMap(data['contactInfo']);
        
        setState(() {
          _lineIdController.text = contactInfo.lineId ?? '';
          _instagramIdController.text = contactInfo.instagramId ?? '';
          _xIdController.text = contactInfo.xId ?? '';
          _tiktokIdController.text = contactInfo.tiktokId ?? '';
          _discordIdController.text = contactInfo.discordId ?? '';
          _kakaoIdController.text = contactInfo.kakaoTalkId ?? '';
          _telegramIdController.text = contactInfo.telegramId ?? '';
          _signalIdController.text = contactInfo.signalId ?? '';
          _phoneController.text = contactInfo.phoneNumber ?? '';
          _emailController.text = contactInfo.email ?? '';
          
          _lineVisibility = contactInfo.lineVisibility;
          _instagramVisibility = contactInfo.instagramVisibility;
          _xVisibility = contactInfo.xVisibility;
          _tiktokVisibility = contactInfo.tiktokVisibility;
          _discordVisibility = contactInfo.discordVisibility;
          _kakaoVisibility = contactInfo.kakaoVisibility;
          _telegramVisibility = contactInfo.telegramVisibility;
          _signalVisibility = contactInfo.signalVisibility;
          _phoneVisibility = contactInfo.phoneVisibility;
          _emailVisibility = contactInfo.emailVisibility;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('読み込みエラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveContactInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final contactInfo = ContactInfo(
        lineId: _lineIdController.text.isEmpty ? null : _lineIdController.text,
        instagramId: _instagramIdController.text.isEmpty ? null : _instagramIdController.text,
        xId: _xIdController.text.isEmpty ? null : _xIdController.text,
        tiktokId: _tiktokIdController.text.isEmpty ? null : _tiktokIdController.text,
        discordId: _discordIdController.text.isEmpty ? null : _discordIdController.text,
        kakaoTalkId: _kakaoIdController.text.isEmpty ? null : _kakaoIdController.text,
        telegramId: _telegramIdController.text.isEmpty ? null : _telegramIdController.text,
        signalId: _signalIdController.text.isEmpty ? null : _signalIdController.text,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        lineVisibility: _lineVisibility,
        instagramVisibility: _instagramVisibility,
        xVisibility: _xVisibility,
        tiktokVisibility: _tiktokVisibility,
        discordVisibility: _discordVisibility,
        kakaoVisibility: _kakaoVisibility,
        telegramVisibility: _telegramVisibility,
        signalVisibility: _signalVisibility,
        phoneVisibility: _phoneVisibility,
        emailVisibility: _emailVisibility,
      );

      await _firestore.collection('users').doc(userId).update({
        'contactInfo': contactInfo.toMap(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('連絡先情報を保存しました')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('連絡先情報の編集'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveContactInfo,
            child: const Text('保存'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    '連絡先情報',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '各項目ごとに公開範囲を設定できます。初期設定は「公開しない」になっています。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // コミュニケーション系
                  _buildSectionHeader('コミュニケーション系', Icons.chat),
                  const SizedBox(height: 16),
                  
                  // LINE ID
                  _buildContactField(
                    label: 'LINE ID',
                    controller: _lineIdController,
                    visibility: _lineVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _lineVisibility = value);
                    },
                    icon: Icons.chat_bubble,
                  ),
                  
                  // Telegram ID
                  _buildContactField(
                    label: 'Telegram ID',
                    controller: _telegramIdController,
                    visibility: _telegramVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _telegramVisibility = value);
                    },
                    icon: Icons.send,
                  ),
                  
                  // Signal ID
                  _buildContactField(
                    label: 'Signal ID',
                    controller: _signalIdController,
                    visibility: _signalVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _signalVisibility = value);
                    },
                    icon: Icons.security,
                  ),
                  
                  // KakaoTalk ID
                  _buildContactField(
                    label: 'KakaoTalk ID',
                    controller: _kakaoIdController,
                    visibility: _kakaoVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _kakaoVisibility = value);
                    },
                    icon: Icons.message,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // SNS・発信系
                  _buildSectionHeader('SNS・発信系', Icons.share),
                  const SizedBox(height: 16),
                  
                  // Instagram ID
                  _buildContactField(
                    label: 'Instagram ID',
                    controller: _instagramIdController,
                    visibility: _instagramVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _instagramVisibility = value);
                    },
                    icon: Icons.camera_alt,
                  ),
                  
                  // TikTok ID
                  _buildContactField(
                    label: 'TikTok ID',
                    controller: _tiktokIdController,
                    visibility: _tiktokVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _tiktokVisibility = value);
                    },
                    icon: Icons.music_video,
                  ),
                  
                  // X (Twitter) ID
                  _buildContactField(
                    label: 'X (Twitter) ID',
                    controller: _xIdController,
                    visibility: _xVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _xVisibility = value);
                    },
                    icon: Icons.tag,
                    hint: '@なしで入力',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ビジネス・その他
                  _buildSectionHeader('ビジネス・その他', Icons.business),
                  const SizedBox(height: 16),
                  
                  // メールアドレス
                  _buildContactField(
                    label: 'メールアドレス',
                    controller: _emailController,
                    visibility: _emailVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _emailVisibility = value);
                    },
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email,
                  ),
                  
                  // 電話番号
                  _buildContactField(
                    label: '電話番号',
                    controller: _phoneController,
                    visibility: _phoneVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _phoneVisibility = value);
                    },
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone,
                  ),
                  
                  // Discord ID
                  _buildContactField(
                    label: 'Discord ID',
                    controller: _discordIdController,
                    visibility: _discordVisibility,
                    onVisibilityChanged: (value) {
                      setState(() => _discordVisibility = value);
                    },
                    icon: Icons.headset,
                    hint: 'ユーザー名#0000',
                  ),
                  
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                '注意事項',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• 連絡先情報は慎重に共有してください\n'
                            '• 「全員に公開」を選択すると、すべてのユーザーがあなたの連絡先を見ることができます\n'
                            '• 「フレンドのみ公開」を選択すると、フレンドのみが連絡先を見ることができます\n'
                            '• 「公開しない」を選択すると、チャット内で手動で共有するまで誰も見ることができません',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactField({
    required String label,
    required TextEditingController controller,
    required ContactVisibility visibility,
    required Function(ContactVisibility) onVisibilityChanged,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint ?? '$labelを入力',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '公開範囲',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildVisibilityOption(
                    '全員に公開',
                    ContactVisibility.public,
                    visibility,
                    onVisibilityChanged,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVisibilityOption(
                    'フレンドのみ',
                    ContactVisibility.friendsOnly,
                    visibility,
                    onVisibilityChanged,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVisibilityOption(
                    '公開しない',
                    ContactVisibility.private,
                    visibility,
                    onVisibilityChanged,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption(
    String label,
    ContactVisibility value,
    ContactVisibility groupValue,
    Function(ContactVisibility) onChanged,
    Color color,
  ) {
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 16,
                color: color,
              ),
            if (isSelected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}