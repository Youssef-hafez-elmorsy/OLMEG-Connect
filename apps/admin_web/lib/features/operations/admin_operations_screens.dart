import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../../core/widgets/admin_metric_card.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/admin_tokens.dart';
import '../shared/admin_action_dialogs.dart';
import '../shared/admin_collection_table_page.dart';

class ProductCatalogScreen extends StatelessWidget {
  const ProductCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Product Catalog',
      description:
          'Search catalog, review seller/category/status context, and open product details.',
      icon: Icons.inventory_2_outlined,
      collectionName: 'products',
      columns: [
        AdminTableColumn.image(
          'Photo',
          fields: ['imageUrl', 'thumbnailUrl', 'images', 'imageUrls'],
        ),
        AdminTableColumn.field('Title', 'title'),
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Category', 'category'),
        AdminTableColumn.field('Seller', 'sellerId'),
        AdminTableColumn.field('Price', 'price'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: _catalogActions,
    );
  }
}

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Category Management',
      description:
          'Manage category visibility, sort order, delivery rules, and storefront taxonomy.',
      icon: Icons.category_outlined,
      collectionName: 'categories',
      columns: [
        AdminTableColumn.field('Name', 'name'),
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Parent', 'parentId'),
        AdminTableColumn.field('Sort', 'sortOrder'),
        AdminTableColumn.field('Delivery Rule', 'deliveryRule'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Show category',
          action: 'category_visible',
          fields: {'status': 'visible'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Hide category',
          action: 'category_hidden',
          fields: {'status': 'hidden'},
        ),
      ],
    );
  }
}

class ReviewModerationScreen extends StatelessWidget {
  const ReviewModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Review Moderation',
      description:
          'Moderate product and seller reviews with audit-backed actions.',
      icon: Icons.rate_review_outlined,
      collectionName: 'reviews',
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Product', 'productId'),
        AdminTableColumn.field('Buyer', 'buyerId'),
        AdminTableColumn.field('Rating', 'rating'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Approve review',
          action: 'review_moderation_approved',
          fields: {'status': 'visible'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Hide review',
          action: 'review_moderation_hidden',
          fields: {'status': 'hidden'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Escalate review',
          action: 'review_moderation_escalated',
          fields: {'status': 'escalated'},
        ),
      ],
    );
  }
}

class OrdersOperationsScreen extends StatelessWidget {
  const OrdersOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Orders Operations',
      description:
          'Investigate orders, payment state, buyer/seller context, and exceptions.',
      icon: Icons.receipt_long_outlined,
      collectionName: 'orders',
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Buyer', 'buyerId'),
        AdminTableColumn.field('Seller(s)', 'sellerIds'),
        AdminTableColumn.field('Payment', 'paymentStatus', status: true),
        AdminTableColumn.field('Total', 'total'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Flag order',
          action: 'order_flagged',
          fields: {'opsStatus': 'flagged'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Mark reviewed',
          action: 'order_reviewed',
          fields: {'opsStatus': 'reviewed'},
        ),
      ],
    );
  }
}

class RefundsOperationsScreen extends StatelessWidget {
  const RefundsOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Returns & Refunds',
      description:
          'Review return/refund/dispute exceptions with scoped support permissions.',
      icon: Icons.assignment_return_outlined,
      collectionName: 'refunds',
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Order', 'orderId'),
        AdminTableColumn.field('User', 'userId'),
        AdminTableColumn.field('Amount', 'amount'),
        AdminTableColumn.field('Reason', 'reason'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Resolve refund',
          action: 'refund_resolved',
          fields: {'status': 'resolved'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Escalate refund',
          action: 'refund_escalated',
          fields: {'status': 'escalated'},
        ),
      ],
    );
  }
}

class PaymentsOperationsScreen extends StatelessWidget {
  const PaymentsOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Payments',
      description:
          'Track payment attempts, failures, payout readiness, and reconciliation state.',
      icon: Icons.payments_outlined,
      collectionName: 'payments',
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('User', 'userId'),
        AdminTableColumn.field('Order', 'orderId'),
        AdminTableColumn.field('Amount', 'amount'),
        AdminTableColumn.field('Provider', 'provider'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Mark reviewed',
          action: 'payment_mark_reviewed',
          fields: {'opsStatus': 'reviewed'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Escalate payment',
          action: 'payment_escalated',
          fields: {'opsStatus': 'escalated'},
        ),
      ],
    );
  }
}

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Support Tickets',
      description:
          'SLA, priority, assignment, linked order/user/product/report context.',
      icon: Icons.support_agent_outlined,
      collectionName: 'support_tickets',
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Priority', 'priority', status: true),
        AdminTableColumn.field('Subject', 'subject'),
        AdminTableColumn.field('User', 'userId'),
        AdminTableColumn.field('Assignee', 'assigneeId'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Assign to me',
          action: 'support_ticket_assigned',
          fields: {'status': 'assigned'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Resolve ticket',
          action: 'support_ticket_resolved',
          fields: {'status': 'resolved'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Escalate ticket',
          action: 'support_ticket_escalated',
          fields: {'status': 'escalated', 'priority': 'high'},
        ),
      ],
    );
  }
}

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Promotions',
      description:
          'Promotions, coupons, home banners, and featured picks management.',
      icon: Icons.local_offer_outlined,
      collectionName: 'promotions',
      columns: [
        AdminTableColumn.field('Title', 'title'),
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Type', 'type'),
        AdminTableColumn.field('Audience', 'audience'),
        AdminTableColumn.field('Starts', 'startsAt'),
        AdminTableColumn.field('Ends', 'endsAt'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Activate promotion',
          action: 'promotion_activated',
          fields: {'status': 'active'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Pause promotion',
          action: 'promotion_paused',
          fields: {'status': 'paused'},
        ),
      ],
    );
  }
}

class RiskDashboardScreen extends StatelessWidget {
  const RiskDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Risk Dashboard',
      description:
          'Suspicious users, sellers, products, payments, watchlist, and case timeline.',
      icon: Icons.radar_outlined,
      collectionName: 'risk_cases',
      columns: [
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Severity', 'severity', status: true),
        AdminTableColumn.field('Entity', 'entityId'),
        AdminTableColumn.field('Type', 'type'),
        AdminTableColumn.field('Owner', 'assigneeId'),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: (context, doc) => [
        _statusAction(
          context,
          doc,
          label: 'Open case',
          action: 'risk_case_opened',
          fields: {'status': 'open'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Escalate case',
          action: 'risk_case_escalated',
          fields: {'status': 'escalated', 'severity': 'high'},
        ),
        _statusAction(
          context,
          doc,
          label: 'Resolve case',
          action: 'risk_case_resolved',
          fields: {'status': 'resolved'},
        ),
      ],
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _AnalyticsCard('GMV signals', 'payments', Icons.payments_outlined),
      _AnalyticsCard('Orders', 'orders', Icons.receipt_long_outlined),
      _AnalyticsCard('Products', 'products', Icons.inventory_2_outlined),
      _AnalyticsCard('Categories', 'categories', Icons.category_outlined),
      _AnalyticsCard('Sellers', 'merchant_verifications', Icons.storefront),
      _AnalyticsCard('Conversions', 'analytics_events', Icons.query_stats),
    ];

    return AdminScaffold(
      title: 'Marketplace Analytics',
      description:
          'GMV, product/category performance, seller performance, cohorts, and conversion signals where data exists.',
      icon: Icons.query_stats_outlined,
      child: GridView.builder(
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 340,
          crossAxisSpacing: AdminSpacing.lg,
          mainAxisSpacing: AdminSpacing.lg,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class OperationsSettingsScreen extends StatelessWidget {
  const OperationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Operations Settings',
      description:
          'Super-admin settings for guarded operational configuration.',
      icon: Icons.settings_outlined,
      collectionName: 'admin_settings',
      columns: [
        AdminTableColumn.field('Name', 'name'),
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Value', 'value'),
        AdminTableColumn.field('Updated', 'updatedAt'),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String collectionName;
  final IconData icon;

  const _AnalyticsCard(this.title, this.collectionName, this.icon);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .limit(25)
          .snapshots(),
      builder: (context, snapshot) {
        final value = snapshot.hasData
            ? snapshot.data!.docs.length.toString()
            : snapshot.hasError
                ? 'Denied'
                : '...';
        return AdminMetricCard(
          title: title,
          value: value,
          caption: 'Capped analytics source: $collectionName',
          icon: icon,
          color: snapshot.hasError ? AdminColors.danger : AdminColors.primary,
        );
      },
    );
  }
}

Widget _statusAction(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc, {
  required String label,
  required String action,
  required Map<String, Object?> fields,
}) {
  return OutlinedButton.icon(
    onPressed: () async {
      final reason = await askAdminReason(
        context,
        title: label,
        actionLabel: label,
        message:
            'This workflow uses a backend command and immutable audit log.',
      );
      if (reason == null) return;
      try {
        await AdminActionService().updateWithAudit(
          targetRef: doc.reference,
          data: fields,
          action: action,
          targetType: doc.reference.parent.id,
          reason: reason,
          metadata: {'workflow': action},
        );
        if (!context.mounted) return;
        showAdminSnack(context, '$label saved.');
      } catch (error) {
        if (!context.mounted) return;
        showAdminSnack(context, 'Action failed: $error', isError: true);
      }
    },
    icon: const Icon(Icons.bolt_outlined),
    label: Text(label),
  );
}

List<Widget> _catalogActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  return [
    _statusAction(
      context,
      doc,
      label: 'Feature product',
      action: 'product_featured',
      fields: {'featured': true},
    ),
    _statusAction(
      context,
      doc,
      label: 'Hide product',
      action: 'product_hidden',
      fields: {'status': 'hidden'},
    ),
  ];
}
