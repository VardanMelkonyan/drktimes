import 'dart:async';
import 'dart:typed_data';

import 'package:drktimes/platform/intake.dart';

class FakeIntake implements Intake {
  final _controller = StreamController<IncomingPayload>.broadcast();

  void emitLink(String url) => _controller.add(IncomingLink(Uri.parse(url)));

  void emitFile(String name, Uint8List bytes) =>
      _controller.add(IncomingFile(name, bytes));

  @override
  Stream<IncomingPayload> get payloads => _controller.stream;
}
