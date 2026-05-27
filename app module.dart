import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:pine/pine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/service/local_data_source.dart';
import '../repositories/accounts_repository.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/investments_repository.dart';
import '../repositories/planning_repository.dart';
import '../repositories/transactions_repository.dart';
import '../routers/app_router.dart';
import '../state_management/bloc/planning_bloc.dart';
import '../state_management/cubit/accounts_cubit.dart';
import '../state_management/cubit/dashboard_cubit.dart';
import '../state_management/cubit/investments_cubit.dart';
import '../state_management/cubit/selected_month_cubit.dart';
import '../state_management/cubit/transactions_cubit.dart';
import '../utils/id_generator.dart';

/// Modulo di DI dell'app costruito con [pine].
///
/// Espone in ordine:
/// 1. Singleton infrastrutturali (Logger, IdGenerator, SharedPreferences,
///    LocalDataSource, AppRouter).
/// 2. Repository (dipendono dagli infrastrutturali).
/// 3. Cubit e BLoC (esposti come Provider/BlocProvider via [providers]
///    nel widget root).
///
/// L'ordine di registrazione è importante: ogni elemento può dipendere
/// solo da quelli registrati prima.
class AppModule extends InjectorModule {
  AppModule({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  Future<DependencyInjector> inject(DependencyInjector injector) async {
    // ─── INFRASTRUCTURE ───────────────────────────────────────────────────
    injector.addSingleton<Logger>((_) => Logger());
    injector.addSingleton<IdGenerator>((_) => IdGenerator());
    injector.addSingleton<SharedPreferences>((_) => sharedPreferences);
    injector.addSingleton<LocalDataSource>(
      (i) => LocalDataSource(
        preferences: i.get<SharedPreferences>(),
        logger: i.get<Logger>(),
      ),
    );
    injector.addSingleton<AppRouter>((_) => AppRouter());

    // ─── REPOSITORIES ─────────────────────────────────────────────────────
    injector.addSingleton<AccountsRepository>(
      (i) => AccountsRepository(
        localDataSource: i.get<LocalDataSource>(),
        logger: i.get<Logger>(),
        idGenerator: i.get<IdGenerator>(),
      ),
    );
    injector.addSingleton<TransactionsRepository>(
      (i) => TransactionsRepository(
        localDataSource: i.get<LocalDataSource>(),
        logger: i.get<Logger>(),
        idGenerator: i.get<IdGenerator>(),
        accountsRepository: i.get<AccountsRepository>(),
      ),
    );
    injector.addSingleton<CategoriesRepository>(
      (i) => CategoriesRepository(
        localDataSource: i.get<LocalDataSource>(),
        logger: i.get<Logger>(),
        idGenerator: i.get<IdGenerator>(),
      ),
    );
    injector.addSingleton<InvestmentsRepository>(
      (i) => InvestmentsRepository(
        localDataSource: i.get<LocalDataSource>(),
        logger: i.get<Logger>(),
        idGenerator: i.get<IdGenerator>(),
        transactionsRepository: i.get<TransactionsRepository>(),
      ),
    );
    injector.addSingleton<PlanningRepository>(
      (i) => PlanningRepository(
        localDataSource: i.get<LocalDataSource>(),
        logger: i.get<Logger>(),
        idGenerator: i.get<IdGenerator>(),
        transactionsRepository: i.get<TransactionsRepository>(),
      ),
    );
    injector.addSingleton<AnalyticsRepository>(
      (i) => AnalyticsRepository(
        logger: i.get<Logger>(),
        accountsRepository: i.get<AccountsRepository>(),
        transactionsRepository: i.get<TransactionsRepository>(),
        investmentsRepository: i.get<InvestmentsRepository>(),
        categoriesRepository: i.get<CategoriesRepository>(),
      ),
    );

    return injector;
  }
}

/// Lista dei [BlocProvider] globali che il widget root costruisce sopra
/// il MaterialApp. Vengono istanziati nuovi (factory) perché il loro ciclo
/// vita è legato al widget, non al singleton DI.
List<BlocProvider> buildGlobalBlocProviders(DependencyInjector i) {
  return [
    BlocProvider<SelectedMonthCubit>(
      create: (_) => SelectedMonthCubit(),
    ),
    BlocProvider<DashboardCubit>(
      create: (_) => DashboardCubit(
        analyticsRepository: i.get<AnalyticsRepository>(),
        planningRepository: i.get<PlanningRepository>(),
      ),
    ),
    BlocProvider<AccountsCubit>(
      create: (_) => AccountsCubit(
        accountsRepository: i.get<AccountsRepository>(),
        transactionsRepository: i.get<TransactionsRepository>(),
      ),
    ),
    BlocProvider<TransactionsCubit>(
      create: (_) => TransactionsCubit(
        transactionsRepository: i.get<TransactionsRepository>(),
      ),
    ),
    BlocProvider<InvestmentsCubit>(
      create: (_) => InvestmentsCubit(
        investmentsRepository: i.get<InvestmentsRepository>(),
        analyticsRepository: i.get<AnalyticsRepository>(),
      ),
    ),
    BlocProvider<PlanningBloc>(
      create: (_) => PlanningBloc(
        planningRepository: i.get<PlanningRepository>(),
      ),
    ),
  ];
}

/// Helper per recuperare dipendenze dal context tramite [DependencyInjector].
extension AppDIContext on BuildContext {
  T get<T extends Object>() => DependencyInjectorWidget.of(this).get<T>();
}
