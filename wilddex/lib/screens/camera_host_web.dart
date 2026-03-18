import 'package:flutter/material.dart';
import 'camera_tab.dart';

Widget buildNativeCameraTab() {
  // On web, always use WebCameraTab
  return const WebCameraTab();
}
