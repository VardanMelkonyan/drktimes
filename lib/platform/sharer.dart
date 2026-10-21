import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The OS share sheet (FR-053, FR-061).
abstract interface class Sharer {
  Future<void> shareText(String text, {String? subject});

  /// Shares [bytes] as a file called [name].
  Future<void> shareFile(String name, Uint8List bytes, {String? subject});
}

class SharePlusSharer implements Sharer {
  const SharePlusSharer();

  @override
  Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));

  @override
  Future<void> shareFile(
    String name,
    Uint8List bytes, {
    String? subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: name)],
        subject: subject,
      ),
    );
  }
}
