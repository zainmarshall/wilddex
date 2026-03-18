import 'package:flutter/material.dart';

/// Native stub — never called (AppNetworkImage uses Image.network directly).
Widget buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.network(url, width: width, height: height, fit: fit, errorBuilder: errorBuilder);
}
