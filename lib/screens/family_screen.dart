import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../theme/app_theme.dart';
import '../widgets/breadcrumb.dart';
import '../widgets/family_card.dart';
import '../widgets/status_dot.dart';
import 'person_screen.dart';
import 'tree_screen.dart';

/// The core step-by-step screen of the app: shows one couple (or single
/// parent) and their children as tappable cards. Tapping a child either
/// steps one generation deeper (if that child has started their own
/// family) or opens their person-detail screen (if they're a leaf).
///
/// [path] is the list of family ids from the root down to the family
/// currently being viewed (path.last). It's used both to render the
/// breadcrumb and to let the user jump back to any earlier generation.
class FamilyScreen extends StatelessWidget {
  final FamilyRepository repository;
  final List<String> path;

  const FamilyScreen({
    super.key,
    required this.repository,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final currentFamilyId = path.last;
    final couple = repository.resolveCouple(currentFamilyId);

    if (couple == null) {
      return const Scaffold(
        body: Center(child: Text('اطلاعات این خانواده یافت نشد')),
      );
    }

    final children = repository
        .childrenOf(currentFamilyId)
        .map((child) {
          final ownFamily = repository.findOwnFamily(child.id);
          if (ownFamily != null) {
            final resolved = repository.resolveCouple(ownFamily.id);
            if (resolved != null) return resolved;
          }
          // No family of their own yet: represent as a single-person "couple".
          return CoupleUnit(
            family: repository.getFamily(currentFamilyId)!,
            husband: child,
          );
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(couple.displayName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'مشاهده نمای درختی',
            icon: const Text('🌳', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TreeScreen(repository: repository),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Breadcrumb(
              items: [
                for (int i = 0; i < path.length; i++)
                  BreadcrumbItem(
                    label: repository.resolveCouple(path[i])?.displayName ?? '',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => FamilyScreen(
                            repository: repository,
                            path: path.sublist(0, i + 1),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _CoupleHeader(repository: repository, couple: couple),
                  const SizedBox(height: 16),
                  _FamilyStats(repository: repository, familyId: currentFamilyId),
                  const SizedBox(height: 24),
                  if (children.isNotEmpty) ...[
                    Text(
                      'فرزندان',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    for (final childCouple in children) ...[
                      FamilyCard(
                        couple: childCouple,
                        onTap: () => _onChildTap(context, childCouple),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'فرزندی برای این خانواده ثبت نشده است',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onChildTap(BuildContext context, CoupleUnit childCouple) {
    final childId = childCouple.husband.id;
    final ownFamily = repository.findOwnFamily(childId);
    if (ownFamily != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FamilyScreen(
            repository: repository,
            path: [...path, ownFamily.id],
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonScreen(repository: repository, personId: childId),
        ),
      );
    }
  }
}

/// The header showing the current couple's names; tapping either name
/// opens that person's detail screen (per the "info screen" requirement).
class _CoupleHeader extends StatelessWidget {
  final FamilyRepository repository;
  final CoupleUnit couple;

  const _CoupleHeader({required this.repository, required this.couple});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _NameLink(
              label: couple.husband.fullName,
              status: couple.husband.status,
              onTap: () => _openPerson(context, couple.husband.id),
            ),
            if (couple.wife != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('+', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              _NameLink(
                label: couple.wife!.fullName,
                status: couple.wife!.status,
                onTap: () => _openPerson(context, couple.wife!.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openPerson(BuildContext context, String personId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonScreen(repository: repository, personId: personId),
      ),
    );
  }
}

class _NameLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final PersonStatus? status;

  const _NameLink({required this.label, required this.onTap, this.status});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.primaryLight,
          ),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: status != null ? NameWithStatus(status: status!, child: text) : text,
    );
  }
}

/// Shows this family's own descendant counts by generation: تعداد فرزند
/// (children), نوه (grandchildren), نتیجه (great-grandchildren), نبیره
/// (great-great-grandchildren) and ندیده (great-great-great-grandchildren),
/// all counted relative to this specific couple.
class _FamilyStats extends StatelessWidget {
  final FamilyRepository repository;
  final String familyId;

  const _FamilyStats({required this.repository, required this.familyId});

  @override
  Widget build(BuildContext context) {
    final counts = repository.descendantGenerationCounts(familyId);
    const labels = ['فرزند', 'نوه', 'نتیجه', 'نبیره', 'ندیده'];

    // Only show generations that have at least one member, but always show
    // "فرزند" even if zero so the requested child-count is always visible.
    final entries = <MapEntry<String, int>>[];
    for (var i = 0; i < labels.length; i++) {
      if (i == 0 || counts[i] > 0) {
        entries.add(MapEntry(labels[i], counts[i]));
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${e.value}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تعداد ${e.key}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
