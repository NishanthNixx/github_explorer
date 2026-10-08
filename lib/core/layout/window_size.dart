import 'package:flutter/widgets.dart';

enum WindowSize {
  compact,
  medium,
  expanded;

  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 840;

  static WindowSize fromWidth(double width) {
    if (width >= expandedMinWidth) return WindowSize.expanded;
    if (width >= mediumMinWidth) return WindowSize.medium;
    return WindowSize.compact;
  }

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == WindowSize.compact;

  bool get isExpanded => this == WindowSize.expanded;
}
