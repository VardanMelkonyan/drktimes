import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';

/// Something the OS handed us: a tapped link or an opened/shared file.
sealed class IncomingPayload {
  const IncomingPayload();
}

class IncomingLink extends IncomingPayload {
  const IncomingLink(this.uri);

  final Uri uri;
}

class IncomingFile extends IncomingPayload {
  const IncomingFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Incoming links and files (contracts/platform-channels.md §5).
abstract interface class Intake {
  Stream<IncomingPayload> get payloads;
}

/// `app_links` for links (and file URLs on iOS), plus a small Android channel
/// for `content://` URIs and share intents.
class PlatformIntake implements Intake {
  PlatformIntake() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'incomingFile') {
        final a = Map<String, dynamic>.from(call.arguments as Map);
        _out.add(
          IncomingFile(
            a['name'] as String? ?? 'shared.drktimes',
            Uint8List.fromList(List<int>.from(a['bytes'] as List)),
          ),
        );
      }
    });
    _links = AppLinks().uriLinkStream.listen(_onUri);
    if (Platform.isAndroid) {
      _channel.invokeMethod<void>('ready');
    }
  }

  static const _channel = MethodChannel('am.drktimes/intake');
  final _out = StreamController<IncomingPayload>.broadcast();
  late final StreamSubscription<Uri> _links;

  @override
  Stream<IncomingPayload> get payloads => _out.stream;

  Future<void> _onUri(Uri uri) async {
    try {
      switch (uri.scheme) {
        case 'file':
          final f = File.fromUri(uri);
          _out.add(
            IncomingFile(
              uri.pathSegments.isEmpty
                  ? 'shared.drktimes'
                  : uri.pathSegments.last,
              await f.readAsBytes(),
            ),
          );
        case 'content':
          final res = await _channel.invokeMethod<Map<Object?, Object?>>(
            'readContent',
            {'uri': uri.toString()},
          );
          if (res != null) {
            _out.add(
              IncomingFile(
                res['name'] as String? ?? 'shared.drktimes',
                Uint8List.fromList(List<int>.from(res['bytes'] as List)),
              ),
            );
          }
        default:
          _out.add(IncomingLink(uri));
      }
    } catch (_) {
      // An unreadable file is reported as an invalid import.
      _out.add(IncomingFile('unreadable', Uint8List(0)));
    }
  }

  Future<void> dispose() async {
    await _links.cancel();
    await _out.close();
  }
}
