class PreviewSession {
  final String id;
  final String projectId;
  final String url;
  final bool isRunning;

  PreviewSession({
    required this.id,
    required this.projectId,
    required this.url,
    this.isRunning = false,
  });
}
