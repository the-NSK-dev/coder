import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

class LocalPreviewServer {
  HttpServer? _server;

  int _port = 0;

  bool get isRunning => _server != null;
  int get port => _port;
  String get url => 'http://localhost:$_port';

  /// Starts the server for the given directory path.
  Future<void> start(String directoryPath, {int port = 8080}) async {
    await stop();

    _port = port;

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(createStaticHandler(directoryPath, defaultDocument: 'index.html'));

    try {
      _server = await io.serve(handler, 'localhost', _port);
    } catch (e) {
      // If port is in use, try port 0 (auto-assign)
      if (e is SocketException) {
        _server = await io.serve(handler, 'localhost', 0);
        _port = _server!.port;
      } else {
        rethrow;
      }
    }
  }

  /// Stops the running server.
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }
}
