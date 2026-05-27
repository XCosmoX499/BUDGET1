import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/category_expense_stat.dart';
import '../../model/dashboard_summary.dart';
import '../../model/routine.dart';
import '../../model/scheduled_expense.dart';
import '../../repositories/analytics_repository.dart';
import '../../repositories/planning_repository.dart';

/// Stato della dashboard.
sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.summary,
    required this.expensesByCategory,
    required this.upcomingRoutines,
    required this.upcomingScheduledExpenses,
  });

  final DashboardSummary summary;
  final List<CategoryExpenseStat> expensesByCategory;

  /// Routine la cui prossima scadenza è nei prossimi 30 giorni.
  final List<({Routine routine, DateTime nextRun})> upcomingRoutines;

  /// Spese programmate non ancora eseguite.
  final List<ScheduledExpense> upcomingScheduledExpenses;

  @override
  List<Object?> get props => [
        summary,
        expensesByCategory,
        upcomingRoutines,
        upcomingScheduledExpenses,
      ];
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

/// Cubit che pilota lo stato della dashboard.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required AnalyticsRepository analyticsRepository,
    required PlanningRepository planningRepository,
  })  : _analyticsRepository = analyticsRepository,
        _planningRepository = planningRepository,
        super(const DashboardInitial());

  final AnalyticsRepository _analyticsRepository;
  final PlanningRepository _planningRepository;

  Future<void> load({required int year, required int month}) async {
    emit(const DashboardLoading());
    try {
      final summary = await _analyticsRepository.buildDashboardSummary(
        year: year,
        month: month,
      );
      final expensesByCategory =
          await _analyticsRepository.getExpensesByCategory(
        year: year,
        month: month,
      );

      final allRoutines = await _planningRepository.getRoutines();
      final now = DateTime.now();
      final horizon = now.add(const Duration(days: 30));
      final upcomingRoutines = allRoutines
          .where((r) => r.isActive)
          .map((r) {
            final next = _planningRepository.computeNextRunDate(
              r,
              r.lastExecutionDate ?? now,
            );
            return (routine: r, nextRun: next);
          })
          .where((entry) =>
              entry.nextRun.isAfter(now) && entry.nextRun.isBefore(horizon))
          .toList()
        ..sort((a, b) => a.nextRun.compareTo(b.nextRun));

      final scheduledExpenses =
          await _planningRepository.getScheduledExpenses();
      final upcomingScheduled = scheduledExpenses
          .where((s) =>
              s.status == ScheduledExpenseStatus.pending &&
              s.dueDate.isBefore(horizon))
          .toList();

      emit(DashboardLoaded(
        summary: summary,
        expensesByCategory: expensesByCategory,
        upcomingRoutines: upcomingRoutines,
        upcomingScheduledExpenses: upcomingScheduled,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
