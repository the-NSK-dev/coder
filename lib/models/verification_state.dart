enum VerificationStatus { pending, running, passed, retrying, failed }

class VerificationState {
  final String stepName;
  VerificationStatus status;
  String? message;

  VerificationState({
    required this.stepName,
    this.status = VerificationStatus.pending,
    this.message,
  });
}
