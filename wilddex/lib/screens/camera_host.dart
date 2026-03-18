import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'camera_tab.dart';
import 'camera_host_native.dart' if (dart.library.html) 'camera_host_web.dart'
    as platform;

class CameraTabHost extends StatelessWidget {
  const CameraTabHost({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebCameraTab();
    }
    return platform.buildNativeCameraTab();
  }
}
