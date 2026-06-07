import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/services/analytics_service.dart';
import 'package:olmeg_connect/features/analytics/data/datasources/analytics_datasource.dart';

final analyticsDataSourceProvider = Provider<AnalyticsDataSource>((ref) {
  return AnalyticsDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(dataSource: ref.watch(analyticsDataSourceProvider));
});
