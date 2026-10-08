import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/search/presentation/pages/search_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Explorer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SearchPage(),
    );
  }
}
