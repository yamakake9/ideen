// lib/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('検索'),
      ),
      body: const Center(
        child: Text('検索画面（実装予定）'),
      ),
    );
  }
}