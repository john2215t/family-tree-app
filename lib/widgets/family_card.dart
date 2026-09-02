import 'package:flutter/material.dart';

import '../models/relationship.dart';
import '../theme/app_theme.dart';
import 'status_dot.dart';

/// A tappable card used in the children list of the family screen.
/// Shows a child (and their spouse, if any) as a couple, plus the child's
/// birth year. Tapping it either opens that person's own family (if they
/// have one) or their person-detail screen.
///
/// Each partner's name carries their own status dot (green / black /
/// gold). In the children list only first names are shown — the family
/// name appears in the profile and search.
class FamilyCard extends StatelessWidget {
  final CoupleUnit couple;
  final VoidCallback onTap;

  const FamilyCard({
    super.key,
    required this.couple,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final birthYear = couple.husband.birthYear;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryLight,
                child: Icon(
                  couple.wife != null ? Icons.people_alt_rounded : Icons.person_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Each partner's first name with their own status dot.
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        NameWithStatus(
                          status: couple.husband.status,
                          child: Text(
                            couple.husband.firstName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (couple.wife != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('+',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          NameWithStatus(
                            status: couple.wife!.status,
                            child: Text(
                              couple.wife!.firstName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (birthYear != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'متولد $birthYear',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
