import 'package:intl/intl.dart';

/// Formattazione di importi in valuta secondo il locale corrente.
///
/// Usa le convenzioni di [intl] per gestire il separatore decimale e
/// delle migliaia: in italiano "1.234,56 €", in inglese "€ 1,234.56".
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formatta un importo come stringa di valuta nel locale specificato.
  ///
  /// [showSign] aggiunge esplicitamente il + per importi positivi.
  /// [decimalDigits] permette di forzare il numero di decimali (default 2).
  static String format(
    double amount, {
    String locale = 'it_IT',
    String symbol = '€',
    bool showSign = false,
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    final formatted = formatter.format(amount.abs());

    if (amount < 0) {
      return '-$formatted';
    }
    if (showSign && amount > 0) {
      return '+$formatted';
    }
    return formatted;
  }

  /// Formatta senza simbolo di valuta, utile per input field.
  static String formatPlain(
    double amount, {
    String locale = 'it_IT',
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(amount);
  }

  /// Parsa una stringa di input utente in double, gestendo virgola/punto.
  static double? parse(String input, {String locale = 'it_IT'}) {
    if (input.trim().isEmpty) return null;
    try {
      final formatter = NumberFormat.decimalPattern(locale);
      return formatter.parse(input).toDouble();
    } catch (_) {
      // Fallback: prova a sostituire la virgola con il punto.
      final normalized = input.replaceAll(',', '.').trim();
      return double.tryParse(normalized);
    }
  }
}
