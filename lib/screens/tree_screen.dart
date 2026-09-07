import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../theme/app_theme.dart';
import '../widgets/status_dot.dart';
import 'family_screen.dart';

/// A zoomable, pannable full-tree overview, built with [InteractiveViewer].
///
/// Visual language mirrors the classic "family tree poster" layout: every
/// person is a **circular avatar** (first letter of their name on a soft
/// colored disc, with a status ring), couples sit **side by side joined by a
/// short connector**, and each couple's children hang **below them** on white
/// connector lines — generations flow top → bottom like the reference poster.
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
    // If the person has no own family (a leaf), root the tree at their
    // birth family instead — so their personal subtree still centers on
    // them rather than jumping back to the clan's founding couple.
    String rootFamilyId = repository.rootFamilyId;
    if (rootPersonId != null) {
      final ownFamily = repository.findOwnFamily(rootPersonId!);
      if (ownFamily != null) {
        rootFamilyId = ownFamily.id;
      } else {
        final birthFamily = repository.findBirthFamily(rootPersonId!);
        if (birthFamily != null) rootFamilyId = birthFamily.id;
      }
    }

    final rootCouple = repository.resolveCouple(rootFamilyId);
    final rootName = rootCouple == null
        ? 'نمای درختی'
        : rootCouple.wife != null
            ? '${rootCouple.husband.firstName} / ${rootCouple.wife!.firstName}'
            : rootCouple.husband.firstName;

    return Scaffold(
      appBar: AppBar(title: Text('شجره‌نامه $rootName')),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(120),
        minScale: 0.3,
        maxScale: 2.5,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _FamilyBranch(
            repository: repository,
            familyId: rootFamilyId,
            path: [rootFamilyId],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout building blocks
// ---------------------------------------------------------------------------

/// The whole subtree of one couple: the couple node (two joined avatars) at
/// the top, and their children's subtrees arranged in a row below, each
/// hanging from a vertical connector line.
class _FamilyBranch extends StatelessWidget {
  final FamilyRepository repository;
  final String familyId;
  final List<String> path;

  const _FamilyBranch({
    required this.repository,
    required this.familyId,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final couple = repository.resolveCouple(familyId);
    if (couple == null) return const SizedBox.shrink();

    final children = repository.childrenOf(familyId);

    final coupleNode = _CoupleNode(
      repository: repository,
      couple: couple,
      path: path,
    );

    if (children.isEmpty) {
      return coupleNode;
    }

    final childBranches = <Widget>[
      for (final child in children)
        _ChildSubtree(
          repository: repository,
          childId: child.id,
          path: path,
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        coupleNode,
        // Vertical stem from the couple down to the children rail.
        const _Stem(height: 22),
        // Horizontal rail spanning the children row, with a drop line to
        // each child's subtree.
        _ChildrenRail(
          branches: childBranches,
        ),
      ],
    );
  }
}

/// One child slot in the row below a couple: a drop-line from the rail, then
/// either the child's own family branch (if they married) or a single leaf
/// avatar (if they didn't).
class _ChildSubtree extends StatelessWidget {
  final FamilyRepository repository;
  final String childId;
  final List<String> path;

  const _ChildSubtree({
    required this.repository,
    required this.childId,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final ownFamily = repository.findOwnFamily(childId);

    Widget content;
    if (ownFamily != null) {
      content = _FamilyBranch(
        repository: repository,
        familyId: ownFamily.id,
        path: [...path, ownFamily.id],
      );
    } else {
      final person = repository.getPerson(childId);
      if (person == null) return const SizedBox.shrink();
      content = _PersonAvatar(person: person, isLeaf: true);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DropLine(),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}

/// The horizontal connector above a row of children: a line spanning the row
/// with vertical drops above each child.
class _ChildrenRail extends StatelessWidget {
  final List<Widget> branches;

  const _ChildrenRail({required this.branches});

  @override
  Widget build(BuildContext context) {
    if (branches.length == 1) {
      return branches.first;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < branches.length; i++) ...[
          if (i > 0) const _RailSpan(),
          branches[i],
        ],
      ],
    );
  }
}

/// Thin vertical line segment (couple → children rail, rail → child).
class _Stem extends StatelessWidget {
  final double height;

  const _Stem({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: height,
      color: Colors.white.withOpacity(0.9),
    );
  }
}

/// Vertical drop line above a child node (drawn on the poster background so
/// it reads as a connector).
class _DropLine extends StatelessWidget {
  const _DropLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Short horizontal piece between adjacent children's drop lines.
class _RailSpan extends StatelessWidget {
  const _RailSpan();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(top: 17),
      color: Colors.white.withOpacity(0.9),
    );
  }
}

// ---------------------------------------------------------------------------
// Person / couple nodes
// ---------------------------------------------------------------------------

/// One person rendered as a circular avatar: a soft colored disc carrying the
/// first letter of the name, wrapped in a status ring (teal = زنده, gold =
/// شهید, dark = فوت کرده), with the first name underneath. Mirrors the
/// reference poster where each family member is a circular portrait.
class _PersonAvatar extends StatelessWidget {
  final Person person;
  final bool isLeaf;
  final double radius;
  final VoidCallback? onTap;

  const _PersonAvatar({
    required this.person,
    this.isLeaf = false,
    this.radius = 26,
    this.onTap,
  });

  static Color _fillFor(Person p) {
    switch (p.status) {
      case PersonStatus.martyr:
        return const Color(0xFFF6E7C1); // warm gold disc
      case PersonStatus.deceased:
        return const Color(0xFFD7DCDA); // gray disc
      case PersonStatus.alive:
        return AppTheme.primaryLight; // soft teal disc
    }
  }

  static Color _ringFor(Person p) {
    switch (p.status) {
      case PersonStatus.martyr:
        return const Color(0xFFC9A227);
      case PersonStatus.deceased:
        return const Color(0xFF5B6663);
      case PersonStatus.alive:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = person.firstName;

    final avatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: radius * 2 + 6,
          height: radius * 2 + 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _ringFor(person).withOpacity(0.55),
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _fillFor(person),
              ),
              alignment: Alignment.center,
              child: Text(
                label.isNotEmpty ? String.fromCharCode(label.runes.elementAt(0)) : '؟',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: radius * 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: isLeaf ? FontWeight.w600 : FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
      ],
    );

    final styled = isLeaf
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E9E7)),
            ),
            child: avatar,
          )
        : avatar;

    if (onTap == null) return styled;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: styled,
    );
  }
}

/// A married couple rendered as two avatars side by side, joined by a short
/// double-line connector (the "گاه‌وبی‌گاه ❤" spot on the poster). Tapping
/// opens the step-by-step family screen for that generation.
class _CoupleNode extends StatelessWidget {
  final FamilyRepository repository;
  final CoupleUnit couple;
  final List<String> path;

  const _CoupleNode({
    required this.repository,
    required this.couple,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final husband = _PersonAvatar(
      person: couple.husband,
      radius: 28,
      onTap: () => _openFamily(context),
    );
    final wife = couple.wife == null
        ? null
        : _PersonAvatar(person: couple.wife!, radius: 28, onTap: () => _openFamily(context));

    final node = wife == null
        ? husband
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              husband,
              const _CoupleLink(),
              wife,
            ],
          );

    return node;
  }

  void _openFamily(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FamilyScreen(repository: repository, path: path),
      ),
    );
  }
}

/// The little connector between the two avatars of a couple.
class _CoupleLink extends StatelessWidget {
  const _CoupleLink();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 2,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(height: 2),
        Text(
          '♥',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFC9A227),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
