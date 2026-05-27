import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

/// Shorthand per accedere a [AppLocalizations] tramite il context.
///
/// Esempio: `context.l10n.welcomeMessage` invece di
/// `AppLocalizations.of(context)!.welcomeMessage`.
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
