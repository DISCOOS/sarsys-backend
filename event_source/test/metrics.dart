import 'package:event_source/event_source.dart';
import 'package:test/test.dart';

void main() {
  test('zero contains initial values', () {
    final m0 = DurationMetric.zero;

    expect(m0.count, 0);
    expect(m0.isZero, isTrue);

    expect(m0.t0, isNull);
    expect(m0.tn, isNull);

    expect(m0.last, Duration.zero);
    expect(m0.total, Duration.zero);

    expect(m0.rateCum, 0);
    expect(m0.varianceCum, 0);
    expect(m0.deviationCum, 0);
    expect(m0.meanCum, Duration.zero);

    expect(m0.alpha, 0.8);
    expect(m0.beta, 1.0 - 0.8);

    expect(m0.rateExp, 0);
    expect(m0.varianceExp, 0);
    expect(m0.deviationExp, 0);
    expect(m0.meanExp, Duration.zero);
  });

  test('first calculation should yield no cum average', () {
    final d0 = Duration(seconds: 1);
    final m0 = DurationMetric.zero;
    final m1 = m0.calc(d0);

    expect(m1.count, 1);
    expect(m1.isZero, isFalse);

    expect(m1.t0, isNotNull);
    expect(m1.tn, isNotNull);

    expect(m1.last, equals(d0));
    expect(m1.total, Duration.zero);

    expect(m1.varianceCum, 0);
    expect(m1.deviationCum, 0);
    expect(m1.rateCum, equals(0));
    expect(m1.meanCum, equals(d0));
  });

  test('first calculation should yield exponential average', () {
    final d0 = Duration(seconds: 1);
    final m0 = DurationMetric.zero;
    final m1 = m0.calc(d0);

    expect(m1.count, 1);
    expect(m1.isZero, isFalse);

    expect(m1.t0, isNotNull);
    expect(m1.tn, isNotNull);

    expect(m1.last, equals(d0));
    expect(m1.total, Duration.zero);

    expect(m1.varianceExp, isNotNaN);
    expect(m1.deviationExp, isNotNaN);
    expect(m1.rateExp, equals(0));
    expect(
      m1.meanExp,
      equals(Duration(milliseconds: (1000 * 0.8).toInt())),
    );
  });

  final isNotInf = isNot(equals(double.infinity));

  test('averages and statistics are calculated', () {
    final m0 = DurationMetric.zero;

    var mi = m0;

    for (var i = 1; i <= 10; i++) {
      final di = Duration(seconds: i);
      mi = mi.calc(di);

      expect(mi.count, i);
      expect(mi.isZero, isFalse);

      expect(mi.t0, isNotNull);
      expect(mi.tn, isNotNull);
      expect(mi.last, equals(di));

      expect(mi.rateCum, isNotInf);
      expect(mi.varianceCum, isNotInf);
      expect(mi.deviationCum, isNotInf);
      expect(mi.meanExp.inMilliseconds, isNotInf);

      expect(mi.rateCum, isNotNaN);
      expect(mi.varianceExp, isNotNaN);
      expect(mi.deviationExp, isNotNaN);
      expect(mi.meanExp.inMilliseconds, isNotNaN);
    }
  });
}
