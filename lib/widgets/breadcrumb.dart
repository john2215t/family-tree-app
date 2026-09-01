import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One entry in the breadcrumb path.
class BreadcrumbItem {
  final String label;
  final VoidCallback onTap;

  const BreadcrumbItem({required this.label, required this.onTap});
}

/// Shows the user's current path through the generations, e.g.
/// "احمد رضایی + مریم حسینی  ›  علی رضایی + سارا کریمی  ›  رضا رضایی + ...".
///
/// Scrolls horizontally when the path is longer than the screen, and lets
/// the user tap any earlier step to jump straight back to it.
class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      reverse: true, // in RTL, start scrolled to the current (right-most) step
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i != 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_left_rounded,
                    size: 18, color: AppTheme.textSecondary),
              ),
            _BreadcrumbChip(
              item: items[i],
              isCurrent: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final BreadcrumbItem item;
  final bool isCurrent;

  const _BreadcrumbChip({required this.item, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isCurrent ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          item.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent ? AppTheme.primary : AppTheme.textSecondary,
              ),
        ),
      ),
    );
  }
}
