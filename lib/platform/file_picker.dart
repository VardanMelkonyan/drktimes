import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class PickedFile {
  const PickedFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Lets the user choose a `.drktimes` file.
abstract interface class FilePicker {
  Future<PickedFile?> pick();
}

class FileSelectorPicker implements FilePicker {
  const FileSelectorPicker();

  @override
  Future<PickedFile?> pick() async {
    final f = await openFile();
    if (f == null) return null;
    return PickedFile(f.name, await f.readAsBytes());
  }
}
