import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendSyncService {
  static const _base = 'http://localhost:8000';

  /// Create project memory in FastAPI when a build starts
  Future<String?> createProject({
    required String name,
    required List<String> pendingTasks,
    required String architecture,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/projects/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'project_name': name,
          'pending_tasks': pendingTasks,
          'completed_tasks': [],
          'architecture': architecture,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['project_id'] as String?;
      }
    } catch (_) {/* offline — fail silent, frontend keeps local state */}
    return null;
  }

  /// Mark task complete when AI finishes a file (your goal #3)
  Future<void> completeTask(String projectId, String task) async {
    try {
      await http.patch(
        Uri.parse('$_base/projects/$projectId/complete-task?task=${Uri.encodeComponent(task)}'),
      );
    } catch (_) {/* fail silent */}
  }
}
