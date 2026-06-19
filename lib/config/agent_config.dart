class AgentConfig {
  String agentId;
  String apiKey;
  String model; // 'Default (Auto Select)' or specific model id
  String endpoint;

  AgentConfig({
    this.agentId = '',
    this.apiKey = '',
    this.model = 'Default (Auto Select)',
    this.endpoint = 'https://api.band.ai/v1/agents/',
  });

  /// Whether this agent has valid credentials configured.
  bool get isConfigured => agentId.isNotEmpty && apiKey.isNotEmpty;

  /// Convert to a map for persistence.
  Map<String, String> toMap() => {
        'agentId': agentId,
        'apiKey': apiKey,
        'model': model,
        'endpoint': endpoint,
      };

  /// Restore from a map.
  void fromMap(Map<String, String> map) {
    agentId = map['agentId'] ?? '';
    apiKey = map['apiKey'] ?? '';
    model = map['model'] ?? 'Default (Auto Select)';
    endpoint = map['endpoint'] ?? 'https://api.band.ai/v1/agents/';
  }
}
