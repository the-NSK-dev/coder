import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../config/app_config.dart';
import '../models/chat_message.dart';

/// Per-project agent data under `<project>/.coder/`.
class ProjectAgentStorage {
  static const agentIds = ['planner', 'engineer', 'reviewer', 'verifier'];

  String? get _projectRoot => AppConfig.currentProjectDir;

  Directory? _coderDir() {
    final root = _projectRoot;
    if (root == null || root.isEmpty || kIsWeb) return null;
    final dir = Directory(p.join(root, '.coder'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Directory? _agentDir(String agentId) {
    final base = _coderDir();
    if (base == null) return null;
    final dir = Directory(p.join(base.path, 'agents', agentId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  String _agentIdForSender(String sender) {
    if (sender.contains('planner')) return 'planner';
    if (sender.contains('engineer')) return 'engineer';
    if (sender.contains('review') && !sender.contains('verifier')) {
      return 'reviewer';
    }
    if (sender.contains('verifier')) return 'verifier';
    return 'planner';
  }

  Future<void> saveUserChat(List<ChatMessage> messages) async {
    final base = _coderDir();
    if (base == null) return;
    final file = File(p.join(base.path, 'user_chat.json'));
    await file.writeAsString(
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  Future<List<ChatMessage>> loadUserChat() async {
    final base = _coderDir();
    if (base == null) return [];
    final file = File(p.join(base.path, 'user_chat.json'));
    if (!file.existsSync()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ProjectAgentStorage.loadUserChat: $e');
      return [];
    }
  }

  Future<void> appendAgentMessage(String sender, ChatMessage message) async {
    final agentId = _agentIdForSender(sender);
    final dir = _agentDir(agentId);
    if (dir == null) return;
    final file = File(p.join(dir.path, 'chat.json'));
    final existing = await _readJsonList(file);
    existing.add(message.toJson());
    await file.writeAsString(jsonEncode(existing));
  }

  Future<List<ChatMessage>> loadAgentChat(String agentId) async {
    final dir = _agentDir(agentId);
    if (dir == null) return [];
    final file = File(p.join(dir.path, 'chat.json'));
    final list = await _readJsonList(file);
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAgentTasks(String agentId, List<Map<String, dynamic>> tasks) async {
    final dir = _agentDir(agentId);
    if (dir == null) return;
    await File(p.join(dir.path, 'tasks.json'))
        .writeAsString(jsonEncode(tasks));
  }

  Future<List<Map<String, dynamic>>> loadAgentTasks(String agentId) async {
    final dir = _agentDir(agentId);
    if (dir == null) return [];
    final file = File(p.join(dir.path, 'tasks.json'));
    return (await _readJsonList(file)).cast<Map<String, dynamic>>();
  }

  Future<void> saveAgentOutputs(String agentId, Map<String, dynamic> output) async {
    final dir = _agentDir(agentId);
    if (dir == null) return;
    final file = File(p.join(dir.path, 'outputs.json'));
    final existing = await _readJsonList(file);
    existing.add(output);
    await file.writeAsString(jsonEncode(existing));
  }

  Future<void> saveReview(String agentId, Map<String, dynamic> review) async {
    final dir = _agentDir(agentId);
    if (dir == null) return;
    final file = File(p.join(dir.path, 'reviews.json'));
    final existing = await _readJsonList(file);
    existing.add(review);
    await file.writeAsString(jsonEncode(existing));
  }

  Future<void> saveApproval(String agentId, Map<String, dynamic> approval) async {
    final dir = _agentDir(agentId);
    if (dir == null) return;
    final file = File(p.join(dir.path, 'approvals.json'));
    final existing = await _readJsonList(file);
    existing.add(approval);
    await file.writeAsString(jsonEncode(existing));
  }

  Future<void> clearProjectData() async {
    final base = _coderDir();
    if (base == null) return;
    try {
      if (base.existsSync()) {
        await base.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('ProjectAgentStorage.clearProjectData: $e');
    }
  }

  Future<List<dynamic>> _readJsonList(File file) async {
    if (!file.existsSync()) return [];
    try {
      return jsonDecode(await file.readAsString()) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }
}
