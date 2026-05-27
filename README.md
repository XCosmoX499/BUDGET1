# BudgetONE

> Gestisci, controlla, cresci.

App di gestione del budget personale costruita in Flutter, seguendo l’architettura `fline`.

-----

## Stato del progetto

Questa è la **prima fase (“parte invisibile”)**: tutta l’architettura, i modelli, la persistenza, lo state management, il routing e le localizzazioni sono pronti. Il livello UI/estetico è **scaffold neutro**, in attesa dei riferimenti di design definitivi forniti dal cliente.

### Cosa è già implementato

- Modelli di dominio completi (`Account`, `Transaction`, `Investment`, `InvestmentMovement`, `Routine`, `Goal`, `ScheduledExpense`, `MonthlySaving`, e DTO di aggregazione).
- Persistenza locale via `SharedPreferences` astratta dietro `LocalDataSource`, pronta a migrare a Hive/Drift senza toccare i repository.
- Repository con logica di business coerente (gestione saldi, invarianti sul conto cash, processing automatico di routine e spese programmate scadute).
- State management `flutter_bloc`: Cubit per le sezioni semplici, BLoC per la sezione Pianificazione.
- Routing tipato con `auto_route` (placeholder per le pagine, sostituiti in fase UI).
- DI con `pine`.
- Localizzazione IT + EN tramite ARB.
- Tema scaffold (Material 3 + Google Fonts Inter come placeholder).

### Cosa manca

- Implementazione dei widget UI per ogni sezione (in attesa dei riferimenti estetici del cliente).
- Eventuale integrazione di notifiche locali (`flutter_local_notifications`) per le scadenze.
- Backup/restore dei dati (export JSON / iCloud / Drive — da decidere col cliente).
- Test (di integrazione e widget — la struttura è pronta per essere testata facilmente).

-----

## Setup

### Requisiti

- Flutter SDK >= 3.22
- Dart SDK >= 3.4
- Xcode (per build iOS) / Android Studio (per build Android)

### Comandi

```bash
# Installa le dipendenze
flutter pub get

# Genera i file .g.dart (json_serializable) e .gr.dart (auto_route)
dart run build_runner build --delete-conflicting-outputs

# Genera le localizzazioni (AppLocalizations da .arb)
flutter gen-l10n

# Esegui in debug
flutter run

# Esegui i lint
flutter analyze
```

-----

## Struttura cartelle (architettura `fline`)

```
lib/
├── di/                  # Dependency injection con pine
├── l10n/                # File ARB IT/EN + generated/
├── mappers/             # Mappers DTO <-> dominio (vuoto, da popolare se servirà API)
├── model/               # Entità di dominio
├── network/
│   ├── interceptor/     # Interceptor Dio (vuoto, futuri)
│   └── service/         # LocalDataSource + futuri service Retrofit
├── repositories/        # Logica di business (CRUD + invarianti)
├── routers/             # Configurazione auto_route
├── state_management/
│   ├── bloc/            # PlanningBloc
│   ├── cubit/           # SelectedMonthCubit, DashboardCubit, AccountsCubit,
│   │                    # TransactionsCubit, InvestmentsCubit
│   └── provider/        # (vuoto, riservato a Provider semplici)
├── theme/               # AppColors, AppSpacing, AppTypography, AppTheme
├── ui/                  # (placeholder, da popolare in fase UI)
└── utils/               # CurrencyFormatter, AppDateUtils, IdGenerator, ecc.
```

-----

## Regole architetturali (`fline`)

- **No `setState`**: gestione stato sempre via BLoC/Cubit/Provider.
- **No funzioni che ritornano `Widget`**: si creano `StatelessWidget` o `StatefulWidget` dedicati.
- **No stringhe / colori / dimensioni hardcoded**: tutto da `AppLocalizations`, `AppColors`, `AppSpacing`, `AppTypography`.
- **No `Navigator` diretto**: routing solo via `auto_route` (`context.router.push(...)`, etc.).
- **DI esplicita**: dipendenze passate via costruttore, mai con singleton globali.

-----

## Note implementative chiave

- **ATM withdrawal**: registra `TransactionType.atmWithdrawal`. Sposta il saldo dal conto al cash ma **non** è conteggiato come uscita nel saldo mensile (vedi `TransactionTypeX.affectsMonthlyBalance`).
- **Transfer**: sposta tra conti, non è né entrata né uscita.
- **Investment in/out**: spostamento patrimoniale, non incide sul saldo mensile.
- **Conto Cash**: speciale, unico (`isCash: true`), creato automaticamente al primo avvio, non eliminabile.
- **Routine & spese programmate**: `PlanningRepository.processDuePlans()` va invocato all’apertura dell’app per applicare automaticamente le scadenze accumulate.