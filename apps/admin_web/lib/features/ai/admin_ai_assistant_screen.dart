import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/admin_tokens.dart';

class AdminAiAssistantScreen extends StatefulWidget {
  const AdminAiAssistantScreen({super.key});

  @override
  State<AdminAiAssistantScreen> createState() => _AdminAiAssistantScreenState();
}

class _AdminAiAssistantScreenState extends State<AdminAiAssistantScreen> {
  final _questionController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _answer;
  String? _error;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('adminAskAssistantWithAi')
          .call<Map<String, dynamic>>({'question': question});
      if (!mounted) return;
      setState(() {
        _answer = Map<String, dynamic>.from(
          result.data['answer'] as Map? ?? const {},
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'AI Assistant',
      description:
          'Ask operational questions against capped queue snapshots. Answers are advisory and audited.',
      icon: Icons.auto_awesome_outlined,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AdminRadius.lg),
              border: Border.all(color: AdminColors.border),
              boxShadow: AdminShadows.card,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _questionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText:
                        'What should operations review first this morning?',
                    prefixIcon: Icon(Icons.question_answer_outlined),
                  ),
                  onSubmitted: (_) => _ask(),
                ),
                const SizedBox(height: AdminSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _ask,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('Ask assistant'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
          if (_error != null)
            _AssistantPanel(
              title: 'Unable to answer',
              items: [_error!],
              icon: Icons.error_outline,
            )
          else if (_answer != null) ...[
            _AssistantPanel(
              title: 'Summary',
              items: [_answer!['summary']?.toString() ?? 'No summary.'],
              icon: Icons.summarize_outlined,
            ),
            const SizedBox(height: AdminSpacing.md),
            _AssistantPanel(
              title: 'Next actions',
              items: _strings(_answer!['nextActions']),
              icon: Icons.task_alt_outlined,
            ),
            const SizedBox(height: AdminSpacing.md),
            _AssistantPanel(
              title: 'Risks',
              items: _strings(_answer!['risks']),
              icon: Icons.warning_amber_outlined,
            ),
            const SizedBox(height: AdminSpacing.md),
            _AssistantPanel(
              title: 'Collections to inspect',
              items: _strings(_answer!['collectionsToInspect']),
              icon: Icons.storage_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantPanel extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;

  const _AssistantPanel({
    required this.title,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AdminColors.primary),
              const SizedBox(width: AdminSpacing.sm),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          for (final item in items.isEmpty ? const ['No items.'] : items)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText(item),
            ),
        ],
      ),
    );
  }
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .where((item) => item.trim().isNotEmpty)
      .map((item) => item.trim())
      .toList(growable: false);
}
