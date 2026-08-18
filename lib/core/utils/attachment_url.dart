import 'package:get/get.dart';

import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';

/// Resolves an attachment's stored path/URL into something a network image
/// widget can actually load.
///
/// The backend hands back attachment paths in several shapes — full URLs,
/// host-relative paths, and occasionally Windows-style absolute paths
/// (backslashes, drive letters) or paths wrapped in brackets/parens — so
/// every place that renders an attachment used to carry its own ad-hoc
/// version of this cleanup. Kept in one place now so an attachment resolves
/// the same way right after upload as it does after a fresh fetch.
String? normalizeAttachmentUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  String path = value.trim().replaceAll('\\', '/');
  if (path.startsWith('~/')) path = path.substring(2);

  if (path.startsWith('[') && path.endsWith(']')) {
    path = path.substring(1, path.length - 1).trim();
  }
  if (path.startsWith('(') && path.endsWith(')')) {
    path = path.substring(1, path.length - 1).trim();
  }

  // A Windows-style absolute path (`C:/inetpub/wwwroot/uploads/x.jpg`) isn't
  // web-servable as-is — pull out just the `/`-rooted tail the server
  // actually serves the file at.
  final match = RegExp(r'(/[^)\]\s]+\.\w+)').firstMatch(path);
  if (match != null) path = match.group(0)!;

  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) return uri.toString();

  try {
    return Uri.parse(ApiClient.baseUrl).resolve(path).toString();
  } catch (_) {
    return null;
  }
}

/// Turns a stored local path into a filesystem path `File()` can open —
/// strips a `file://` prefix if present.
String? normalizeLocalPath(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final path = value.trim();
  if (!path.startsWith('file://')) return path;
  final uri = Uri.tryParse(path);
  return uri?.toFilePath();
}

/// The header a direct request to an attachment URL needs to authenticate.
///
/// [ApiClient]'s Dio instance attaches this to every request automatically,
/// but `Image.network`/`NetworkImage` talk to the attachment host directly
/// and skip that interceptor entirely — without this, a private attachment
/// 401s and the image renders as permanently unavailable.
Map<String, String>? attachmentAuthHeaders() {
  final session = Get.find<SessionStorage>();
  final token = session.token.value;
  if (!session.isLoggedIn || token == null) return null;
  return {'Authorization': 'Bearer $token'};
}
