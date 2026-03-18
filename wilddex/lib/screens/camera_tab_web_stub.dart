// Web stub — CameraTab is not used on web (WebCameraTab is used instead).
// This file exists only to satisfy the conditional import.
// On web, CameraDescription doesn't exist, so we use a dummy class.

import 'package:flutter/material.dart';
import 'camera_tab.dart';

class CameraTab extends StatelessWidget {
  final dynamic camera;
  const CameraTab({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    // On web, fall back to WebCameraTab or SampleCameraTab
    return const WebCameraTab();
  }
}
