import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/person_card.dart';
import '../widgets/status_dot.dart';
import 'family_screen.dart';

/// Full-information screen for a single person: name, birth year, spouse,
/// parents, and children — plus, when relevant, a link to jump to the
/// family in which this person was born ("مشاهده در خانواده اصلی"),
/// which matters most when this person is being viewed as someone else's
/// spouse (an in-law) rather than as a child of the family on screen.
class PersonScreen extends StatelessWidget {
  final FamilyRepository repository;
  final String personId;

  const PersonScreen({
    super.key,
    required this.repository,
    required this.personId,
  });

  @override
  Widget build(BuildContext context) {
    final relations = repository.relationsFor(personId);
    final person = relations.person;

    return Scaffold(
      appBar: AppBar(title: const Text('اطلاعات فرد')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.primaryLight,
                    child: Icon(Icons.person_rounded, color: AppTheme.primary, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    person.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (person.birthYear != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'سال تولد: ${person.birthYear}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _StatusChip(status: person.status),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (relations.spouse != null) ...[
              _SectionTitle('همسر'),
              const SizedBox(height: 10),
              PersonCard(
                person: relations.spouse!,
                onTap: () => _openPerson(context, relations.spouse!.id),
              ),
              const SizedBox(height: 22),
            ],
            if (relations.parents != null) ...[
              _SectionTitle('والدین'),
              const SizedBox(height: 10),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openFamily(context, relations.parents!.family.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: NameWithStatus(
                            status: relations.parents!.husband.status,
                            child: Text(
                              relations.parents!.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_left_rounded,
                            color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  final birthFamilyId = relations.parents!.family.id;
                  final path = repository.buildPathToFamily(birthFamilyId);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FamilyScreen(repository: repository, path: path),
                    ),
                  );
                },
                icon: const Icon(Icons.north_east_rounded, size: 18),
                label: const Text('مشاهده در خانواده اصلی'),
              ),
              const SizedBox(height: 22),
            ],
            if (relations.children.isNotEmpty) ...[
              _SectionTitle('فرزندان'),
              const SizedBox(height: 10),
              for (final child in relations.children) ...[
                PersonCard(
                  person: child,
                  onTap: () => _openPerson(context, child.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _openPerson(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonScreen(repository: repository, personId: id),
      ),
    );
  }

  void _openFamily(BuildContext context, String familyId) {
    final path = repository.buildPathToFamily(familyId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FamilyScreen(repository: repository, path: path),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// The only place in the app where life status is spelled out as text
/// (زنده / فوت کرده / شهید) — everywhere else it's shown only as a small
/// colored dot next to the name.
class _StatusChip extends StatelessWidget {
  final PersonStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case PersonStatus.alive:
        return const Color(0xFF3FB562);
      case PersonStatus.deceased:
        return const Color(0xFF2A2A2A);
      case PersonStatus.martyr:
        return const Color(0xFFD4AF37);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
          ),
        ],
      ),
    );
  }
}
