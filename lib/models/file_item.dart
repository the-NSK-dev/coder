import 'verification_status.dart';

class FileItem {
  final String path; // e.g. "src/components/Hero.jsx"
  final String name; // display name, e.g. "Hero.jsx"
  String content;
  VerificationStatus step1; // Supporter: syntax
  VerificationStatus step2; // Engineer self-review: standards
  VerificationStatus step3; // Reviewer: UI/UX/functional

  FileItem({
    required this.path,
    required this.name,
    this.content = '',
    this.step1 = VerificationStatus.pending,
    this.step2 = VerificationStatus.pending,
    this.step3 = VerificationStatus.pending,
  });

  /// Returns the verification status for a specific step (1, 2, or 3).
  VerificationStatus getStep(int step) {
    switch (step) {
      case 1:
        return step1;
      case 2:
        return step2;
      case 3:
        return step3;
      default:
        return VerificationStatus.pending;
    }
  }

  /// File extension (lowercase, no dot).
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}
