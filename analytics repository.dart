import 'package:logger/logger.dart';

import '../model/category_expense_stat.dart';
import '../model/dashboard_summary.dart';
import '../model/monthly_saving.dart';
import '../model/transaction.dart';
import '../model/transaction_type.dart';
import '../utils/date_utils.dart';
import 'accounts_repository.dart';
import 'categories_repository.dart';
import 'investments_repository.dart';
import 'transactions_repository.dart';

/// Repository di sola lettura che calcola aggregati per dashboard e analytics.
///
/// Non persiste nulla: legge dagli altri repository e combina i dati al
/// volo. Per dataset molto grandi si potrà aggiungere caching, ma allo
/// stato attuale (volumi tipici di un'app personale) il calcolo on-demand
/// è ampiamente accettabile in termini di performance.
class AnalyticsRepository {
  AnalyticsRepository({
    required Logger logger,
    required AccountsRepository accountsRepository,
    required TransactionsRepository transactionsRepository,
    required InvestmentsRepository investmentsRepository,
    required CategoriesRepository categoriesRepository,
  })  : _logger = logger,
        _accountsRepository = accountsRepository,
        _transactionsRepository = transactionsRepository,
        _investmentsRepository = investmentsRepository,
        _categoriesRepository = categoriesRepository;

  final Logger _logger;
  final AccountsRepository _accountsRepository;
  final TransactionsRepository _transactionsRepository;
  final InvestmentsRepository _investmentsRepository;
  final CategoriesRepository _categoriesRepository;

  /// Calcola il summary completo della dashboard per un mese di riferimento.
  Future<DashboardSummary> buildDashboardSummary({
    required int year,
    required int month,
  }) async {
    try {
      final accounts = await _accountsRepository.getAll();
      final investments = await _investmentsRepository.getAll();
      final monthTxs = await _transactionsRepository.getByMonth(year, month);

      final cashBalance =
          accounts.where((a) => a.isCash).fold<double>(0, (s, a) => s + a.balance);
      final accountsBalance = accounts
          .where((a) => !a.isCash)
          .fold<double>(0, (s, a) => s + a.balance);
      final investmentsValue =
          investments.fold<double>(0, (s, i) => s + i.currentValue);
      final netWorth = accountsBalance + cashBalance + investmentsValue;

      final monthIncome = monthTxs
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (s, t) => s + t.amount);
      final monthExpense = monthTxs
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (s, t) => s + t.amount);
      final monthIncomeCount =
          monthTxs.where((t) => t.type == TransactionType.income).length;
      final monthExpenseCount =
          monthTxs.where((t) => t.type == TransactionType.expense).length;
      final monthInvested = monthTxs
          .where((t) => t.type == TransactionType.investmentIn)
          .fold<double>(0, (s, t) => s + t.amount);

      // Movimenti cash del mese = entrate cash + uscite cash + prelievi atm.
      final cashAccount = accounts.where((a) => a.isCash).firstOrNull;
      final cashMovements = cashAccount == null
          ? 0.0
          : monthTxs
              .where((t) =>
                  t.accountId == cashAccount.id ||
                  t.fromAccountId == cashAccount.id ||
                  t.toAccountId == cashAccount.id)
              .fold<double>(0, (s, t) => s + t.amount);

      return DashboardSummary(
        referenceYear: year,
        referenceMonth: month,
        netWorth: netWorth,
        accountsBalance: accountsBalance,
        cashBalance: cashBalance,
        investmentsValue: investmentsValue,
        monthIncome: monthIncome,
        monthExpense: monthExpense,
        monthBalance: monthIncome - monthExpense,
        monthIncomeCount: monthIncomeCount,
        monthExpenseCount: monthExpenseCount,
        monthInvestedAmount: monthInvested,
        cashMonthMovements: cashMovements,
      );
    } catch (e, st) {
      _logger.e('AnalyticsRepository.buildDashboardSummary failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Statistiche di uscita per categoria, ordinate per importo decrescente.
  /// Usato per il grafico a ciambella.
  Future<List<CategoryExpenseStat>> getExpensesByCategory({
    required int year,
    required int month,
  }) async {
    try {
      final txs = await _transactionsRepository.getByMonth(year, month);
      final expenses =
          txs.where((t) => t.type == TransactionType.expense).toList();

      final totals = <String, double>{};
      final counts = <String, int>{};
      for (final t in expenses) {
        final cat = t.categoryId ?? 'unknown';
        totals[cat] = (totals[cat] ?? 0) + t.amount;
        counts[cat] = (counts[cat] ?? 0) + 1;
      }

      final grandTotal = totals.values.fold<double>(0, (s, v) => s + v);
      final categories = await _categoriesRepository.getAll();

      final stats = <CategoryExpenseStat>[];
      for (final entry in totals.entries) {
        final cat = categories.where((c) => c.id == entry.key).firstOrNull;
        stats.add(CategoryExpenseStat(
          categoryId: entry.key,
          categoryNameKey: cat?.nameKey ?? 'categoryOtherExpense',
          emoji: cat?.emoji ?? '📦',
          totalAmount: entry.value,
          transactionCount: counts[entry.key] ?? 0,
          percentage: grandTotal == 0 ? 0 : (entry.value / grandTotal) * 100,
        ));
      }

      stats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return stats;
    } catch (e, st) {
      _logger.e('AnalyticsRepository.getExpensesByCategory failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Risparmio netto per ognuno degli ultimi [count] mesi.
  /// Usato per il grafico storico dei risparmi.
  Future<List<MonthlySaving>> getRecentSavingsHistory({
    int count = 12,
    int? endYear,
    int? endMonth,
  }) async {
    try {
      final now = AppDateUtils.currentMonth();
      final ey = endYear ?? now.year;
      final em = endMonth ?? now.month;
      final months = AppDateUtils.lastNMonths(count, ey, em);
      final allTxs = await _transactionsRepository.getAll();

      return months.map((m) {
        final monthTxs =
            allTxs.where((t) => AppDateUtils.isInMonth(t.date, m.year, m.month));
        final income = monthTxs
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0, (s, t) => s + t.amount);
        final expense = monthTxs
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0, (s, t) => s + t.amount);

        return MonthlySaving(
          id: '${m.year}-${m.month.toString().padLeft(2, '0')}',
          year: m.year,
          month: m.month,
          totalIncome: income,
          totalExpense: expense,
          netSaving: income - expense,
          computedAt: DateTime.now(),
        );
      }).toList();
    } catch (e, st) {
      _logger.e('AnalyticsRepository.getRecentSavingsHistory failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Importo investito mese per mese (utile per il grafico investimenti).
  Future<List<({int year, int month, double amount})>>
      getMonthlyInvestmentFlow({
    int count = 12,
    int? endYear,
    int? endMonth,
  }) async {
    try {
      final now = AppDateUtils.currentMonth();
      final ey = endYear ?? now.year;
      final em = endMonth ?? now.month;
      final months = AppDateUtils.lastNMonths(count, ey, em);
      final allTxs = await _transactionsRepository.getAll();

      return months.map((m) {
        final amount = allTxs
            .where((t) =>
                t.type == TransactionType.investmentIn &&
                AppDateUtils.isInMonth(t.date, m.year, m.month))
            .fold<double>(0, (s, t) => s + t.amount);
        return (year: m.year, month: m.month, amount: amount);
      }).toList();
    } catch (e, st) {
      _logger.e('AnalyticsRepository.getMonthlyInvestmentFlow failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
