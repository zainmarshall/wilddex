import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_tab.dart';
import 'camera_tab_native.dart';

Widget buildNativeCameraTab() {
  return const _NativeCameraLoader();
}

class _NativeCameraLoader extends StatelessWidget {
  const _NativeCameraLoader();

  Future<List<CameraDescription>> _loadCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      debugPrint('availableCameras failed: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CameraDescription>>(
      future: _loadCameras(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final cameras = snapshot.data ?? [];
        if (cameras.isEmpty) {
          return const SampleCameraTab(
            errorMessage: 'No cameras available. Using sample image.',
          );
        }
        return CameraTab(camera: cameras.first);
      },
    );
  }
}
