import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<bool> saveFileImpl({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
  String dialogTitle = 'Save File',
}) async {
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
    );
    return path != null;
  } catch (e) {
    return false;
  }
}

