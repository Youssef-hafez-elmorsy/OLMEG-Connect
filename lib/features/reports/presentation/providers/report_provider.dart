import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/reports/domain/entities/report_entity.dart';
import 'package:uuid/uuid.dart';

final openReportsProvider = StreamProvider<List<ReportEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection('reports')
      .where('status', isEqualTo: reportStatusToString(ReportStatus.open))
      .limit(100)
      .snapshots()
      .map((snapshot) {
    final reports = snapshot.docs.map(_reportFromDoc).toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  });
});

Future<void> createReport({
  required String reporterId,
  required ReportTargetType targetType,
  required String targetId,
  required String reason,
}) async {
  final id = const Uuid().v4();
  final now = DateTime.now();
  await FirebaseFirestore.instance.collection('reports').doc(id).set({
    'id': id,
    'reporterId': reporterId,
    'targetType': reportTargetTypeToString(targetType),
    'targetId': targetId,
    'reason': reason,
    'status': reportStatusToString(ReportStatus.open),
    'createdAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
  });
}

Future<void> resolveReport(String reportId, ReportStatus status) async {
  await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
    'status': reportStatusToString(status),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

ReportEntity _reportFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? const <String, dynamic>{};
  return ReportEntity(
    id: doc.id,
    reporterId: data['reporterId'] as String? ?? '',
    targetType: ReportTargetType.values.firstWhere(
      (type) => type.name == data['targetType'],
      orElse: () => ReportTargetType.product,
    ),
    targetId: data['targetId'] as String? ?? '',
    reason: data['reason'] as String? ?? '',
    status: ReportStatus.values.firstWhere(
      (status) => status.name == data['status'],
      orElse: () => ReportStatus.open,
    ),
    createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
    updatedAt: _readDate(data['updatedAt']) ?? DateTime.now(),
  );
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
