import 'package:flutter/material.dart';

class ReactionBar extends StatefulWidget {
  final String currentReaction;
  final Function(String) onReactionSelected;
  final VoidCallback? onTap;

  const ReactionBar({
    super.key,
    required this.currentReaction,
    required this.onReactionSelected,
    this.onTap,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isVisible = false;

  static const List<Map<String, String>> _reactions = [
    {'type': 'like', 'emoji': '👍'},
    {'type': 'love', 'emoji': '❤️'},
    {'type': 'haha', 'emoji': '😂'},
    {'type': 'wow', 'emoji': '😮'},
    {'type': 'sad', 'emoji': '😢'},
    {'type': 'angry', 'emoji': '😡'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    setState(() => _isVisible = true);
    _controller.forward();
  }

  void _hide() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_isVisible)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _reactions.map((r) {
                    final isActive = widget.currentReaction == r['type'];
                    return GestureDetector(
                      onTap: () {
                        widget.onReactionSelected(r['type']!);
                        _hide();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.all(8),
                        decoration: isActive
                            ? BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          r['emoji']!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        GestureDetector(
          onLongPress: _isVisible ? _hide : _show,
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              _getCurrentEmoji(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ],
    );
  }

  String _getCurrentEmoji() {
    for (final r in _reactions) {
      if (r['type'] == widget.currentReaction) {
        return r['emoji']!;
      }
    }
    return '👍';
  }
}

class ReactionSummary extends StatelessWidget {
  final List<String> topReactions;
  final int totalCount;
  final int commentCount;

  const ReactionSummary({
    super.key,
    required this.topReactions,
    required this.totalCount,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (totalCount == 0 && commentCount == 0) return const SizedBox.shrink();

    return Row(
      children: [
        if (topReactions.isNotEmpty)
          Text(topReactions.join(' '), style: const TextStyle(fontSize: 14)),
        if (totalCount > 0) ...[
          const SizedBox(width: 4),
          Text('$totalCount', style: theme.textTheme.bodySmall),
        ],
        const Spacer(),
        if (commentCount > 0)
          Text('$commentCount comments', style: theme.textTheme.bodySmall),
      ],
    );
  }
}