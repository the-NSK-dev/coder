import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/project_agent_storage.dart';

/// Agent role identifiers shown in the UI status bar.
enum AgentRole { planner, engineer, reviewer, verifier }

extension AgentRoleId on AgentRole {
  String get id {
    switch (this) {
      case AgentRole.planner:
        return 'planner';
      case AgentRole.engineer:
        return 'engineer';
      case AgentRole.reviewer:
        return 'reviewer';
      case AgentRole.verifier:
        return 'verifier';
    }
  }

  String get label {
    switch (this) {
      case AgentRole.planner:
        return 'Planner';
      case AgentRole.engineer:
        return 'Engineer';
      case AgentRole.reviewer:
        return 'Reviewer';
      case AgentRole.verifier:
        return 'Verifier';
    }
  }
}

/// Background agent conversations — separate from the single user-facing chat.
class AgentActivityProvider extends ChangeNotifier {
  final ProjectAgentStorage _storage = ProjectAgentStorage();

  final Map<String, List<ChatMessage>> _agentChats = {
    for (final id in ProjectAgentStorage.agentIds) id: [],
  };
  final Map<String, String> _agentStatus = {
    for (final id in ProjectAgentStorage.agentIds) id: 'Idle',
  };
  final Map<String, String> _agentTasks = {
    for (final id in ProjectAgentStorage.agentIds) id: '',
  };

  bool _bandConnected = false;

  bool get bandConnected => _bandConnected;

  List<ChatMessage> chatFor(String agentId) =>
      List.unmodifiable(_agentChats[agentId] ?? const []);

  String statusFor(String agentId) => _agentStatus[agentId] ?? 'Idle';

  String taskFor(String agentId) => _agentTasks[agentId] ?? '';

  void setBandConnected(bool connected) {
    if (_bandConnected == connected) return;
    _bandConnected = connected;
    notifyListeners();
  }

  /// Route a Band room message into the correct background conversation.
  Future<void> recordBandMessage({
    required String sender,
    required String content,
    required DateTime timestamp,
  }) async {
    final agentId = _storageAgentId(sender);
    final msg = ChatMessage(
      id: '${timestamp.millisecondsSinceEpoch}_$agentId',
      sender: sender,
      text: content,
      timestamp: timestamp,
    );

    _agentChats.putIfAbsent(agentId, () => []).add(msg);
    _agentStatus[agentId] = 'Running';
    _agentTasks[agentId] = _defaultTask(agentId);

    await _storage.appendAgentMessage(sender, msg);

    if (content.contains('PASS') ||
        content.contains('COMPLETE') ||
        content.contains('```json')) {
      await _storage.saveAgentOutputs(agentId, {
        'timestamp': timestamp.toIso8601String(),
        'preview': content.length > 500 ? '${content.substring(0, 500)}…' : content,
      });
    }

    notifyListeners();
  }

  void setAgentIdle(String agentId) {
    _agentStatus[agentId] = 'Idle';
    _agentTasks[agentId] = '';
    notifyListeners();
  }

  void setAllIdle() {
    for (final id in ProjectAgentStorage.agentIds) {
      _agentStatus[id] = 'Idle';
      _agentTasks[id] = '';
    }
    notifyListeners();
  }

  Future<void> loadForCurrentProject() async {
    for (final id in ProjectAgentStorage.agentIds) {
      _agentChats[id] = await _storage.loadAgentChat(id);
      _agentStatus[id] = 'Idle';
      _agentTasks[id] = '';
    }
    notifyListeners();
  }

  Future<void> saveReview(String agentId, String summary, bool passed) async {
    await _storage.saveReview(agentId, {
      'agentId': agentId,
      'summary': summary,
      'passed': passed,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveApproval(String agentId, String step, bool approved) async {
    await _storage.saveApproval(agentId, {
      'step': step,
      'approved': approved,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void reset() {
    for (final id in ProjectAgentStorage.agentIds) {
      _agentChats[id] = [];
      _agentStatus[id] = 'Idle';
      _agentTasks[id] = '';
    }
    notifyListeners();
  }

  String _storageAgentId(String sender) {
    if (sender.contains('planner')) return 'planner';
    if (sender.contains('engineer')) return 'engineer';
    if (sender.contains('review') && !sender.contains('verifier')) {
      return 'reviewer';
    }
    if (sender.contains('verifier')) return 'verifier';
    return 'planner';
  }

  String _defaultTask(String agentId) {
    switch (agentId) {
      case 'planner':
        return 'Analyzing requirements…';
      case 'engineer':
        return 'Generating code…';
      case 'reviewer':
        return 'Reviewing code…';
      case 'verifier':
        return 'Verifying requirements…';
      default:
        return 'Working…';
    }
  }
}
