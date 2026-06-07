import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class WishlistCollectionService {
  WishlistCollectionService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchCollections(
    String userId,
  ) {
    return _firestore
        .collection('wishlist_collections')
        .where('ownerId', isEqualTo: userId)
        .limit(50)
        .snapshots();
  }

  static Future<String> createCollection({
    required String ownerId,
    required String name,
    bool isPublic = false,
  }) async {
    final id = const Uuid().v4();
    await _firestore.collection('wishlist_collections').doc(id).set({
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'isPublic': isPublic,
      'shareToken': const Uuid().v4(),
      'productIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  static Future<void> addProduct({
    required String collectionId,
    required String productId,
  }) {
    return _firestore.collection('wishlist_collections').doc(collectionId).set({
      'productIds': FieldValue.arrayUnion([productId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
