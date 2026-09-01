import 'package:flutter/material.dart';

import '../models/person.dart';
import '../theme/app_theme.dart';
import 'status_dot.dart';

/// A simple tappable row for a single [Person] — used in search results
/// and in lists of relatives on the person-detail screen.
class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
    this.trailingIcon = Icons.chevron_left_rounded,
  });

  @override
  Widget build(BuildContext context) {
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
