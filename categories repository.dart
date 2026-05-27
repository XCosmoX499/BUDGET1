import 'package:logger/logger.dart';

import '../model/transaction_category.dart';
import '../network/service/local_data_source.dart';
import '../utils/id_generator.dart';
import '../utils/storage_keys.dart';

/// Repository per le categorie di transazione.
///
/// Le categorie predefinite [DefaultCategories] sono sempre presenti.
/// L'utente può aggiungere categorie custom, che vengono persistite
/// separatamente.
class CategoriesRepository {
  CategoriesRepository({
    required LocalDataSource localDataSource,
    required Logger logger,
    required IdGenerator idGenerator,
  })  : _localDataSource = localDataSource,
        _logger = logger,
        _idGenerator = idGenerator;

  final LocalDataSource _localDataSource;
  final Logger _logger;
  final IdGenerator _idGenerator;

  /// Restituisce tutte le categorie: predefinite + custom.
  Future<List<TransactionCategory>> getAll() async {
    try {
      final custom = _localDataSource.readCollection<TransactionCategory>(
        key: StorageKeys.categories,
        fromJson: TransactionCategory.fromJson,
      );
      return [...DefaultCategories.all, ...custom];
    } catch (e, st) {
      _logger.e('CategoriesRepository.getAll failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Categorie di entrata (predefinite + custom).
  Future<List<TransactionCategory>> getIncomeCategories() async {
    final all = await getAll();
    return all.where((c) => c.isIncome).toList();
  }

  /// Categorie di uscita (predefinite + custom).
  Future<List<TransactionCategory>> getExpenseCategories() async {
    final all = await getAll();
    return all.where((c) => !c.isIncome).toList();
  }

  /// Cerca una categoria per id (tra predefinite e custom).
  Future<TransactionCategory?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Crea una nuova categoria custom.
  Future<TransactionCategory> create({
    required String name,
    required String emoji,
    required bool isIncome,
  }) async {
    try {
      final category = TransactionCategory(
        id: _idGenerator.generate(),
        nameKey: name, // per le custom il nameKey è il nome stesso
        emoji: emoji,
        isIncome: isIncome,
        isCustom: true,
      );

      final existing = _localDataSource.readCollection<TransactionCategory>(
        key: StorageKeys.categories,
        fromJson: TransactionCategory.fromJson,
      );

      await _localDataSource.writeCollection(
        key: StorageKeys.categories,
        items: [...existing, category],
        toJson: (c) => c.toJson(),
      );

      return category;
    } catch (e, st) {
      _logger.e('CategoriesRepository.create failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Elimina una categoria custom. Le predefinite non possono essere eliminate.
  Future<void> delete(String categoryId) async {
    try {
      final existing = _localDataSource.readCollection<TransactionCategory>(
        key: StorageKeys.categories,
        fromJson: TransactionCategory.fromJson,
      );

      final target = existing.where((c) => c.id == categoryId).toList();
      if (target.isEmpty) {
        // Probabile tentativo di eliminare una categoria predefinita.
        throw StateError('Default categories cannot be deleted');
      }

      await _localDataSource.writeCollection(
        key: StorageKeys.categories,
        items: existing.where((c) => c.id != categoryId).toList(),
        toJson: (c) => c.toJson(),
      );
    } catch (e, st) {
      _logger.e('CategoriesRepository.delete failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }
}
