import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/investment.dart';
import '../../model/investment_movement.dart';
import '../../repositories/analytics_repository.dart';
import '../../repositories/investments_repository.dart';

sealed class InvestmentsState extends Equatable {
  const InvestmentsState();
  @override
  List<Object?> get props => [];
}

class InvestmentsInitial extends InvestmentsState {
  const InvestmentsInitial();
}

class InvestmentsLoading extends InvestmentsState {
  const InvestmentsLoading();
}

class InvestmentsLoaded extends InvestmentsState {
  const InvestmentsLoaded({
    required this.investments,
    required this.totalValue,
    required this.totalInvested,
    required this.monthlyFlow,
  });

  final List<Investment> investments;

  /// Valore corrente complessivo del portafoglio.
  final double totalValue;

  /// Capitale netto versato complessivo.
  final double totalInvested;

  /// Importi versati negli ultimi 12 mesi, per il grafico.
  final List<({int year, int month, double amount})> monthlyFlow;

  double get totalProfitLoss => totalValue - totalInvested;

  @override
  List<Object?> get props =>
      [investments, totalValue, totalInvested, monthlyFlow];
}

class InvestmentsError extends InvestmentsState {
  const InvestmentsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class InvestmentsCubit extends Cubit<InvestmentsState> {
  InvestmentsCubit({
    required InvestmentsRepository investmentsRepository,
    required AnalyticsRepository analyticsRepository,
  })  : _investmentsRepository = investmentsRepository,
        _analyticsRepository = analyticsRepository,
        super(const InvestmentsInitial());

  final InvestmentsRepository _investmentsRepository;
  final AnalyticsRepository _analyticsRepository;

  Future<void> load() async {
    emit(const InvestmentsLoading());
    try {
      final investments = await _investmentsRepository.getAll();
      final totalValue =
          investments.fold<double>(0, (s, i) => s + i.currentValue);
      final totalInvested =
          investments.fold<double>(0, (s, i) => s + i.totalInvested);
      final flow = await _analyticsRepository.getMonthlyInvestmentFlow();
      emit(InvestmentsLoaded(
        investments: investments,
        totalValue: totalValue,
        totalInvested: totalInvested,
        monthlyFlow: flow,
      ));
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> createInvestment({
    required String name,
    required String emoji,
    required InvestmentType type,
    required String colorHex,
    double initialValue = 0,
    String? note,
  }) async {
    try {
      await _investmentsRepository.create(
        name: name,
        emoji: emoji,
        type: type,
        colorHex: colorHex,
        initialValue: initialValue,
        note: note,
      );
      await load();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> contribute({
    required String investmentId,
    required double amount,
    required String fromAccountId,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _investmentsRepository.recordContribution(
        investmentId: investmentId,
        amount: amount,
        fromAccountId: fromAccountId,
        date: date,
        note: note,
      );
      await load();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> withdraw({
    required String investmentId,
    required double amount,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _investmentsRepository.recordWithdrawal(
        investmentId: investmentId,
        amount: amount,
        toAccountId: toAccountId,
        date: date,
        note: note,
      );
      await load();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> recordGain({
    required String investmentId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _investmentsRepository.recordGain(
        investmentId: investmentId,
        amount: amount,
        date: date,
        note: note,
      );
      await load();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<void> recordLoss({
    required String investmentId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _investmentsRepository.recordLoss(
        investmentId: investmentId,
        amount: amount,
        date: date,
        note: note,
      );
      await load();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }

  Future<List<InvestmentMovement>> getMovements(String investmentId) {
    return _investmentsRepository.getMovementsFor(investmentId);
  }

  Future<void> deleteInvestment(String investmentId) async {
    try {
      await _investmentsRepository.delete(investmentId);
      await load();
    } catch (e) {
      emit(InvestmentsError(e.toString()));
    }
  }
}
