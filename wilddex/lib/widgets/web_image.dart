import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'web_image_native.dart' if (dart.library.html) 'web_image_web.dart'
    as platform;

/// Network image that works on both web (native <img>) and mobile (Image.network).
/// On web, uses HtmlElementView to bypass CanvasKit CORS restrictions.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return platform.buildWebImage(
        url: url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
}
