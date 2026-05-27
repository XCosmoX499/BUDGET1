import 'package:logger/logger.dart';

import '../model/account.dart';
import '../network/service/local_data_source.dart';
import '../utils/id_generator.dart';
import '../utils/storage_keys.dart';

/// Repository per la gestione dei conti dell'utente.
///
/// Garantisce alcuni invarianti:
/// - Esiste sempre uno e un solo conto "default".
/// - Esiste sempre uno e un solo conto cash (con isCash=true).
/// - Il conto cash non può essere eliminato.
class AccountsRepository {
  AccountsRepository({
    required LocalDataSource localDataSource,
    required Logger logger,
    required IdGenerator idGenerator,
  })  : _localDataSource = localDataSource,
        _logger = logger,
        _idGenerator = idGenerator;

  final LocalDataSource _localDataSource;
  final Logger _logger;
  final IdGenerator _idGenerator;

  /// Restituisce tutti i conti, con il default per primo e il cash per ultimo.
  Future<List<Account>> getAll() async {
    try {
      final accounts = _localDataSource.readCollection<Account>(
        key: StorageKeys.accounts,
        fromJson: Account.fromJson,
      );

      accounts.sort((a, b) {
        if (a.isCash && !b.isCash) return 1;
        if (!a.isCash && b.isCash) return -1;
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      return accounts;
    } catch (e, st) {
      _logger.e('AccountsRepository.getAll failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Restituisce un conto per id, null se non trovato.
  Future<Account?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Restituisce il conto cash. Lo crea se non esiste.
  Future<Account> getCashAccount() async {
    final all = await getAll();
    final existing = all.where((a) => a.isCash).toList();
    if (existing.isNotEmpty) return existing.first;

    // Inizializza il conto cash al primo accesso.
    final cash = Account(
      id: _idGenerator.generate(),
      name: 'Contante',
      emoji: '💵',
      balance: 0,
      colorHex: '#F59E0B',
      isCash: true,
      isDefault: false,
      createdAt: DateTime.now(),
    );
    await _persist([...all, cash]);
    return cash;
  }

  /// Restituisce il conto default. Se non esiste e ci sono conti, promuove
  /// il primo non-cash a default.
  Future<Account?> getDefaultAccount() async {
    final all = await getAll();
    final defaults = all.where((a) => a.isDefault).toList();
    if (defaults.isNotEmpty) return defaults.first;

    final firstNonCash = all.where((a) => !a.isCash).toList();
    if (firstNonCash.isEmpty) return null;

    final promoted = firstNonCash.first.copyWith(isDefault: true);
    await update(promoted);
    return promoted;
  }

  /// Crea un nuovo conto.
  Future<Account> create({
    required String name,
    required String emoji,
    required String colorHex,
    double initialBalance = 0,
    bool isDefault = false,
  }) async {
    try {
      final all = await getAll();
      final account = Account(
        id: _idGenerator.generate(),
        name: name,
        emoji: emoji,
        balance: initialBalance,
        colorHex: colorHex,
        isCash: false,
        isDefault: isDefault,
        createdAt: DateTime.now(),
      );

      var updated = [...all, account];
      if (isDefault) {
        updated = updated
            .map((a) => a.id == account.id
                ? a
                : a.copyWith(isDefault: false))
            .toList();
      } else if (updated.where((a) => a.isDefault && !a.isCash).isEmpty) {
        // Se non c'è nessun default, promuoviamo questo.
        updated = updated
            .map((a) => a.id == account.id ? a.copyWith(isDefault: true) : a)
            .toList();
      }

      await _persist(updated);
      return updated.firstWhere((a) => a.id == account.id);
    } catch (e, st) {
      _logger.e('AccountsRepository.create failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Aggiorna un conto esistente.
  Future<void> update(Account account) async {
    try {
      final all = await getAll();
      final updated =
          all.map((a) => a.id == account.id ? account : a).toList();
      await _persist(updated);
    } catch (e, st) {
      _logger.e('AccountsRepository.update failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Imposta un conto come default. Solo i conti non-cash possono essere
  /// default.
  Future<void> setAsDefault(String accountId) async {
    try {
      final all = await getAll();
      final target = all.firstWhere((a) => a.id == accountId);
      if (target.isCash) {
        throw StateError('Cash account cannot be set as default');
      }

      final updated = all
          .map((a) => a.copyWith(isDefault: a.id == accountId))
          .toList();
      await _persist(updated);
    } catch (e, st) {
      _logger.e('AccountsRepository.setAsDefault failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Aggiorna il saldo di un conto sommandogli un delta (può essere negativo).
  Future<Account> adjustBalance(String accountId, double delta) async {
    try {
      final account = await getById(accountId);
      if (account == null) {
        throw StateError('Account $accountId not found');
      }
      final updated = account.copyWith(balance: account.balance + delta);
      await update(updated);
      return updated;
    } catch (e, st) {
      _logger.e('AccountsRepository.adjustBalance failed',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Elimina un conto. Il conto cash non può essere eliminato.
  Future<void> delete(String accountId) async {
    try {
      final all = await getAll();
      final target = all.firstWhere((a) => a.id == accountId);
      if (target.isCash) {
        throw StateError('Cash account cannot be deleted');
      }

      var updated = all.where((a) => a.id != accountId).toList();

      // Se abbiamo eliminato il default, ne promuoviamo un altro.
      if (target.isDefault) {
        final nextDefault = updated.where((a) => !a.isCash).firstOrNull;
        if (nextDefault != null) {
          updated = updated
              .map((a) =>
                  a.id == nextDefault.id ? a.copyWith(isDefault: true) : a)
              .toList();
        }
      }

      await _persist(updated);
    } catch (e, st) {
      _logger.e('AccountsRepository.delete failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> _persist(List<Account> accounts) async {
    await _localDataSource.writeCollection(
      key: StorageKeys.accounts,
      items: accounts,
      toJson: (a) => a.toJson(),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
