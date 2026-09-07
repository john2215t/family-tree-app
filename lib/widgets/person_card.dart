import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import 'status_dot.dart';

/// A simple tappable row for a single [Person] — used in search results
/// and in lists of relatives on the person-detail screen.
///
/// When [repository] is supplied, the person's paternal lineage (پدر ›
/// پدربزرگ › پدر پدربزرگ — نام سلسله پدری) is rendered under the name in
/// a smaller, secondary style. Search results and the clan-stat member
/// lists both pass the repository so the lineage is always visible.
class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final FamilyRepository? repository;

  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
    this.trailingIcon = Icons.chevron_left_rounded,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    // Paternal lineage: only the father's side chain (پدر، پدربزرگ، پدر
    // پدربزرگ، …). Rendered under the full name in a smaller font.
    final lineage = repository?.paternalLineageText(person.id) ?? '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryLight,
                child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NameWithStatus(
                      status: person.status,
                      child: Text(
                        person.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (lineage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lineage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                    if (person.birthYear != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'متولد ${person.birthYear}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: AppTheme.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
