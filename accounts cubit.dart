import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/account.dart';
import '../../repositories/accounts_repository.dart';
import '../../repositories/transactions_repository.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();
  @override
  List<Object?> get props => [];
}

class AccountsInitial extends AccountsState {
  const AccountsInitial();
}

class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

class AccountsLoaded extends AccountsState {
  const AccountsLoaded({
    required this.accounts,
    required this.totalBalance,
  });

  final List<Account> accounts;

  /// Saldo complessivo di tutti i conti (incluso cash).
  final double totalBalance;

  @override
  List<Object?> get props => [accounts, totalBalance];
}

class AccountsError extends AccountsState {
  const AccountsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit({
    required AccountsRepository accountsRepository,
    required TransactionsRepository transactionsRepository,
  })  : _accountsRepository = accountsRepository,
        _transactionsRepository = transactionsRepository,
        super(const AccountsInitial());

  final AccountsRepository _accountsRepository;
  final TransactionsRepository _transactionsRepository;

  Future<void> load() async {
    emit(const AccountsLoading());
    try {
      // Assicuriamoci che il conto cash esista.
      await _accountsRepository.getCashAccount();
      final accounts = await _accountsRepository.getAll();
      final total = accounts.fold<double>(0, (s, a) => s + a.balance);
      emit(AccountsLoaded(accounts: accounts, totalBalance: total));
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> createAccount({
    required String name,
    required String emoji,
    required String colorHex,
    double initialBalance = 0,
    bool isDefault = false,
  }) async {
    try {
      await _accountsRepository.create(
        name: name,
        emoji: emoji,
        colorHex: colorHex,
        initialBalance: initialBalance,
        isDefault: isDefault,
      );
      await load();
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await _accountsRepository.update(account);
      await load();
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> setAsDefault(String accountId) async {
    try {
      await _accountsRepository.setAsDefault(accountId);
      await load();
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _accountsRepository.delete(accountId);
      await load();
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    try {
      await _transactionsRepository.recordTransfer(
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        date: date,
        note: note,
      );
      await load();
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }
}
