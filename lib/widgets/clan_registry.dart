import 'package:flutter/material.dart';

import '../data/family_repository.dart';
import 'family_screen.dart';
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

/// Opens the family page of the clan that [ref] points to, at the family
/// where the linked person appears (their own family if they are a spouse/
/// parent there, otherwise their birth family). Falls back to the person's
/// profile when the person has no family in that clan.
void openCrossClanFamily(BuildContext context, CrossClanRef ref) {
  final registry = ClanRegistry.of(context);
  final target = registry?.resolve(ref);
  if (target == null) return;
  final familyId = target.findOwnFamily(ref.id)?.id ??
      target.findBirthFamily(ref.id)?.id;
  if (familyId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FamilyScreen(
          repository: target,
          path: [familyId],
        ),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonScreen(repository: target, personId: ref.id),
      ),
    );
  }
}
