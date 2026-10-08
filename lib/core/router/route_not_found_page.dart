import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/status_view.dart';
import 'app_router.dart';

class RouteNotFoundPage extends StatelessWidget {
  const RouteNotFoundPage({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StatusView(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message: 'Nothing lives at $location.',
        actionLabel: 'Go to search',
        onAction: () => context.go(AppRoutes.search),
      ),
    );
  }
}
