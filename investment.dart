import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'investment.g.dart';

/// Tipo di investimento. L'utente può scegliere tra i predefiniti o crearne
/// uno custom.
@JsonEnum()
enum InvestmentType {
  @JsonValue('pac_etf')
  pacEtf,
  @JsonValue('pension_fund')
  pensionFund,
  @JsonValue('stocks')
  stocks,
  @JsonValue('crypto')
  crypto,
  @JsonValue('bonds')
  bonds,
  @JsonValue('other')
  other,
}

/// Rappresenta una categoria di investimento dell'utente.
///
/// Es. "PAC ETF MSCI World", "Fondo Pensione XYZ", "Bitcoin", ecc.
///
/// Il [currentValue] è il valore corrente del portafoglio per questa categoria,
/// aggiornato dai movimenti (versamenti, disinvestimenti, plus/minusvalenze).
/// [totalInvested] è il capitale netto versato (utile per calcolare il
/// rendimento).
@JsonSerializable()
class Investment extends Equatable {
  const Investment({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.currentValue,
    required this.totalInvested,
    required this.colorHex,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String name;
  final String emoji;
  final InvestmentType type;

  /// Valore attuale del portafoglio (somma versamenti +/- variazioni).
  final double currentValue;

  /// Capitale netto effettivamente versato dall'utente (al netto dei
  /// disinvestimenti). Serve per calcolare plus/minusvalenza.
  final double totalInvested;

  final String colorHex;
  final DateTime createdAt;
  final String? note;

  /// Plus o minusvalenza: differenza tra valore attuale e capitale versato.
  double get profitLoss => currentValue - totalInvested;

  /// Percentuale di rendimento.
  double get profitLossPercentage {
    if (totalInvested == 0) return 0;
    return (profitLoss / totalInvested) * 100;
  }

  factory Investment.fromJson(Map<String, dynamic> json) =>
      _$InvestmentFromJson(json);

  Map<String, dynamic> toJson() => _$InvestmentToJson(this);

  Investment copyWith({
    String? id,
    String? name,
    String? emoji,
    InvestmentType? type,
    double? currentValue,
    double? totalInvested,
    String? colorHex,
    DateTime? createdAt,
    String? note,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      currentValue: currentValue ?? this.currentValue,
      totalInvested: totalInvested ?? this.totalInvested,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        emoji,
        type,
        currentValue,
        totalInvested,
        colorHex,
        createdAt,
        note,
      ];
}
