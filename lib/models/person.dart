/// Life status of a person. Kept separate from the rest of the profile
/// because it is displayed differently in different places: spelled out
/// as text only on the person's own detail screen, and everywhere else
/// (cards, tree nodes, couple headers) shown only as a small colored dot
/// next to the name — never as text — to keep list views uncluttered.
enum PersonStatus {
  /// زنده
  alive,

  /// فوت کرده
  deceased,

  /// شهید
  martyr;

  static PersonStatus fromJson(String? value) {
    switch (value) {
      case 'deceased':
        return PersonStatus.deceased;
      case 'martyr':
        return PersonStatus.martyr;
      case 'alive':
      default:
        return PersonStatus.alive;
    }
  }

  String toJson() => name;

  /// Text shown only on the person-detail screen.
  String get label {
    switch (this) {
      case PersonStatus.alive:
        return 'زنده';
      case PersonStatus.deceased:
        return 'فوت کرده';
      case PersonStatus.martyr:
        return 'شهید';
    }
  }
}

/// Represents a single individual in the family tree.
///
/// A [Person] is a pure data entity with a unique [id]. The same person
/// object is referenced (never duplicated) across every [Family] they
/// belong to — either as a child, a husband, or a wife. This is what makes
/// it possible for one person to appear in multiple branches of the tree
/// (e.g. as a child in their birth family and as a spouse in the family
/// they married into) without any data duplication.
class Person {
  final String id;
  final String firstName;
  final String lastName;

  /// Only the birth *year* is stored (Iranian/Shamsi calendar), never the
  /// full date. This field is optional.
  final int? birthYear;

  /// Life status (alive / deceased / martyr). Defaults to alive when not
  /// specified in the source data.
  final PersonStatus status;

  /// محل دفن (burial place) — only meaningful for deceased/martyr people.
  /// Empty string means "not recorded"; the UI hides it in that case.
  final String burialPlace;

  const Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.birthYear,
    this.status = PersonStatus.alive,
    this.burialPlace = '',
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthYear: json['birthYear'] as int?,
      status: PersonStatus.fromJson(json['status'] as String?),
      burialPlace: json['burialPlace'] as String? ?? '',
    );
  }

  /// Full display name, e.g. "علی رضایی". If no last name is recorded,
  /// only the first name is shown (some source records only have a given
  /// name).
  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';

  @override
  bool operator ==(Object other) => other is Person && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => fullName;
}
