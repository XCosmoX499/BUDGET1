/// Helper per il lavoro con date e mesi.
///
/// L'app è "mensile per costruzione": quasi tutte le query partono da
/// un anno + mese di riferimento. Queste utility centralizzano la logica
/// di confronto e navigazione tra mesi.
class AppDateUtils {
  AppDateUtils._();

  /// Restituisce l'inizio del mese (giorno 1, ore 00:00:00) per la data data.
  static DateTime startOfMonth(int year, int month) =>
      DateTime(year, month, 1);

  /// Restituisce l'inizio del mese successivo (esclusivo).
  static DateTime startOfNextMonth(int year, int month) {
    if (month == 12) return DateTime(year + 1, 1, 1);
    return DateTime(year, month + 1, 1);
  }

  /// Restituisce l'ultimo istante del mese (utile per range inclusivi).
  static DateTime endOfMonth(int year, int month) {
    final next = startOfNextMonth(year, month);
    return next.subtract(const Duration(milliseconds: 1));
  }

  /// Numero di giorni nel mese specificato.
  static int daysInMonth(int year, int month) {
    final next = startOfNextMonth(year, month);
    return next.subtract(const Duration(days: 1)).day;
  }

  /// Verifica se una data appartiene al mese specificato.
  static bool isInMonth(DateTime date, int year, int month) {
    return date.year == year && date.month == month;
  }

  /// Mese precedente come tupla (year, month).
  static ({int year, int month}) previousMonth(int year, int month) {
    if (month == 1) return (year: year - 1, month: 12);
    return (year: year, month: month - 1);
  }

  /// Mese successivo come tupla (year, month).
  static ({int year, int month}) nextMonth(int year, int month) {
    if (month == 12) return (year: year + 1, month: 1);
    return (year: year, month: month + 1);
  }

  /// Confronto solo per data (ignora ora/minuto/secondo).
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Normalizza una data troncandola all'inizio del giorno.
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Anno e mese correnti come tupla.
  static ({int year, int month}) currentMonth() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  /// Genera una lista di (year, month) ordinata cronologicamente che
  /// copre [count] mesi terminando con quello specificato (incluso).
  static List<({int year, int month})> lastNMonths(
    int count,
    int endYear,
    int endMonth,
  ) {
    final result = <({int year, int month})>[];
    var y = endYear;
    var m = endMonth;
    for (var i = 0; i < count; i++) {
      result.insert(0, (year: y, month: m));
      final prev = previousMonth(y, m);
      y = prev.year;
      m = prev.month;
    }
    return result;
  }
}
