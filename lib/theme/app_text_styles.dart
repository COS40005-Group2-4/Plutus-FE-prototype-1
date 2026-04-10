/// Standardized type scale for the Plutus app.
///
/// Consolidates 15+ ad-hoc font sizes into a clean scale:
///   display  40    (hero numbers, large stats)
///   heading  24    (page titles)
///   title    20    (section headings)
///   subtitle 18    (card titles)
///   body     14    (default readable text)
///   label    12    (labels, badges, chips)
///   caption  10    (timestamps, fine print)
///
/// Use these instead of hardcoded fontSize values.
class AppTextStyles {
  AppTextStyles._();

  // ── Font sizes ──
  static const double display = 40;
  static const double heading = 24;
  static const double title = 20;
  static const double subtitle = 18;
  static const double bodyLarge = 16;
  static const double body = 14;
  static const double label = 12;
  static const double caption = 10;
}
