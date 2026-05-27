import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data source locale generica per persistere e leggere collezioni di oggetti
/// serializzabili in JSON.
///
/// Astrae il dettaglio di SharedPreferences: i repository non devono
/// conoscere come/dove i dati sono salvati. In futuro si potrà sostituire
/// l'implementazione con Hive o un database SQL senza modificare i
/// repository.
class LocalDataSource {
  LocalDataSource({
    required SharedPreferences preferences,
    required Logger logger,
  })  : _preferences = preferences,
        _logger = logger;

  final SharedPreferences _preferences;
  final Logger _logger;

  /// Legge una collezione di oggetti serializzati in JSON sotto [key].
  ///
  /// [fromJson] è la funzione di deserializzazione per ogni elemento.
  /// Restituisce lista vuota se la chiave non esiste o se il parsing fallisce.
  List<T> readCollection<T>({
    required String key,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    try {
      final raw = _preferences.getString(key);
      if (raw == null || raw.isEmpty) return <T>[];

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _logger.w('LocalDataSource: stored value for "$key" is not a list');
        return <T>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: true);
    } catch (e, st) {
      _logger.e(
        'LocalDataSource.readCollection failed for "$key"',
        error: e,
        stackTrace: st,
      );
      return <T>[];
    }
  }

  /// Scrive una collezione di oggetti come JSON sotto [key].
  Future<bool> writeCollection<T>({
    required String key,
    required List<T> items,
    required Map<String, dynamic> Function(T item) toJson,
  }) async {
    try {
      final encoded = jsonEncode(items.map(toJson).toList());
      return await _preferences.setString(key, encoded);
    } catch (e, st) {
      _logger.e(
        'LocalDataSource.writeCollection failed for "$key"',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Legge un singolo oggetto serializzato in JSON.
  T? readObject<T>({
    required String key,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    try {
      final raw = _preferences.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      return fromJson(decoded);
    } catch (e, st) {
      _logger.e(
        'LocalDataSource.readObject failed for "$key"',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Scrive un singolo oggetto.
  Future<bool> writeObject<T>({
    required String key,
    required T item,
    required Map<String, dynamic> Function(T item) toJson,
  }) async {
    try {
      return await _preferences.setString(key, jsonEncode(toJson(item)));
    } catch (e, st) {
      _logger.e(
        'LocalDataSource.writeObject failed for "$key"',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  String? readString(String key) => _preferences.getString(key);

  Future<bool> writeString(String key, String value) =>
      _preferences.setString(key, value);

  bool? readBool(String key) => _preferences.getBool(key);

  Future<bool> writeBool(String key, bool value) =>
      _preferences.setBool(key, value);

  Future<bool> remove(String key) => _preferences.remove(key);
}
