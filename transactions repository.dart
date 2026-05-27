import 'package:logger/logger.dart';

import '../model/transaction.dart';
import '../model/transaction_type.dart';
import '../network/service/local_data_source.dart';
import '../utils/date_utils.dart';
import '../utils/id_generator.dart';
import '../utils/storage_keys.dart';
import 'accounts_repository.dart';

/// Repository per la gestione delle transazioni.
///
/// È il punto centrale per qualunque movimento di denaro nell'app.
/// Garantisce che, ogni volta che si crea una transazione, i saldi degli
/// account coinvolti vengano aggiornati di conseguenza.
///
/// Convenzioni dal brief:
/// - Income/Expense: variano il saldo del conto coinvolto.
/// - ATM withdrawal: sposta saldo dal conto al cash, NON è un'uscita.
/// - Transfer: sposta saldo tra due conti, non è né entrata né uscita.
/// - Investment in/out: spostano denaro tra conto e investimento, non
///   sono uscite/entrate ai fini del saldo mensile.
class TransactionsRepository {
  TransactionsRepository({
    required LocalDataSource localDataSource,
    required Logger logger,
    required IdGenerator idGenerator,
    required AccountsRepository accountsRepository,
  })  : _localDataSource = localDataSource,
        _logger = logger,
        _idGenerator = idGenerator,
        _accountsRepository = accountsRepository;

  final LocalDataSource _localDataSource;
  final Logger _logger;
  final IdGenerator _idGenerator;
  final AccountsRepository _accountsRepository;

  /// Restituisce tutte le transazioni ordinate dalla più recente.
  Future<List<Transaction>> getAll() async {
    try {
      final txs = _localDataSource.readCollection<Transaction>(
        key: StorageKeys.transactions,
        fromJson: Transaction.fromJson,
      );
      txs.sort((a, b) => b.date.compareTo(a.date));
      return txs;
    } catch (e, st) {
      _logger.e('TransactionsRepository.getAll failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Restituisce le transazioni filtrate per anno + mese.
  Future<List<Transaction>> getByMonth(int year, int month) async {
    final all = await getAll();
    return all.where((t) => AppDateUtils.isInMonth(t.date, year, month)).toList();
  }

  /// Restituisce le transazioni associate a un conto specifico.
  Future<List<Transaction>> getByAccount(String accountId) async {
    final all = await getAll();
    return all
        .where((t) =>
            t.accountId == accountId ||
            t.fromAccountId == accountId ||
            t.toAccountId == accountId)
        .toList();
  }

  // ─── REGISTRAZIONE OPERAZIONI ATOMICHE ──────────────────────────────────

  /// Registra un'entrata sul conto specificato.
  ///
  /// Effetto: aumenta il saldo dell'account, crea una transazione di tipo
  /// [TransactionType.income].
  Future<Transaction> recordIncome({
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? description,
    String? note,
  }) async {
    _validateAmount(amount);
    try {
      final tx = Transaction(
        id: _idGenerator.generate(),
        type: TransactionType.income,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        accountId: accountId,
        categoryId: categoryId,
        description: description,
        note: note,
      );

      await _accountsRepository.adjustBalance(accountId, amount);
      await _save(tx);
      return tx;
    } catch (e, st) {
      _logger.e('TransactionsRepository.recordIncome failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Registra un'uscita sul conto specificato.
  ///
  /// Effetto: decurta il saldo dell'account, crea una transazione di tipo
  /// [TransactionType.expense].
  Future<Transaction> recordExpense({
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? description,
    String? note,
    String? relatedRoutineId,
    String? relatedScheduledExpenseId,
  }) async {
    _validateAmount(amount);
    try {
      final tx = Transaction(
        id: _idGenerator.generate(),
        type: TransactionType.expense,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        accountId: accountId,
        categoryId: categoryId,
        description: description,
        note: note,
        relatedRoutineId: relatedRoutineId,
        relatedScheduledExpenseId: relatedScheduledExpenseId,
      );

      await _accountsRepository.adjustBalance(accountId, -amount);
      await _save(tx);
      return tx;
    } catch (e, st) {
      _logger.e('TransactionsRepository.recordExpense failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Registra un prelievo ATM: sposta saldo dal conto al cash.
  ///
  /// IMPORTANTE: NON è considerato un'uscita ai fini del saldo mensile.
  /// L'utente ha semplicemente cambiato la forma del proprio denaro
  /// (da elettronico a fisico).
  Future<Transaction> recordAtmWithdrawal({
    required double amount,
    required String fromAccountId,
    required DateTime date,
    String? note,
  }) async {
    _validateAmount(amount);
    try {
      final cash = await _accountsRepository.getCashAccount();
      if (cash.id == fromAccountId) {
        throw ArgumentError('Cannot withdraw from cash to cash');
      }

      final tx = Transaction(
        id: _idGenerator.generate(),
        type: TransactionType.atmWithdrawal,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        fromAccountId: fromAccountId,
        toAccountId: cash.id,
        note: note,
      );

      await _accountsRepository.adjustBalance(fromAccountId, -amount);
      await _accountsRepository.adjustBalance(cash.id, amount);
      await _save(tx);
      return tx;
    } catch (e, st) {
      _logger.e('TransactionsRepository.recordAtmWithdrawal failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Registra un trasferimento tra due conti.
  Future<Transaction> recordTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    _validateAmount(amount);
    if (fromAccountId == toAccountId) {
      throw ArgumentError('Source and destination accounts must differ');
    }
    try {
      final tx = Transaction(
        id: _idGenerator.generate(),
        type: TransactionType.transfer,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        note: note,
      );

      await _accountsRepository.adjustBalance(fromAccountId, -amount);
      await _accountsRepository.adjustBalance(toAccountId, amount);
      await _save(tx);
      return tx;
    } catch (e, st) {
      _logger.e('TransactionsRepository.recordTransfer failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Registra un movimento di investimento in entrata: il denaro lascia
  /// il conto e va al portafoglio investimenti.
  ///
  /// Il bilanciamento sul lato investimento è responsabilità di
  /// InvestmentsRepository.
  Future<Transaction> recordInvestmentIn({
    required double amount,
    required String fromAccountId,
    required String investmentId,
    required DateTime date,
    String? note,
  }) async {
    _validateAmount(amount);
    try {
      final tx = Transaction(
        id: _idGenerator.generate(),
        type: TransactionType.investmentIn,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        fromAccountId: fromAccountId,
        investmentId: investmentId,
        note: note,
      );

      await _accountsRepository.adjustBalance(fromAccountId, -amount);
      await _save(tx);
      return tx;
    } catch (e, st) {
      _logger.e('TransactionsRepository.recordInvestmentIn failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Registra un disinvestimento: il denaro torna dal portafoglio al conto.
  Future<Transaction> recordInvestmentOut({
    required double amount,
    required String toAccountId,
    required String investmentId,
    required DateTime date,
    String? note,
  }) async {
    _validateAmount(amount);
    try {
      final tx = Transaction(
        id: _idGenerator.generate(),
        type: TransactionType.investmentOut,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        toAccountId: toAccountId,
        investmentId: investmentId,
        note: note,
      );

      await _accountsRepository.adjustBalance(toAccountId, amount);
      await _save(tx);
      return tx;
    } catch (e, st) {
      _logger.e('TransactionsRepository.recordInvestmentOut failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Elimina una transazione e revoca il suo effetto sui saldi.
  Future<void> delete(String transactionId) async {
    try {
      final all = await getAll();
      final target = all.where((t) => t.id == transactionId).firstOrNull;
      if (target == null) return;

      await _revertBalanceEffect(target);

      final updated = all.where((t) => t.id != transactionId).toList();
      await _persistAll(updated);
    } catch (e, st) {
      _logger.e('TransactionsRepository.delete failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  void _validateAmount(double amount) {
    if (amount <= 0 || amount.isNaN || amount.isInfinite) {
      throw ArgumentError('Amount must be a positive finite number');
    }
  }

  Future<void> _save(Transaction tx) async {
    final all = await getAll();
    await _persistAll([tx, ...all]);
  }

  Future<void> _persistAll(List<Transaction> transactions) async {
    await _localDataSource.writeCollection(
      key: StorageKeys.transactions,
      items: transactions,
      toJson: (t) => t.toJson(),
    );
  }

  /// Annulla l'effetto sul saldo di una transazione (per delete/undo).
  Future<void> _revertBalanceEffect(Transaction tx) async {
    switch (tx.type) {
      case TransactionType.income:
        if (tx.accountId != null) {
          await _accountsRepository.adjustBalance(tx.accountId!, -tx.amount);
        }
      case TransactionType.expense:
        if (tx.accountId != null) {
          await _accountsRepository.adjustBalance(tx.accountId!, tx.amount);
        }
      case TransactionType.atmWithdrawal:
        if (tx.fromAccountId != null) {
          await _accountsRepository.adjustBalance(tx.fromAccountId!, tx.amount);
        }
        if (tx.toAccountId != null) {
          await _accountsRepository.adjustBalance(tx.toAccountId!, -tx.amount);
        }
      case TransactionType.transfer:
        if (tx.fromAccountId != null) {
          await _accountsRepository.adjustBalance(tx.fromAccountId!, tx.amount);
        }
        if (tx.toAccountId != null) {
          await _accountsRepository.adjustBalance(tx.toAccountId!, -tx.amount);
        }
      case TransactionType.investmentIn:
        if (tx.fromAccountId != null) {
          await _accountsRepository.adjustBalance(tx.fromAccountId!, tx.amount);
        }
      case TransactionType.investmentOut:
        if (tx.toAccountId != null) {
          await _accountsRepository.adjustBalance(tx.toAccountId!, -tx.amount);
        }
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
