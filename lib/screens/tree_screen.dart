import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_dot.dart';
import 'family_screen.dart';

/// A zoomable, pannable full-tree overview, built with [InteractiveViewer].
/// This is a secondary view for getting a bird's-eye picture — the app's
/// primary navigation model is still the step-by-step [FamilyScreen].
///
/// By default the tree is rooted at the clan's founding couple. When
/// [rootPersonId] is given (e.g. from a person's profile), the tree is
/// rooted at that person's own family instead — showing their personal
/// subtree. Tapping any node jumps into the step-by-step view at that
/// generation.
class TreeScreen extends StatelessWidget {
  final FamilyRepository repository;
  final String? rootPersonId;

  const TreeScreen({
    super.key,
    required this.repository,
    this.rootPersonId,
  });

  @override
  Widget build(BuildContext context) {
    // Root family: the root person's own family if given, else the clan root.
    String rootFamilyId = repository.rootFamilyId;
    if (rootPersonId != null) {
      final ownFamily = repository.findOwnFamily(rootPersonId!);
      if (ownFamily != null) rootFamilyId = ownFamily.id;
    }

    final rootCouple = repository.resolveCouple(rootFamilyId);
    final rootName = rootCouple == null
        ? 'نمای درختی'
        : rootCouple.wife != null
            ? '${rootCouple.husband.firstName} + ${rootCouple.wife!.firstName}'
            : rootCouple.husband.firstName;

    return Scaffold(
      appBar: AppBar(title: Text('شجره‌نامه $rootName')),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(80),
        minScale: 0.4,
        maxScale: 2.5,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _TreeNode(
            repository: repository,
            familyId: rootFamilyId,
            path: [rootFamilyId],
          ),
        ),
      ),
    );
  }
}

class _TreeNode extends StatelessWidget {
  final FamilyRepository repository;
  final String familyId;
  final List<String> path;

  const _TreeNode({
    required this.repository,
    required this.familyId,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final couple = repository.resolveCouple(familyId);
    if (couple == null) return const SizedBox.shrink();

    final children = repository.childrenOf(familyId);

    // Tree view intentionally shows first names only (no last names) to
    // keep the diagram compact and readable across many generations.
    final firstNameLabel = couple.wife != null
        ? '${couple.husband.firstName} + ${couple.wife!.firstName}'
        : couple.husband.firstName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FamilyScreen(repository: repository, path: path),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLight, width: 1.5),
            ),
            // Status dots for both partners.
            child: couple.wife != null
                ? Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      NameWithStatus(
                        status: couple.husband.status,
                        child: Text(
                          couple.husband.firstName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        ' + ',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      NameWithStatus(
                        status: couple.wife!.status,
                        child: Text(
                          couple.wife!.firstName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  )
                : NameWithStatus(
                    status: couple.husband.status,
                    child: Text(
                      firstNameLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ),
        if (children.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ChildBranch(
                      repository: repository,
                      childId: child.id,
                      path: path,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Renders either a nested [_TreeNode] (if the child started their own
/// family) or a plain leaf label (if they didn't).
class _ChildBranch extends StatelessWidget {
  final FamilyRepository repository;
  final String childId;
  final List<String> path;

  const _ChildBranch({
    required this.repository,
    required this.childId,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final ownFamily = repository.findOwnFamily(childId);
    if (ownFamily != null) {
      return _TreeNode(
        repository: repository,
        familyId: ownFamily.id,
        path: [...path, ownFamily.id],
      );
    }
    final person = repository.getPerson(childId);
    if (person == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9E7)),
      ),
      // First name only in tree view, per app convention.
      child: NameWithStatus(
        status: person.status,
        child: Text(
          person.firstName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
