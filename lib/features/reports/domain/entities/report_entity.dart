import 'package:equatable/equatable.dart';

enum ReportTargetType {
  product,
  seller,
  review,
  post,
}

enum ReportStatus {
  open,
  resolved,
  dismissed,
}

String reportTargetTypeToString(ReportTargetType type) => type.name;
String reportStatusToString(ReportStatus status) => status.name;

class ReportEntity extends Equatable {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportEntity({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.status = ReportStatus.open,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        reporterId,
        targetType,
        targetId,
        reason,
        status,
        createdAt,
        updatedAt,
      ];
}
