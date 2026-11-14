import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

void main() {
  group('WNumFormatExtension', () {
    test('toThousandsSeparated', () {
      expect(1234.toThousandsSeparated, '1,234');
      expect(1234567.toThousandsSeparated, '1,234,567');
      expect(1234.56.toThousandsSeparated, '1,234.56');
      expect(0.toThousandsSeparated, '0');
      expect((-1234).toThousandsSeparated, '-1,234');
    });

    test('toThousandsSeparated — 科学计数法展开', () {
      expect(1e21.toThousandsSeparated, '1,000,000,000,000,000,000,000');
      expect((-1e21).toThousandsSeparated, '-1,000,000,000,000,000,000,000');
      expect(1.2345e22.toThousandsSeparated, '12,345,000,000,000,000,000,000');
      expect(1.5e-7.toThousandsSeparated, '0.00000015');
      expect(1e-7.toThousandsSeparated, '0.0000001');
      expect(double.nan.toThousandsSeparated, 'NaN');
      expect(double.infinity.toThousandsSeparated, 'Infinity');
      expect((-double.infinity).toThousandsSeparated, '-Infinity');
    });

    test('toCurrency', () {
      expect(1234.toCurrency(symbol: '¥'), '¥1,234');
      expect(1234.56.toCurrency(symbol: '\$'), '\$1,234.56');
      expect(0.toCurrency(symbol: '¥'), '¥0');
      expect((-1234.56).toCurrency(symbol: '\$'), '-\$1,234.56');
    });

    test('toCurrency — 科学计数法展开', () {
      expect(1e21.toCurrency(symbol: '¥'), '¥1,000,000,000,000,000,000,000');
      expect(
        1.2345e22.toCurrency(symbol: '¥', thousandSeparator: ' '),
        '¥12 345 000 000 000 000 000 000',
      );
      expect(
        1.5e-7.toCurrency(symbol: '\$', decimalSeparator: ','),
        '\$0,00000015',
      );
      expect(double.nan.toCurrency(symbol: '¥'), 'NaN');
      expect(double.infinity.toCurrency(symbol: '¥'), 'Infinity');
    });

    test('toPercent', () {
      expect(0.5.toPercent, '50%');
      expect(0.333.toPercent, '33.3%');
      expect(1.25.toPercentWithFixed(1), '125.0%');
      expect(0.0.toPercent, '0%');
      expect(2.0.toPercent, '200%');
      expect(double.infinity.toPercent, 'Infinity%');
      expect(double.nan.toPercent, 'NaN%');
    });

    test('toPadLeft', () {
      expect(1.toPadLeft(2), '01');
      expect(123.toPadLeft(2), '123');
      expect(5.toPadLeft(4), '0005');
      expect(0.toPadLeft(3), '000');
      expect((-1).toPadLeft(3), '-01');
      expect((-12).toPadLeft(4), '-012');
      expect(() => 1.toPadLeft(-1), throwsAssertionError);
    });
  });
}
