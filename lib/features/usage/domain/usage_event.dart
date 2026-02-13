class UsageEvent {
  const UsageEvent({
    required this.id,
    required this.timestamp,
    required this.endpointId,
    required this.endpointName,
    required this.inputTokens,
    required this.outputTokens,
    required this.currency,
    required this.actualInputCostPerMillion,
    required this.actualOutputCostPerMillion,
    required this.referenceInputCostPerMillion,
    required this.referenceOutputCostPerMillion,
  });

  final String id;
  final DateTime timestamp;
  final String endpointId;
  final String endpointName;
  final int inputTokens;
  final int outputTokens;
  final String currency;
  final double actualInputCostPerMillion;
  final double actualOutputCostPerMillion;
  final double referenceInputCostPerMillion;
  final double referenceOutputCostPerMillion;

  double get actualCost {
    return (inputTokens / 1000000) * actualInputCostPerMillion +
        (outputTokens / 1000000) * actualOutputCostPerMillion;
  }

  double get referenceCost {
    return (inputTokens / 1000000) * referenceInputCostPerMillion +
        (outputTokens / 1000000) * referenceOutputCostPerMillion;
  }

  double get savedCost => referenceCost - actualCost;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'endpointId': endpointId,
      'endpointName': endpointName,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'currency': currency,
      'actualInputCostPerMillion': actualInputCostPerMillion,
      'actualOutputCostPerMillion': actualOutputCostPerMillion,
      'referenceInputCostPerMillion': referenceInputCostPerMillion,
      'referenceOutputCostPerMillion': referenceOutputCostPerMillion,
    };
  }

  static UsageEvent fromJson(Map<String, dynamic> json) {
    return UsageEvent(
      id: json['id'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      endpointId: json['endpointId'] as String? ?? '',
      endpointName: json['endpointName'] as String? ?? 'Endpoint',
      inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      actualInputCostPerMillion:
          (json['actualInputCostPerMillion'] as num?)?.toDouble() ?? 0,
      actualOutputCostPerMillion:
          (json['actualOutputCostPerMillion'] as num?)?.toDouble() ?? 0,
      referenceInputCostPerMillion:
          (json['referenceInputCostPerMillion'] as num?)?.toDouble() ?? 0,
      referenceOutputCostPerMillion:
          (json['referenceOutputCostPerMillion'] as num?)?.toDouble() ?? 0,
    );
  }
}
