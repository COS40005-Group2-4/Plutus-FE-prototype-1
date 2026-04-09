import 'app_localizations.dart';

/// Locale-aware string accessor for services that lack BuildContext
/// (e.g. PDF generation, export). Uses the same translation map
/// as [AppLocalizations].
class ReportStrings {
  final String locale;

  const ReportStrings(this.locale);

  String tr(String key) => AppLocalizations.translateForLocale(locale, key);
}
