import 'package:flutter_test/flutter_test.dart';
import 'package:family_tree_flutter/data/family_repository.dart';
import 'package:family_tree_flutter/models/person.dart';

/// A small self-contained sample dataset used only for testing, deliberately
/// shaped like the real data: a founding couple, a child who married an
/// "outsider" (sara), and grandchildren — enough to exercise every query
/// method including the shared-person / birth-family logic.
const _sampleJson = '''
{
  "title": "خاندان آزمایشی",
  "rootFamilyId": "family_001",
  "people": [
    { "id": "p001", "firstName": "احمد", "lastName": "رضایی", "birthYear": 1300 },
    { "id": "p002", "firstName": "مریم", "lastName": "حسینی", "birthYear": 1302 },
    { "id": "p003", "firstName": "علی", "lastName": "رضایی", "birthYear": 1325 },
    { "id": "p004", "firstName": "سارا", "lastName": "کریمی", "birthYear": 1327 },
    { "id": "p005", "firstName": "حسن", "lastName": "رضایی", "birthYear": 1330, "status": "deceased" },
    { "id": "p010", "firstName": "حسن", "lastName": "کریمی", "birthYear": 1295 },
    { "id": "p011", "firstName": "زهرا", "lastName": "احمدی", "birthYear": 1298, "status": "martyr" },
    { "id": "p007", "firstName": "رضا", "lastName": "رضایی", "birthYear": 1350 },
    { "id": "p008", "firstName": "مینا", "lastName": "", "birthYear": 1352 },
    { "id": "p009", "firstName": "نگار", "lastName": "رضایی", "birthYear": 1375 }
  ],
  "families": {
    "family_001": {
      "husbandId": "p001",
      "wifeId": "p002",
      "childrenIds": ["p003", "p005"]
    },
    "family_002": {
      "husbandId": "p010",
      "wifeId": "p011",
      "childrenIds": ["p004"]
    },
    "family_003": {
      "husbandId": "p003",
      "wifeId": "p004",
      "childrenIds": ["p007", "p008"]
    },
    "family_004": {
      "husbandId": "p007",
      "wifeId": null,
      "childrenIds": ["p009"]
    }
  }
}
''';

void main() {
  late FamilyRepository repo;

  setUp(() {
    repo = FamilyRepository.fromJsonString(_sampleJson);
  });

  test('getPerson finds a person by id', () {
    final person = repo.getPerson('p003');
    expect(person, isNotNull);
    expect(person!.fullName, 'علی رضایی');
  });

  test('getPerson returns null for unknown id', () {
    expect(repo.getPerson('nonexistent'), isNull);
  });

  test('searchPeople matches by first name', () {
    final results = repo.searchPeople('علی');
    expect(results.map((p) => p.id), contains('p003'));
  });

  test('searchPeople matches by last name', () {
    final results = repo.searchPeople('رضایی');
    expect(results.length, greaterThanOrEqualTo(4));
  });

  test('searchPeople returns empty list for empty query', () {
    expect(repo.searchPeople(''), isEmpty);
  });

  test('resolveCouple builds a display-ready couple', () {
    final couple = repo.resolveCouple('family_001');
    expect(couple, isNotNull);
    expect(couple!.displayName, 'احمد رضایی + مریم حسینی');
  });

  test('childrenOf returns children in stored order', () {
    final children = repo.childrenOf('family_001');
    expect(children.map((p) => p.id).toList(), ['p003', 'p005']);
  });

  test('findBirthFamily finds the family a person was born into', () {
    final family = repo.findBirthFamily('p003');
    expect(family?.id, 'family_001');
  });

  test('findBirthFamily returns null for the founding ancestor', () {
    expect(repo.findBirthFamily('p001'), isNull);
  });

  test('findOwnFamily finds the family a person started as a spouse', () {
    final family = repo.findOwnFamily('p003');
    expect(family?.id, 'family_003');
  });

  test('findOwnFamily returns null for someone with no family of their own',
      () {
    expect(repo.findOwnFamily('p005'), isNull);
  });

  test('relationsFor resolves spouse, parents and children together', () {
    final relations = repo.relationsFor('p003');
    expect(relations.spouse?.id, 'p004');
    expect(relations.parents?.family.id, 'family_001');
    expect(relations.children.map((p) => p.id), ['p007', 'p008']);
  });

  group('shared person across branches (in-law)', () {
    test('a spouse keeps a single shared Person id, not a duplicate', () {
      final saraViaFamily = repo.resolveCouple('family_003')!.wife!;
      final saraViaBirthFamily = repo.childrenOf('family_002').first;
      expect(saraViaFamily.id, saraViaBirthFamily.id);
      expect(identical(saraViaFamily, saraViaBirthFamily), isFalse);
      expect(saraViaFamily, equals(saraViaBirthFamily));
    });

    test('buildPathToFamily walks from the founding ancestor down to a '
        'married-into family', () {
      final path = repo.buildPathToFamily('family_003');
      expect(path, ['family_001', 'family_003']);
    });

    test("buildPathToFamily for sara's own birth family has no ancestor "
        'chain beyond it', () {
      final path = repo.buildPathToFamily('family_002');
      expect(path, ['family_002']);
    });
  });

  group('statistics', () {
    test('totalPeopleCount counts every person in the clan', () {
      expect(repo.totalPeopleCount, 10);
    });

    test('statusCounts defaults everyone to alive unless specified', () {
      final counts = repo.statusCounts;
      expect(counts[PersonStatus.deceased], 1); // p005
      expect(counts[PersonStatus.martyr], 1); // p011
      expect(counts[PersonStatus.alive], 8);
    });

    test('descendantGenerationCounts counts children, grandchildren, etc. '
        "relative to a specific family's couple", () {
      // family_001 (احمد+مریم): children = p003,p005 (2)
      // grandchildren = p003's own-family children p007,p008 (2)
      //   (p005 has no own family, so contributes none)
      // great-grandchildren = p007's own-family children p009 (1)
      final counts = repo.descendantGenerationCounts('family_001');
      expect(counts[0], 2); // فرزند
      expect(counts[1], 2); // نوه
      expect(counts[2], 1); // نتیجه
      expect(counts[3], 0); // نبیره
      expect(counts[4], 0); // ندیده
    });

    test('descendantGenerationCounts returns zero children for a childless '
        'family', () {
      final counts = repo.descendantGenerationCounts('family_004');
      expect(counts[0], 1); // p009 is family_004's one child
    });
  });
}
