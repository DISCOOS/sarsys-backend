///
//  Generated code. Do not modify.
//  source: metric.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'timestamp.pb.dart' as $4;

class DurationMetricMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DurationMetricMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'count')
    ..aOM<$4.Timestamp>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 't0',
        subBuilder: $4.Timestamp.create)
    ..aOM<$4.Timestamp>(3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tn',
        subBuilder: $4.Timestamp.create)
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'last')
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'total')
    ..aOM<DurationCumulativeAverage>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cumulative', subBuilder: DurationCumulativeAverage.create)
    ..aOM<DurationExponentialAverage>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exponential', subBuilder: DurationExponentialAverage.create)
    ..hasRequiredFields = false;

  DurationMetricMeta._() : super();
  factory DurationMetricMeta({
    $fixnum.Int64? count,
    $4.Timestamp? t0,
    $4.Timestamp? tn,
    $fixnum.Int64? last,
    $fixnum.Int64? total,
    DurationCumulativeAverage? cumulative,
    DurationExponentialAverage? exponential,
  }) {
    final _result = create();
    if (count != null) {
      _result.count = count;
    }
    if (t0 != null) {
      _result.t0 = t0;
    }
    if (tn != null) {
      _result.tn = tn;
    }
    if (last != null) {
      _result.last = last;
    }
    if (total != null) {
      _result.total = total;
    }
    if (cumulative != null) {
      _result.cumulative = cumulative;
    }
    if (exponential != null) {
      _result.exponential = exponential;
    }
    return _result;
  }
  factory DurationMetricMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DurationMetricMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DurationMetricMeta clone() => DurationMetricMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DurationMetricMeta copyWith(void Function(DurationMetricMeta) updates) =>
      super.copyWith((message) => updates(message as DurationMetricMeta))
          as DurationMetricMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DurationMetricMeta create() => DurationMetricMeta._();
  DurationMetricMeta createEmptyInstance() => create();
  static $pb.PbList<DurationMetricMeta> createRepeated() =>
      $pb.PbList<DurationMetricMeta>();
  @$core.pragma('dart2js:noInline')
  static DurationMetricMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DurationMetricMeta>(create);
  static DurationMetricMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get count => $_getI64(0);
  @$pb.TagNumber(1)
  set count($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => clearField(1);

  @$pb.TagNumber(2)
  $4.Timestamp get t0 => $_getN(1);
  @$pb.TagNumber(2)
  set t0($4.Timestamp v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasT0() => $_has(1);
  @$pb.TagNumber(2)
  void clearT0() => clearField(2);
  @$pb.TagNumber(2)
  $4.Timestamp ensureT0() => $_ensure(1);

  @$pb.TagNumber(3)
  $4.Timestamp get tn => $_getN(2);
  @$pb.TagNumber(3)
  set tn($4.Timestamp v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTn() => $_has(2);
  @$pb.TagNumber(3)
  void clearTn() => clearField(3);
  @$pb.TagNumber(3)
  $4.Timestamp ensureTn() => $_ensure(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get last => $_getI64(3);
  @$pb.TagNumber(4)
  set last($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLast() => $_has(3);
  @$pb.TagNumber(4)
  void clearLast() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get total => $_getI64(4);
  @$pb.TagNumber(5)
  set total($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTotal() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotal() => clearField(5);

  @$pb.TagNumber(6)
  DurationCumulativeAverage get cumulative => $_getN(5);
  @$pb.TagNumber(6)
  set cumulative(DurationCumulativeAverage v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCumulative() => $_has(5);
  @$pb.TagNumber(6)
  void clearCumulative() => clearField(6);
  @$pb.TagNumber(6)
  DurationCumulativeAverage ensureCumulative() => $_ensure(5);

  @$pb.TagNumber(7)
  DurationExponentialAverage get exponential => $_getN(6);
  @$pb.TagNumber(7)
  set exponential(DurationExponentialAverage v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasExponential() => $_has(6);
  @$pb.TagNumber(7)
  void clearExponential() => clearField(7);
  @$pb.TagNumber(7)
  DurationExponentialAverage ensureExponential() => $_ensure(6);
}

class DurationCumulativeAverage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DurationCumulativeAverage',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..a<$core.double>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'rate',
        $pb.PbFieldType.OD)
    ..aInt64(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mean')
    ..a<$core.double>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'variance',
        $pb.PbFieldType.OD)
    ..a<$core.double>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deviation', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  DurationCumulativeAverage._() : super();
  factory DurationCumulativeAverage({
    $core.double? rate,
    $fixnum.Int64? mean,
    $core.double? variance,
    $core.double? deviation,
  }) {
    final _result = create();
    if (rate != null) {
      _result.rate = rate;
    }
    if (mean != null) {
      _result.mean = mean;
    }
    if (variance != null) {
      _result.variance = variance;
    }
    if (deviation != null) {
      _result.deviation = deviation;
    }
    return _result;
  }
  factory DurationCumulativeAverage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DurationCumulativeAverage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DurationCumulativeAverage clone() =>
      DurationCumulativeAverage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DurationCumulativeAverage copyWith(
          void Function(DurationCumulativeAverage) updates) =>
      super.copyWith((message) => updates(message as DurationCumulativeAverage))
          as DurationCumulativeAverage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DurationCumulativeAverage create() => DurationCumulativeAverage._();
  DurationCumulativeAverage createEmptyInstance() => create();
  static $pb.PbList<DurationCumulativeAverage> createRepeated() =>
      $pb.PbList<DurationCumulativeAverage>();
  @$core.pragma('dart2js:noInline')
  static DurationCumulativeAverage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DurationCumulativeAverage>(create);
  static DurationCumulativeAverage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get rate => $_getN(0);
  @$pb.TagNumber(1)
  set rate($core.double v) {
    $_setDouble(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRate() => $_has(0);
  @$pb.TagNumber(1)
  void clearRate() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get mean => $_getI64(1);
  @$pb.TagNumber(2)
  set mean($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMean() => $_has(1);
  @$pb.TagNumber(2)
  void clearMean() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get variance => $_getN(2);
  @$pb.TagNumber(3)
  set variance($core.double v) {
    $_setDouble(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVariance() => $_has(2);
  @$pb.TagNumber(3)
  void clearVariance() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get deviation => $_getN(3);
  @$pb.TagNumber(4)
  set deviation($core.double v) {
    $_setDouble(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasDeviation() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviation() => clearField(4);
}

class DurationExponentialAverage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DurationExponentialAverage',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..a<$core.double>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'alpha',
        $pb.PbFieldType.OD)
    ..a<$core.double>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'beta',
        $pb.PbFieldType.OD)
    ..a<$core.double>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rate',
        $pb.PbFieldType.OD)
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mean')
    ..a<$core.double>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'variance', $pb.PbFieldType.OD)
    ..a<$core.double>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deviation', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  DurationExponentialAverage._() : super();
  factory DurationExponentialAverage({
    $core.double? alpha,
    $core.double? beta,
    $core.double? rate,
    $fixnum.Int64? mean,
    $core.double? variance,
    $core.double? deviation,
  }) {
    final _result = create();
    if (alpha != null) {
      _result.alpha = alpha;
    }
    if (beta != null) {
      _result.beta = beta;
    }
    if (rate != null) {
      _result.rate = rate;
    }
    if (mean != null) {
      _result.mean = mean;
    }
    if (variance != null) {
      _result.variance = variance;
    }
    if (deviation != null) {
      _result.deviation = deviation;
    }
    return _result;
  }
  factory DurationExponentialAverage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DurationExponentialAverage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DurationExponentialAverage clone() =>
      DurationExponentialAverage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DurationExponentialAverage copyWith(
          void Function(DurationExponentialAverage) updates) =>
      super.copyWith(
              (message) => updates(message as DurationExponentialAverage))
          as DurationExponentialAverage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DurationExponentialAverage create() => DurationExponentialAverage._();
  DurationExponentialAverage createEmptyInstance() => create();
  static $pb.PbList<DurationExponentialAverage> createRepeated() =>
      $pb.PbList<DurationExponentialAverage>();
  @$core.pragma('dart2js:noInline')
  static DurationExponentialAverage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DurationExponentialAverage>(create);
  static DurationExponentialAverage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get alpha => $_getN(0);
  @$pb.TagNumber(1)
  set alpha($core.double v) {
    $_setDouble(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasAlpha() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlpha() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get beta => $_getN(1);
  @$pb.TagNumber(2)
  set beta($core.double v) {
    $_setDouble(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBeta() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeta() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get rate => $_getN(2);
  @$pb.TagNumber(3)
  set rate($core.double v) {
    $_setDouble(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasRate() => $_has(2);
  @$pb.TagNumber(3)
  void clearRate() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get mean => $_getI64(3);
  @$pb.TagNumber(4)
  set mean($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMean() => $_has(3);
  @$pb.TagNumber(4)
  void clearMean() => clearField(4);

  @$pb.TagNumber(5)
  $core.double get variance => $_getN(4);
  @$pb.TagNumber(5)
  set variance($core.double v) {
    $_setDouble(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasVariance() => $_has(4);
  @$pb.TagNumber(5)
  void clearVariance() => clearField(5);

  @$pb.TagNumber(6)
  $core.double get deviation => $_getN(5);
  @$pb.TagNumber(6)
  set deviation($core.double v) {
    $_setDouble(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasDeviation() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviation() => clearField(6);
}
