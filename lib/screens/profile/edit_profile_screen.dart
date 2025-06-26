// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  // SNS ID用のコントローラー
  final _lineIdController = TextEditingController();
  final _tiktokIdController = TextEditingController();
  final _kakaoTalkIdController = TextEditingController();
  final _instagramIdController = TextEditingController();
  final _telegramIdController = TextEditingController();
  final _signalIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _contactEmailController = TextEditingController();
  
  String _selectedGender = '未設定';
  String _selectedPrefecture = '未設定';
  String _selectedAgeGroup = '未設定';
  List<String> _selectedHobbies = [];
  bool _isLoading = false;
  bool _showSnsIds = false; // SNS ID入力欄の表示切り替え

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    
    if (userData != null) {
      _usernameController.text = userData['username'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _selectedGender = userData['gender'] ?? '未設定';
      _selectedPrefecture = userData['prefecture'] ?? '未設定';
      _selectedAgeGroup = userData['ageGroup'] ?? '未設定';
      _selectedHobbies = List<String>.from(userData['hobbies'] ?? []);
      
      // SNS IDsの読み込み
      _lineIdController.text = userData['lineId'] ?? '';
      _tiktokIdController.text = userData['tiktokId'] ?? '';
      _kakaoTalkIdController.text = userData['kakaoTalkId'] ?? '';
      _instagramIdController.text = userData['instagramId'] ?? '';
      _telegramIdController.text = userData['telegramId'] ?? '';
      _signalIdController.text = userData['signalId'] ?? '';
      _phoneNumberController.text = userData['phoneNumber'] ?? '';
      _contactEmailController.text = userData['contactEmail'] ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _lineIdController.dispose();
    _tiktokIdController.dispose();
    _kakaoTalkIdController.dispose();
    _instagramIdController.dispose();
    _telegramIdController.dispose();
    _signalIdController.dispose();
    _phoneNumberController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final profileData = {
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'prefecture': _selectedPrefecture,
        'ageGroup': _selectedAgeGroup,
        'hobbies': _selectedHobbies,
        // SNS IDs
        'lineId': _lineIdController.text.trim(),
        'tiktokId': _tiktokIdController.text.trim(),
        'kakaoTalkId': _kakaoTalkIdController.text.trim(),
        'instagramId': _instagramIdController.text.trim(),
        'telegramId': _telegramIdController.text.trim(),
        'signalId': _signalIdController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
      };

      final success = await authProvider.updateUserProfile(profileData);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新に失敗しました'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildSnsIdField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // プロフィール画像
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: Text(
                      _usernameController.text.isNotEmpty
                          ? _usernameController.text[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // TODO: 画像選択機能
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ユーザー名（ニックネーム）
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'ニックネーム',
                hintText: '掲示板に表示される名前',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ニックネームを入力してください';
                }
                if (value.length < 2) {
                  return 'ニックネームは2文字以上必要です';
                }
                if (value.length > 20) {
                  return 'ニックネームは20文字以内にしてください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ひとことコメント（自己紹介）
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'ひとことコメント',
                hintText: '掲示板に表示されるコメント',
                prefixIcon: Icon(Icons.edit_note),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // 基本情報
            Text(
              '基本情報',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // 性別
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: '性別',
                prefixIcon: Icon(Icons.person),
              ),
              items: AppConstants.genderOptions.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value ?? '未設定';
                });
              },
            ),
            const SizedBox(height: 16),

            // 都道府県
            DropdownButtonFormField<String>(
              value: _selectedPrefecture,
              decoration: const InputDecoration(
                labelText: '都道府県',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: AppConstants.prefectureOptions.map((prefecture) {
                return DropdownMenuItem(
                  value: prefecture,
                  child: Text(prefecture),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrefecture = value ?? '未設定';
                });
              },
            ),
            const SizedBox(height: 16),

            // 年齢層
            DropdownButtonFormField<String>(
              value: _selectedAgeGroup,
              decoration: const InputDecoration(
                labelText: '年齢層',
                prefixIcon: Icon(Icons.cake),
              ),
              items: AppConstants.ageGroupOptions.map((ageGroup) {
                return DropdownMenuItem(
                  value: ageGroup,
                  child: Text(ageGroup),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAgeGroup = value ?? '未設定';
                });
              },
            ),
            const SizedBox(height: 24),

            // 趣味・興味
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
              children: AppConstants.hobbyOptions.map((hobby) {
                final isSelected = _selectedHobbies.contains(hobby);
                return FilterChip(
                  label: Text(hobby),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedHobbies.add(hobby);
                      } else {
                        _selectedHobbies.remove(hobby);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // 連絡先ID設定（非公開）
            Card(
              elevation: 0,
              color: AppTheme.primaryColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '連絡先ID設定（非公開）',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'チャット時に相手に送信できるIDです。掲示板には表示されません。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // 表示/非表示切り替えボタン
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showSnsIds = !_showSnsIds;
                        });
                      },
                      icon: Icon(
                        _showSnsIds ? Icons.visibility_off : Icons.visibility,
                      ),
                      label: Text(
                        _showSnsIds ? '連絡先IDを隠す' : '連絡先IDを設定する',
                      ),
                    ),

                    // SNS ID入力フィールド
                    if (_showSnsIds) ...[
                      const SizedBox(height: 16),
                      
                      // LINE ID
                      _buildSnsIdField(
                        label: 'LINE ID',
                        controller: _lineIdController,
                        icon: Icons.chat,
                        hint: 'あなたのLINE ID',
                      ),
                      const SizedBox(height: 16),

                      // TikTok ID
                      _buildSnsIdField(
                        label: 'TikTok ID',
                        controller: _tiktokIdController,
                        icon: Icons.music_video,
                        hint: '@なしで入力',
                      ),
                      const SizedBox(height: 16),

                      // KakaoTalk ID
                      _buildSnsIdField(
                        label: 'KakaoTalk ID',
                        controller: _kakaoTalkIdController,
                        icon: Icons.message,
                        hint: 'KakaoTalk ID',
                      ),
                      const SizedBox(height: 16),

                      // Instagram
                      _buildSnsIdField(
                        label: 'Instagram',
                        controller: _instagramIdController,
                        icon: Icons.photo_camera,
                        hint: '@を含めて入力',
                      ),
                      const SizedBox(height: 16),

                      // Telegram
                      _buildSnsIdField(
                        label: 'Telegram',
                        controller: _telegramIdController,
                        icon: Icons.send,
                        hint: '@を含めて入力',
                      ),
                      const SizedBox(height: 16),

                      // Signal
                      _buildSnsIdField(
                        label: 'Signal ID',
                        controller: _signalIdController,
                        icon: Icons.security,
                        hint: 'Signal ID',
                      ),
                      const SizedBox(height: 16),

                      // 電話番号
                      _buildSnsIdField(
                        label: '電話番号',
                        controller: _phoneNumberController,
                        icon: Icons.phone,
                        hint: '090-1234-5678',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // 連絡用メールアドレス
                      _buildSnsIdField(
                        label: '連絡用メールアドレス',
                        controller: _contactEmailController,
                        icon: Icons.email,
                        hint: 'contact@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}