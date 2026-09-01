import 'person.dart';
import 'family.dart';

/// A fully-resolved view of a couple (husband + optional wife) together
/// with the [Family] record that ties them together. This is a *derived*
/// convenience object built by the repository at query time — it does not
/// introduce any new stored data, it just bundles resolved [Person]
/// references for easy use in the UI (headers, breadcrumbs, cards).
class CoupleUnit {
  final Family family;
  final Person husband;
  final Person? wife;

  const CoupleUnit({
    required this.family,
    required this.husband,
    this.wife,
  });

  /// Display label, e.g. "علی رضایی + سارا کریمی" or just "حسن رضایی"
  /// when there is no spouse.
  String get displayName =>
      wife != null ? '${husband.fullName} + ${wife!.fullName}' : husband.fullName;
}

/// A fully-resolved bundle of everything relevant to a single [Person]:
/// their spouse, their birth parents, and their children. Used by the
/// person detail screen. Also purely derived — built from ids, not stored.
class PersonRelations {
  final Person person;
  final Person? spouse;
  final CoupleUnit? parents;
  final List<Person> children;

  /// The family in which [person] is a spouse (husband or wife), if any.
  /// Needed so the UI can navigate to "this person's own family" (i.e. the
  /// family they started), as opposed to [parents] (the family they were
  /// born into).
  final Family? ownFamily;

  const PersonRelations({
    required this.person,
    this.spouse,
    this.parents,
    this.children = const [],
    this.ownFamily,
  });
}
