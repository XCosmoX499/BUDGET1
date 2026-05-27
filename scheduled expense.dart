import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scheduled_expense.g.dart';

/// Stato di una spesa programmata.
@JsonEnum()
enum ScheduledExpenseStatus {
  /// In attesa: la data di scadenza non è ancora arrivata.
  @JsonValue('pending')
  pending,

  /// Eseguita: alla data di scadenza è stata generata la transazione di uscita.
  @JsonValue('executed')
  executed,

  /// Annullata dall'utente prima della scadenza.
  @JsonValue('cancelled')
  cancelled,
}

/// Spesa programmata nel futuro.
///
/// Esempio dal brief: bollo auto, assicurazione auto. L'utente sa già che
/// dovrà sostenere questa spesa e la registra in anticipo. L'app ricorda
/// quanti giorni mancano alla scadenza e, al momento giusto, genera
/// automaticamente la transazione di uscita.
@JsonSerializable()
class ScheduledExpense extends Equatable {
  const ScheduledExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.accountId,
    required this.categoryId,
    required this.status,
    required this.createdAt,
    this.executedTransactionId,
    this.note,
  });

  final String id;
  final String description;
  final double amount;

  /// Data in cui la spesa deve essere effettuata.
  final DateTime dueDate;

  final String accountId;
  final String categoryId;
  final ScheduledExpenseStatus status;
  final DateTime createdAt;

  /// ID della transazione generata al momento dell'esecuzione.
  /// Valorizzato solo quando [status] è [ScheduledExpenseStatus.executed].
  final String? executedTransactionId;

  final String? note;

  /// Giorni mancanti alla scadenza. Negativo se già scaduta.
  int daysUntilDue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  factory ScheduledExpense.fromJson(Map<String, dynamic> json) =>
      _$ScheduledExpenseFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduledExpenseToJson(this);

  ScheduledExpense copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? dueDate,
    String? accountId,
    String? categoryId,
    ScheduledExpenseStatus? status,
    DateTime? createdAt,
    String? executedTransactionId,
    String? note,
  }) {
    return ScheduledExpense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      executedTransactionId:
          executedTransactionId ?? this.executedTransactionId,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        dueDate,
        accountId,
        categoryId,
        status,
        createdAt,
        executedTransactionId,
        note,
      ];
}
