import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine.g.dart';

/// Frequenza di ricorrenza di una routine.
@JsonEnum()
enum RoutineFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('yearly')
  yearly,
}

/// Tipo di movimento della routine: può essere un'uscita ricorrente
/// (affitto, abbonamenti) o un'entrata ricorrente (stipendio).
@JsonEnum()
enum RoutineKind {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

/// Spesa o entrata ricorrente programmata.
///
/// Esempio dal brief: l'affitto di casa che si ripete ogni mese allo stesso
/// modo. Quando arriva il giorno di scadenza, viene generata automaticamente
/// una transazione che decurta/aggiunge il saldo del conto specificato.
@JsonSerializable()
class Routine extends Equatable {
  const Routine({
    required this.id,
    required this.description,
    required this.amount,
    required this.kind,
    required this.frequency,
    required this.dayOfMonth,
    required this.startDate,
    required this.accountId,
    required this.categoryId,
    required this.isActive,
    required this.createdAt,
    this.endDate,
    this.lastExecutionDate,
    this.note,
  });

  final String id;
  final String description;
  final double amount;
  final RoutineKind kind;
  final RoutineFrequency frequency;

  /// Giorno del mese (1-31) per ricorrenze mensili.
  /// Per altri tipi di frequenza viene ignorato.
  final int dayOfMonth;

  final DateTime startDate;

  /// Data di fine ricorrenza opzionale.
  final DateTime? endDate;

  /// Ultima data in cui è stata generata una transazione da questa routine.
  /// Serve a evitare doppie esecuzioni.
  final DateTime? lastExecutionDate;

  final String accountId;
  final String categoryId;

  /// Se false, la routine è sospesa e non genera transazioni.
  final bool isActive;

  final DateTime createdAt;
  final String? note;

  factory Routine.fromJson(Map<String, dynamic> json) =>
      _$RoutineFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineToJson(this);

  Routine copyWith({
    String? id,
    String? description,
    double? amount,
    RoutineKind? kind,
    RoutineFrequency? frequency,
    int? dayOfMonth,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastExecutionDate,
    String? accountId,
    String? categoryId,
    bool? isActive,
    DateTime? createdAt,
    String? note,
  }) {
    return Routine(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastExecutionDate: lastExecutionDate ?? this.lastExecutionDate,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        kind,
        frequency,
        dayOfMonth,
        startDate,
        endDate,
        lastExecutionDate,
        accountId,
        categoryId,
        isActive,
        createdAt,
        note,
      ];
}
