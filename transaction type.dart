import 'package:json_annotation/json_annotation.dart';

/// Tipologia di una transazione.
///
/// Distinzione fondamentale richiesta dal brief:
/// - [income] e [expense] influenzano il saldo mensile (entrate/uscite).
/// - [atmWithdrawal] sposta denaro dal conto al cash: NON è un'uscita,
///   alimenta solo la voce "Cash" senza essere conteggiata tra le spese.
/// - [transfer] sposta denaro tra due conti dell'utente: NON è né entrata
///   né uscita, è solo una riorganizzazione interna.
/// - [investmentIn] sposta denaro dal conto al portafoglio investimenti:
///   NON è un'uscita, è un trasferimento patrimoniale.
/// - [investmentOut] è un disinvestimento: il denaro torna su un conto.
@JsonEnum()
enum TransactionType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
  @JsonValue('atm_withdrawal')
  atmWithdrawal,
  @JsonValue('transfer')
  transfer,
  @JsonValue('investment_in')
  investmentIn,
  @JsonValue('investment_out')
  investmentOut,
}

extension TransactionTypeX on TransactionType {
  /// Indica se la transazione partecipa al calcolo del saldo mensile
  /// (entrate - uscite). Trasferimenti, prelievi e movimenti su investimenti
  /// NON partecipano.
  bool get affectsMonthlyBalance =>
      this == TransactionType.income || this == TransactionType.expense;

  /// Indica se la transazione è un'uscita reale (spesa).
  bool get isExpense => this == TransactionType.expense;

  /// Indica se la transazione è un'entrata reale.
  bool get isIncome => this == TransactionType.income;
}
