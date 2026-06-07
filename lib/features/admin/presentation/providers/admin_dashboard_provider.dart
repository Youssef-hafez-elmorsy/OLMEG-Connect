import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/admin/data/admin_dashboard_data.dart';

final adminDashboardDataSourceProvider =
    Provider<AdminDashboardDataSource>((ref) {
  return AdminDashboardDataSource(FirebaseFirestore.instance);
});

final adminDashboardDataProvider =
    FutureProvider.autoDispose<AdminDashboardData>((ref) {
  return ref.watch(adminDashboardDataSourceProvider).load();
});
