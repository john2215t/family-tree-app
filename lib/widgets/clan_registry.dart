import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import 'person_screen.dart';

/// App-wide registry of all loaded clans (main + side clans), looked up by
/// [FamilyRepository.clanKey]. Provided above [HomeScreen]; screens use
/// [ClanRegistry.of] to resolve cross-clan person references.
class ClanRegistry extends InheritedWidget {
  final Map<String, FamilyRepository> clans;

  const ClanRegistry({
    super.key,
    required this.clans,
    required super.child,
  });

  static ClanRegistry? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClanRegistry>();

  /// Resolves a cross-clan reference to the target repository, if the
  /// referenced clan is loaded.
  FamilyRepository? resolve(CrossClanRef ref) => clans[ref.clan];

  @override
  bool updateShouldNotify(ClanRegistry oldWidget) =>
      oldWidget.clans != clans;
}

/// Opens a person's profile, transparently following a cross-clan
/// reference: if [repository] declares [personId] as the same person in
/// another clan, the profile opens in THAT clan instead (so spouses that
/// belong to the other خاندان land in their own tree).
void openPersonResolvingCrossRef(
  BuildContext context,
  FamilyRepository repository,
  String personId,
) {
  final registry = ClanRegistry.of(context);
  final ref = repository.crossRefFor(personId);
  if (registry != null && ref != null) {
    final target = registry.resolve(ref);
    if (target != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonScreen(repository: target, personId: ref.id),
        ),
      );
      return;
    }
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PersonScreen(repository: repository, personId: personId),
    ),
  );
}
