import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'transaction_type.dart';

part 'transaction.g.dart';

/// Rappresenta una singola transazione finanziaria.
///
/// L'unità atomica di tutto il sistema. Ogni operazione dell'utente
/// (entrata, uscita, prelievo, trasferimento, investimento) genera una
/// o più transazioni di questo tipo.
///
/// Casi d'uso:
/// - Entrata su conto: type=income, accountId=conto destinazione
/// - Entrata cash: type=income, accountId=conto cash
/// - Entrata su entrambi: due transazioni separate
/// - Uscita: type=expense, accountId=conto su cui è stata fatta la spesa
/// - Prelievo ATM: type=atmWithdrawal, fromAccountId=conto, toAccountId=cash
/// - Trasferimento: type=transfer, fromAccountId e toAccountId
/// - Investimento in entrata: type=investmentIn, fromAccountId=conto,
///   investmentId=investimento destinazione
/// - Disinvestimento: type=investmentOut, investmentId=fonte,
///   toAccountId=conto destinazione
@JsonSerializable()
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.categoryId,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.investmentId,
    this.description,
    this.note,
    this.relatedRoutineId,
    this.relatedScheduledExpenseId,
    this.relatedGoalId,
  });

  final String id;
  final TransactionType type;

  /// Importo assoluto (sempre positivo). Il segno è dato dal [type].
  final double amount;

  /// Data effettiva dell'operazione (può differire dalla creazione,
  /// es. spese programmate inserite il giorno di scadenza).
  final DateTime date;

  /// Timestamp di creazione del record nel sistema.
  final DateTime createdAt;

  final String? categoryId;

  /// Conto coinvolto per income/expense.
  final String? accountId;

  /// Conto di partenza per transfer, atmWithdrawal, investmentIn.
  final String? fromAccountId;

  /// Conto di arrivo per transfer, atmWithdrawal, investmentOut.
  final String? toAccountId;

  /// Investimento coinvolto per investmentIn/investmentOut.
  final String? investmentId;

  /// Descrizione breve mostrata in lista.
  final String? description;

  /// Note aggiuntive libere.
  final String? note;

  /// ID della routine che ha generato questa transazione (se applicabile).
  final String? relatedRoutineId;

  /// ID della spesa programmata che ha generato questa transazione.
  final String? relatedScheduledExpenseId;

  /// ID dell'obiettivo a cui è collegata (es. accantonamento).
  final String? relatedGoalId;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    DateTime? date,
    DateTime? createdAt,
    String? categoryId,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    String? investmentId,
    String? description,
    String? note,
    String? relatedRoutineId,
    String? relatedScheduledExpenseId,
    String? relatedGoalId,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      investmentId: investmentId ?? this.investmentId,
      description: description ?? this.description,
      note: note ?? this.note,
      relatedRoutineId: relatedRoutineId ?? this.relatedRoutineId,
      relatedScheduledExpenseId:
          relatedScheduledExpenseId ?? this.relatedScheduledExpenseId,
      relatedGoalId: relatedGoalId ?? this.relatedGoalId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        date,
        createdAt,
        categoryId,
        accountId,
        fromAccountId,
        toAccountId,
        investmentId,
        description,
        note,
        relatedRoutineId,
        relatedScheduledExpenseId,
        relatedGoalId,
      ];
}
