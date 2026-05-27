/// Token di spaziatura dell'app, basati su una scala 4-point.
///
/// SCAFFOLD: valori provvisori. Quando arriveranno le specifiche di design,
/// si potrà solo modificare la scala qui senza toccare i widget.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Padding di default delle schermate.
  static const double screenPadding = 16;

  /// Spazio verticale di default tra card/sezioni.
  static const double sectionGap = 24;
}

/// Raggi di smussatura standard.
class AppRadii {
  AppRadii._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Card / wallet style.
  static const double card = 20;

  /// Bottoni primari.
  static const double button = 14;

  /// Modali bottom-sheet.
  static const double bottomSheet = 28;
}
