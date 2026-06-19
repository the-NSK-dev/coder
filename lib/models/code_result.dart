import 'file_item.dart';
import 'verification_status.dart';

typedef GeneratedFile = FileItem;

class CodeResult {
  String projectName;
  String version;
  String projectType;
  List<FileItem> files;
  String currentFilePath;

  CodeResult({
    required this.projectName,
    this.version = '1.0',
    this.projectType = 'App Build',
    required this.files,
    this.currentFilePath = '',
  });

  /// Returns the aggregate verification status for a given step (1, 2, or 3).
  /// - Returns `failed` if ANY file failed.
  /// - Returns `inProgress` if any file is pending or inProgress.
  /// - Otherwise returns `passed`.
  VerificationStatus aggregateStep(int step) {
    bool anyInProgressOrPending = false;
    for (final file in files) {
      final status = file.getStep(step);
      if (status == VerificationStatus.failed) return VerificationStatus.failed;
      if (status == VerificationStatus.inProgress ||
          status == VerificationStatus.pending) {
        anyInProgressOrPending = true;
      }
    }
    return anyInProgressOrPending
        ? VerificationStatus.inProgress
        : VerificationStatus.passed;
  }

  /// Get the current file being worked on.
  FileItem? get currentFile {
    try {
      return files.firstWhere((f) => f.path == currentFilePath);
    } catch (_) {
      return files.isNotEmpty ? files.first : null;
    }
  }
}
