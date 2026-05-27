import 'package:equatable/equatable.dart';

/// Aggregato non persistito, calcolato al volo dal repository per popolare
/// la dashboard.
///
/// Riflette i dati principali richiesti nel brief:
/// - Patrimonio netto totale (conti + cash + investimenti)
/// - Saldo dei conti tradizionali
/// - Cash disponibile
/// - Valore corrente degli investimenti
/// - Saldo del mese (entrate - uscite)
/// - Totale entrate e uscite del mese
/// - Capitale investito nel mese corrente
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.referenceYear,
    required this.referenceMonth,
    required this.netWorth,
    required this.accountsBalance,
    required this.cashBalance,
    required this.investmentsValue,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthBalance,
    required this.monthIncomeCount,
    required this.monthExpenseCount,
    required this.monthInvestedAmount,
    required this.cashMonthMovements,
  });

  final int referenceYear;
  final int referenceMonth;

  /// Patrimonio netto: somma di tutti i conti, cash e investimenti.
  final double netWorth;

  /// Somma dei saldi dei conti non-cash.
  final double accountsBalance;

  /// Saldo del conto contante.
  final double cashBalance;

  /// Valore corrente totale degli investimenti.
  final double investmentsValue;

  /// Totale entrate del mese di riferimento.
  final double monthIncome;

  /// Totale uscite del mese di riferimento.
  final double monthExpense;

  /// Saldo del mese = monthIncome - monthExpense.
  final double monthBalance;

  /// Numero di entrate registrate nel mese.
  final int monthIncomeCount;

  /// Numero di uscite registrate nel mese.
  final int monthExpenseCount;

  /// Totale movimenti verso investimenti nel mese di riferimento.
  /// Non è conteggiato come uscita.
  final double monthInvestedAmount;

  /// Movimenti cash nel mese (prelievi e spese in contanti).
  final double cashMonthMovements;

  @override
  List<Object?> get props => [
        referenceYear,
        referenceMonth,
        netWorth,
        accountsBalance,
        cashBalance,
        investmentsValue,
        monthIncome,
        monthExpense,
        monthBalance,
        monthIncomeCount,
        monthExpenseCount,
        monthInvestedAmount,
        cashMonthMovements,
      ];
}
