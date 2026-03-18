import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../utils/captured_image.dart';
import '../widgets/shutter_button.dart';
import 'camera_tab.dart';

const double _kMinZoom = 1.0;
const double _kMaxZoom = 189.0;

class CameraTab extends StatefulWidget {
  final CameraDescription camera;
  const CameraTab({super.key, required this.camera});

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab> with SingleTickerProviderStateMixin {
  bool _showBlackFlick = false;
  CameraController? _controller;
  bool _isInit = false;
  bool _hasError = false;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      final controller = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      await controller.setZoomLevel(_currentZoom);
      setState(() {
        _controller = controller;
        _isInit = true;
      });
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        setState(() => _showBlackFlick = true);
        await Future.delayed(const Duration(milliseconds: 80));
        setState(() => _showBlackFlick = false);
        final xfile = await _controller!.takePicture();
        if (!mounted) return;
        final file = File(xfile.path);
        final bytes = await file.readAsBytes();
        final image = CapturedImage(bytes: bytes, filePath: xfile.path);
        await runPredictionFlow(context, image);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SampleCameraTab(
        errorMessage: 'Camera unavailable. Using sample image.',
      );
    }

    if (!_isInit || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onScaleStart: (details) {
              _baseZoom = _currentZoom;
            },
            onScaleUpdate: (details) async {
              if (_controller != null && _controller!.value.isInitialized) {
                double newZoom = (_baseZoom * details.scale).clamp(_kMinZoom, _kMaxZoom);
                setState(() {
                  _currentZoom = newZoom;
                });
                await _controller!.setZoomLevel(_currentZoom);
              }
            },
            child: CameraPreview(_controller!),
          ),
        ),
        if (_showBlackFlick)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _showBlackFlick ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 80),
              child: Container(color: Colors.black),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: ShutterButton(
              onTap: () {
                if (_controller != null && _controller!.value.isInitialized) {
                  _takePicture();
                } else {
                  debugPrint('Camera not initialized, ignoring shutter press');
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
