/// Statut d'un chargement camion.
enum ChargementStatus { actif, pause, termine }

extension ChargementStatusX on ChargementStatus {
  String get dbValue => switch (this) {
    ChargementStatus.actif => 'actif',
    ChargementStatus.pause => 'pause',
    ChargementStatus.termine => 'termine',
  };

  static ChargementStatus fromDb(String v) => switch (v) {
    'pause' => ChargementStatus.pause,
    'termine' => ChargementStatus.termine,
    _ => ChargementStatus.actif,
  };
}

/// Un chargement camion : session dans laquelle on ajoute des Big Bags.
/// À la fin, génère un bon d'expédition (numéro, date, etc.).
class Chargement {
  final int id;
  final String client;
  final String? camion;
  final String? chauffeur;
  final ChargementStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;
  final String? bonNumero; // ex: BE-2026-0001

  const Chargement({
    required this.id,
    required this.client,
    this.camion,
    this.chauffeur,
    required this.status,
    required this.createdAt,
    this.closedAt,
    this.bonNumero,
  });

  Chargement copyWith({
    ChargementStatus? status,
    DateTime? closedAt,
    String? bonNumero,
  }) {
    return Chargement(
      id: id,
      client: client,
      camion: camion,
      chauffeur: chauffeur,
      status: status ?? this.status,
      createdAt: createdAt,
      closedAt: closedAt ?? this.closedAt,
      bonNumero: bonNumero ?? this.bonNumero,
    );
  }

  factory Chargement.fromMap(Map<String, Object?> m) {
    return Chargement(
      id: m['id'] as int,
      client: m['client'] as String,
      camion: m['camion'] as String?,
      chauffeur: m['chauffeur'] as String?,
      status: ChargementStatusX.fromDb(m['status'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
      closedAt: m['closed_at'] != null
          ? DateTime.parse(m['closed_at'] as String)
          : null,
      bonNumero: m['bon_numero'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'client': client,
    'camion': camion,
    'chauffeur': chauffeur,
    'status': status.dbValue,
    'created_at': createdAt.toIso8601String(),
    'closed_at': closedAt?.toIso8601String(),
    'bon_numero': bonNumero,
  };

  static String padBon(int n) =>
      'BE-${DateTime.now().year}-${n.toString().padLeft(4, '0')}';
}
