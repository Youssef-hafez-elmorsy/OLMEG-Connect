import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/auth/domain/entities/user_entity.dart';

class AdminAuditService {
  AdminAuditService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> record({
    UserEntity? actor,
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _firestore.collection('audit_logs').add({
      'actorId': actor?.id ?? 'system',
      'actorName': actor?.name ?? 'System',
      'actorRole': actor?.role ?? 'system',
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> moderationHistory({
    UserEntity? actor,
    required String targetType,
    required String targetId,
    required String status,
    String? note,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _firestore.collection('moderation_history').add({
      'actorId': actor?.id ?? 'system',
      'actorName': actor?.name ?? 'System',
      'actorRole': actor?.role ?? 'system',
      'targetType': targetType,
      'targetId': targetId,
      'status': status,
      'note': note,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
