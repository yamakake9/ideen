// lib/screens/community/community_screen.dart

import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('みんなで語る'),
      ),
      body: const Center(
        child: Text('コミュニティ画面（実装予定）'),
      ),
    );
  }
}