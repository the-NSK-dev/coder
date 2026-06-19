import '../services/aiml_api_service.dart';
import '../services/band_ai_service.dart';
import '../models/agent_task.dart';

/// Abstract interface for receiving agent status updates.
/// Both IdeProvider and ChatProvider can implement this.
abstract class AgentStatusHandler {
  void setAgentStatus(String agentName, String status,
      {String? task, String? model, String? file});
}

class AgentOrchestrator {
  final AimlApiService aiml;
  final BandAIService band;
  final dynamic ide; // Accepts any object with setAgentStatus method

  AgentOrchestrator({
    required this.aiml,
    required this.band,
    required this.ide,
  });

  Future<String> runAgentStep({
    required String agentName,
    required String systemPrompt,
    required String userPrompt,
    String model = 'gpt-4o-mini',
  }) async {
    final task = await band.sendTask(userPrompt);
    
    ide.setAgentStatus(agentName, 'Running');

    try {
      final result = await aiml.complete(
        userPrompt,
        model: model,
        systemPrompt: systemPrompt,
      );
      
      ide.setAgentStatus(agentName, 'Completed');
      await band.updateTaskStatus(task.id, TaskStatus.completed, output: result);
      return result;
    } catch (e) {
      ide.setAgentStatus(agentName, 'Failed');
      await band.updateTaskStatus(task.id, TaskStatus.failed, output: e.toString());
      rethrow;
    }
  }
}
