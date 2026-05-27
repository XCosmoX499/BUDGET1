import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pine/pine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di/app_module.dart';
import 'l10n/generated/app_localizations.dart';
import 'routers/app_router.dart';
import 'theme/app_theme.dart';

/// Entry point dell'app BudgetONE.
///
/// Sequenza di bootstrap:
/// 1. Inizializza i binding Flutter.
/// 2. Inizializza SharedPreferences (dipendenza obbligatoria del
///    LocalDataSource).
/// 3. Costruisce il container DI con [AppModule].
/// 4. Monta il MaterialApp.router con tema, localizzazione e routing.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    DependencyInjectorWidget(
      modules: [AppModule(sharedPreferences: sharedPreferences)],
      child: const BudgetOneApp(),
    ),
  );
}

class BudgetOneApp extends StatelessWidget {
  const BudgetOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final injector = DependencyInjectorWidget.of(context);
    final appRouter = injector.get<AppRouter>();

    return MultiBlocProvider(
      providers: buildGlobalBlocProviders(injector),
      child: MaterialApp.router(
        title: 'BudgetONE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter.config(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('it'),
          Locale('en'),
        ],
      ),
    );
  }
}
