import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'captured_image.dart';

Future<File> savePhotoToGallery(CapturedImage image, {String? binomialName}) async {
  final dir = await getApplicationDocumentsDirectory();
  final photosDir = Directory('${dir.path}/photos');
  if (!await photosDir.exists()) {
    await photosDir.create(recursive: true);
  }
  final String safeName = binomialName != null ? binomialName.toLowerCase().replaceAll(' ', '_') : 'unknown';
  final String fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final String destPath = '${photosDir.path}/$fileName';

  // If we have a file path, copy it; otherwise write bytes
  if (image.filePath != null) {
    await File(image.filePath!).copy(destPath);
  } else {
    await File(destPath).writeAsBytes(image.bytes);
  }
  return File(destPath);
}
