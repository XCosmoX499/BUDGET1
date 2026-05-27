import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'goal.g.dart';

/// Stato di un obiettivo di risparmio.
@JsonEnum()
enum GoalStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('abandoned')
  abandoned,
}

/// Obiettivo di risparmio dell'utente.
///
/// Esempio dal brief: acquisto di un nuovo iPhone, organizzazione di un
/// viaggio. L'utente imposta nome, target in €, scadenza e accantona
/// periodicamente la cifra che preferisce fino al raggiungimento.
@JsonSerializable()
class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    required this.createdAt,
    this.deadline,
    this.note,
  });

  final String id;
  final String name;
  final String emoji;

  /// Cifra obiettivo da raggiungere.
  final double targetAmount;

  /// Cifra attualmente accantonata.
  final double currentAmount;

  /// Scadenza opzionale entro cui raggiungere l'obiettivo.
  final DateTime? deadline;

  final GoalStatus status;
  final DateTime createdAt;
  final String? note;

  /// Percentuale di completamento (0.0 - 1.0).
  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Cifra ancora mancante per raggiungere il target.
  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Giorni mancanti alla scadenza, null se non c'è scadenza.
  int? daysUntilDeadline() {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return target.difference(today).inDays;
  }

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

  Map<String, dynamic> toJson() => _$GoalToJson(this);

  Goal copyWith({
    String? id,
    String? name,
    String? emoji,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    GoalStatus? status,
    DateTime? createdAt,
    String? note,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        emoji,
        targetAmount,
        currentAmount,
        deadline,
        status,
        createdAt,
        note,
      ];
}
