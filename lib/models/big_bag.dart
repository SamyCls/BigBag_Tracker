/// Statut d'un Big Bag dans son cycle de vie.
enum BigBagStatus { stock, charge, expedie }

extension BigBagStatusX on BigBagStatus {
  String get dbValue => switch (this) {
    BigBagStatus.stock => 'stock',
    BigBagStatus.charge => 'charge',
    BigBagStatus.expedie => 'expedie',
  };

  static BigBagStatus fromDb(String v) => switch (v) {
    'charge' => BigBagStatus.charge,
    'expedie' => BigBagStatus.expedie,
    _ => BigBagStatus.stock,
  };

  String get label => switch (this) {
    BigBagStatus.stock => 'EN STOCK',
    BigBagStatus.charge => 'CHARGÉ',
    BigBagStatus.expedie => 'EXPÉDIÉ',
  };
}

/// Qualité (optionnelle) du PET produit.
enum Quality { clair, mixte, colore }

extension QualityX on Quality {
  String get dbValue => switch (this) {
    Quality.clair => 'clear',
    Quality.mixte => 'mixte',
    Quality.colore => 'colore',
  };

  static Quality fromDb(String? v) => switch (v) {
    'mixte' => Quality.mixte,
    'colore' => Quality.colore,
    _ => Quality.clair,
  };

  String get label => switch (this) {
    Quality.clair => 'Bleu clair',
    Quality.mixte => 'Mixte',
    Quality.colore => 'Coloré',
  };
}

/// Un Big Bag produit dans l'usine.
/// Tare fixe: 3 kg par Big Bag (voir cahier des charges).
class BigBag {
  static const int tareKg = 3;

  final int id; // clé numérique interne (correspond au compteur)
  final String code; // ex: BB-000001
  final double poidsBrut; // kg
  final Quality qualite;
  final BigBagStatus status;
  final DateTime createdAt;
  final int? chargementId;

  const BigBag({
    required this.id,
    required this.code,
    required this.poidsBrut,
    required this.qualite,
    required this.status,
    required this.createdAt,
    this.chargementId,
  });

  double get poidsNet => poidsBrut - tareKg;

  BigBag copyWith({
    BigBagStatus? status,
    int? chargementId,
    bool clearChargementId = false,
  }) {
    return BigBag(
      id: id,
      code: code,
      poidsBrut: poidsBrut,
      qualite: qualite,
      status: status ?? this.status,
      createdAt: createdAt,
      chargementId: clearChargementId
          ? null
          : (chargementId ?? this.chargementId),
    );
  }

  factory BigBag.fromMap(Map<String, Object?> m) {
    return BigBag(
      id: m['id'] as int,
      code: m['code'] as String,
      poidsBrut: (m['poids_brut'] as num).toDouble(),
      qualite: QualityX.fromDb(m['qualite'] as String?),
      status: BigBagStatusX.fromDb(m['status'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
      chargementId: m['chargement_id'] as int?,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'code': code,
    'poids_brut': poidsBrut,
    'qualite': qualite.dbValue,
    'status': status.dbValue,
    'created_at': createdAt.toIso8601String(),
    'chargement_id': chargementId,
  };

  static String padCode(int n) => 'BB-${n.toString().padLeft(6, '0')}';
}
