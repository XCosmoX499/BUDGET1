import 'package:logger/logger.dart';

import '../model/goal.dart';
import '../model/routine.dart';
import '../model/scheduled_expense.dart';
import '../network/service/local_data_source.dart';
import '../utils/date_utils.dart';
import '../utils/id_generator.dart';
import '../utils/storage_keys.dart';
import 'transactions_repository.dart';

/// Repository che gestisce le tre tipologie di pianificazione previste dal
/// brief:
/// - Routine: spese/entrate ricorrenti che si autogenerano alla scadenza.
/// - Goal: obiettivi di risparmio con accantonamenti progressivi.
/// - ScheduledExpense: spese future che diventano uscite alla scadenza.
///
/// Espone anche [processDuePlans] che è il "motore" del background: applica
/// automaticamente le routine e le spese programmate la cui scadenza è
/// arrivata. Va chiamato all'apertura dell'app e periodicamente.
class PlanningRepository {
  PlanningRepository({
    required LocalDataSource localDataSource,
    required Logger logger,
    required IdGenerator idGenerator,
    required TransactionsRepository transactionsRepository,
  })  : _localDataSource = localDataSource,
        _logger = logger,
        _idGenerator = idGenerator,
        _transactionsRepository = transactionsRepository;

  final LocalDataSource _localDataSource;
  final Logger _logger;
  final IdGenerator _idGenerator;
  final TransactionsRepository _transactionsRepository;

  // ─── ROUTINE ────────────────────────────────────────────────────────────

  Future<List<Routine>> getRoutines() async {
    try {
      final list = _localDataSource.readCollection<Routine>(
        key: StorageKeys.routines,
        fromJson: Routine.fromJson,
      );
      list.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
      return list;
    } catch (e, st) {
      _logger.e('PlanningRepository.getRoutines failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Routine> createRoutine({
    required String description,
    required double amount,
    required RoutineKind kind,
    required RoutineFrequency frequency,
    required int dayOfMonth,
    required DateTime startDate,
    required String accountId,
    required String categoryId,
    DateTime? endDate,
    String? note,
  }) async {
    try {
      final routine = Routine(
        id: _idGenerator.generate(),
        description: description,
        amount: amount,
        kind: kind,
        frequency: frequency,
        dayOfMonth: dayOfMonth,
        startDate: startDate,
        endDate: endDate,
        lastExecutionDate: null,
        accountId: accountId,
        categoryId: categoryId,
        isActive: true,
        createdAt: DateTime.now(),
        note: note,
      );

      final all = await getRoutines();
      await _persistRoutines([...all, routine]);
      return routine;
    } catch (e, st) {
      _logger.e('PlanningRepository.createRoutine failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    final all = await getRoutines();
    final updated = all.map((r) => r.id == routine.id ? routine : r).toList();
    await _persistRoutines(updated);
  }

  Future<void> deleteRoutine(String routineId) async {
    final all = await getRoutines();
    await _persistRoutines(all.where((r) => r.id != routineId).toList());
  }

  /// Restituisce la prossima data di esecuzione di una routine dopo [from].
  ///
  /// Logica semplificata che copre il caso d'uso del brief (mensile,
  /// settimanale, annuale, giornaliero). Per ora consideriamo solo i giorni
  /// di calendario; non gestiamo casi limite come "il 31 di un mese che
  /// ne ha 30" (in tal caso si applica l'ultimo giorno del mese).
  DateTime computeNextRunDate(Routine routine, DateTime from) {
    switch (routine.frequency) {
      case RoutineFrequency.daily:
        return AppDateUtils.startOfDay(from).add(const Duration(days: 1));
      case RoutineFrequency.weekly:
        return AppDateUtils.startOfDay(from).add(const Duration(days: 7));
      case RoutineFrequency.monthly:
        final next = AppDateUtils.nextMonth(from.year, from.month);
        final maxDay = AppDateUtils.daysInMonth(next.year, next.month);
        final day =
            routine.dayOfMonth > maxDay ? maxDay : routine.dayOfMonth;
        return DateTime(next.year, next.month, day);
      case RoutineFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  // ─── GOAL ───────────────────────────────────────────────────────────────

  Future<List<Goal>> getGoals() async {
    try {
      final list = _localDataSource.readCollection<Goal>(
        key: StorageKeys.goals,
        fromJson: Goal.fromJson,
      );
      list.sort((a, b) {
        if (a.status != b.status) {
          // Active first, completed last
          return a.status.index.compareTo(b.status.index);
        }
        final aDeadline = a.deadline;
        final bDeadline = b.deadline;
        if (aDeadline != null && bDeadline != null) {
          return aDeadline.compareTo(bDeadline);
        }
        if (aDeadline != null) return -1;
        if (bDeadline != null) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });
      return list;
    } catch (e, st) {
      _logger.e('PlanningRepository.getGoals failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Goal> createGoal({
    required String name,
    required String emoji,
    required double targetAmount,
    double initialAmount = 0,
    DateTime? deadline,
    String? note,
  }) async {
    try {
      final goal = Goal(
        id: _idGenerator.generate(),
        name: name,
        emoji: emoji,
        targetAmount: targetAmount,
        currentAmount: initialAmount,
        deadline: deadline,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        note: note,
      );

      final all = await getGoals();
      await _persistGoals([...all, goal]);
      return goal;
    } catch (e, st) {
      _logger.e('PlanningRepository.createGoal failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Accantona una somma verso un obiettivo. Non tocca i conti: è solo
  /// un'allocazione concettuale del risparmio.
  Future<Goal> contributeToGoal({
    required String goalId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    final all = await getGoals();
    final target = all.firstWhere((g) => g.id == goalId);
    final newAmount = target.currentAmount + amount;
    final newStatus = newAmount >= target.targetAmount
        ? GoalStatus.completed
        : target.status;
    final updated = target.copyWith(
      currentAmount: newAmount,
      status: newStatus,
    );
    await _persistGoals(
      all.map((g) => g.id == goalId ? updated : g).toList(),
    );
    return updated;
  }

  Future<void> updateGoal(Goal goal) async {
    final all = await getGoals();
    await _persistGoals(
      all.map((g) => g.id == goal.id ? goal : g).toList(),
    );
  }

  Future<void> deleteGoal(String goalId) async {
    final all = await getGoals();
    await _persistGoals(all.where((g) => g.id != goalId).toList());
  }

  // ─── SCHEDULED EXPENSES ─────────────────────────────────────────────────

  Future<List<ScheduledExpense>> getScheduledExpenses() async {
    try {
      final list = _localDataSource.readCollection<ScheduledExpense>(
        key: StorageKeys.scheduledExpenses,
        fromJson: ScheduledExpense.fromJson,
      );
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    } catch (e, st) {
      _logger.e('PlanningRepository.getScheduledExpenses failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<ScheduledExpense> createScheduledExpense({
    required String description,
    required double amount,
    required DateTime dueDate,
    required String accountId,
    required String categoryId,
    String? note,
  }) async {
    try {
      final expense = ScheduledExpense(
        id: _idGenerator.generate(),
        description: description,
        amount: amount,
        dueDate: dueDate,
        accountId: accountId,
        categoryId: categoryId,
        status: ScheduledExpenseStatus.pending,
        createdAt: DateTime.now(),
        note: note,
      );

      final all = await getScheduledExpenses();
      await _persistScheduledExpenses([...all, expense]);
      return expense;
    } catch (e, st) {
      _logger.e('PlanningRepository.createScheduledExpense failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateScheduledExpense(ScheduledExpense expense) async {
    final all = await getScheduledExpenses();
    await _persistScheduledExpenses(
      all.map((s) => s.id == expense.id ? expense : s).toList(),
    );
  }

  Future<void> deleteScheduledExpense(String expenseId) async {
    final all = await getScheduledExpenses();
    await _persistScheduledExpenses(
      all.where((s) => s.id != expenseId).toList(),
    );
  }

  // ─── BACKGROUND PROCESSING ──────────────────────────────────────────────

  /// Esegue tutte le routine e le spese programmate la cui scadenza è
  /// passata e che non sono ancora state eseguite.
  ///
  /// Va invocato all'apertura dell'app. Restituisce il numero di operazioni
  /// processate, utile per mostrare all'utente "abbiamo applicato N
  /// movimenti programmati".
  Future<int> processDuePlans({DateTime? now}) async {
    final reference = now ?? DateTime.now();
    var processed = 0;
    try {
      processed += await _processDueRoutines(reference);
      processed += await _processDueScheduledExpenses(reference);

      await _localDataSource.writeString(
        StorageKeys.lastBackgroundProcessing,
        reference.toIso8601String(),
      );
      return processed;
    } catch (e, st) {
      _logger.e('PlanningRepository.processDuePlans failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<int> _processDueRoutines(DateTime reference) async {
    final routines = await getRoutines();
    var processed = 0;

    for (final routine in routines) {
      if (!routine.isActive) continue;
      if (routine.endDate != null &&
          reference.isAfter(routine.endDate!)) {
        continue;
      }

      var nextDue = _computeFirstDueDate(routine);
      while (!nextDue.isAfter(reference)) {
        // Salta se già eseguita per questa data.
        final lastExec = routine.lastExecutionDate;
        if (lastExec != null && !nextDue.isAfter(lastExec)) {
          nextDue = computeNextRunDate(routine, nextDue);
          continue;
        }
        if (routine.endDate != null && nextDue.isAfter(routine.endDate!)) {
          break;
        }

        if (routine.kind == RoutineKind.expense) {
          await _transactionsRepository.recordExpense(
            amount: routine.amount,
            accountId: routine.accountId,
            categoryId: routine.categoryId,
            date: nextDue,
            description: routine.description,
            note: routine.note,
            relatedRoutineId: routine.id,
          );
        } else {
          await _transactionsRepository.recordIncome(
            amount: routine.amount,
            accountId: routine.accountId,
            categoryId: routine.categoryId,
            date: nextDue,
            description: routine.description,
            note: routine.note,
          );
        }
        processed++;
        await updateRoutine(routine.copyWith(lastExecutionDate: nextDue));

        nextDue = computeNextRunDate(routine, nextDue);
      }
    }
    return processed;
  }

  DateTime _computeFirstDueDate(Routine routine) {
    final last = routine.lastExecutionDate;
    if (last != null) {
      return computeNextRunDate(routine, last);
    }

    // Prima esecuzione: usa startDate, eventualmente allineando al
    // dayOfMonth per le mensili.
    if (routine.frequency == RoutineFrequency.monthly) {
      final maxDay = AppDateUtils.daysInMonth(
        routine.startDate.year,
        routine.startDate.month,
      );
      final day =
          routine.dayOfMonth > maxDay ? maxDay : routine.dayOfMonth;
      final candidate = DateTime(
        routine.startDate.year,
        routine.startDate.month,
        day,
      );
      if (candidate.isBefore(routine.startDate)) {
        return computeNextRunDate(routine, candidate);
      }
      return candidate;
    }
    return routine.startDate;
  }

  Future<int> _processDueScheduledExpenses(DateTime reference) async {
    final expenses = await getScheduledExpenses();
    var processed = 0;

    for (final expense in expenses) {
      if (expense.status != ScheduledExpenseStatus.pending) continue;
      if (expense.dueDate.isAfter(reference)) continue;

      final tx = await _transactionsRepository.recordExpense(
        amount: expense.amount,
        accountId: expense.accountId,
        categoryId: expense.categoryId,
        date: expense.dueDate,
        description: expense.description,
        note: expense.note,
        relatedScheduledExpenseId: expense.id,
      );

      await updateScheduledExpense(expense.copyWith(
        status: ScheduledExpenseStatus.executed,
        executedTransactionId: tx.id,
      ));
      processed++;
    }
    return processed;
  }

  // ─── PERSISTENCE HELPERS ────────────────────────────────────────────────

  Future<void> _persistRoutines(List<Routine> routines) {
    return _localDataSource.writeCollection(
      key: StorageKeys.routines,
      items: routines,
      toJson: (r) => r.toJson(),
    );
  }

  Future<void> _persistGoals(List<Goal> goals) {
    return _localDataSource.writeCollection(
      key: StorageKeys.goals,
      items: goals,
      toJson: (g) => g.toJson(),
    );
  }

  Future<void> _persistScheduledExpenses(
    List<ScheduledExpense> expenses,
  ) {
    return _localDataSource.writeCollection(
      key: StorageKeys.scheduledExpenses,
      items: expenses,
      toJson: (s) => s.toJson(),
    );
  }
}
