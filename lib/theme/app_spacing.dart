/// Standardized spacing on a 4pt grid, split into two scales (spec §2.2):
/// the component scale spaces content *inside* a card/button/field; the
/// layout scale spaces sections and cards *apart*. Keeping them named
/// separately stops internal padding drifting into structural rhythm.
class AppSpacing {
  AppSpacing._();

  // ── Legacy generic scale (kept for existing call-sites) ──
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // ── Component scale: padding and gaps inside a component ──
  static const double componentXs = 4;
  static const double componentSm = 8;
  static const double componentMd = 12;
  static const double componentLg = 16;
  static const double componentXl = 20;
  static const double componentXxl = 24;

  // ── Layout scale: space between sections and cards ──
  static const double layoutSm = 24;
  static const double layoutMd = 32;
  static const double layoutLg = 48;
  static const double layoutXl = 64;
}
