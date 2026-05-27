import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/date_utils.dart';

/// Stato del mese di riferimento attualmente selezionato in tutta l'app.
class SelectedMonthState extends Equatable {
  const SelectedMonthState({required this.year, required this.month});

  factory SelectedMonthState.current() {
    final now = AppDateUtils.currentMonth();
    return SelectedMonthState(year: now.year, month: now.month);
  }

  final int year;
  final int month;

  bool get isCurrentMonth {
    final now = AppDateUtils.currentMonth();
    return year == now.year && month == now.month;
  }

  @override
  List<Object?> get props => [year, month];
}

/// Cubit globale del mese di riferimento.
///
/// Le frecce "avanti/indietro" e il selettore di mese/anno nella dashboard
/// emettono qui. Tutte le sezioni (dashboard, conti, investimenti,
/// pianificazione) leggono questo Cubit per sapere quale mese mostrare.
///
/// Lo registriamo come Provider perché è uno stato globale senza business
/// logic (vedi linee guida fline).
class SelectedMonthCubit extends Cubit<SelectedMonthState> {
  SelectedMonthCubit() : super(SelectedMonthState.current());

  void goToPreviousMonth() {
    final prev = AppDateUtils.previousMonth(state.year, state.month);
    emit(SelectedMonthState(year: prev.year, month: prev.month));
  }

  void goToNextMonth() {
    final next = AppDateUtils.nextMonth(state.year, state.month);
    emit(SelectedMonthState(year: next.year, month: next.month));
  }

  void goToMonth(int year, int month) {
    emit(SelectedMonthState(year: year, month: month));
  }

  void goToCurrentMonth() {
    final now = AppDateUtils.currentMonth();
    emit(SelectedMonthState(year: now.year, month: now.month));
  }
}
