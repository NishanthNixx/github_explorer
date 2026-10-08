import 'package:flutter/material.dart';

import '../widgets/status_view.dart';
import 'window_size.dart';

class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    super.key,
    required this.master,
    required this.detail,
    this.masterWidth = 380,
  });

  final Widget master;
  final Widget detail;
  final double masterWidth;

  @override
  Widget build(BuildContext context) {
    if (!WindowSize.of(context).isExpanded) return detail;

    return Row(
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: detail),
      ],
    );
  }
}

class MasterHome extends StatelessWidget {
  const MasterHome({
    super.key,
    required this.master,
    required this.emptyDetail,
  });

  final Widget master;
  final Widget emptyDetail;

  @override
  Widget build(BuildContext context) {
    return WindowSize.of(context).isExpanded ? emptyDetail : master;
  }
}

class EmptyDetailPane extends StatelessWidget {
  const EmptyDetailPane({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.person_search_rounded,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StatusView(icon: icon, title: title, message: message),
    );
  }
}
