/// Represents a marriage/parental unit: a husband, an (optional) wife, and
/// their children — all referenced purely by [Person] id.
///
/// Storing relationships by id (rather than nesting full [Person] objects)
/// is what allows the same person to be shared across several families,
/// which is essential for handling in-laws and multi-branch relatives.
class Family {
  final String id;
  final String husbandId;
  final String? wifeId;
  final List<String> childrenIds;

  const Family({
    required this.id,
    required this.husbandId,
    this.wifeId,
    this.childrenIds = const [],
  });

  factory Family.fromJson(String id, Map<String, dynamic> json) {
    return Family(
      id: id,
      husbandId: json['husbandId'] as String,
      wifeId: json['wifeId'] as String?,
      childrenIds: (json['childrenIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  bool get hasSpouse => wifeId != null;

  bool get hasChildren => childrenIds.isNotEmpty;

  /// True if [personId] is either the husband or the wife of this family.
  bool includesSpouse(String personId) =>
      husbandId == personId || wifeId == personId;
}
