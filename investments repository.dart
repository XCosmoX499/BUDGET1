import 'package:logger/logger.dart';

import '../model/investment.dart';
import '../model/investment_movement.dart';
import '../model/transaction.dart';
import '../network/service/local_data_source.dart';
import '../utils/id_generator.dart';
import '../utils/storage_keys.dart';
import 'transactions_repository.dart';

/// Repository per la gestione di investimenti e relativi movimenti.
///
/// Coordina con [TransactionsRepository] per garantire la coerenza tra
/// saldo dei conti e valore degli investimenti. Quando l'utente versa
/// su un PAC, il denaro lascia il conto e arriva all'investimento; i due
/// movimenti devono restare allineati.
class InvestmentsRepository {
  InvestmentsRepository({
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

  // ─── INVESTIMENTI ───────────────────────────────────────────────────────

  Future<List<Investment>> getAll() async {
    try {
      final list = _localDataSource.readCollection<Investment>(
        key: StorageKeys.investments,
        fromJson: Investment.fromJson,
      );
      list.sort((a, b) => b.currentValue.compareTo(a.currentValue));
      return list;
    } catch (e, st) {
      _logger.e('InvestmentsRepository.getAll failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Investment?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Investment> create({
    required String name,
    required String emoji,
    required InvestmentType type,
    required String colorHex,
    double initialValue = 0,
    String? note,
  }) async {
    try {
      final investment = Investment(
        id: _idGenerator.generate(),
        name: name,
        emoji: emoji,
        type: type,
        currentValue: initialValue,
        totalInvested: initialValue,
        colorHex: colorHex,
        createdAt: DateTime.now(),
        note: note,
      );

      final all = await getAll();
      await _persistInvestments([...all, investment]);
      return investment;
    } catch (e, st) {
      _logger.e('InvestmentsRepository.create failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> update(Investment investment) async {
    try {
      final all = await getAll();
      final updated =
          all.map((i) => i.id == investment.id ? investment : i).toList();
      await _persistInvestments(updated);
    } catch (e, st) {
      _logger.e('InvestmentsRepository.update failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> delete(String investmentId) async {
    try {
      final all = await getAll();
      await _persistInvestments(
        all.where((i) => i.id != investmentId).toList(),
      );
      // Cancelliamo anche tutti i movimenti collegati.
      final allMovements = await getAllMovements();
      await _persistMovements(
        allMovements.where((m) => m.investmentId != investmentId).toList(),
      );
    } catch (e, st) {
      _logger.e('InvestmentsRepository.delete failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── MOVIMENTI ──────────────────────────────────────────────────────────

  Future<List<InvestmentMovement>> getAllMovements() async {
    try {
      final list = _localDataSource.readCollection<InvestmentMovement>(
        key: StorageKeys.investmentMovements,
        fromJson: InvestmentMovement.fromJson,
      );
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e, st) {
      _logger.e('InvestmentsRepository.getAllMovements failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<InvestmentMovement>> getMovementsFor(
    String investmentId,
  ) async {
    final all = await getAllMovements();
    return all.where((m) => m.investmentId == investmentId).toList();
  }

  /// Versamento periodico: l'utente sposta denaro dal conto all'investimento.
  ///
  /// Coordina due effetti: una [TransactionType.investmentIn] sul conto e
  /// un [InvestmentMovementType.contribution] sull'investimento.
  Future<InvestmentMovement> recordContribution({
    required String investmentId,
    required double amount,
    required String fromAccountId,
    required DateTime date,
    String? note,
  }) async {
    _validateAmount(amount);
    try {
      // 1. Movimento sul conto (uscita verso investimento, non spesa).
      final Transaction tx =
          await _transactionsRepository.recordInvestmentIn(
        amount: amount,
        fromAccountId: fromAccountId,
        investmentId: investmentId,
        date: date,
        note: note,
      );

      // 2. Movimento sull'investimento.
      final movement = InvestmentMovement(
        id: _idGenerator.generate(),
        investmentId: investmentId,
        type: InvestmentMovementType.contribution,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        relatedAccountId: fromAccountId,
        relatedTransactionId: tx.id,
        note: note,
      );

      // 3. Aggiorno il valore corrente e il totale versato dell'investimento.
      final investment = await getById(investmentId);
      if (investment == null) {
        throw StateError('Investment $investmentId not found');
      }
      await update(investment.copyWith(
        currentValue: investment.currentValue + amount,
        totalInvested: investment.totalInvested + amount,
      ));

      await _saveMovement(movement);
      return movement;
    } catch (e, st) {
      _logger.e('InvestmentsRepository.recordContribution failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Disinvestimento: l'utente riscatta una parte e la accredita su un conto.
  Future<InvestmentMovement> recordWithdrawal({
    required String investmentId,
    required double amount,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    _validateAmount(amount);
    try {
      final Transaction tx =
          await _transactionsRepository.recordInvestmentOut(
        amount: amount,
        toAccountId: toAccountId,
        investmentId: investmentId,
        date: date,
        note: note,
      );

      final movement = InvestmentMovement(
        id: _idGenerator.generate(),
        investmentId: investmentId,
        type: InvestmentMovementType.withdrawal,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        relatedAccountId: toAccountId,
        relatedTransactionId: tx.id,
        note: note,
      );

      final investment = await getById(investmentId);
      if (investment == null) {
        throw StateError('Investment $investmentId not found');
      }
      await update(investment.copyWith(
        currentValue: investment.currentValue - amount,
        totalInvested:
            (investment.totalInvested - amount).clamp(0, double.infinity),
      ));

      await _saveMovement(movement);
      return movement;
    } catch (e, st) {
      _logger.e('InvestmentsRepository.recordWithdrawal failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Registra una plusvalenza (variazione positiva del valore di mercato).
  /// Non coinvolge nessun conto: è solo un aggiornamento del valore corrente.
  Future<InvestmentMovement> recordGain({
    required String investmentId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    return _recordValueAdjustment(
      investmentId: investmentId,
      amount: amount,
      type: InvestmentMovementType.gain,
      date: date,
      note: note,
    );
  }

  /// Registra una minusvalenza.
  Future<InvestmentMovement> recordLoss({
    required String investmentId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    return _recordValueAdjustment(
      investmentId: investmentId,
      amount: amount,
      type: InvestmentMovementType.loss,
      date: date,
      note: note,
    );
  }

  Future<InvestmentMovement> _recordValueAdjustment({
    required String investmentId,
    required double amount,
    required InvestmentMovementType type,
    required DateTime date,
    String? note,
  }) async {
    _validateAmount(amount);
    final isGain = type == InvestmentMovementType.gain;
    try {
      final investment = await getById(investmentId);
      if (investment == null) {
        throw StateError('Investment $investmentId not found');
      }

      final movement = InvestmentMovement(
        id: _idGenerator.generate(),
        investmentId: investmentId,
        type: type,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
        note: note,
      );

      final delta = isGain ? amount : -amount;
      await update(investment.copyWith(
        currentValue: investment.currentValue + delta,
      ));

      await _saveMovement(movement);
      return movement;
    } catch (e, st) {
      _logger.e('InvestmentsRepository._recordValueAdjustment failed',
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

  Future<void> _persistInvestments(List<Investment> investments) async {
    await _localDataSource.writeCollection(
      key: StorageKeys.investments,
      items: investments,
      toJson: (i) => i.toJson(),
    );
  }

  Future<void> _persistMovements(List<InvestmentMovement> movements) async {
    await _localDataSource.writeCollection(
      key: StorageKeys.investmentMovements,
      items: movements,
      toJson: (m) => m.toJson(),
    );
  }

  Future<void> _saveMovement(InvestmentMovement movement) async {
    final all = await getAllMovements();
    await _persistMovements([movement, ...all]);
  }
}
