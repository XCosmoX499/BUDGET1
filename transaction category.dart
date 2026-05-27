import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_category.g.dart';

/// Categoria di una transazione, identificata da un'emoji e un nome.
///
/// Esempi dal brief: Casa, Spesa, Trasporti, Ristorante, Salute, Svago,
/// Abbonamenti, Istruzione, Abbigliamento, Auto, Regali, Prestiti, Altro
/// per le uscite; Stipendio, Extra, Regalo, Rimborso, Freelance, Altro
/// per le entrate.
@JsonSerializable()
class TransactionCategory extends Equatable {
  const TransactionCategory({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.isIncome,
    required this.isCustom,
  });

  final String id;

  /// Chiave di localizzazione del nome (es. "categoryHome", "categoryFood").
  /// Per categorie custom create dall'utente coincide con il nome stesso.
  final String nameKey;
  final String emoji;
  final bool isIncome;

  /// True se è una categoria creata dall'utente, false se è predefinita.
  final bool isCustom;

  factory TransactionCategory.fromJson(Map<String, dynamic> json) =>
      _$TransactionCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionCategoryToJson(this);

  TransactionCategory copyWith({
    String? id,
    String? nameKey,
    String? emoji,
    bool? isIncome,
    bool? isCustom,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      emoji: emoji ?? this.emoji,
      isIncome: isIncome ?? this.isIncome,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  List<Object?> get props => [id, nameKey, emoji, isIncome, isCustom];
}

/// Catalogo delle categorie predefinite.
///
/// Gli ID sono stabili e usati come chiavi di riferimento in tutto il sistema.
class DefaultCategories {
  // Uscite
  static const home = TransactionCategory(
    id: 'cat_home',
    nameKey: 'categoryHome',
    emoji: '🏠',
    isIncome: false,
    isCustom: false,
  );
  static const groceries = TransactionCategory(
    id: 'cat_groceries',
    nameKey: 'categoryGroceries',
    emoji: '🛒',
    isIncome: false,
    isCustom: false,
  );
  static const transport = TransactionCategory(
    id: 'cat_transport',
    nameKey: 'categoryTransport',
    emoji: '🚇',
    isIncome: false,
    isCustom: false,
  );
  static const restaurant = TransactionCategory(
    id: 'cat_restaurant',
    nameKey: 'categoryRestaurant',
    emoji: '🍽️',
    isIncome: false,
    isCustom: false,
  );
  static const health = TransactionCategory(
    id: 'cat_health',
    nameKey: 'categoryHealth',
    emoji: '💊',
    isIncome: false,
    isCustom: false,
  );
  static const leisure = TransactionCategory(
    id: 'cat_leisure',
    nameKey: 'categoryLeisure',
    emoji: '🎉',
    isIncome: false,
    isCustom: false,
  );
  static const subscriptions = TransactionCategory(
    id: 'cat_subscriptions',
    nameKey: 'categorySubscriptions',
    emoji: '📱',
    isIncome: false,
    isCustom: false,
  );
  static const education = TransactionCategory(
    id: 'cat_education',
    nameKey: 'categoryEducation',
    emoji: '📚',
    isIncome: false,
    isCustom: false,
  );
  static const clothing = TransactionCategory(
    id: 'cat_clothing',
    nameKey: 'categoryClothing',
    emoji: '👗',
    isIncome: false,
    isCustom: false,
  );
  static const car = TransactionCategory(
    id: 'cat_car',
    nameKey: 'categoryCar',
    emoji: '🚗',
    isIncome: false,
    isCustom: false,
  );
  static const gifts = TransactionCategory(
    id: 'cat_gifts',
    nameKey: 'categoryGifts',
    emoji: '🎁',
    isIncome: false,
    isCustom: false,
  );
  static const loans = TransactionCategory(
    id: 'cat_loans',
    nameKey: 'categoryLoans',
    emoji: '💳',
    isIncome: false,
    isCustom: false,
  );
  static const otherExpense = TransactionCategory(
    id: 'cat_other_expense',
    nameKey: 'categoryOtherExpense',
    emoji: '📦',
    isIncome: false,
    isCustom: false,
  );

  // Entrate
  static const salary = TransactionCategory(
    id: 'cat_salary',
    nameKey: 'categorySalary',
    emoji: '💼',
    isIncome: true,
    isCustom: false,
  );
  static const extra = TransactionCategory(
    id: 'cat_extra',
    nameKey: 'categoryExtra',
    emoji: '⭐',
    isIncome: true,
    isCustom: false,
  );
  static const gift = TransactionCategory(
    id: 'cat_gift_in',
    nameKey: 'categoryGiftIncome',
    emoji: '🎁',
    isIncome: true,
    isCustom: false,
  );
  static const refund = TransactionCategory(
    id: 'cat_refund',
    nameKey: 'categoryRefund',
    emoji: '↩️',
    isIncome: true,
    isCustom: false,
  );
  static const freelance = TransactionCategory(
    id: 'cat_freelance',
    nameKey: 'categoryFreelance',
    emoji: '💻',
    isIncome: true,
    isCustom: false,
  );
  static const otherIncome = TransactionCategory(
    id: 'cat_other_income',
    nameKey: 'categoryOtherIncome',
    emoji: '📦',
    isIncome: true,
    isCustom: false,
  );

  static const List<TransactionCategory> expenseCategories = [
    home,
    groceries,
    transport,
    restaurant,
    health,
    leisure,
    subscriptions,
    education,
    clothing,
    car,
    gifts,
    loans,
    otherExpense,
  ];

  static const List<TransactionCategory> incomeCategories = [
    salary,
    extra,
    gift,
    refund,
    freelance,
    otherIncome,
  ];

  static List<TransactionCategory> get all =>
      [...expenseCategories, ...incomeCategories];
}
