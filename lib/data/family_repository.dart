import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/person.dart';
import '../models/family.dart';
import '../models/relationship.dart';

/// Loads family-tree data from the bundled JSON asset and exposes typed,
/// id-based query methods.
///
/// This is the single source of truth for family data in the app. All
/// screens read through this repository — nothing is ever hard-coded in a
/// widget. The underlying model is effectively a small graph (people +
/// families referencing people by id), even though the UI walks it as a
/// step-by-step hierarchy.
///
/// The [title] and [rootFamilyId] are exposed as instance fields so that,
/// in the future, the app can hold more than one loaded "خاندان" (clan)
/// without changing this class's shape.
class FamilyRepository {
  final String title;
  final String rootFamilyId;
  final Map<String, Person> _peopleById;
  final Map<String, Family> _familiesById;

  FamilyRepository._({
    required this.title,
    required this.rootFamilyId,
    required Map<String, Person> peopleById,
    required Map<String, Family> familiesById,
  })  : _peopleById = peopleById,
        _familiesById = familiesById;

  /// Loads and parses the default clan data from
  /// `assets/data/family.json`. In the future this could take an asset
  /// path parameter to support loading additional clans.
  static Future<FamilyRepository> loadDefault() async {
    final raw = await rootBundle.loadString('assets/data/family.json');
    return FamilyRepository.fromJsonString(raw);
  }

  /// Parses clan data from a raw JSON string. Split out from [loadDefault]
  /// so the parsing/query logic can be unit-tested without needing Flutter's
  /// asset bundle.
  factory FamilyRepository.fromJsonString(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    final peopleJson = json['people'] as List<dynamic>;
    final Map<String, Person> people = {
      for (final p in peopleJson)
        (p as Map<String, dynamic>)['id'] as String: Person.fromJson(p),
    };

    final familiesJson = json['families'] as Map<String, dynamic>;
    final Map<String, Family> families = {
      for (final entry in familiesJson.entries)
        entry.key: Family.fromJson(entry.key, entry.value as Map<String, dynamic>),
    };

    return FamilyRepository._(
      title: json['title'] as String,
      rootFamilyId: json['rootFamilyId'] as String,
      peopleById: people,
      familiesById: families,
    );
  }

  // ---- Basic lookups -------------------------------------------------

  Person? getPerson(String id) => _peopleById[id];

  Family? getFamily(String id) => _familiesById[id];

  /// All people in the clan, in stored order (used for status-filtered
  /// lists on the home screen).
  List<Person> get allPeople => _peopleById.values.toList(growable: false);

  /// All people with the given life status, sorted by full name.
  List<Person> peopleWithStatus(PersonStatus status) {
    final result =
        _peopleById.values.where((p) => p.status == status).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return result;
  }

  /// Resolves a [Family] into a display-ready [CoupleUnit]. Returns null
  /// if the family or husband cannot be found (defensive against bad data).
  CoupleUnit? resolveCouple(String familyId) {
    final family = _familiesById[familyId];
    if (family == null) return null;
    final husband = _peopleById[family.husbandId];
    if (husband == null) return null;
    final wife = family.wifeId != null ? _peopleById[family.wifeId] : null;
    return CoupleUnit(family: family, husband: husband, wife: wife);
  }

  /// Children of a family, resolved to [Person] objects, in stored order.
  List<Person> childrenOf(String familyId) {
    final family = _familiesById[familyId];
    if (family == null) return [];
    return family.childrenIds
        .map((id) => _peopleById[id])
        .whereType<Person>()
        .toList();
  }

  // ---- Relationship graph traversal -----------------------------------

  /// Finds the family in which [personId] is a *child* — i.e. their birth
  /// family / where their own parents are. Returns null for the founding
  /// ancestor(s), who have no recorded parents.
  Family? findBirthFamily(String personId) {
    for (final family in _familiesById.values) {
      if (family.childrenIds.contains(personId)) return family;
    }
    return null;
  }

  /// Finds the family in which [personId] is a spouse (husband or wife) —
  /// i.e. the family they started with their partner and children, if any.
  Family? findOwnFamily(String personId) {
    for (final family in _familiesById.values) {
      if (family.includesSpouse(personId)) return family;
    }
    return null;
  }

  /// Builds the fully-resolved relationship bundle for a person, used by
  /// the person-detail screen.
  PersonRelations relationsFor(String personId) {
    final person = _peopleById[personId];
    if (person == null) {
      throw ArgumentError('Unknown person id: $personId');
    }

    final ownFamily = findOwnFamily(personId);
    Person? spouse;
    List<Person> children = const [];
    if (ownFamily != null) {
      final spouseId =
          ownFamily.husbandId == personId ? ownFamily.wifeId : ownFamily.husbandId;
      spouse = spouseId != null ? _peopleById[spouseId] : null;
      children = childrenOf(ownFamily.id);
    }

    final birthFamily = findBirthFamily(personId);
    final parents = birthFamily != null ? resolveCouple(birthFamily.id) : null;

    return PersonRelations(
      person: person,
      spouse: spouse,
      parents: parents,
      children: children,
      ownFamily: ownFamily,
    );
  }

  /// Builds the ancestry path (as a list of family ids, root-first) leading
  /// down to [familyId], by walking up through the *husband's* birth family
  /// at each step until no further birth family is recorded (i.e. the
  /// founding ancestor is reached).
  ///
  /// This is what powers "مشاهده در خانواده اصلی": given any family
  /// (typically one a person married into), it reconstructs the full
  /// breadcrumb path from the root of the tree down to that family, purely
  /// from the id-based relationships — no data is duplicated to make this
  /// possible.
  List<String> buildPathToFamily(String familyId) {
    final path = <String>[];
    String? currentId = familyId;
    final visited = <String>{};
    while (currentId != null && visited.add(currentId)) {
      path.insert(0, currentId);
      final family = _familiesById[currentId];
      if (family == null) break;
      final husbandBirthFamily = findBirthFamily(family.husbandId);
      currentId = husbandBirthFamily?.id;
    }
    return path;
  }

  /// Builds the paternal lineage chain of [personId]: the father, paternal
  /// grandfather, paternal great-grandfather, … up to the founding
  /// ancestor (سرسلسله). Each entry is a [Person]; the chain is returned
  /// nearest-first (پدر اول، بعد پدربزرگ، …). Empty for the founding
  /// ancestor himself.
  ///
  /// The walk follows each generation's *birth family* (where the person
  /// is recorded as a child) and takes its husband as the paternal
  /// ancestor — matching the patrilineal convention used throughout the
  /// app. A visited-set guards against cycles in malformed data.
  List<Person> paternalLineage(String personId) {
    final chain = <Person>[];
    final visited = <String>{personId};
    String? currentId = personId;
    while (currentId != null) {
      final birthFamily = findBirthFamily(currentId);
      if (birthFamily == null) break;
      final father = _peopleById[birthFamily.husbandId];
      if (father == null || !visited.add(father.id)) break;
      chain.add(father);
      currentId = father.id;
    }
    return chain;
  }

  /// One-line rendering of [paternalLineage], e.g.
  /// «محمد رفسنجانی › علی رفسنجانی › یوسف رفسنجانی (سرسلسله)».
  /// Returns an empty string for the founding ancestor.
  String paternalLineageText(String personId) {
    final chain = paternalLineage(personId);
    if (chain.isEmpty) return '';
    final names = [
      for (var i = 0; i < chain.length; i++)
        i == chain.length - 1
            ? '${chain[i].fullName} (سرسلسله)'
            : chain[i].fullName,
    ];
    return names.join(' › ');
  }

  // ---- Search -----------------------------------------------------------

  /// Searches people by first name, last name, or full name (case- and
  /// diacritic-insensitive is not needed for Persian input as typed, so a
  /// simple substring match is used).
  List<Person> searchPeople(String query) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    return _peopleById.values.where((p) {
      return p.firstName.contains(q) ||
          p.lastName.contains(q) ||
          p.fullName.contains(q);
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  // ---- Statistics ---------------------------------------------------------

  /// Total number of people recorded anywhere in the clan.
  int get totalPeopleCount => _peopleById.length;

  /// Counts of people by life status, for the whole clan (زنده / فوت‌کرده /
  /// شهید), used by the home screen's overview stats.
  Map<PersonStatus, int> get statusCounts {
    final counts = {for (final s in PersonStatus.values) s: 0};
    for (final p in _peopleById.values) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Counts descendants of [familyId] generation by generation, starting
  /// from that family's own children (generation 0) down through
  /// grandchildren (نوه), great-grandchildren (نتیجه),
  /// great-great-grandchildren (نبیره), and great-great-great-grandchildren
  /// (ندیده) — i.e. up to 5 generations below the family's couple.
  ///
  /// Returns exactly 5 entries (index 0 = children, 1 = نوه, 2 = نتیجه,
  /// 3 = نبیره, 4 = ندیده); a generation with no members simply has a
  /// count of 0, and traversal stops naturally since later generations
  /// will also be empty.
  List<int> descendantGenerationCounts(String familyId) {
    const generationLabels = 5;
    final counts = List<int>.filled(generationLabels, 0);
    List<Person> currentGeneration = childrenOf(familyId);
    for (var gen = 0; gen < generationLabels; gen++) {
      counts[gen] = currentGeneration.length;
      if (currentGeneration.isEmpty) break;
      final nextGeneration = <Person>[];
      for (final person in currentGeneration) {
        final ownFamily = findOwnFamily(person.id);
        if (ownFamily != null) {
          nextGeneration.addAll(childrenOf(ownFamily.id));
        }
      }
      currentGeneration = nextGeneration;
    }
    return counts;
  }

  /// Returns the people of each descendant generation of [familyId] as
  /// resolved [Person] lists (index 0 = children, 1 = نوه, 2 = نتیجه,
  /// 3 = نبیره, 4 = ندیده) — the list-based counterpart of
  /// [descendantGenerationCounts], used to open a member list when the
  /// user taps a generation count.
  List<List<Person>> descendantGenerationPeople(String familyId) {
    const generationLabels = 5;
    final generations = List<List<Person>>.generate(
        generationLabels, (_) => <Person>[], growable: false);
    List<Person> currentGeneration = childrenOf(familyId);
    for (var gen = 0; gen < generationLabels; gen++) {
      generations[gen] = List.of(currentGeneration);
      if (currentGeneration.isEmpty) break;
      final nextGeneration = <Person>[];
      for (final person in currentGeneration) {
        final ownFamily = findOwnFamily(person.id);
        if (ownFamily != null) {
          nextGeneration.addAll(childrenOf(ownFamily.id));
        }
      }
      currentGeneration = nextGeneration;
    }
    return generations;
  }

  /// Persian labels for descendant generations, shared by the family and
  /// person screens. Index 0 = فرزند, 1 = نوه, 2 = نتیجه, 3 = نبیره,
  /// 4 = ندیده.
  static const descendantGenerationLabels = [
    'فرزند',
    'نوه',
    'نتیجه',
    'نبیره',
    'ندیده',
  ];
}
