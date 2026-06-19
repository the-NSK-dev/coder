import 'dart:async';
import '../models/plan_result.dart';
import '../models/code_result.dart';
import '../models/verification_status.dart';
import '../services/band_room_service.dart';
import '../services/agent_response_parser.dart';

enum PipelineState {
  idle,
  planning,
  clarifying,
  engineering,
  reviewing,
  verifying,
  complete,
  error,
}

enum ReviewStatus { idle, passed, failed }
enum VerifyStatus { idle, passed, failed }

/// State machine driven by Band.ai room messages.
class GenerationPipeline {
  final AgentResponseParser _parser = AgentResponseParser();

  PipelineState state = PipelineState.idle;
  PlanResult? plan;
  CodeResult? codeResult;
  String? errorMessage;
  List<String>? clarifyingQuestions;

  ReviewStatus currentReviewStatus = ReviewStatus.idle;
  VerifyStatus currentVerifyStatus = VerifyStatus.idle;

  final StringBuffer _plannerBuffer = StringBuffer();
  final StringBuffer _engineerBuffer = StringBuffer();
  final StringBuffer _reviewerBuffer = StringBuffer();
  final StringBuffer _verifierBuffer = StringBuffer();

  final _stateController = StreamController<PipelineState>.broadcast();
  Stream<PipelineState> get stateStream => _stateController.stream;

  Completer<void>? _completionCompleter;
  Timer? _stepTimeout;

  static const _agentPlanner = '@the.nsk.founder/controller-planner';
  static const _agentEngineer = '@the.nsk.founder/engineer';
  static const _agentReviewer = '@the.nsk.founder/review';
  static const _agentVerifier = '@the.nsk.founder/verifier';

  /// Start a new generation run.
  void start({required bool verificationEnabled}) {
    _cancelTimeout();
    state = PipelineState.planning;
    plan = null;
    codeResult = null;
    errorMessage = null;
    clarifyingQuestions = null;
    currentReviewStatus = ReviewStatus.idle;
    currentVerifyStatus = VerifyStatus.idle;
    _plannerBuffer.clear();
    _engineerBuffer.clear();
    _reviewerBuffer.clear();
    _verifierBuffer.clear();
    _verificationEnabled = verificationEnabled;
    _stateController.add(state);
    _startStepTimeout(const Duration(minutes: 3));
  }

  bool _verificationEnabled = true;

  /// Wait until pipeline reaches complete or error.
  Future<void> waitForCompletion({Duration timeout = const Duration(minutes: 5)}) {
    if (state == PipelineState.complete || state == PipelineState.error) {
      return Future.value();
    }
    _completionCompleter = Completer<void>();
    return _completionCompleter!.future.timeout(
      timeout,
      onTimeout: () {
        _fail('Pipeline timed out waiting for agents.');
      },
    );
  }

  /// Handle an incoming Band room message.
  void handleMessage(BandMessage message) {
    final sender = message.sender;
    final content = message.content;

    if (sender == _agentPlanner) {
      _plannerBuffer.write(content);
      _handlePlanner(content);
    } else if (sender == _agentEngineer) {
      _engineerBuffer.write(content);
      _handleEngineer(content);
    } else if (sender == _agentReviewer && _verificationEnabled) {
      _reviewerBuffer.write(content);
      _handleReviewer(content);
    } else if (sender == _agentVerifier && _verificationEnabled) {
      _verifierBuffer.write(content);
      _handleVerifier(content);
    }
  }

  void _handlePlanner(String content) {
    if (state != PipelineState.planning && state != PipelineState.idle && state != PipelineState.clarifying) return;

    final questions = _parser.parseClarifyingQuestions(content);
    if (questions != null && questions.isNotEmpty) {
      clarifyingQuestions = questions;
      state = PipelineState.clarifying;
      _stateController.add(state);
      // Wait for user reply
      _cancelTimeout();
      return;
    }

    final parsed = _parser.parsePlan(content);
    if (parsed == null) return;

    plan = parsed;
    state = PipelineState.engineering;
    _resetStepTimeout(const Duration(minutes: 5));
    _stateController.add(state);
  }

  void _handleEngineer(String content) {
    if (state != PipelineState.engineering && state != PipelineState.planning) {
      return;
    }

    final result = _parser.parseCodeResult(
      content,
      projectName: plan?.steps.firstOrNull?.replaceAll('Project: ', '') ?? 'Generated App',
    );
    if (result == null || result.files.isEmpty) return;

    codeResult = result;
    _resetStepTimeout(const Duration(minutes: 3));

    if (_verificationEnabled) {
      state = PipelineState.reviewing;
      _stateController.add(state);
    } else {
      _complete();
    }
  }

  void _handleReviewer(String content) {
    if (state != PipelineState.reviewing) return;

    if (content.contains('REVIEW RESULT: PASS')) {
      currentReviewStatus = ReviewStatus.passed;
    } else if (content.contains('REVIEW RESULT: FAIL')) {
      currentReviewStatus = ReviewStatus.failed;
    }

    final verdict = _parser.parseVerification(content);
    if (codeResult != null) {
      for (final file in codeResult!.files) {
        file.step1 = verdict.failed || currentReviewStatus == ReviewStatus.failed
            ? VerificationStatus.failed
            : VerificationStatus.passed;
      }
    }

    if (verdict.failed || currentReviewStatus == ReviewStatus.failed) {
      _fail('Reviewer reported failures.');
      return;
    }

    // Don't advance to verifying until reviewer explicitly says so, or just assume it's passed if we got the PASS result
    if (currentReviewStatus == ReviewStatus.passed) {
      state = PipelineState.verifying;
      _resetStepTimeout(const Duration(minutes: 3));
      _stateController.add(state);
    }
  }

  void _handleVerifier(String content) {
    if (state != PipelineState.verifying) return;

    if (content.contains('VERIFICATION RESULT: PASS')) {
      currentVerifyStatus = VerifyStatus.passed;
    } else if (content.contains('VERIFICATION RESULT: FAIL')) {
      currentVerifyStatus = VerifyStatus.failed;
    }

    final verdict = _parser.parseVerification(content);
    if (codeResult != null) {
      for (final file in codeResult!.files) {
        file.step2 = VerificationStatus.passed;
        file.step3 = verdict.failed || currentVerifyStatus == VerifyStatus.failed
            ? VerificationStatus.failed
            : VerificationStatus.passed;
      }
    }

    if (verdict.failed || currentVerifyStatus == VerifyStatus.failed) {
      _fail('Verifier reported missing features.');
      return;
    }

    if (content.contains('BUILD COMPLETE') || currentVerifyStatus == VerifyStatus.passed) {
      _complete();
    }
  }

  void _complete() {
    _cancelTimeout();
    state = PipelineState.complete;
    _stateController.add(state);
    _completionCompleter?.complete();
    _completionCompleter = null;
  }

  void _fail(String message) {
    _cancelTimeout();
    state = PipelineState.error;
    errorMessage = message;
    _stateController.add(state);
    _completionCompleter?.completeError(Exception(message));
    _completionCompleter = null;
  }

  void _startStepTimeout(Duration duration) {
    _stepTimeout?.cancel();
    _stepTimeout = Timer(duration, () {
      if (state != PipelineState.complete && state != PipelineState.error) {
        _fail('Agent step timed out.');
      }
    });
  }

  void _resetStepTimeout(Duration duration) {
    _startStepTimeout(duration);
  }

  void _cancelTimeout() {
    _stepTimeout?.cancel();
    _stepTimeout = null;
  }

  void reset() {
    _cancelTimeout();
    state = PipelineState.idle;
    plan = null;
    codeResult = null;
    errorMessage = null;
    _completionCompleter = null;
    _stateController.add(state);
  }

  void dispose() {
    _cancelTimeout();
    _stateController.close();
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
