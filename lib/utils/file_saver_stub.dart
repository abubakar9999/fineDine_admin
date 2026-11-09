import 'dart:typed_data';

Future<bool> saveFileImpl({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
  String dialogTitle = 'Save File',
}) async {
  throw UnsupportedError('Saving files is not supported on this platform.');
}

