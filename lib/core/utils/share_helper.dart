import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Anchors the OS share sheet to [context]'s render box.
///
/// Some share_plus/iOS combinations reject a share call outright with
/// "sharePositionOrigin: argument must be set" when it's omitted — not just
/// the iPad/Mac popover case this is usually needed for.
Rect? shareOriginFromContext(BuildContext context) {
  final box = context.findRenderObject();
  return box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
}

Future<void> shareXFilesSafely(BuildContext context, List<XFile> files) async {
  await SharePlus.instance.share(
    ShareParams(
      files: files,
      sharePositionOrigin: shareOriginFromContext(context),
    ),
  );
}
