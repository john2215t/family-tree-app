import 'package:flutter/material.dart';

import '../models/person.dart';

/// A small colored dot indicating a person's life status:
/// - green: alive (زنده)
/// - black: deceased (فوت کرده)
/// - gold: martyr (شهید)
///
/// This widget is intentionally icon-only with no text — the status is
/// only ever spelled out in words on the person's own detail screen.
/// Everywhere else in the app (cards, tree nodes, couple headers) only
/// this dot appears, positioned at the top-left corner of the person's
/// name via [NameWithStatus].
class StatusDot extends StatelessWidget {
  final PersonStatus status;
  final double size;

  const StatusDot({super.key, required this.status, this.size = 9});

  Color get _color {
    switch (status) {
      case PersonStatus.alive:
        return const Color(0xFF3FB562); // green
      case PersonStatus.deceased:
        return const Color(0xFF2A2A2A); // black
      case PersonStatus.martyr:
        return const Color(0xFFD4AF37); // gold
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
    );
  }
}

/// Wraps a name [Text] (or any widget) with a [StatusDot] pinned to its
/// top-left corner, matching the requirement that status is shown as a
/// small dot at the top-left of the person's name wherever it appears.
class NameWithStatus extends StatelessWidget {
  final Widget child;
  final PersonStatus status;

  const NameWithStatus({super.key, required this.child, required this.status});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          // Reserve a little space so the dot doesn't overlap the glyphs.
          padding: const EdgeInsets.only(top: 3),
          child: child,
        ),
        Positioned(
          top: -1,
          left: -1,
          child: StatusDot(status: status),
        ),
      ],
    );
  }
}
