// lib/services/band_room_service.dart
//
// Real Band.ai integration — WebSocket + REST.
//
// Band is NOT a REST endpoint you call to get text back.
// It is an agent collaboration platform: your Python agent
// processes stay connected over WebSocket, call their own
// LLM, and post replies into a shared chat room. This Flutter
// service lets the app join that same room as a participant —
// posting the user's prompt and streaming every agent reply
// back to the UI in real time.
//
// Prerequisites (done once in the Band website / terminal):
//   1. Create 4 "External Agent" entries on app.band.ai/agents
//      → copy each agent's UUID + API key → goes in Python agent_config.yaml
//   2. Create a chat room on app.band.ai/chats, add all 4 agents
//      → copy room ID → paste into AppConfig.bandRoomId
//   3. Copy your personal Band account API key → AppConfig.bandUserApiKey
//   4. Run each Python agent process (uv run python *_agent.py)
//      before triggering a build from Flutter

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

// ─────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────

/// A single message arriving from the Band chat room.
class BandMessage {
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isAgent;

  const BandMessage({
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isAgent = false,
  });

  static const _agentNames = {
    '@the.nsk.founder/controller-planner',
    '@the.nsk.founder/engineer',
    '@the.nsk.founder/review',
    '@the.nsk.founder/verifier',
  };

  factory BandMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as String? ?? 'Unknown';
    return BandMessage(
      sender: sender,
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isAgent: _agentNames.contains(sender),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────

/// Connects the Flutter app to a Band.ai chat room.
///
/// Usage:
/// ```dart
/// final svc = BandRoomService();
/// await svc.connect();
/// svc.messages.listen((msg) { /* update UI */ });
/// await svc.sendPrompt('Build a todo app in React');
/// ```
class BandRoomService extends ChangeNotifier {
  static const String _restBase = 'https://app.band.ai/api/v1';
  static const String _wsBase   = 'wss://app.band.ai/api/v1/socket/websocket';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _messageController = StreamController<BandMessage>.broadcast();

  /// Stream of messages arriving from the Band room in real time.
  Stream<BandMessage> get messages => _messageController.stream;

  bool _connected = false;
  bool get connected => _connected;

  String? _lastError;
  String? get lastError => _lastError;

  // ── Connection ────────────────────────────────────────────

  int _reconnectAttempts = 0;
  bool _intentionalClose = false;
  Timer? _heartbeat;

  /// Opens a WebSocket connection to the Band room.
  /// Call this once when the user starts a session.
  Future<void> connect() async {
    if (!AppConfig.isBandConfigured) {
      throw Exception('Band.ai is not configured. Please add your credentials in Settings.');
    }
    await disconnect();
    _intentionalClose = false;
    _connectWithRetry();
  }

  void _connectWithRetry() {
    final uri = Uri.parse(
      '$_wsBase'
      '?api_key=${AppConfig.bandUserApiKey}'
      '&room_id=${AppConfig.bandRoomId}',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _reconnectAttempts = 0;
      _startHeartbeat();

      _sub = _channel!.stream.listen(
        _onRawMessage,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
      );
      _connected = true;
      _lastError = null;
      notifyListeners();
      debugPrint('[BandRoomService] Connected to room ${AppConfig.bandRoomId}');
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onDisconnect() {
    _heartbeat?.cancel();
    _connected = false;
    notifyListeners();
    if (_intentionalClose) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    if (_reconnectAttempts > 8) return; // give up after ~exponential cap
    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 30));
    Future.delayed(delay, _connectWithRetry);
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      } catch (_) {}
    });
  }

  /// Closes the WebSocket connection.
  Future<void> disconnect() async {
    _intentionalClose = true;
    _heartbeat?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _sub = null;
    _connected = false;
    notifyListeners();
  }

  // ── Sending ───────────────────────────────────────────────

  /// Posts the user's build prompt into the Band room,
  /// @mentioning the Controller-Planner to kick off the pipeline.
  ///
  /// The Controller-Planner's Python process receives this via
  /// WebSocket, calls its LLM, and replies in the room —
  /// typically with a plan that @mentions @Engineer next.
  Future<bool> sendPrompt(String prompt) async {
    if (!AppConfig.isBandConfigured) {
      throw Exception('Band.ai is not configured.');
    }

    final url = Uri.parse('$_restBase/rooms/${AppConfig.bandRoomId}/messages');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.bandUserApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': '@the.nsk.founder/controller-planner $prompt',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[BandRoomService] Prompt sent to room.');
        return true;
      } else {
        _lastError = 'HTTP ${response.statusCode}: ${response.body}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Posts a raw message into the Band room (without auto @mention prefix).
  Future<bool> sendRaw(String content) async {
    if (!AppConfig.isBandConfigured) return false;
    final url = Uri.parse('$_restBase/rooms/${AppConfig.bandRoomId}/messages');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.bandUserApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Internal ──────────────────────────────────────────────

  void _onRawMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'message') {
        final msg = BandMessage.fromJson(data);
        _messageController.add(msg);
        debugPrint('[BandRoomService] ← ${msg.sender}: ${msg.content.substring(0, msg.content.length.clamp(0, 80))}…');
      }
    } catch (e) {
      debugPrint('[BandRoomService] Failed to parse message: $e');
    }
  }

  @override
  void dispose() {
    _intentionalClose = true;
    _heartbeat?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _messageController.close();
    super.dispose();
  }
}
