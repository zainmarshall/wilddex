import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../utils/captured_image.dart';
import '../widgets/shutter_button.dart';
import 'prediction_result_screen.dart';
import '../utils/photo_saver.dart';
import '../utils/settings_provider.dart';

const String kSampleImageAsset = 'assets/data/lion.png';
const Duration kApiTimeout = Duration(seconds: 30);

Future<Map<String, dynamic>> uploadImageAndGetPrediction(
  CapturedImage image, {
  required String apiBaseUrl,
  required bool useCrops,
}) async {
  final uri = Uri.parse('$apiBaseUrl/predict').replace(
    queryParameters: {'use_crops': useCrops ? 'true' : 'false'},
  );
  final request = http.MultipartRequest('POST', uri);
  request.files.add(http.MultipartFile.fromBytes(
    'file',
    image.bytes,
    filename: 'capture.jpg',
  ));

  final response = await request.send().timeout(kApiTimeout);
  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    return jsonDecode(respStr);
  } else {
    final body = await response.stream.bytesToString();
    throw Exception('Prediction failed (${response.statusCode}): $body');
  }
}

Future<void> runPredictionFlow(BuildContext context, CapturedImage image) async {
  final settings = Provider.of<SettingsProvider>(context, listen: false);
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PredictionResultScreen(
      image: image,
      isLoading: true,
    ),
  ));
  try {
    final prediction = await uploadImageAndGetPrediction(
      image,
      apiBaseUrl: settings.apiBaseUrl,
      useCrops: settings.useCropModel,
    );
    final binomialName = prediction['scientific_name'] ?? 'unknown';
    if (!kIsWeb && image.filePath != null) {
      await savePhotoToGallery(image, binomialName: binomialName);
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PredictionResultScreen(
        image: image,
        predictionResult: prediction,
        isLoading: false,
      ),
    ));
  } catch (e) {
    debugPrint('Prediction error: $e');
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => PredictionResultScreen(
        image: image,
        predictionResult: {'error': e.toString()},
        isLoading: false,
      ),
    ));
  }
}

/// Web camera tab — uses image_picker which opens the native camera/file picker.
class WebCameraTab extends StatefulWidget {
  const WebCameraTab({super.key});

  @override
  State<WebCameraTab> createState() => _WebCameraTabState();
}

class _WebCameraTabState extends State<WebCameraTab> {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _capturePhoto() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xfile == null) {
        setState(() => _isLoading = false);
        return;
      }
      final bytes = await xfile.readAsBytes();
      final image = CapturedImage(bytes: bytes);
      if (!mounted) return;
      await runPredictionFlow(context, image);
    } catch (e) {
      debugPrint('Web capture error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Tap the button to take a photo',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ShutterButton(
            onTap: _isLoading ? () {} : _capturePhoto,
          ),
        ],
      ),
    );
  }
}

/// Sample image fallback (works on all platforms via asset bytes).
class SampleCameraTab extends StatefulWidget {
  final String? errorMessage;
  const SampleCameraTab({super.key, this.errorMessage});

  @override
  State<SampleCameraTab> createState() => _SampleCameraTabState();
}

class _SampleCameraTabState extends State<SampleCameraTab> {
  bool _isLoading = false;

  Future<void> _runSample() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final byteData = await rootBundle.load(kSampleImageAsset);
      final bytes = byteData.buffer.asUint8List();
      final image = CapturedImage(bytes: bytes);
      if (!mounted) return;
      await runPredictionFlow(context, image);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            kSampleImageAsset,
            fit: BoxFit.cover,
          ),
        ),
        if (widget.errorMessage != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black.withOpacity(0.6),
                child: Text(
                  widget.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: ShutterButton(
              onTap: _isLoading ? () {} : () => _runSample(),
            ),
          ),
        ),
      ],
    );
  }
}
