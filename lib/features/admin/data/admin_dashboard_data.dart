import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardData {
  final int users;
  final int products;
  final int orders;
  final int openReports;
  final int pendingProducts;
  final int pendingMerchants;
  final int supportTickets;
  final int activeChats;
  final double revenue;

  const AdminDashboardData({
    required this.users,
    required this.products,
    required this.orders,
    required this.openReports,
    required this.pendingProducts,
    required this.pendingMerchants,
    required this.supportTickets,
    required this.activeChats,
    required this.revenue,
  });
}

class AdminDashboardDataSource {
  final FirebaseFirestore firestore;

  const AdminDashboardDataSource(this.firestore);

  Future<AdminDashboardData> load() async {
    final users = firestore.collection('users').limit(500).get();
    final products = firestore.collection('products').limit(500).get();
    final orders = firestore.collection('orders').limit(500).get();
    final reports = firestore
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .limit(500)
        .get();
    final submissions = firestore
        .collection('product_submissions')
        .where('moderationStatus', isEqualTo: 'pending_admin')
        .limit(500)
        .get();
    final merchants = firestore
        .collection('merchant_verifications')
        .where('status', whereIn: ['submitted', 'pending'])
        .limit(500)
        .get();
    final tickets = firestore
        .collection('support_tickets')
        .where('status', whereIn: ['open', 'in_progress'])
        .limit(500)
        .get();
    final chats = firestore.collection('chats').limit(500).get();

    final results = await Future.wait([
      users,
      products,
      orders,
      reports,
      submissions,
      merchants,
      tickets,
      chats,
    ]);

    final orderDocs = results[2].docs;
    final revenue = orderDocs.fold<double>(0, (runningTotal, doc) {
      final data = doc.data();
      final status = (data['status'] as String? ?? '').toLowerCase();
      final payment = data['payment'];
      final paymentStatus = payment is Map
          ? (payment['status'] as String? ?? '').toLowerCase()
          : '';
      final isPaid = status == 'paid' ||
          status == 'preparing' ||
          status == 'shipped' ||
          status == 'delivered' ||
          paymentStatus == 'paid';
      return isPaid
          ? runningTotal + ((data['total'] as num?)?.toDouble() ?? 0)
          : runningTotal;
    });

    return AdminDashboardData(
      users: results[0].size,
      products: results[1].size,
      orders: results[2].size,
      openReports: results[3].size,
      pendingProducts: results[4].size,
      pendingMerchants: results[5].size,
      supportTickets: results[6].size,
      activeChats: results[7].size,
      revenue: revenue,
    );
  }
}
