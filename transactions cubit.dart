import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/transaction.dart';
import '../../repositories/transactions_repository.dart';

sealed class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsLoaded extends TransactionsState {
  const TransactionsLoaded({
    required this.transactions,
    required this.year,
    required this.month,
  });

  final List<Transaction> transactions;
  final int year;
  final int month;

  @override
  List<Object?> get props => [transactions, year, month];
}

class TransactionsError extends TransactionsState {
  const TransactionsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

/// Cubit che gestisce la lista delle transazioni del mese di riferimento
/// e tutte le operazioni di inserimento.
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit({required TransactionsRepository transactionsRepository})
      : _transactionsRepository = transactionsRepository,
        super(const TransactionsInitial());

  final TransactionsRepository _transactionsRepository;

  Future<void> loadForMonth({required int year, required int month}) async {
    emit(const TransactionsLoading());
    try {
      final txs = await _transactionsRepository.getByMonth(year, month);
      emit(TransactionsLoaded(transactions: txs, year: year, month: month));
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> addIncome({
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? description,
    String? note,
  }) async {
    try {
      await _transactionsRepository.recordIncome(
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        date: date,
        description: description,
        note: note,
      );
      await _reloadCurrent();
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> addExpense({
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? description,
    String? note,
  }) async {
    try {
      await _transactionsRepository.recordExpense(
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        date: date,
        description: description,
        note: note,
      );
      await _reloadCurrent();
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> addAtmWithdrawal({
    required double amount,
    required String fromAccountId,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _transactionsRepository.recordAtmWithdrawal(
        amount: amount,
        fromAccountId: fromAccountId,
        date: date,
        note: note,
      );
      await _reloadCurrent();
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactionsRepository.delete(transactionId);
      await _reloadCurrent();
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> _reloadCurrent() async {
    final current = state;
    if (current is TransactionsLoaded) {
      await loadForMonth(year: current.year, month: current.month);
    }
  }
}
