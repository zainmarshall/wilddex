import 'dart:typed_data';

/// Platform-agnostic image container.
/// On native, [filePath] points to the original file.
/// On web, only [bytes] is available.
class CapturedImage {
  final Uint8List bytes;
  final String? filePath;

  CapturedImage({required this.bytes, this.filePath});
}
