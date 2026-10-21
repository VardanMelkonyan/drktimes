import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../app/config.dart';
import 'codec.dart';
import 'document.dart';

/// A recipe link: `https://<host>/r#base64url(deflate-raw(utf8(json)))`.
/// The payload lives in the fragment so no server ever receives it (FR-072).
class ShareLink {
  const ShareLink(this.url);

  final String url;

  bool get tooLongForLink => url.length > kMaxLinkLength;
}

class LinkCodec {
  const LinkCodec._();

  static String encodePayload(ExchangeDocument d) {
    final bytes = utf8.encode(ExchangeCodec.encodeString(d));
    final packed = Deflate(bytes).getBytes();
    return base64Url.encode(packed).replaceAll('=', '');
  }

  static ShareLink encode(ExchangeDocument d, {String host = kShareHost}) =>
      ShareLink('https://$host/r#${encodePayload(d)}');

  /// Decodes a link's fragment (or a bare payload). Throws [ExchangeException].
  static ExchangeDocument decode(String linkOrPayload) {
    var payload = linkOrPayload.trim();
    final hash = payload.indexOf('#');
    if (hash >= 0) payload = payload.substring(hash + 1);
    final Uint8List packed;
    try {
      packed = base64Url.decode(base64Url.normalize(payload));
    } on FormatException catch (e) {
      throw ExchangeException(ExchangeError.badEncoding, e.message);
    }
    final String text;
    try {
      text = utf8.decode(Inflate(packed).getBytes());
    } catch (e) {
      throw ExchangeException(ExchangeError.badEncoding, '$e');
    }
    return ExchangeCodec.decodeString(text);
  }
}
