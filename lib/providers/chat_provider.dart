import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../config/standards_config.dart';
import '../models/chat_message.dart';
import '../models/agent_state.dart';
import '../models/plan_result.dart';
import '../models/code_result.dart';
import '../services/band_room_service.dart';
import '../services/generation_pipeline.dart';
import '../services/verification_engine.dart';
import '../models/verification_step_detail.dart';
import '../services/backend_sync_service.dart';
import '../services/project_agent_storage.dart';
import '../providers/agent_activity_provider.dart';
import '../models/verification_status.dart';
import '../services/aiml_api_service.dart';

enum ChatScope { folder, project }

/// Manages the single user-facing chat and orchestrates the agent pipeline.
/// Background agent conversations live in [AgentActivityProvider].
class ChatProvider extends ChangeNotifier {
  final BandRoomService _bandRoom = BandRoomService();
  final GenerationPipeline _pipeline = GenerationPipeline();
  final BackendSyncService _backendSync = BackendSyncService();
  final ProjectAgentStorage _projectStorage = ProjectAgentStorage();

  AgentActivityProvider? _agentActivity;
  final AimlApiService _aimlApi = AimlApiService();

  // ── Verification state ──────────────────────────────
  final _verificationEngine = VerificationEngine();
  List<VerificationStepDetail>? _localVerificationSteps;

  List<VerificationStepDetail> get verificationSteps {
    if (_localVerificationSteps != null) {
      return _localVerificationSteps!;
    }
    final pipeline = _pipeline;
    return VerificationEngine.initialSteps().asMap().map((i, step) {
      VerificationStatus status;
      if (i == 0) {
        if (pipeline.state == PipelineState.reviewing) {
          status = VerificationStatus.inProgress;
        } else if (pipeline.currentReviewStatus == ReviewStatus.passed) {
          status = VerificationStatus.passed;
        } else if (pipeline.currentReviewStatus == ReviewStatus.failed) {
          status = VerificationStatus.failed;
        } else {
          status = VerificationStatus.pending;
        }
      } else if (i == 1 || i == 2) {
        if (pipeline.state == PipelineState.verifying) {
          status = VerificationStatus.inProgress;
        } else if (pipeline.currentVerifyStatus == VerifyStatus.passed) {
          status = VerificationStatus.passed;
        } else if (pipeline.currentVerifyStatus == VerifyStatus.failed) {
          status = VerificationStatus.failed;
        } else {
          status = VerificationStatus.pending;
        }
      } else {
        status = VerificationStatus.pending;
      }
      return MapEntry(i, step.copyWith(status: status));
    }).values.toList();
  }

  String _currentVerifyFile = '';
  String get currentVerifyFile => _currentVerifyFile;

  String? _backendProjectId;

  StreamSubscription? _bandMessageSub;

  List<ChatMessage> _messages = [];
  AgentState? _currentAgentState;
  PlanResult? _currentPlan;
  CodeResult? _currentCodeResult;
  String? _errorMessage;
  bool _isProcessing = false;
  String _selectedModel = 'gpt-4o-mini';
  ChatScope _chatScope = ChatScope.folder;

  /// Called when files are generated and should be saved to disk.
  Future<void> Function(CodeResult result)? onFilesGenerated;

  /// Optional workspace context provider for folder-scoped chat.
  String Function()? workspaceContextProvider;

  // ── Getters ─────────────────────────────────────────────
  List<ChatMessage> get messages => _messages;
  AgentState? get currentAgentState => _currentAgentState;
  PlanResult? get currentPlan => _currentPlan;
  CodeResult? get currentCodeResult => _currentCodeResult;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  String get selectedModel => _selectedModel;
  ChatScope get chatScope => _chatScope;
  bool get bandConnected => _bandRoom.connected;

  bool get hasApiKey => AppConfig.isBandConfigured;

  static const String errorNoAgent =
      'No agent available. Please connect Band.ai in Settings.';
  static const String errorTimeout =
      'Please check your internet connection and try again.';
  static String errorUnexpected(int code) =>
      'Unexpected error occurred. Error Code: $code.';

  ChatProvider() {
    _bandMessageSub = _bandRoom.messages.listen(_onBandMessage);
    _pipeline.stateStream.listen((_) => notifyListeners());
  }

  void bindAgentActivity(AgentActivityProvider activity) {
    _agentActivity = activity;
    _agentActivity?.setBandConnected(_bandRoom.connected);
  }

  /// Reload keys from AppConfig and reconnect Band room.
  Future<void> reloadConfig() async {
    if (AppConfig.isBandConfigured) {
      await _bandRoom.connect();
    } else {
      await _bandRoom.disconnect();
    }
    _agentActivity?.setBandConnected(_bandRoom.connected);
    notifyListeners();
  }

  Future<void> connectBandRoom() async {
    if (AppConfig.isBandConfigured) {
      await _bandRoom.connect();
      _agentActivity?.setBandConnected(_bandRoom.connected);
      notifyListeners();
    }
  }

  Future<void> loadProjectChat() async {
    _messages = await _projectStorage.loadUserChat();
    await _agentActivity?.loadForCurrentProject();
    notifyListeners();
  }

  void setChatScope(ChatScope scope) {
    _chatScope = scope;
    notifyListeners();
  }

  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setAgentStatus(String agentName, String status,
      {String? task, String? model, String? file}) {
    _currentAgentState = AgentState(
      currentAgent: agentName,
      currentTask: task ?? _currentAgentState?.currentTask ?? 'Working...',
      currentFile: file ?? _currentAgentState?.currentFile ?? '',
      currentModel: model ?? _currentAgentState?.currentModel ?? _selectedModel,
      currentStatus: status,
    );
    notifyListeners();
  }

  void _onBandMessage(BandMessage message) {
    if (!_isProcessing) return;

    // Background agent conversations — not shown in user chat.
    _agentActivity?.recordBandMessage(
      sender: message.sender,
      content: message.content,
      timestamp: message.timestamp,
    );

    if (message.isAgent) {
      setAgentStatus(message.sender, 'Running',
          task: _taskForAgent(message.sender));
    }

    _pipeline.handleMessage(message);

    if (_pipeline.plan != null) {
      _currentPlan = _pipeline.plan;
    }
    if (_pipeline.codeResult != null) {
      _currentCodeResult = _pipeline.codeResult;
    }

    if (_pipeline.state == PipelineState.error) {
      final rawError = _pipeline.errorMessage ?? 'Unknown error occurred.';
      if (rawError.contains('timeout') || rawError.contains('timed out')) {
        _errorMessage = 'Agent connection lost. Please try again.';
      } else if (rawError.contains('failures') ||
          rawError.contains('missing features')) {
        _errorMessage = 'Verification failed: $rawError';
      } else {
        _errorMessage = 'Agent Error: $rawError';
      }
    }

    if (_pipeline.state == PipelineState.clarifying &&
        _pipeline.clarifyingQuestions != null) {
      _clarifyingQuestions = _pipeline.clarifyingQuestions;
    } else {
      _clarifyingQuestions = null;
    }

    notifyListeners();
  }

  List<String>? _clarifyingQuestions;
  List<String>? get clarifyingQuestions => _clarifyingQuestions;

  Future<void> submitClarifyingAnswers(List<String> answers) async {
    if (_pipeline.state != PipelineState.clarifying) return;

    final answerText = answers
        .asMap()
        .entries
        .map((e) => 'A${e.key + 1}: ${e.value}')
        .join('\n');

    _messages.add(ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user_answers',
      sender: 'user',
      text: 'Answers to clarifying questions:\n$answerText',
      timestamp: DateTime.now(),
    ));
    await _persistUserChat();

    if (!AppConfig.isBandConfigured) {
      _errorMessage = errorNoAgent;
      notifyListeners();
      return;
    }

    await _bandRoom.sendRaw(answerText);

    _clarifyingQuestions = null;
    notifyListeners();
  }

  String _taskForAgent(String agent) {
    switch (agent) {
      case '@the.nsk.founder/controller-planner':
        return 'Analyzing requirements...';
      case '@the.nsk.founder/engineer':
        return 'Generating code...';
      case '@the.nsk.founder/review':
        return 'Reviewing code...';
      case '@the.nsk.founder/verifier':
        return 'Verifying requirements...';
      default:
        return 'Working...';
    }
  }

  Future<void> _onPipelineComplete() async {
    setAgentStatus('Idle', 'Idle', task: 'Waiting for instructions');
    _agentActivity?.setAllIdle();

    if (_currentCodeResult != null && _currentCodeResult!.files.isNotEmpty) {
      _backendProjectId ??= await _backendSync.createProject(
        name: _currentCodeResult!.projectName,
        pendingTasks: _currentCodeResult!.files.map((f) => f.path).toList(),
        architecture: 'mobile-first',
      );

      if (onFilesGenerated != null) {
        await onFilesGenerated!(_currentCodeResult!);
      }

      final firstFile = _currentCodeResult!.files.first;
      await runVerification(firstFile, _currentCodeResult!.projectType);
    }

    final summary = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_done',
      sender: 'ai',
      text:
          'Build complete! ${_currentCodeResult?.files.length ?? 0} files ready.',
      timestamp: DateTime.now(),
      isPlanOrStatus: true,
    );
    _messages.add(summary);
    await _persistUserChat();

    _isProcessing = false;
    notifyListeners();
  }

  Future<void> sendMessage(String prompt,
      {List<dynamic> attachments = const []}) async {
    if (prompt.trim().isEmpty) return;

    final enriched = await _enrichPrompt(prompt, attachments);



    if (AppConfig.useLiveAgents) {
      await _runBandPipeline(enriched,
          promptDisplay: prompt, attachments: attachments);
    } else {
      await _runLocalPipeline(enriched,
          promptDisplay: prompt, attachments: attachments);
    }
  }

  Future<String> _enrichPrompt(String prompt, List<dynamic> attachments) async {
    final buffer = StringBuffer(prompt);

    if (attachments.isNotEmpty) {
      for (final att in attachments) {
        if (att.type != 'image' && att.bytes != null) {
          try {
            final content = String.fromCharCodes(att.bytes!);
            buffer.writeln(
                '\n\n## Attached File: ${att.name}\n```\n$content\n```');
          } catch (_) {}
        }
      }
    }

    if (_chatScope == ChatScope.folder && workspaceContextProvider != null) {
      final ctx = workspaceContextProvider!();
      if (ctx.isNotEmpty) {
        buffer.writeln('\n\n## Workspace Context\n$ctx');
      }
    } else if (_chatScope == ChatScope.project) {
      if (_currentPlan != null) {
        buffer.writeln(
            '\n\n## Current Plan\n${_currentPlan!.steps.join('\n')}');
      }
      if (_currentCodeResult != null) {
        buffer.writeln('\n\n## Existing Files');
        for (final f in _currentCodeResult!.files) {
          buffer.writeln('- ${f.path}');
        }
      }
    }

    final lang = _detectProjectLanguage();
    final standards = await StandardsConfig.getStandardsFor(lang);
    if (standards.isNotEmpty) {
      buffer.writeln('\n\n## Coding Standards\n$standards');
    }

    return buffer.toString();
  }

  String _detectProjectLanguage() {
    if (_currentCodeResult != null && _currentCodeResult!.files.isNotEmpty) {
      final path = _currentCodeResult!.files.first.path;
      final ext = path.split('.').last.toLowerCase();
      if (ext == 'dart') return 'dart';
      if (ext == 'py') return 'python';
      if (ext == 'ts' || ext == 'tsx') return 'typescript';
      if (ext == 'js' || ext == 'jsx') return 'javascript';
      if (ext == 'html') return 'html';
    }
    return 'react';
  }

  Future<void> _runBandPipeline(String prompt,
      {String? promptDisplay, List<dynamic> attachments = const []}) async {
    _errorMessage = null;

    final msgAttachments = attachments
        .map((att) => MessageAttachment(
              name: att.name ?? 'Unknown',
              type: att.type ?? 'file',
            ))
        .toList();

    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      text: promptDisplay ?? prompt,
      timestamp: DateTime.now(),
      attachments: msgAttachments,
    ));
    await _persistUserChat();
    notifyListeners();

    _isProcessing = true;
    _localVerificationSteps = null;
    _currentVerifyFile = '';
    _pipeline.reset();
    _pipeline.start(verificationEnabled: AppConfig.verificationEnabled);
    _agentActivity?.reset();
    setAgentStatus('@the.nsk.founder/controller-planner', 'Running',
        task: 'Sending prompt to Band room...');
    notifyListeners();

    try {
      if (!_bandRoom.connected) {
        await _bandRoom.connect();
        _agentActivity?.setBandConnected(_bandRoom.connected);
      }

      final sent = await _bandRoom.sendPrompt(prompt);
      if (!sent) {
        throw Exception(
            _bandRoom.lastError ?? 'Failed to send prompt to Band room.');
      }

      await _pipeline.waitForCompletion();

      if (_pipeline.state == PipelineState.complete) {
        await _onPipelineComplete();
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
        _errorMessage = errorTimeout;
      } else if (errorStr.contains('socket') ||
          errorStr.contains('host lookup') ||
          errorStr.contains('network')) {
        _errorMessage = errorTimeout;
      } else {
        _errorMessage = errorUnexpected(404);
      }

      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_error',
        sender: 'system',
        text: _errorMessage!,
        timestamp: DateTime.now(),
      ));
      await _persistUserChat();

      setAgentStatus('System', 'Error', task: 'Failed');
      _agentActivity?.setAllIdle();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _runLocalPipeline(String prompt,
      {String? promptDisplay, List<dynamic> attachments = const []}) async {
    _errorMessage = null;

    final msgAttachments = attachments
        .map((att) => MessageAttachment(
              name: att.name ?? 'Unknown',
              type: att.type ?? 'file',
            ))
        .toList();

    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      text: promptDisplay ?? prompt,
      timestamp: DateTime.now(),
      attachments: msgAttachments,
    ));
    await _persistUserChat();
    notifyListeners();

    _isProcessing = true;
    _localVerificationSteps = null;
    _currentVerifyFile = '';
    _pipeline.reset();
    _pipeline.start(verificationEnabled: AppConfig.verificationEnabled);
    _agentActivity?.reset();
    notifyListeners();

    try {
      _aimlApi.initialize(AppConfig.aimlApiKey);

      // 1. Planner
      setAgentStatus('@the.nsk.founder/controller-planner', 'Running', task: 'Planning architecture...');
      notifyListeners();
      
      final plannerSystem = '''
You are the Controller-Planner agent. Create a clear implementation plan for the user's request.
Start your response with "Project: Generated App".
Then, provide a numbered list of steps.
Do not write code, just the plan.
''';
      final planResponse = await _aimlApi.complete(prompt, systemPrompt: plannerSystem);
      _onBandMessage(BandMessage(
        sender: '@the.nsk.founder/controller-planner',
        content: planResponse,
        timestamp: DateTime.now(),
        isAgent: true,
      ));
      notifyListeners();

      // Wait a moment for pipeline to process
      await Future.delayed(const Duration(milliseconds: 500));
      if (_pipeline.state == PipelineState.clarifying) {
        // Skip clarifier in local mode for simplicity
        _onBandMessage(BandMessage(
          sender: '@the.nsk.founder/controller-planner',
          content: 'No further clarification needed. Proceeding to Engineer.',
          timestamp: DateTime.now(),
          isAgent: true,
        ));
      }

      // 2. Engineer
      setAgentStatus('@the.nsk.founder/engineer', 'Running', task: 'Writing code...');
      notifyListeners();

      final engineerSystem = '''
You are the Engineer agent.
You must output code for the requested plan.
For each file you create or modify, YOU MUST prefix it with:
## File: <filepath>
Followed immediately by a markdown code block containing the complete file content.
Example:
## File: lib/main.dart
```dart
void main() {}
```
Do not skip the ## File: header. It is strictly required.
''';
      final engPrompt = 'Plan:\n$planResponse\n\nPlease implement the code exactly as planned.';
      final engResponse = await _aimlApi.complete(engPrompt, systemPrompt: engineerSystem);
      _onBandMessage(BandMessage(
        sender: '@the.nsk.founder/engineer',
        content: engResponse,
        timestamp: DateTime.now(),
        isAgent: true,
      ));
      notifyListeners();

      // 3. Reviewer
      if (AppConfig.verificationEnabled) {
        setAgentStatus('@the.nsk.founder/review', 'Running', task: 'Reviewing code...');
        notifyListeners();
        
        final reviewSystem = 'You are the Reviewer agent. Review the provided code. If it looks reasonable, output "REVIEW RESULT: PASS". Otherwise output "REVIEW RESULT: FAIL".';
        final revResponse = await _aimlApi.complete('Code:\n$engResponse', systemPrompt: reviewSystem);
        _onBandMessage(BandMessage(
          sender: '@the.nsk.founder/review',
          content: revResponse,
          timestamp: DateTime.now(),
          isAgent: true,
        ));
        notifyListeners();

        // Wait a moment
        await Future.delayed(const Duration(milliseconds: 500));

        // 4. Verifier
        setAgentStatus('@the.nsk.founder/verifier', 'Running', task: 'Verifying requirements...');
        notifyListeners();

        final verSystem = 'You are the Verifier agent. Check if the code meets the original prompt requirements. If yes, output "VERIFICATION RESULT: PASS" and then "BUILD COMPLETE".';
        final verResponse = await _aimlApi.complete('Original Prompt: $prompt\n\nCode:\n$engResponse', systemPrompt: verSystem);
        _onBandMessage(BandMessage(
          sender: '@the.nsk.founder/verifier',
          content: verResponse,
          timestamp: DateTime.now(),
          isAgent: true,
        ));
        notifyListeners();
      } else {
        // Automatically complete if verification disabled
        _onBandMessage(BandMessage(
          sender: '@the.nsk.founder/verifier',
          content: 'VERIFICATION RESULT: PASS\nBUILD COMPLETE',
          timestamp: DateTime.now(),
          isAgent: true,
        ));
      }

      await _pipeline.waitForCompletion(timeout: const Duration(minutes: 5));
      if (_pipeline.state == PipelineState.complete) {
        await _onPipelineComplete();
      }
    } catch (e) {
      _errorMessage = 'Featherless Local Agent Error: $e';
      _messages.add(ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_error',
        sender: 'system',
        text: _errorMessage!,
        timestamp: DateTime.now(),
      ));
      await _persistUserChat();

      setAgentStatus('System', 'Error', task: 'Failed');
      _agentActivity?.setAllIdle();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> runVerification(GeneratedFile file, String stack) async {
    _currentVerifyFile = file.path;
    _localVerificationSteps = VerificationEngine.initialSteps();
    notifyListeners();

    await _verificationEngine.verify(
      file: file,
      stack: stack,
      onUpdate: (steps) {
        _localVerificationSteps = steps;
        notifyListeners();
      },
    );

    if (_backendProjectId != null) {
      final allPassed = _localVerificationSteps
              ?.every((s) => s.status == VerificationStatus.passed) ??
          false;
      if (allPassed) {
        await _backendSync.completeTask(_backendProjectId!, file.path);
        await _agentActivity?.saveReview('verifier', file.path, true);
      }
    }
  }

  Future<void> sendMessageFromEditor(String prompt, String fileContext) async {
    final fullPrompt = '$prompt\n\nFile context:\n```\n$fileContext\n```';
    return sendMessage(fullPrompt);
  }

  Future<void> _persistUserChat() async {
    await _projectStorage.saveUserChat(_messages);
  }

  void clearChat() {
    _messages = [];
    _currentPlan = null;
    _currentCodeResult = null;
    _currentAgentState = null;
    _errorMessage = null;
    _pipeline.reset();
    _agentActivity?.reset();
    _projectStorage.saveUserChat(_messages);
    notifyListeners();
  }

  @override
  void dispose() {
    _bandMessageSub?.cancel();
    _bandRoom.dispose();
    _pipeline.dispose();
    super.dispose();
  }
}
