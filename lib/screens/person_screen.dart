import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/person_card.dart';
import '../widgets/status_dot.dart';
import 'family_screen.dart';
import 'person_list_screen.dart';
import 'person_screen.dart';
import 'tree_screen.dart';

/// Full-information screen for a single person: name, birth year, status,
/// burial place, spouse, parents, children, paternal lineage (پدر،
/// پدربزرگ، … تا سرسلسله), tappable descendant-generation counts, and —
/// via the 🌳 app-bar action — the full tree view rooted at this person.
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
    final lineageText = repository.paternalLineageText(personId);
    final genCounts = _ownFamilyGenerationCounts(personId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اطلاعات فرد'),
        actions: [
          IconButton(
            tooltip: 'نمای درختی از این فرد',
            icon: const Text('🌳', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TreeScreen(repository: repository, rootPersonId: personId),
                ),
              );
            },
          ),
        ],
      ),
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
                    textAlign: TextAlign.center,
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
                  if (person.status != PersonStatus.alive &&
                      person.burialPlace.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place_rounded,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'محل دفن: ${person.burialPlace}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Paternal lineage: پدر › پدربزرگ › … › سرسلسله
            if (lineageText.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle('سلسله پدری'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.family_restroom_rounded,
                          size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lineageText,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Descendant generations (فرزند / نوه / نتیجه / نبیره / ندیده)
            // relative to this person's own family — tappable.
            if (genCounts.isNotEmpty) ...[
              const SizedBox(height: 22),
              _PersonGenerationStats(
                repository: repository,
                personId: personId,
                counts: genCounts,
              ),
            ],
            const SizedBox(height: 24),
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
                              // Parents keep the full name (نام + نام خانوادگی)
                              // per the family-name display rule.
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

  /// Generation counts relative to the person's own family (the one they
  /// started as a spouse). Empty when the person has no family of their
  /// own — in that case there are no descendants to count.
  List<int> _ownFamilyGenerationCounts(String personId) {
    final ownFamily = repository.findOwnFamily(personId);
    if (ownFamily == null) return const [];
    return repository.descendantGenerationCounts(ownFamily.id);
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

/// Tappable generation counts shown on the person profile: فرزند / نوه /
/// نتیجه / نبیره / ندیده — each count opens the member list of that
/// generation (same behavior as the family screen's stats).
class _PersonGenerationStats extends StatelessWidget {
  final FamilyRepository repository;
  final String personId;
  final List<int> counts;

  const _PersonGenerationStats({
    required this.repository,
    required this.personId,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final labels = FamilyRepository.descendantGenerationLabels;
    final ownFamilyId = repository.findOwnFamily(personId)!.id;

    final entries = <MapEntry<int, int>>[];
    for (var i = 0; i < labels.length; i++) {
      if (i == 0 || counts[i] > 0) {
        entries.add(MapEntry(i, counts[i]));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 10,
          children: [
            for (final e in entries)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: e.value == 0
                    ? null
                    : () {
                        final people = repository
                            .descendantGenerationPeople(ownFamilyId)[e.key];
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonListScreen(
                              repository: repository,
                              title: '${labels[e.key]}های ${repository
                                      .getPerson(personId)!.firstName}',
                              people: people,
                            ),
                          ),
                        );
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${e.value}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تعداد ${labels[e.key]}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
