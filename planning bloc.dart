import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/goal.dart';
import '../../model/routine.dart';
import '../../model/scheduled_expense.dart';
import '../../repositories/planning_repository.dart';

// ─── EVENTS ────────────────────────────────────────────────────────────────

sealed class PlanningEvent extends Equatable {
  const PlanningEvent();
  @override
  List<Object?> get props => [];
}

class LoadPlanning extends PlanningEvent {
  const LoadPlanning();
}

class ProcessDuePlans extends PlanningEvent {
  const ProcessDuePlans();
}

class CreateRoutine extends PlanningEvent {
  const CreateRoutine({
    required this.description,
    required this.amount,
    required this.kind,
    required this.frequency,
    required this.dayOfMonth,
    required this.startDate,
    required this.accountId,
    required this.categoryId,
    this.endDate,
    this.note,
  });

  final String description;
  final double amount;
  final RoutineKind kind;
  final RoutineFrequency frequency;
  final int dayOfMonth;
  final DateTime startDate;
  final String accountId;
  final String categoryId;
  final DateTime? endDate;
  final String? note;

  @override
  List<Object?> get props => [
        description,
        amount,
        kind,
        frequency,
        dayOfMonth,
        startDate,
        accountId,
        categoryId,
        endDate,
        note,
      ];
}

class UpdateRoutine extends PlanningEvent {
  const UpdateRoutine(this.routine);
  final Routine routine;
  @override
  List<Object?> get props => [routine];
}

class DeleteRoutine extends PlanningEvent {
  const DeleteRoutine(this.routineId);
  final String routineId;
  @override
  List<Object?> get props => [routineId];
}

class CreateGoal extends PlanningEvent {
  const CreateGoal({
    required this.name,
    required this.emoji,
    required this.targetAmount,
    this.initialAmount = 0,
    this.deadline,
    this.note,
  });

  final String name;
  final String emoji;
  final double targetAmount;
  final double initialAmount;
  final DateTime? deadline;
  final String? note;

  @override
  List<Object?> get props =>
      [name, emoji, targetAmount, initialAmount, deadline, note];
}

class ContributeToGoal extends PlanningEvent {
  const ContributeToGoal({required this.goalId, required this.amount});
  final String goalId;
  final double amount;
  @override
  List<Object?> get props => [goalId, amount];
}

class UpdateGoal extends PlanningEvent {
  const UpdateGoal(this.goal);
  final Goal goal;
  @override
  List<Object?> get props => [goal];
}

class DeleteGoal extends PlanningEvent {
  const DeleteGoal(this.goalId);
  final String goalId;
  @override
  List<Object?> get props => [goalId];
}

class CreateScheduledExpense extends PlanningEvent {
  const CreateScheduledExpense({
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.accountId,
    required this.categoryId,
    this.note,
  });

  final String description;
  final double amount;
  final DateTime dueDate;
  final String accountId;
  final String categoryId;
  final String? note;

  @override
  List<Object?> get props =>
      [description, amount, dueDate, accountId, categoryId, note];
}

class UpdateScheduledExpense extends PlanningEvent {
  const UpdateScheduledExpense(this.expense);
  final ScheduledExpense expense;
  @override
  List<Object?> get props => [expense];
}

class DeleteScheduledExpense extends PlanningEvent {
  const DeleteScheduledExpense(this.expenseId);
  final String expenseId;
  @override
  List<Object?> get props => [expenseId];
}

// ─── STATES ────────────────────────────────────────────────────────────────

sealed class PlanningState extends Equatable {
  const PlanningState();
  @override
  List<Object?> get props => [];
}

class PlanningInitial extends PlanningState {
  const PlanningInitial();
}

class PlanningLoading extends PlanningState {
  const PlanningLoading();
}

class PlanningLoaded extends PlanningState {
  const PlanningLoaded({
    required this.routines,
    required this.goals,
    required this.scheduledExpenses,
    this.justProcessedCount = 0,
  });

  final List<Routine> routines;
  final List<Goal> goals;
  final List<ScheduledExpense> scheduledExpenses;

  /// Numero di operazioni applicate automaticamente all'ultimo
  /// [ProcessDuePlans]. Usato per mostrare un toast informativo.
  final int justProcessedCount;

  PlanningLoaded copyWith({
    List<Routine>? routines,
    List<Goal>? goals,
    List<ScheduledExpense>? scheduledExpenses,
    int? justProcessedCount,
  }) {
    return PlanningLoaded(
      routines: routines ?? this.routines,
      goals: goals ?? this.goals,
      scheduledExpenses: scheduledExpenses ?? this.scheduledExpenses,
      justProcessedCount: justProcessedCount ?? this.justProcessedCount,
    );
  }

  @override
  List<Object?> get props =>
      [routines, goals, scheduledExpenses, justProcessedCount];
}

class PlanningError extends PlanningState {
  const PlanningError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ──────────────────────────────────────────────────────────────────

class PlanningBloc extends Bloc<PlanningEvent, PlanningState> {
  PlanningBloc({required PlanningRepository planningRepository})
      : _planningRepository = planningRepository,
        super(const PlanningInitial()) {
    on<LoadPlanning>(_onLoad);
    on<ProcessDuePlans>(_onProcessDuePlans);
    on<CreateRoutine>(_onCreateRoutine);
    on<UpdateRoutine>(_onUpdateRoutine);
    on<DeleteRoutine>(_onDeleteRoutine);
    on<CreateGoal>(_onCreateGoal);
    on<ContributeToGoal>(_onContributeToGoal);
    on<UpdateGoal>(_onUpdateGoal);
    on<DeleteGoal>(_onDeleteGoal);
    on<CreateScheduledExpense>(_onCreateScheduledExpense);
    on<UpdateScheduledExpense>(_onUpdateScheduledExpense);
    on<DeleteScheduledExpense>(_onDeleteScheduledExpense);
  }

  final PlanningRepository _planningRepository;

  Future<void> _refresh(Emitter<PlanningState> emit,
      {int processedCount = 0}) async {
    try {
      final routines = await _planningRepository.getRoutines();
      final goals = await _planningRepository.getGoals();
      final scheduled = await _planningRepository.getScheduledExpenses();
      emit(PlanningLoaded(
        routines: routines,
        goals: goals,
        scheduledExpenses: scheduled,
        justProcessedCount: processedCount,
      ));
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onLoad(LoadPlanning event, Emitter<PlanningState> emit) async {
    emit(const PlanningLoading());
    await _refresh(emit);
  }

  Future<void> _onProcessDuePlans(
    ProcessDuePlans event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      final count = await _planningRepository.processDuePlans();
      await _refresh(emit, processedCount: count);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onCreateRoutine(
    CreateRoutine event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.createRoutine(
        description: event.description,
        amount: event.amount,
        kind: event.kind,
        frequency: event.frequency,
        dayOfMonth: event.dayOfMonth,
        startDate: event.startDate,
        accountId: event.accountId,
        categoryId: event.categoryId,
        endDate: event.endDate,
        note: event.note,
      );
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onUpdateRoutine(
    UpdateRoutine event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.updateRoutine(event.routine);
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onDeleteRoutine(
    DeleteRoutine event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.deleteRoutine(event.routineId);
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onCreateGoal(
    CreateGoal event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.createGoal(
        name: event.name,
        emoji: event.emoji,
        targetAmount: event.targetAmount,
        initialAmount: event.initialAmount,
        deadline: event.deadline,
        note: event.note,
      );
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onContributeToGoal(
    ContributeToGoal event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.contributeToGoal(
        goalId: event.goalId,
        amount: event.amount,
      );
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onUpdateGoal(
    UpdateGoal event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.updateGoal(event.goal);
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onDeleteGoal(
    DeleteGoal event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.deleteGoal(event.goalId);
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onCreateScheduledExpense(
    CreateScheduledExpense event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.createScheduledExpense(
        description: event.description,
        amount: event.amount,
        dueDate: event.dueDate,
        accountId: event.accountId,
        categoryId: event.categoryId,
        note: event.note,
      );
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onUpdateScheduledExpense(
    UpdateScheduledExpense event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.updateScheduledExpense(event.expense);
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }

  Future<void> _onDeleteScheduledExpense(
    DeleteScheduledExpense event,
    Emitter<PlanningState> emit,
  ) async {
    try {
      await _planningRepository.deleteScheduledExpense(event.expenseId);
      await _refresh(emit);
    } catch (e) {
      emit(PlanningError(e.toString()));
    }
  }
}
