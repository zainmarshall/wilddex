import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

int _viewIdCounter = 0;

String _boxFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitWidth:
      return 'cover';
    case BoxFit.fitHeight:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}

Widget buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return _WebHtmlImage(
    url: url,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}

class _WebHtmlImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const _WebHtmlImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  State<_WebHtmlImage> createState() => _WebHtmlImageState();
}

class _WebHtmlImageState extends State<_WebHtmlImage> {
  late final String _viewType;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-img-${_viewIdCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _boxFitToCss(widget.fit)
        ..style.display = 'block';
      img.onError.listen((_) {
        if (mounted) setState(() => _hasError = true);
      });
      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && widget.errorBuilder != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorBuilder!(context, Exception('Image failed to load'), null),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
