import 'package:cloud_firestore/cloud_firestore.dart';

const adminDefaultPageSize = 25;
const adminMaxPageSize = 50;

int cappedAdminLimit([int? requestedLimit]) {
  if (requestedLimit == null || requestedLimit < 1) {
    return adminDefaultPageSize;
  }

  return requestedLimit.clamp(1, adminMaxPageSize);
}

Query<T> cappedAdminQuery<T>(
  Query<T> query, {
  int? requestedLimit,
}) {
  return query.limit(cappedAdminLimit(requestedLimit));
}

Query<T> cursorAdminQuery<T>(
  Query<T> query, {
  DocumentSnapshot<T>? startAfter,
  int? requestedLimit,
}) {
  final capped = cappedAdminQuery(query, requestedLimit: requestedLimit);
  if (startAfter == null) return capped;
  return capped.startAfterDocument(startAfter);
}

class AdminCursorPage<T> {
  final List<QueryDocumentSnapshot<T>> docs;
  final int pageSize;

  const AdminCursorPage({
    required this.docs,
    required this.pageSize,
  });

  bool get hasMore => docs.length == pageSize;

  QueryDocumentSnapshot<T>? get nextCursor =>
      docs.isEmpty ? null : docs.last;
}

AdminCursorPage<T> adminCursorPage<T>(
  QuerySnapshot<T> snapshot, {
  int? requestedLimit,
}) {
  return AdminCursorPage<T>(
    docs: snapshot.docs,
    pageSize: cappedAdminLimit(requestedLimit),
  );
}
