import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/agent_task.dart';
import '../models/agent_state.dart';

class BandAIService {
  String _apiKey = '';

  Future<void> initialize(String apiKey) async {
    _apiKey = apiKey;
  }

  Future<AgentTask> sendTask(String taskDescription) async {
    if (!AppConfig.useLiveAgents || _apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return AgentTask(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        agentName: 'Controller',
        description: taskDescription,
        status: TaskStatus.inProgress,
        createdAt: DateTime.now(),
      );
    }

    // Example real HTTP implementation:
    final url = Uri.parse('https://api.band.ai/v1/tasks');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'description': taskDescription,
          'agent': 'controller',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AgentTask(
          id: data['id'] ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
          agentName: data['agent'] ?? 'Controller',
          description: taskDescription,
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Band AI Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status, {String? output}) async {
    if (!AppConfig.useLiveAgents || _apiKey.isEmpty) {
      return;
    }
    final url = Uri.parse('https://api.band.ai/v1/tasks/$taskId');
    try {
      await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'status': status.name,
          'output': output,
        }..removeWhere((k, v) => v == null)),
      );
    } catch (_) {}
  }

  Future<TaskStatus> getTaskStatus(String taskId) async {
    if (!AppConfig.useLiveAgents || _apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      return TaskStatus.completed;
    }

    final url = Uri.parse('https://api.band.ai/v1/tasks/$taskId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        if (status == 'completed') return TaskStatus.completed;
        if (status == 'failed') return TaskStatus.failed;
        return TaskStatus.inProgress;
      }
      return TaskStatus.failed;
    } catch (e) {
      return TaskStatus.failed;
    }
  }

  Future<void> retryTask(String taskId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> cancelTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<AgentState> getAgentState() async {
    return AgentState(
      currentAgent: 'Engineer',
      currentTask: 'Writing logic...',
      currentFile: 'main.dart',
      currentModel: 'gpt-4o',
      currentStatus: 'Generating',
    );
  }
}
