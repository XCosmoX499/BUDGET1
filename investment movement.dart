import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'investment_movement.g.dart';

/// Tipologia di movimento su un investimento.
@JsonEnum()
enum InvestmentMovementType {
  /// Versamento (PAC, accumulo, acquisto).
  @JsonValue('contribution')
  contribution,

  /// Disinvestimento (vendita, riscatto): il denaro torna su un conto.
  @JsonValue('withdrawal')
  withdrawal,

  /// Aggiustamento del valore corrente per riflettere plusvalenze
  /// (variazione di mercato senza versamenti).
  @JsonValue('gain')
  gain,

  /// Aggiustamento del valore corrente per riflettere minusvalenze.
  @JsonValue('loss')
  loss,
}

/// Singolo movimento storico su un investimento.
///
/// Permette di ricostruire l'andamento temporale del valore del portafoglio
/// e di mostrare lo "storico" richiesto nel brief.
@JsonSerializable()
class InvestmentMovement extends Equatable {
  const InvestmentMovement({
    required this.id,
    required this.investmentId,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.relatedAccountId,
    this.relatedTransactionId,
    this.note,
  });

  final String id;
  final String investmentId;
  final InvestmentMovementType type;

  /// Importo assoluto sempre positivo.
  final double amount;

  final DateTime date;
  final DateTime createdAt;

  /// Conto da cui sono arrivati (contribution) o verso cui sono andati
  /// (withdrawal) i fondi.
  final String? relatedAccountId;

  /// Transazione associata che ha spostato il denaro da/verso il conto.
  final String? relatedTransactionId;

  final String? note;

  factory InvestmentMovement.fromJson(Map<String, dynamic> json) =>
      _$InvestmentMovementFromJson(json);

  Map<String, dynamic> toJson() => _$InvestmentMovementToJson(this);

  InvestmentMovement copyWith({
    String? id,
    String? investmentId,
    InvestmentMovementType? type,
    double? amount,
    DateTime? date,
    DateTime? createdAt,
    String? relatedAccountId,
    String? relatedTransactionId,
    String? note,
  }) {
    return InvestmentMovement(
      id: id ?? this.id,
      investmentId: investmentId ?? this.investmentId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      relatedAccountId: relatedAccountId ?? this.relatedAccountId,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        investmentId,
        type,
        amount,
        date,
        createdAt,
        relatedAccountId,
        relatedTransactionId,
        note,
      ];
}
