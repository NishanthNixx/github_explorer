import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final shareServiceProvider = Provider<ShareService>(
  (ref) => NativeShareService(SharePlus.instance),
);

enum ShareOutcome { shared, dismissed, unknown, failed }

abstract interface class ShareService {
  Future<ShareOutcome> shareText({
    required String text,
    String? subject,
    Rect? origin,
  });
}

class NativeShareService implements ShareService {
  const NativeShareService(this._sharePlus);

  final SharePlus _sharePlus;

  @override
  Future<ShareOutcome> shareText({
    required String text,
    String? subject,
    Rect? origin,
  }) async {
    try {
      final result = await _sharePlus.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      );
      return switch (result.status) {
        ShareResultStatus.success => ShareOutcome.shared,
        ShareResultStatus.dismissed => ShareOutcome.dismissed,
        ShareResultStatus.unavailable => ShareOutcome.unknown,
      };
    } on PlatformException {
      return ShareOutcome.failed;
    } on MissingPluginException {
      return ShareOutcome.failed;
    }
  }
}
