// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../config/theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../utils/constants.dart';
import '../../models/friend_model.dart';
import 'contact_edit_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedGender = '未設定';
  String _selectedPrefecture = '未設定';
  String _selectedAgeGroup = '未設定';
  List<String> _selectedHobbies = [];
  bool _isLoading = false;
  
  // 連絡先情報の状態
  int _publicContactCount = 0;
  int _friendsOnlyContactCount = 0;
  int _privateContactCount = 0;
  
  // プロフィール画像
  File? _imageFile;
  XFile? _webImageFile;
  String? _currentPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadContactStatus();
  }

  void _loadUserData() {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    
    if (userData != null) {
      _usernameController.text = userData['username'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _selectedGender = userData['gender'] ?? '未設定';
      _selectedPrefecture = userData['prefecture'] ?? '未設定';
      _selectedAgeGroup = userData['ageGroup'] ?? '未設定';
      _selectedHobbies = List<String>.from(userData['hobbies'] ?? []);
      _currentPhotoUrl = userData['photoUrl'];
    }
  }

  void _loadContactStatus() async {
          final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final data = doc.data();
      if (data != null && data['contactInfo'] != null) {
        final contactInfo = ContactInfo.fromMap(data['contactInfo']);
        
        int publicCount = 0;
        int friendsOnlyCount = 0;
        int privateCount = 0;
        
        // 各連絡先の公開設定をカウント
        void countVisibility(ContactVisibility? visibility) {
          if (visibility == ContactVisibility.public) publicCount++;
          else if (visibility == ContactVisibility.friendsOnly) friendsOnlyCount++;
          else if (visibility == ContactVisibility.private) privateCount++;
        }
        
        countVisibility(contactInfo.lineVisibility);
        countVisibility(contactInfo.instagramVisibility);
        countVisibility(contactInfo.xVisibility);
        countVisibility(contactInfo.tiktokVisibility);
        countVisibility(contactInfo.discordVisibility);
        countVisibility(contactInfo.kakaoVisibility);
        countVisibility(contactInfo.telegramVisibility);
        countVisibility(contactInfo.signalVisibility);
        countVisibility(contactInfo.phoneVisibility);
        countVisibility(contactInfo.emailVisibility);
        
        if (mounted) {
          setState(() {
            _publicContactCount = publicCount;
            _friendsOnlyContactCount = friendsOnlyCount;
            _privateContactCount = privateCount;
          });
        }
      }
    } catch (e) {
      print('連絡先情報の読み込みエラー: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Firebase Storageが利用可能か確認
      print('Firebase Storage instance: ${FirebaseStorage.instance}');
      print('Firebase Auth current user: ${FirebaseAuth.instance.currentUser?.uid}');
      
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          if (kIsWeb) {
            _webImageFile = pickedFile;
          } else {
            _imageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      print('Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の選択に失敗しました: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (!kIsWeb && _imageFile == null) return _currentPhotoUrl;
    if (kIsWeb && _webImageFile == null) return _currentPhotoUrl;

    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    
    print('Current user ID from Provider: ${authProvider.user?.uid}');
    print('Current user ID from FirebaseAuth: ${FirebaseAuth.instance.currentUser?.uid}');
    print('Auth user email: ${authProvider.user?.email}');
    
    if (userId == null) {
      print('User ID is null!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザーが認証されていません')),
      );
      return null;
    }

    try {
      // Firebase Storageにアップロード
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles/$fileName');

      print('Uploading to path: user_profiles/$fileName');
      print('User ID: $userId');
      print('Storage reference: ${storageRef.fullPath}');

      UploadTask uploadTask;
      
      if (kIsWeb && _webImageFile != null) {
        // Web環境の場合
        final bytes = await _webImageFile!.readAsBytes();
        print('Image size: ${bytes.length} bytes');
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (_imageFile != null) {
        // モバイル環境の場合
        uploadTask = storageRef.putFile(
          _imageFile!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        return null;
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Upload error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像のアップロードに失敗しました: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      
      // 画像をアップロード
      String? photoUrl = await _uploadImage();
      
      final profileData = {
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'prefecture': _selectedPrefecture,
        'ageGroup': _selectedAgeGroup,
        'hobbies': _selectedHobbies,
        if (photoUrl != null) 'photoUrl': photoUrl,
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
                  kIsWeb && _webImageFile != null
                      ? FutureBuilder<Uint8List>(
                          future: _webImageFile!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                backgroundImage: MemoryImage(snapshot.data!),
                              );
                            }
                            return CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                              child: const CircularProgressIndicator(),
                            );
                          },
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                          backgroundImage: _getImageProvider(),
                          child: _shouldShowInitial()
                              ? Text(
                                  _usernameController.text.isNotEmpty
                                      ? _usernameController.text[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
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
                        onPressed: _pickImage,
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
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // 連絡先情報の管理
            Card(
              elevation: 0,
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
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
                          '連絡先情報の管理',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '各連絡先の公開範囲を個別に設定できます。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // 連絡先編集画面へのボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactEditScreen(),
                            ),
                          );
                          // 画面から戻ってきたら連絡先情報を再読み込み
                          _loadContactStatus();
                        },
                        icon: const Icon(Icons.contact_phone),
                        label: const Text('連絡先情報を編集'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    // 現在の設定状況を表示
                    if (_publicContactCount > 0 || _friendsOnlyContactCount > 0 || _privateContactCount > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '現在の公開設定',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (_publicContactCount > 0) ...[
                                  _buildStatusChip(
                                    '全員に公開',
                                    _publicContactCount,
                                    Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (_friendsOnlyContactCount > 0) ...[
                                  _buildStatusChip(
                                    'フレンドのみ',
                                    _friendsOnlyContactCount,
                                    Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (_privateContactCount > 0)
                                  _buildStatusChip(
                                    '非公開',
                                    _privateContactCount,
                                    Colors.green,
                                  ),
                              ],
                            ),
                          ],
                        ),
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
  
  ImageProvider? _getImageProvider() {
    if (kIsWeb && _webImageFile != null) {
      // Web環境で新しい画像が選択された場合
      // FutureBuilderを使って非同期で画像を読み込む必要があるため、
      // 別の方法で実装する必要があります
      return null;
    } else if (!kIsWeb && _imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_currentPhotoUrl != null) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  bool _shouldShowInitial() {
    if (kIsWeb && _webImageFile != null) return false;
    if (!kIsWeb && _imageFile != null) return false;
    if (_currentPhotoUrl != null) return false;
    return true;
  }
  
  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}