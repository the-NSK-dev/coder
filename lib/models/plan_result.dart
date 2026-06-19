class PlanResult {
  final List<String> steps; // the 5 displayed steps
  final List<String> languages; // subset of the 8 supported
  final String previewMode; // 'live' | 'simulated'

  PlanResult({
    required this.steps,
    required this.languages,
    required this.previewMode,
  });
}
