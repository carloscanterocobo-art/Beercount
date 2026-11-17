class BeerType {
  final int id;
  final String name;
  final int volumeMl;
  final bool isBeer;

  const BeerType({
    required this.id,
    required this.name,
    required this.volumeMl,
    required this.isBeer,
  });

  factory BeerType.fromMap(Map<String, dynamic> map) {
    return BeerType(
      id: map['id'] as int,
      name: map['name'] as String,
      volumeMl: map['volume_ml'] as int,
      isBeer: (map['is_beer'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'volume_ml': volumeMl,
      'is_beer': isBeer ? 1 : 0,
    };
  }
}
