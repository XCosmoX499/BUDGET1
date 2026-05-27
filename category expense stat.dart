import 'package:equatable/equatable.dart';

/// Statistica di spesa per una singola categoria in un mese.
///
/// Usato per popolare il grafico a ciambella "Uscite per categoria"
/// della dashboard.
class CategoryExpenseStat extends Equatable {
  const CategoryExpenseStat({
    required this.categoryId,
    required this.categoryNameKey,
    required this.emoji,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  final String categoryId;
  final String categoryNameKey;
  final String emoji;
  final double totalAmount;
  final int transactionCount;

  /// Percentuale rispetto al totale delle uscite del mese (0.0 - 100.0).
  final double percentage;

  @override
  List<Object?> get props => [
        categoryId,
        categoryNameKey,
        emoji,
        totalAmount,
        transactionCount,
        percentage,
      ];
}
