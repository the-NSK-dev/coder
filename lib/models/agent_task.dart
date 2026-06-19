enum TaskStatus { pending, inProgress, completed, failed }

class AgentTask {
  final String id;
  final String agentName;
  final String description;
  TaskStatus status;
  final DateTime createdAt;

  AgentTask({
    required this.id,
    required this.agentName,
    required this.description,
    this.status = TaskStatus.pending,
    required this.createdAt,
  });
}
