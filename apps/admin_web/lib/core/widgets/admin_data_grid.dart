import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_status_badge.dart';
import 'admin_tokens.dart';

typedef AdminCellBuilder = String Function(Map<String, dynamic> data);
typedef AdminCellWidgetBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> data,
);
typedef AdminRowActionsBuilder = List<Widget> Function(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
);
typedef AdminRowTap = void Function(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
);

class AdminDataGridColumn {
  final String label;
  final AdminCellBuilder value;
  final AdminCellWidgetBuilder? cellBuilder;
  final bool status;
  final double width;

  const AdminDataGridColumn({
    required this.label,
    required this.value,
    this.cellBuilder,
    this.status = false,
    this.width = 190,
  });

  factory AdminDataGridColumn.field(
    String label,
    String field, {
    bool status = false,
  }) {
    return AdminDataGridColumn(
      label: label,
      status: status,
      value: (data) => adminCellValue(data[field]),
    );
  }

  factory AdminDataGridColumn.image(
    String label, {
    List<String> fields = const ['imageUrl', 'thumbnailUrl', 'photoUrl'],
  }) {
    return AdminDataGridColumn(
      label: label,
      width: 96,
      value: (data) => _firstImageUrl(data, fields) ?? '-',
      cellBuilder: (context, data) {
        return _AdminImageCell(imageUrl: _firstImageUrl(data, fields));
      },
    );
  }
}

class AdminDataGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final List<AdminDataGridColumn> columns;
  final AdminRowActionsBuilder? rowActionsBuilder;
  final AdminRowTap? onRowTap;
  final String title;
  final String subtitle;

  const AdminDataGrid({
    super.key,
    required this.docs,
    required this.columns,
    this.rowActionsBuilder,
    this.onRowTap,
    this.title = 'Live records',
    this.subtitle = 'Click any row to inspect the full protected document.',
  });

  @override
  Widget build(BuildContext context) {
    final minWidth = 260 +
        columns.fold<double>(
            0, (totalWidth, column) => totalWidth + column.width) +
        (rowActionsBuilder == null ? 0 : 360);

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _GridHeader(title: title, subtitle: subtitle, count: docs.length),
          const Divider(height: 1, color: AdminColors.border),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: minWidth.toDouble()),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: DataTableTheme(
                        data: const DataTableThemeData(
                          headingTextStyle: TextStyle(
                            color: AdminColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                          dataTextStyle: TextStyle(
                            color: AdminColors.ink,
                            fontSize: 13,
                          ),
                          dividerThickness: 0.6,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AdminColors.cardWarm,
                          ),
                          dataRowMinHeight: 68,
                          dataRowMaxHeight: 86,
                          horizontalMargin: 22,
                          columnSpacing: 28,
                          showCheckboxColumn: false,
                          columns: [
                            const DataColumn(label: Text('Document ID')),
                            for (final column in columns)
                              DataColumn(label: Text(column.label)),
                            if (rowActionsBuilder != null)
                              const DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            for (var index = 0; index < docs.length; index++)
                              _rowForDoc(context, docs[index], index),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _rowForDoc(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int index,
  ) {
    final rowColor = index.isEven ? Colors.white : AdminColors.cardWarm;
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AdminColors.primarySoft;
        }
        return rowColor;
      }),
      onSelectChanged: onRowTap == null ? null : (_) => onRowTap!(context, doc),
      cells: [
        DataCell(_DocumentIdCell(doc.id)),
        for (final column in columns)
          DataCell(_cellForColumn(context, column, doc.data())),
        if (rowActionsBuilder != null)
          DataCell(
            _ActionWrap(children: rowActionsBuilder!(context, doc)),
          ),
      ],
    );
  }

  Widget _cellForColumn(
    BuildContext context,
    AdminDataGridColumn column,
    Map<String, dynamic> data,
  ) {
    if (column.cellBuilder != null) {
      return column.cellBuilder!(context, data);
    }
    if (column.status) {
      return AdminStatusBadge(
        label: column.value(data),
        tone: adminToneForStatus(column.value(data)),
      );
    }
    return _ClippedText(column.value(data));
  }
}

class _GridHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;

  const _GridHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminColors.ink,
              borderRadius: BorderRadius.circular(AdminRadius.md),
            ),
            child: const Icon(Icons.view_week_outlined, color: Colors.white),
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(color: AdminColors.muted)),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AdminColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: AdminColors.primary.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '$count rows',
                style: const TextStyle(
                  color: AdminColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionWrap extends StatelessWidget {
  final List<Widget> children;

  const _ActionWrap({required this.children});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Wrap(spacing: 8, runSpacing: 8, children: children),
    );
  }
}

class _DocumentIdCell extends StatelessWidget {
  final String value;

  const _DocumentIdCell(this.value);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: AdminColors.accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: AdminSpacing.sm),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClippedText extends StatelessWidget {
  final String value;

  const _ClippedText(this.value);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AdminImageCell extends StatelessWidget {
  final String? imageUrl;

  const _AdminImageCell({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AdminColors.cardWarm,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? const Icon(Icons.image_not_supported_outlined,
              color: AdminColors.faint)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: AdminColors.faint,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
    );
  }
}

String adminCellValue(Object? value) {
  if (value == null) return '-';
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is Iterable) return value.join(', ');
  if (value is Map) {
    return value.entries.map((entry) {
      return '${entry.key}: ${entry.value}';
    }).join(', ');
  }
  return value.toString();
}

String? _firstImageUrl(Map<String, dynamic> data, List<String> fields) {
  for (final field in fields) {
    final value = data[field];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Iterable) {
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) return item.trim();
      }
    }
  }
  return null;
}
