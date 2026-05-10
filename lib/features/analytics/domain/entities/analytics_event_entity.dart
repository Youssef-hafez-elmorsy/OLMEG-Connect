import 'package:equatable/equatable.dart';

class AnalyticsEventEntity extends Equatable {
  final String id;
  final String userId;
  final String eventType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AnalyticsEventEntity({
    required this.id,
    required this.userId,
    required this.eventType,
    this.metadata,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        eventType,
        metadata,
        createdAt,
      ];
}
