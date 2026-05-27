/// Chiavi di storage usate dalla persistenza locale.
///
/// Centralizzate qui per evitare typo e facilitare future migrazioni
/// (es. verso Hive, Drift o database remoto).
class StorageKeys {
  StorageKeys._();

  static const String accounts = 'budgetone.accounts';
  static const String transactions = 'budgetone.transactions';
  static const String categories = 'budgetone.categories';
  static const String investments = 'budgetone.investments';
  static const String investmentMovements = 'budgetone.investment_movements';
  static const String routines = 'budgetone.routines';
  static const String goals = 'budgetone.goals';
  static const String scheduledExpenses = 'budgetone.scheduled_expenses';
  static const String monthlySavings = 'budgetone.monthly_savings';

  /// Indica se l'utente ha già completato l'onboarding/splash iniziale.
  static const String onboardingCompleted = 'budgetone.onboarding_completed';

  /// Lingua scelta dall'utente (it/en).
  static const String userLanguage = 'budgetone.user_language';

  /// Ultima esecuzione del job di processing di routine e spese programmate.
  static const String lastBackgroundProcessing =
      'budgetone.last_background_processing';
}
