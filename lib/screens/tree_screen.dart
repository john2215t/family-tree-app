import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
class TreeScreen extends StatefulWidget {
  final FamilyRepository repository;
  final String? rootPersonId;

  const TreeScreen({
    super.key,
    required this.repository,
    this.rootPersonId,
  });

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  final TransformationController _transform = TransformationController();
  final GlobalKey _treeKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();

  FamilyRepository get repository => widget.repository;
  String? get rootPersonId => widget.rootPersonId;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

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
      appBar: AppBar(
        title: Text('شجره‌نامه $rootName'),
        actions: [
          IconButton(
            tooltip: 'نمایش کل شجره در یک نما',
            icon: const Icon(Icons.filter_center_focus_rounded),
            onPressed: _fitAll,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // One-shot auto-fit on first layout: scale the (very wide) tree so
          // the whole shajire nomaye fits in view right away.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_didAutoFit && mounted) {
              _didAutoFit = true;
              _fitAll();
            }
          });
          return InteractiveViewer(
            key: _viewportKey,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(4000),
            minScale: 0.02,
            maxScale: 2.5,
            transformationController: _transform,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FamilyBranch(
                    key: _treeKey,
                    repository: repository,
                    familyId: rootFamilyId,
                    path: [rootFamilyId],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _didAutoFit = false;

  /// Zooms out far enough that the whole tree fits the viewport.
  void _fitAll() {
    final box = _treeKey.currentContext?.findRenderObject() as RenderBox?;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || viewport == null || !box.hasSize || !viewport.hasSize) {
      return;
    }
    final treeSize = box.size;
    final viewSize = viewport.size;
    if (treeSize.isEmpty || viewSize.isEmpty) return;
    final fitScale = (viewSize.width / treeSize.width)
        .clamp(0.02, 1.0)
        .toDouble();
    final centered = Matrix4.identity()
      ..translate(
        (viewSize.width - treeSize.width * fitScale) / 2,
        16,
      )
      ..scale(fitScale);
    _transform.value = centered;
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
    super.key,
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

/// The horizontal connector above a row of children: a continuous dark line
/// running at the drop-line mid-height across the full row, with each
/// child's branch hanging below it — so parent, rail and drops are one
/// unbroken path.
class _ChildrenRail extends StatelessWidget {
  final List<Widget> branches;

  const _ChildrenRail({required this.branches});

  @override
  Widget build(BuildContext context) {
    // The drop-line is 18 tall; the rail runs through its middle (y = 9).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Continuous horizontal rail behind the branches.
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Container(height: 2, color: const Color(0xFF37474F)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: branches,
        ),
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
      color: const Color(0xFF37474F),
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
      color: const Color(0xFF37474F),
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
        : _PersonAvatar(
            person: couple.wife!,
            radius: 28,
            onTap: () => _openFamily(context),
          );

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
          color: const Color(0xFF37474F),
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
