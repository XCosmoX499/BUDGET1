import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'monthly_saving.g.dart';

/// Snapshot del risparmio di un singolo mese.
///
/// Calcolato come entrate - uscite del mese. Permette di visualizzare
/// l'andamento dei risparmi nel lungo periodo nel grafico mensile.
///
/// Per default viene rigenerato al volo dalle transazioni, ma può essere
/// persistito come cache per performance su mesi storici chiusi.
@JsonSerializable()
class MonthlySaving extends Equatable {
  const MonthlySaving({
    required this.id,
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSaving,
    required this.computedAt,
  });

  final String id;
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;

  /// Risparmio netto del mese: totalIncome - totalExpense.
  final double netSaving;

  final DateTime computedAt;

  factory MonthlySaving.fromJson(Map<String, dynamic> json) =>
      _$MonthlySavingFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlySavingToJson(this);

  MonthlySaving copyWith({
    String? id,
    int? year,
    int? month,
    double? totalIncome,
    double? totalExpense,
    double? netSaving,
    DateTime? computedAt,
  }) {
    return MonthlySaving(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      netSaving: netSaving ?? this.netSaving,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        year,
        month,
        totalIncome,
        totalExpense,
        netSaving,
        computedAt,
      ];
}
