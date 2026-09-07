import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/relationship.dart';
import '../theme/app_theme.dart';
import '../widgets/clan_registry.dart';
import 'status_dot.dart';

/// A tappable card used in the children list of the family screen.
/// Shows a child (and their spouse, if any) as a couple, plus the child's
/// birth year. Tapping it either opens that person's own family (if they
/// have one) or their person-detail screen.
///
/// Each partner's name carries their own status dot (green / black /
/// gold). The child is shown by first name; the spouse's name is shown
/// with their family name so in-law spouses are identifiable — per the
/// requirement that spouses' last names appear in the children section.
///
class FamilyCard extends StatelessWidget {
  final CoupleUnit couple;
  final FamilyRepository repository;
  final VoidCallback onTap;
  final void Function(String personId)? onOpenPerson;

  const FamilyCard({
    super.key,
    required this.couple,
    required this.repository,
    required this.onTap,
    this.onOpenPerson,
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
                    // Child by first name, spouse by full name (with last name).
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
                            child: Text('/',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              final ref =
                                  repository.crossRefFor(couple.wife!.id);
                              if (ref != null) {
                                // Same real person in another خاندان: jump
                                // to that clan's family page.
                                openCrossClanFamily(context, ref);
                              } else if (onOpenPerson != null) {
                                onOpenPerson!(couple.wife!.id);
                              }
                            },
                            child: NameWithStatus(
                              status: couple.wife!.status,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    couple.wife!.fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  if (repository
                                          .crossRefFor(couple.wife!.id) !=
                                      null) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.forest_rounded,
                                        size: 14,
                                        color: AppTheme.textSecondary),
                                  ],
                                ],
                              ),
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
