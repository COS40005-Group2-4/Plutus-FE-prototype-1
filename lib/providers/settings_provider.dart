enum AppLanguage {
  english('en', 'English'),
  vietnamese('vi', 'Tiếng Việt');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

enum AppCurrency {
  original('ORIGINAL', '', 'Original Currency'),
  vnd('VND', '₫', 'Vietnamese Dong'),
  usd('USD', '\$', 'US Dollar'),
  eur('EUR', '€', 'Euro');

  final String code;
  final String symbol;
  final String displayName;
  const AppCurrency(this.code, this.symbol, this.displayName);

  bool get isOriginal => this == AppCurrency.original;

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => AppCurrency.vnd,
    );
  }
}

enum DateFormatType {
  yyyyMMdd('YYYY/MM/DD'),
  ddMMyyyy('DD/MM/YYYY'),
  ddMonthYyyy('DD Month YYYY'),
  mmDDyyyy('MM/DD/YYYY'),
  monthDDyyyy('Month DD, YYYY');

  final String displayName;
  const DateFormatType(this.displayName);

  static DateFormatType fromString(String value) {
    return DateFormatType.values.firstWhere(
      (format) => format.name == value,
      orElse: () => DateFormatType.ddMMyyyy,
    );
  }
}

enum TimeFormatType {
  format24h('24-hour'),
  format12h('12-hour (AM/PM)');

  final String displayName;
  const TimeFormatType(this.displayName);

  static TimeFormatType fromString(String value) {
    return TimeFormatType.values.firstWhere(
      (format) => format.name == value,
      orElse: () => TimeFormatType.format24h,
    );
  }
}

