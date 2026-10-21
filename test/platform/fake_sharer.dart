import 'dart:typed_data';

import 'package:drktimes/platform/file_picker.dart';
import 'package:drktimes/platform/sharer.dart';

class FakeSharer implements Sharer {
  final texts = <String>[];
  final files = <({String name, Uint8List bytes})>[];

  @override
  Future<void> shareText(String text, {String? subject}) async =>
      texts.add(text);

  @override
  Future<void> shareFile(
    String name,
    Uint8List bytes, {
    String? subject,
  }) async => files.add((name: name, bytes: bytes));
}

class FakeFilePicker implements FilePicker {
  PickedFile? next;

  @override
  Future<PickedFile?> pick() async => next;
}
