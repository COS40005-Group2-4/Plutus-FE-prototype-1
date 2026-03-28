import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/widgets/chart_theme.dart';

void main() {
  group('PlutusChartStyle.monthAxisLabel', () {
    test('first label (null prev) gets year suffix', () {
      expect(PlutusChartStyle.monthAxisLabel('2024-01', null), "Jan '24");
    });

    test('subsequent same-year label has no suffix', () {
      expect(PlutusChartStyle.monthAxisLabel('2024-02', '2024-01'), 'Feb');
    });

    test('year rollover from Dec to Jan adds suffix', () {
      expect(PlutusChartStyle.monthAxisLabel('2025-01', '2024-12'), "Jan '25");
    });

    test('same year, no rollover, no suffix', () {
      expect(PlutusChartStyle.monthAxisLabel('2024-12', '2024-11'), 'Dec');
    });

    test('all 12 months of a rolling window crossing year boundary', () {
      final keys = [
        '2024-02', '2024-03', '2024-04', '2024-05', '2024-06',
        '2024-07', '2024-08', '2024-09', '2024-10', '2024-11',
        '2024-12', '2025-01',
      ];
      final labels = <String>[];
      for (int i = 0; i < keys.length; i++) {
        labels.add(PlutusChartStyle.monthAxisLabel(keys[i], i > 0 ? keys[i - 1] : null));
      }
      expect(labels.first, "Feb '24");
      expect(labels[1], 'Mar');
      expect(labels.last, "Jan '25");
    });
  });
}
