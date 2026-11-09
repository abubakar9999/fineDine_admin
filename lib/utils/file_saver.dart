import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

class FileSaver {
  static Future<bool> saveFile({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
    String dialogTitle = 'Save File',
  }) async {
    return saveFileImpl(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      dialogTitle: dialogTitle,
    );
  }
}

