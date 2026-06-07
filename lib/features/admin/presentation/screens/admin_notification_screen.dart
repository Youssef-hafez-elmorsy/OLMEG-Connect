import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationScreen extends ConsumerStatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  ConsumerState<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState
    extends ConsumerState<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _targetType = 'all';
  bool _isLoading = false;
  String? _message;
  bool _success = false;

  final List<String> _targets = [
    'all',
    'buyers',
    'merchants',
    'handmadeBuyers',
    'inactiveUsers',
    'newUsers',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Send',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickButton('Test', _sendTest, Icons.notifications),
                  _quickButton('Seller update', () {
                    _titleController.text = 'Seller update';
                    _bodyController.text =
                        'New seller tools and marketplace updates are ready.';
                    setState(() => _targetType = 'merchants');
                  }, Icons.storefront),
                  _quickButton('Handmade buyers', () {
                    _titleController.text = 'Handmade picks are waiting';
                    _bodyController.text =
                        'Fresh handmade products were added near you.';
                    setState(() => _targetType = 'handmadeBuyers');
                  }, Icons.auto_awesome),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Custom Message',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _targetType,
                decoration: InputDecoration(
                  labelText: 'Send To',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.people),
                ),
                items: _targets.map((t) {
                  return DropdownMenuItem(
                      value: t, child: Text(_targetLabel(t)));
                }).toList(),
                onChanged: (v) => setState(() => _targetType = v ?? 'all'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter notification title',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Title required' : null,
                maxLength: 100,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'Enter your message',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Message required' : null,
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendCustomNotification,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Sending...' : 'Send Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _success ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: _success ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(_success ? Icons.check_circle : Icons.error,
                          color: _success ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_message!,
                              style: TextStyle(
                                  color: _success
                                      ? Colors.green.shade700
                                      : Colors.red.shade700))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text('Recent Notifications',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildRecentNotifications(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickButton(String label, VoidCallback onPressed, IconData icon) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildRecentNotifications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_notifications')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: const Center(child: Text('No notifications yet')),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: Icon(
                (data['read'] ?? true) == false
                    ? Icons.circle
                    : Icons.circle_outlined,
                color: (data['read'] ?? true) == false
                    ? Colors.green
                    : Colors.grey,
                size: 12,
              ),
              title: Text(data['title'] ?? ''),
              subtitle: Text(data['body'] ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(
                _formatDate(data['createdAt']),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date =
          timestamp is DateTime ? timestamp : (timestamp as Timestamp).toDate();
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Future<void> _sendTest() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': 'Test from Admin',
        'body': 'Testing the notification panel',
        'target': 'all',
        'type': 'manual',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _createInAppNotifications(
        title: 'Test from Admin',
        message: 'Testing the notification panel',
      );
      setState(() {
        _message =
            'Test notification sent to the Firebase admin notification queue.';
        _success = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _success = false;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendCustomNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final title = _titleController.text.trim();
      final message = _bodyController.text.trim();

      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': title,
        'body': message,
        'target': _targetType,
        'targetLabel': _targetLabel(_targetType),
        'type': 'manual',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final createdCount = await _createInAppNotifications(
        title: title,
        message: message,
      );

      setState(() {
        _message =
            'Notification queued. In-app copies created for $createdCount users.';
        _success = true;
        _titleController.clear();
        _bodyController.clear();
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
        _success = false;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<int> _createInAppNotifications({
    required String title,
    required String message,
  }) async {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('users');

    if (_targetType == 'newUsers') {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      query = query.where('createdAt', isGreaterThanOrEqualTo: cutoff);
    } else if (_targetType == 'merchants') {
      query = query.where('role', whereIn: ['merchant', 'seller']);
    } else if (_targetType == 'buyers') {
      query = query.where('role', isEqualTo: 'user');
    } else if (_targetType == 'handmadeBuyers') {
      query = query.where('interests', arrayContains: 'handmade');
    } else if (_targetType == 'inactiveUsers') {
      final cutoff = DateTime.now().subtract(const Duration(days: 14));
      query = query.where('lastActiveAt', isLessThan: cutoff);
    }

    final users = await query.get();
    if (users.docs.isEmpty) return 0;

    var batch = FirebaseFirestore.instance.batch();
    var writeCount = 0;
    var total = 0;

    for (final userDoc in users.docs) {
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': userDoc.id,
        'title': title,
        'message': message,
        'body': message,
        'type': 'manual',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      writeCount++;
      total++;

      if (writeCount == 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        writeCount = 0;
      }
    }

    if (writeCount > 0) {
      await batch.commit();
    }

    return total;
  }

  String _targetLabel(String target) {
    switch (target) {
      case 'buyers':
        return 'Buyers';
      case 'merchants':
        return 'Merchants and sellers';
      case 'handmadeBuyers':
        return 'Handmade buyers';
      case 'inactiveUsers':
        return 'Inactive users';
      case 'newUsers':
        return 'New users (24h)';
      default:
        return 'All users';
    }
  }
}
