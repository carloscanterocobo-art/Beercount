class Consumption {
  final int? id;
  final int beerTypeId;
  final DateTime dateTime;
  final int? priceCents;

  const Consumption({
    this.id,
    required this.beerTypeId,
    required this.dateTime,
    this.priceCents,
  });

  /// Convierte una consumición en un mapa para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'beer_type_id': beerTypeId,
      'date_time': dateTime.toIso8601String(),
      'price_cents': priceCents,
    };
  }

  /// Construye una consumición a partir de un registro de SQLite.
  factory Consumption.fromMap(Map<String, dynamic> map) {
    return Consumption(
      id: map['id'] as int?,
      beerTypeId: map['beer_type_id'] as int,
      dateTime: DateTime.parse(map['date_time'] as String),
      priceCents: map['price_cents'] as int?,
    );
  }

  /// Crea una copia con los campos indicados modificados.
  Consumption copyWith({
    int? id,
    int? beerTypeId,
    DateTime? dateTime,
    int? priceCents,
    bool clearPrice = false,
  }) {
    return Consumption(
      id: id ?? this.id,
      beerTypeId: beerTypeId ?? this.beerTypeId,
      dateTime: dateTime ?? this.dateTime,
      priceCents: clearPrice ? null : (priceCents ?? this.priceCents),
    );
  }
}
