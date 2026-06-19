import 'verification_status.dart';

class VerificationCheck {
  final String name;
  final bool pass;
  final String reason;

  const VerificationCheck({
    required this.name,
    required this.pass,
    required this.reason,
  });
}

class VerificationStepDetail {
  final int step;            // 1, 2, 3
  final String name;         // Review / Verify / Standard
  final String agentHandle;  // @the.nsk.founder/review etc.
  final String agentLabel;   // "Reviewer"
  final String model;        // gpt-4o
  final VerificationStatus status;
  final Duration duration;
  final List<VerificationCheck> checks;
  final int attempts;        // for ⚫ escalate-after-2-fails

  const VerificationStepDetail({
    required this.step,
    required this.name,
    required this.agentHandle,
    required this.agentLabel,
    this.model = 'gpt-4o',
    this.status = VerificationStatus.pending,
    this.duration = Duration.zero,
    this.checks = const [],
    this.attempts = 0,
  });

  VerificationStepDetail copyWith({
    VerificationStatus? status,
    Duration? duration,
    List<VerificationCheck>? checks,
    int? attempts,
  }) {
    return VerificationStepDetail(
      step: step,
      name: name,
      agentHandle: agentHandle,
      agentLabel: agentLabel,
      model: model,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      checks: checks ?? this.checks,
      attempts: attempts ?? this.attempts,
    );
  }

  /// ⚫ black = failed twice → escalate
  bool get isEscalated => status == VerificationStatus.failed && attempts >= 2;

  int get passedCount => checks.where((c) => c.pass).length;
  int get totalChecks => checks.length;
}
