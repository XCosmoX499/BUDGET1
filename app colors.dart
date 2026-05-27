import 'package:flutter/material.dart';

/// Token colore dell'app.
///
/// SCAFFOLD: questi valori sono placeholder neutri. Saranno sostituiti
/// dalla palette definitiva quando arriveranno i riferimenti estetici dal
/// cliente. La struttura della classe (con tutti i ruoli semantici già
/// definiti) resterà invariata, così il rebranding sarà solo questione di
/// cambiare i valori in questo file.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1A2B4A);
  static const Color primaryVariant = Color(0xFF2C3E5C);
  static const Color accent = Color(0xFF4ADE80);

  // Background & surface
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);
  static const Color cash = Color(0xFFF59E0B);
  static const Color investment = Color(0xFF6366F1);
  static const Color neutral = Color(0xFF9CA3AF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF10B981);

  // Borders & dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEEF0F3);

  // Shadow placeholder (tinta soft)
  static const Color shadow = Color(0x14000000);

  /// Palette di default per la creazione di nuovi conti / investimenti.
  /// L'utente sceglie il colore tra questi all'interno della modale.
  static const List<Color> palette = [
    Color(0xFF1A2B4A), // navy
    Color(0xFF10B981), // verde
    Color(0xFFEF4444), // rosso
    Color(0xFFF59E0B), // ambra
    Color(0xFF6366F1), // indaco
    Color(0xFFEC4899), // rosa
    Color(0xFF14B8A6), // teal
    Color(0xFF8B5CF6), // viola
  ];
}
