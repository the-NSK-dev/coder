import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as wv_win;

class DesktopPreviewWebview extends StatefulWidget {
  final String url;

  const DesktopPreviewWebview({super.key, required this.url});

  @override
  State<DesktopPreviewWebview> createState() => DesktopPreviewWebviewState();
}

class DesktopPreviewWebviewState extends State<DesktopPreviewWebview> {
  WebViewController? _controller;
  wv_win.WebviewController? _winController;
  bool _isWindowsReady = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows) {
      _initWindowsWebview();
    } else if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));
      _loadUrl(widget.url);
    }
  }

  Future<void> _initWindowsWebview() async {
    _winController = wv_win.WebviewController();
    await _winController!.initialize();
    await _winController!.setBackgroundColor(Colors.transparent);
    _loadUrl(widget.url);
    if (mounted) setState(() => _isWindowsReady = true);
  }

  void _loadUrl(String url) {
    if (!kIsWeb && Platform.isWindows) {
      if (_winController == null) return;
      if (url.startsWith('data:text/html;charset=utf-8,')) {
        final htmlStr = Uri.decodeComponent(url.substring(31));
        _winController!.loadStringContent(htmlStr);
      } else {
        _winController!.loadUrl(url);
      }
    } else {
      if (_controller == null) return;
      if (url.startsWith('data:text/html;charset=utf-8,')) {
        final htmlStr = Uri.decodeComponent(url.substring(31));
        _controller!.loadHtmlString(htmlStr);
      } else {
        _controller!.loadRequest(Uri.parse(url));
      }
    }
  }

  Future<void> goBack() async {
    if (!kIsWeb && Platform.isWindows) {
      _winController?.goBack();
    } else {
      _controller?.goBack();
    }
  }

  Future<void> goForward() async {
    if (!kIsWeb && Platform.isWindows) {
      _winController?.goForward();
    } else {
      _controller?.goForward();
    }
  }

  Future<void> reload() async {
    if (!kIsWeb && Platform.isWindows) {
      _winController?.reload();
    } else {
      _controller?.reload();
    }
  }

  @override
  void didUpdateWidget(covariant DesktopPreviewWebview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadUrl(widget.url);
    }
  }

  @override
  void dispose() {
    _winController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: Text(
          'WebViews are not supported natively in this configuration on Web. Please open ${widget.url} in a new tab.',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    if (Platform.isWindows) {
      if (!_isWindowsReady || _winController == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return wv_win.Webview(_winController!);
    }
    return WebViewWidget(
      controller: _controller!,
      gestureRecognizers: {
        Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
        Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
        Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
      },
    );
  }
}
