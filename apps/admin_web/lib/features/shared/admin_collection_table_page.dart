import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firestore/admin_capped_query.dart';
import '../../core/widgets/admin_data_grid.dart';
import '../../core/widgets/admin_detail_drawer.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/admin_status_badge.dart';
import '../../core/widgets/admin_tokens.dart';

typedef AdminQueryBuilder = Query<Map<String, dynamic>> Function(
  CollectionReference<Map<String, dynamic>> collection,
);

typedef AdminTableColumn = AdminDataGridColumn;
typedef AdminRowActionsBuilder = List<Widget> Function(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
);

class AdminServerFilter {
  final String field;
  final Object? isEqualTo;
  final Object? isGreaterThanOrEqualTo;
  final Object? isLessThanOrEqualTo;

  const AdminServerFilter.equals(this.field, this.isEqualTo)
      : isGreaterThanOrEqualTo = null,
        isLessThanOrEqualTo = null;

  const AdminServerFilter.range({
    required this.field,
    this.isGreaterThanOrEqualTo,
    this.isLessThanOrEqualTo,
  }) : isEqualTo = null;
}

class AdminServerFilterOption {
  final String label;
  final IconData icon;
  final List<AdminServerFilter> filters;

  const AdminServerFilterOption({
    required this.label,
    required this.icon,
    this.filters = const [],
  });
}

class AdminCollectionTablePage extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String collectionName;
  final List<AdminTableColumn> columns;
  final int pageSize;
  final AdminQueryBuilder? queryBuilder;
  final List<Widget> headerActions;
  final AdminRowActionsBuilder? rowActionsBuilder;
  final List<AdminServerFilter> serverFilters;
  final List<AdminServerFilterOption> serverFilterOptions;

  const AdminCollectionTablePage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.collectionName,
    required this.columns,
    this.pageSize = adminDefaultPageSize,
    this.queryBuilder,
    this.headerActions = const [],
    this.rowActionsBuilder,
    this.serverFilters = const [],
    this.serverFilterOptions = const [],
  });

  @override
  State<AdminCollectionTablePage> createState() =>
      _AdminCollectionTablePageState();
}

class _AdminCollectionTablePageState extends State<AdminCollectionTablePage> {
  final _searchController = TextEditingController();
  String _search = '';
  int _selectedServerFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collection =
        FirebaseFirestore.instance.collection(widget.collectionName);
    final activeFilters = _activeServerFilters();
    final baseQuery = _applyServerFilters(
      widget.queryBuilder?.call(collection) ?? collection,
      activeFilters,
    );
    final query = cappedAdminQuery(baseQuery, requestedLimit: widget.pageSize);
    final cappedLimit = cappedAdminLimit(widget.pageSize);

    return AdminScaffold(
      title: widget.title,
      description: widget.description,
      icon: widget.icon,
      actions: widget.headerActions,
      bottom: Column(
        children: [
          _GuardrailBanner(
            collectionName: widget.collectionName,
            pageSize: cappedLimit,
          ),
          const SizedBox(height: AdminSpacing.xs),
          _OperationsToolbar(
            collectionName: widget.collectionName,
            pageSize: cappedLimit,
            controller: _searchController,
            serverFilterOptions: widget.serverFilterOptions,
            selectedServerFilter: _selectedServerFilter,
            onChanged: (value) => setState(() => _search = value.trim()),
            onServerFilterChanged: (index) {
              setState(() => _selectedServerFilter = index);
            },
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _TableStateCard(
              icon: Icons.lock_outline,
              title: 'Unable to load protected data',
              message:
                  'Firestore Rules rejected this request or the collection needs an index.',
              details: snapshot.error.toString(),
            );
          }

          if (!snapshot.hasData) {
            return const _LoadingTableState();
          }

          final docs = _filterDocs(snapshot.data!.docs);
          if (docs.isEmpty) {
            return _TableStateCard(
              icon: Icons.inventory_2_outlined,
              title: _search.isEmpty ? 'No records yet' : 'No local matches',
              message: _search.isEmpty
                  ? 'This capped admin table is connected, but no matching documents were returned.'
                  : 'The capped page loaded, but no row contains "$_search".',
            );
          }

          return AdminDataGrid(
            docs: docs,
            columns: widget.columns,
            rowActionsBuilder: widget.rowActionsBuilder,
            onRowTap: _openDetailDrawer,
            title: '${widget.title} queue',
            subtitle:
                'Protected source: ${widget.collectionName}. Showing a capped working set.',
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_search.isEmpty) return docs;
    final needle = _search.toLowerCase();
    return docs.where((doc) {
      final values = [
        doc.id,
        ...doc.data().entries.map((entry) => '${entry.key} ${entry.value}'),
      ].join(' ').toLowerCase();
      return values.contains(needle);
    }).toList();
  }

  Query<Map<String, dynamic>> _applyServerFilters(
    Query<Map<String, dynamic>> query,
    List<AdminServerFilter> filters,
  ) {
    var filtered = query;
    for (final filter in filters) {
      if (filter.isEqualTo != null) {
        filtered = filtered.where(filter.field, isEqualTo: filter.isEqualTo);
      }
      if (filter.isGreaterThanOrEqualTo != null) {
        filtered = filtered.where(
          filter.field,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
        );
      }
      if (filter.isLessThanOrEqualTo != null) {
        filtered = filtered.where(
          filter.field,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
        );
      }
    }
    return filtered;
  }

  List<AdminServerFilter> _activeServerFilters() {
    final options = widget.serverFilterOptions;
    if (options.isEmpty) return widget.serverFilters;
    if (_selectedServerFilter < 0 || _selectedServerFilter >= options.length) {
      return const [];
    }
    return [
      ...widget.serverFilters,
      ...options[_selectedServerFilter].filters,
    ];
  }

  void _openDetailDrawer(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 620),
      builder: (context) {
        return AdminDetailDrawer(
          title: '${widget.title} detail',
          subtitle: doc.id,
          sections: [
            AdminDetailSection(
              title: 'Record fields',
              children: [
                for (final entry in data.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: AdminColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(adminCellValue(entry.value)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _OperationsToolbar extends StatelessWidget {
  final String collectionName;
  final int pageSize;
  final TextEditingController controller;
  final List<AdminServerFilterOption> serverFilterOptions;
  final int selectedServerFilter;
  final ValueChanged<String> onChanged;
  final ValueChanged<int> onServerFilterChanged;

  const _OperationsToolbar({
    required this.collectionName,
    required this.pageSize,
    required this.controller,
    required this.serverFilterOptions,
    required this.selectedServerFilter,
    required this.onChanged,
    required this.onServerFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      padding: const EdgeInsets.all(AdminSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final search = TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Filter this capped page...',
              prefixIcon: Icon(Icons.tune, size: 18),
              prefixIconConstraints: BoxConstraints(minWidth: 36),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AdminSpacing.sm,
                vertical: AdminSpacing.xs,
              ),
            ),
          );
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminStatusBadge(
                label: 'Source: $collectionName',
                tone: AdminStatusTone.info,
                icon: Icons.storage_outlined,
              ),
              AdminStatusBadge(
                label: 'Limit $pageSize',
                tone: AdminStatusTone.warning,
                icon: Icons.speed_outlined,
              ),
              const AdminStatusBadge(
                label: 'Audit required',
                tone: AdminStatusTone.success,
                icon: Icons.verified_outlined,
              ),
            ],
          );
          final serverFilters = _ServerFilterBar(
            options: serverFilterOptions,
            selectedIndex: selectedServerFilter,
            onSelected: onServerFilterChanged,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: AdminSpacing.xs),
                serverFilters,
                if (serverFilterOptions.isNotEmpty)
                  const SizedBox(height: AdminSpacing.xs),
                chips,
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AdminSpacing.xs),
                  Flexible(child: chips),
                ],
              ),
              if (serverFilterOptions.isNotEmpty) ...[
                const SizedBox(height: AdminSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: serverFilters,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ServerFilterBar extends StatelessWidget {
  final List<AdminServerFilterOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ServerFilterBar({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var index = 0; index < options.length; index++)
          FilterChip(
            selected: index == selectedIndex,
            avatar: Icon(options[index].icon, size: 14),
            label: Text(
              options[index].label,
              style: const TextStyle(fontSize: 11),
            ),
            visualDensity: const VisualDensity(horizontal: -2, vertical: -4),
            onSelected: (_) => onSelected(index),
            selectedColor: AdminColors.primarySoft,
            checkmarkColor: AdminColors.primary,
            side: BorderSide(
              color: index == selectedIndex
                  ? AdminColors.primary.withValues(alpha: 0.42)
                  : AdminColors.border,
            ),
          ),
      ],
    );
  }
}

class _GuardrailBanner extends StatelessWidget {
  final String collectionName;
  final int pageSize;

  const _GuardrailBanner({
    required this.collectionName,
    required this.pageSize,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.infoSoft,
        border: Border.all(color: AdminColors.info.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AdminRadius.sm),
              ),
              child: const Icon(
                Icons.security_outlined,
                color: AdminColors.info,
                size: 16,
              ),
            ),
            const SizedBox(width: AdminSpacing.xs),
            Expanded(
              child: Text(
                'Protected source: $collectionName. Reads are capped at '
                '$pageSize rows. Backend commands, Firestore Rules, and '
                'Custom Claims enforce access. Sensitive actions require a '
                'reason and immutable audit log.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, height: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingTableState extends StatelessWidget {
  const _LoadingTableState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AdminSpacing.md),
            Text('Loading protected records...'),
          ],
        ),
      ),
    );
  }
}

class _TableStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? details;

  const _TableStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(AdminRadius.xl),
          border: Border.all(color: AdminColors.border),
          boxShadow: AdminShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AdminColors.primarySoft,
                    borderRadius: BorderRadius.circular(AdminRadius.lg),
                  ),
                  child: Icon(icon, size: 36, color: AdminColors.primary),
                ),
                const SizedBox(height: AdminSpacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AdminSpacing.sm),
                Text(message, textAlign: TextAlign.center),
                if (details != null) ...[
                  const SizedBox(height: AdminSpacing.md),
                  SelectableText(
                    details!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
