import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../l10n/app_localizations.dart';

extension SettingsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  CurrencyService get currencyService => CurrencyService();
}
