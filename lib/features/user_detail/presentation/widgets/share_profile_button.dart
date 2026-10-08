import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/share_service.dart';
import '../../domain/profile_share_content.dart';
import '../../domain/user_detail.dart';

class ShareProfileButton extends ConsumerWidget {
  const ShareProfileButton({super.key, required this.user});

  final UserDetail user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Share profile',
      icon: Icon(Icons.adaptive.share),
      onPressed: () => _share(context, ref),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final content = ProfileShareContent.forUser(user);
    final messenger = ScaffoldMessenger.maybeOf(context);

    final outcome = await ref
        .read(shareServiceProvider)
        .shareText(
          text: content.text,
          subject: content.subject,
          origin: _originOf(context),
        );

    if (outcome == ShareOutcome.failed) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't open the share sheet. Please try again."),
          ),
        );
    }
  }

  Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
