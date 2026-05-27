import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// Configurazione del routing dell'app.
///
/// L'app usa esclusivamente [auto_route] (mai [Navigator] diretto, vincolo
/// fline). Le route sono dichiarative e tipate. La sezione UI verrà
/// implementata dopo i riferimenti estetici; per ora le route puntano a
/// placeholder che lasciano la firma corretta delle pagine.
///
/// NOTA: questa è la configurazione "non-generata" via [RootStackRouter].
/// In fase di implementazione UI verrà valutato l'uso di build_runner per
/// generare il file `app_router.gr.dart` (richiede annotation
/// @AutoRouterConfig + flutter pub run build_runner build).
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: _SplashRoute.page,
          initial: true,
        ),
        AutoRoute(
          path: '/home',
          page: _MainShellRoute.page,
          children: [
            AutoRoute(path: 'dashboard', page: _DashboardRoute.page, initial: true),
            AutoRoute(path: 'accounts', page: _AccountsRoute.page),
            AutoRoute(path: 'investments', page: _InvestmentsRoute.page),
            AutoRoute(path: 'planning', page: _PlanningRoute.page),
            AutoRoute(path: 'savings', page: _SavingsRoute.page),
          ],
        ),
        AutoRoute(path: '/account/new', page: _AccountEditorRoute.page),
        AutoRoute(path: '/account/:id', page: _AccountDetailRoute.page),
        AutoRoute(path: '/investment/new', page: _InvestmentEditorRoute.page),
        AutoRoute(path: '/investment/:id', page: _InvestmentDetailRoute.page),
        AutoRoute(path: '/transaction/income/new', page: _IncomeFormRoute.page),
        AutoRoute(path: '/transaction/expense/new', page: _ExpenseFormRoute.page),
        AutoRoute(path: '/transaction/transfer/new', page: _TransferFormRoute.page),
        AutoRoute(path: '/transaction/atm/new', page: _AtmWithdrawalFormRoute.page),
        AutoRoute(path: '/routine/new', page: _RoutineEditorRoute.page),
        AutoRoute(path: '/goal/new', page: _GoalEditorRoute.page),
        AutoRoute(path: '/scheduled/new', page: _ScheduledExpenseEditorRoute.page),
      ];
}

// ─── PLACEHOLDER PAGES (sostituite quando arriverà il design) ─────────────
//
// Ogni placeholder è una pagina marcata con [RoutePage] che mostra un
// semplice scaffold con il nome della rotta. Permette al sistema di
// routing di compilare e funzionare; le pagine vere prenderanno il loro
// posto durante la fase UI.

@RoutePage(name: '_SplashRoute')
class SplashPlaceholderPage extends StatelessWidget {
  const SplashPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Splash');
}

@RoutePage(name: '_MainShellRoute')
class MainShellPlaceholderPage extends StatelessWidget {
  const MainShellPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const AutoRouter();
}

@RoutePage(name: '_DashboardRoute')
class DashboardPlaceholderPage extends StatelessWidget {
  const DashboardPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Dashboard');
}

@RoutePage(name: '_AccountsRoute')
class AccountsPlaceholderPage extends StatelessWidget {
  const AccountsPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Accounts');
}

@RoutePage(name: '_InvestmentsRoute')
class InvestmentsPlaceholderPage extends StatelessWidget {
  const InvestmentsPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Investments');
}

@RoutePage(name: '_PlanningRoute')
class PlanningPlaceholderPage extends StatelessWidget {
  const PlanningPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Planning');
}

@RoutePage(name: '_SavingsRoute')
class SavingsPlaceholderPage extends StatelessWidget {
  const SavingsPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Savings');
}

@RoutePage(name: '_AccountEditorRoute')
class AccountEditorPlaceholderPage extends StatelessWidget {
  const AccountEditorPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Account Editor');
}

@RoutePage(name: '_AccountDetailRoute')
class AccountDetailPlaceholderPage extends StatelessWidget {
  const AccountDetailPlaceholderPage({super.key, @PathParam('id') this.id});
  final String? id;
  @override
  Widget build(BuildContext context) => _Placeholder('Account Detail: $id');
}

@RoutePage(name: '_InvestmentEditorRoute')
class InvestmentEditorPlaceholderPage extends StatelessWidget {
  const InvestmentEditorPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _Placeholder('Investment Editor');
}

@RoutePage(name: '_InvestmentDetailRoute')
class InvestmentDetailPlaceholderPage extends StatelessWidget {
  const InvestmentDetailPlaceholderPage({super.key, @PathParam('id') this.id});
  final String? id;
  @override
  Widget build(BuildContext context) => _Placeholder('Investment Detail: $id');
}

@RoutePage(name: '_IncomeFormRoute')
class IncomeFormPlaceholderPage extends StatelessWidget {
  const IncomeFormPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('New Income');
}

@RoutePage(name: '_ExpenseFormRoute')
class ExpenseFormPlaceholderPage extends StatelessWidget {
  const ExpenseFormPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('New Expense');
}

@RoutePage(name: '_TransferFormRoute')
class TransferFormPlaceholderPage extends StatelessWidget {
  const TransferFormPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('New Transfer');
}

@RoutePage(name: '_AtmWithdrawalFormRoute')
class AtmWithdrawalFormPlaceholderPage extends StatelessWidget {
  const AtmWithdrawalFormPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('ATM Withdrawal');
}

@RoutePage(name: '_RoutineEditorRoute')
class RoutineEditorPlaceholderPage extends StatelessWidget {
  const RoutineEditorPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Routine Editor');
}

@RoutePage(name: '_GoalEditorRoute')
class GoalEditorPlaceholderPage extends StatelessWidget {
  const GoalEditorPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Goal Editor');
}

@RoutePage(name: '_ScheduledExpenseEditorRoute')
class ScheduledExpenseEditorPlaceholderPage extends StatelessWidget {
  const ScheduledExpenseEditorPlaceholderPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _Placeholder('Scheduled Expense Editor');
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          '$label\n(in attesa del design)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
