import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../utils/date_time_formatter.dart';
import '../l10n/app_localizations.dart';

extension SettingsContext on BuildContext {
  SettingsProvider get settings => Provider.of<SettingsProvider>(this, listen: false);
  
  SettingsProvider get watchSettings => Provider.of<SettingsProvider>(this, listen: true);
  
  AppLocalizations get l10n => AppLocalizations.of(this);
  
  CurrencyService get currencyService => CurrencyService();
  
  String formatDate(DateTime date) {
    return DateTimeFormatter.formatDate(
      date,
      settings.dateFormat,
    );
  }
  
  String formatTime(DateTime time) {
    return DateTimeFormatter.formatTime(
      time,
      settings.timeFormat,
    );
  }
  
  String formatDateTime(DateTime dateTime) {
    return DateTimeFormatter.formatDateTime(
      dateTime,
      settings.dateFormat,
      settings.timeFormat,
    );
  }
  
  String formatDateTimeShort(DateTime dateTime, {bool includeTime = true}) {
    return DateTimeFormatter.formatDateTimeShort(
      dateTime,
      settings.dateFormat,
      settings.timeFormat,
      includeTime: includeTime,
    );
  }
  
  String formatRelativeTime(DateTime dateTime) {
    return DateTimeFormatter.formatRelativeTime(dateTime);
  }
  
  Future<String> formatCurrency(double amount, {String? currencyCode}) async {
    // Original mode: use the provided currency code as-is, no conversion
    if (settings.currency.isOriginal) {
      final code = currencyCode ?? 'VND';
      return currencyService.formatCurrency(
        amount: amount,
        currencyCode: code,
      );
    }

    final code = currencyCode ?? settings.currency.code;
    final currency = AppCurrency.fromCode(code);
    
    // If the amount is in a different currency, convert it
    if (currencyCode != null && currencyCode != settings.currency.code) {
      final converted = await currencyService.convert(
        amount: amount,
        fromCurrency: currencyCode,
        toCurrency: settings.currency.code,
      );
      return currencyService.formatCurrency(
        amount: converted,
        currencyCode: settings.currency.code,
      );
    }
    
    return currencyService.formatCurrency(
      amount: amount,
      currencyCode: code,
    );
  }
  
  String formatCurrencySync(double amount, {String? currencyCode}) {
    // Original mode: use the provided currency code as-is
    if (settings.currency.isOriginal) {
      final code = currencyCode ?? 'VND';
      return currencyService.formatCurrency(
        amount: amount,
        currencyCode: code,
      );
    }

    final code = currencyCode ?? settings.currency.code;
    
    return currencyService.formatCurrency(
      amount: amount,
      currencyCode: code,
    );
  }
}
