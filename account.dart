import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'account.g.dart';

/// Rappresenta un conto dell'utente.
///
/// Un conto può essere un conto bancario tradizionale, una carta come Revolut,
/// un broker come Trade Republic, oppure un conto speciale "Contante" che
/// gestisce il cash in tasca.
///
/// Il conto contante ha un comportamento speciale: non viene azzerato a fine
/// mese e i prelievi ATM lo alimentano spostando saldo dai conti tradizionali.
@JsonSerializable()
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.emoji,
    required this.balance,
    required this.colorHex,
    required this.isCash,
    required this.isDefault,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String emoji;
  final double balance;
  final String colorHex;
  final bool isCash;
  final bool isDefault;
  final DateTime createdAt;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);

  Account copyWith({
    String? id,
    String? name,
    String? emoji,
    double? balance,
    String? colorHex,
    bool? isCash,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      balance: balance ?? this.balance,
      colorHex: colorHex ?? this.colorHex,
      isCash: isCash ?? this.isCash,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        emoji,
        balance,
        colorHex,
        isCash,
        isDefault,
        createdAt,
      ];
}
