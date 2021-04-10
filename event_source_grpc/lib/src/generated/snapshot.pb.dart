///
//  Generated code. Do not modify.
//  source: snapshot.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'aggregate.pb.dart' as $0;
import 'metric.pb.dart' as $7;
import 'file.pb.dart' as $3;

import 'snapshot.pbenum.dart';

export 'snapshot.pbenum.dart';

class GetSnapshotMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetSnapshotMetaRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..pc<SnapshotExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: SnapshotExpandFields.valueOf,
        enumValues: SnapshotExpandFields.values)
    ..hasRequiredFields = false;

  GetSnapshotMetaRequest._() : super();
  factory GetSnapshotMetaRequest({
    $core.String? type,
    $core.Iterable<SnapshotExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory GetSnapshotMetaRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetSnapshotMetaRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetSnapshotMetaRequest clone() =>
      GetSnapshotMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetSnapshotMetaRequest copyWith(
          void Function(GetSnapshotMetaRequest) updates) =>
      super.copyWith((message) => updates(message as GetSnapshotMetaRequest))
          as GetSnapshotMetaRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetSnapshotMetaRequest create() => GetSnapshotMetaRequest._();
  GetSnapshotMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetSnapshotMetaRequest> createRepeated() =>
      $pb.PbList<GetSnapshotMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetSnapshotMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSnapshotMetaRequest>(create);
  static GetSnapshotMetaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<SnapshotExpandFields> get expand => $_getList(1);
}

class GetSnapshotMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetSnapshotMetaResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<SnapshotMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
        subBuilder: SnapshotMeta.create)
    ..hasRequiredFields = false;

  GetSnapshotMetaResponse._() : super();
  factory GetSnapshotMetaResponse({
    $core.String? type,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    SnapshotMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory GetSnapshotMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetSnapshotMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetSnapshotMetaResponse clone() =>
      GetSnapshotMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetSnapshotMetaResponse copyWith(
          void Function(GetSnapshotMetaResponse) updates) =>
      super.copyWith((message) => updates(message as GetSnapshotMetaResponse))
          as GetSnapshotMetaResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetSnapshotMetaResponse create() => GetSnapshotMetaResponse._();
  GetSnapshotMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetSnapshotMetaResponse> createRepeated() =>
      $pb.PbList<GetSnapshotMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetSnapshotMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSnapshotMetaResponse>(create);
  static GetSnapshotMetaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set statusCode($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatusCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(3)
  set reasonPhrase($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(3)
  void clearReasonPhrase() => clearField(3);

  @$pb.TagNumber(4)
  SnapshotMeta get meta => $_getN(3);
  @$pb.TagNumber(4)
  set meta(SnapshotMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(4)
  void clearMeta() => clearField(4);
  @$pb.TagNumber(4)
  SnapshotMeta ensureMeta() => $_ensure(3);
}

class SnapshotMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SnapshotMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuid')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'last')
    ..aInt64(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'number')
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'position')
    ..aOM<SnapshotConfig>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'config', subBuilder: SnapshotConfig.create)
    ..aOM<SnapshotMetricsMeta>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'metrics', subBuilder: SnapshotMetricsMeta.create)
    ..aOM<$0.AggregateMetaList>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'aggregates', subBuilder: $0.AggregateMetaList.create)
    ..hasRequiredFields = false;

  SnapshotMeta._() : super();
  factory SnapshotMeta({
    $core.String? type,
    $core.String? uuid,
    $core.String? last,
    $fixnum.Int64? number,
    $fixnum.Int64? position,
    SnapshotConfig? config,
    SnapshotMetricsMeta? metrics,
    $0.AggregateMetaList? aggregates,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (last != null) {
      _result.last = last;
    }
    if (number != null) {
      _result.number = number;
    }
    if (position != null) {
      _result.position = position;
    }
    if (config != null) {
      _result.config = config;
    }
    if (metrics != null) {
      _result.metrics = metrics;
    }
    if (aggregates != null) {
      _result.aggregates = aggregates;
    }
    return _result;
  }
  factory SnapshotMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SnapshotMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SnapshotMeta clone() => SnapshotMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SnapshotMeta copyWith(void Function(SnapshotMeta) updates) =>
      super.copyWith((message) => updates(message as SnapshotMeta))
          as SnapshotMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SnapshotMeta create() => SnapshotMeta._();
  SnapshotMeta createEmptyInstance() => create();
  static $pb.PbList<SnapshotMeta> createRepeated() =>
      $pb.PbList<SnapshotMeta>();
  @$core.pragma('dart2js:noInline')
  static SnapshotMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotMeta>(create);
  static SnapshotMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get uuid => $_getSZ(1);
  @$pb.TagNumber(2)
  set uuid($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUuid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUuid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get last => $_getSZ(2);
  @$pb.TagNumber(3)
  set last($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLast() => $_has(2);
  @$pb.TagNumber(3)
  void clearLast() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get number => $_getI64(3);
  @$pb.TagNumber(4)
  set number($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasNumber() => $_has(3);
  @$pb.TagNumber(4)
  void clearNumber() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get position => $_getI64(4);
  @$pb.TagNumber(5)
  set position($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPosition() => $_has(4);
  @$pb.TagNumber(5)
  void clearPosition() => clearField(5);

  @$pb.TagNumber(6)
  SnapshotConfig get config => $_getN(5);
  @$pb.TagNumber(6)
  set config(SnapshotConfig v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasConfig() => $_has(5);
  @$pb.TagNumber(6)
  void clearConfig() => clearField(6);
  @$pb.TagNumber(6)
  SnapshotConfig ensureConfig() => $_ensure(5);

  @$pb.TagNumber(7)
  SnapshotMetricsMeta get metrics => $_getN(6);
  @$pb.TagNumber(7)
  set metrics(SnapshotMetricsMeta v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasMetrics() => $_has(6);
  @$pb.TagNumber(7)
  void clearMetrics() => clearField(7);
  @$pb.TagNumber(7)
  SnapshotMetricsMeta ensureMetrics() => $_ensure(6);

  @$pb.TagNumber(8)
  $0.AggregateMetaList get aggregates => $_getN(7);
  @$pb.TagNumber(8)
  set aggregates($0.AggregateMetaList v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasAggregates() => $_has(7);
  @$pb.TagNumber(8)
  void clearAggregates() => clearField(8);
  @$pb.TagNumber(8)
  $0.AggregateMetaList ensureAggregates() => $_ensure(7);
}

class SnapshotConfig extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SnapshotConfig',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'keep',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'threshold',
        $pb.PbFieldType.O3)
    ..aOB(3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'automatic')
    ..hasRequiredFields = false;

  SnapshotConfig._() : super();
  factory SnapshotConfig({
    $core.int? keep,
    $core.int? threshold,
    $core.bool? automatic,
  }) {
    final _result = create();
    if (keep != null) {
      _result.keep = keep;
    }
    if (threshold != null) {
      _result.threshold = threshold;
    }
    if (automatic != null) {
      _result.automatic = automatic;
    }
    return _result;
  }
  factory SnapshotConfig.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SnapshotConfig.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SnapshotConfig clone() => SnapshotConfig()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SnapshotConfig copyWith(void Function(SnapshotConfig) updates) =>
      super.copyWith((message) => updates(message as SnapshotConfig))
          as SnapshotConfig; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SnapshotConfig create() => SnapshotConfig._();
  SnapshotConfig createEmptyInstance() => create();
  static $pb.PbList<SnapshotConfig> createRepeated() =>
      $pb.PbList<SnapshotConfig>();
  @$core.pragma('dart2js:noInline')
  static SnapshotConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotConfig>(create);
  static SnapshotConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get keep => $_getIZ(0);
  @$pb.TagNumber(1)
  set keep($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasKeep() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeep() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get threshold => $_getIZ(1);
  @$pb.TagNumber(2)
  set threshold($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasThreshold() => $_has(1);
  @$pb.TagNumber(2)
  void clearThreshold() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get automatic => $_getBF(2);
  @$pb.TagNumber(3)
  set automatic($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAutomatic() => $_has(2);
  @$pb.TagNumber(3)
  void clearAutomatic() => clearField(3);
}

class SnapshotMetricsMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo
      _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SnapshotMetricsMeta',
          package: const $pb.PackageName(
              const $core.bool.fromEnvironment('protobuf.omit_message_names')
                  ? ''
                  : 'org.discoos.es'),
          createEmptyInstance: create)
        ..aInt64(
            1,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'snapshots')
        ..aInt64(
            2,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'unsaved')
        ..aInt64(
            3,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'missing')
        ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isPartial',
            protoName: 'isPartial')
        ..aOM<$7.DurationMetricMeta>(
            5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'save',
            subBuilder: $7.DurationMetricMeta.create)
        ..hasRequiredFields = false;

  SnapshotMetricsMeta._() : super();
  factory SnapshotMetricsMeta({
    $fixnum.Int64? snapshots,
    $fixnum.Int64? unsaved,
    $fixnum.Int64? missing,
    $core.bool? isPartial,
    $7.DurationMetricMeta? save,
  }) {
    final _result = create();
    if (snapshots != null) {
      _result.snapshots = snapshots;
    }
    if (unsaved != null) {
      _result.unsaved = unsaved;
    }
    if (missing != null) {
      _result.missing = missing;
    }
    if (isPartial != null) {
      _result.isPartial = isPartial;
    }
    if (save != null) {
      _result.save = save;
    }
    return _result;
  }
  factory SnapshotMetricsMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SnapshotMetricsMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SnapshotMetricsMeta clone() => SnapshotMetricsMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SnapshotMetricsMeta copyWith(void Function(SnapshotMetricsMeta) updates) =>
      super.copyWith((message) => updates(message as SnapshotMetricsMeta))
          as SnapshotMetricsMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SnapshotMetricsMeta create() => SnapshotMetricsMeta._();
  SnapshotMetricsMeta createEmptyInstance() => create();
  static $pb.PbList<SnapshotMetricsMeta> createRepeated() =>
      $pb.PbList<SnapshotMetricsMeta>();
  @$core.pragma('dart2js:noInline')
  static SnapshotMetricsMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotMetricsMeta>(create);
  static SnapshotMetricsMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get snapshots => $_getI64(0);
  @$pb.TagNumber(1)
  set snapshots($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSnapshots() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshots() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get unsaved => $_getI64(1);
  @$pb.TagNumber(2)
  set unsaved($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUnsaved() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnsaved() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get missing => $_getI64(2);
  @$pb.TagNumber(3)
  set missing($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMissing() => $_has(2);
  @$pb.TagNumber(3)
  void clearMissing() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isPartial => $_getBF(3);
  @$pb.TagNumber(4)
  set isPartial($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasIsPartial() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsPartial() => clearField(4);

  @$pb.TagNumber(5)
  $7.DurationMetricMeta get save => $_getN(4);
  @$pb.TagNumber(5)
  set save($7.DurationMetricMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasSave() => $_has(4);
  @$pb.TagNumber(5)
  void clearSave() => clearField(5);
  @$pb.TagNumber(5)
  $7.DurationMetricMeta ensureSave() => $_ensure(4);
}

class ConfigureSnapshotRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ConfigureSnapshotRequest',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'automatic')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'keep',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'threshold',
        $pb.PbFieldType.O3)
    ..pc<SnapshotExpandFields>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE,
        valueOf: SnapshotExpandFields.valueOf,
        enumValues: SnapshotExpandFields.values)
    ..hasRequiredFields = false;

  ConfigureSnapshotRequest._() : super();
  factory ConfigureSnapshotRequest({
    $core.String? type,
    $core.bool? automatic,
    $core.int? keep,
    $core.int? threshold,
    $core.Iterable<SnapshotExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (automatic != null) {
      _result.automatic = automatic;
    }
    if (keep != null) {
      _result.keep = keep;
    }
    if (threshold != null) {
      _result.threshold = threshold;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory ConfigureSnapshotRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConfigureSnapshotRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConfigureSnapshotRequest clone() =>
      ConfigureSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConfigureSnapshotRequest copyWith(
          void Function(ConfigureSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as ConfigureSnapshotRequest))
          as ConfigureSnapshotRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConfigureSnapshotRequest create() => ConfigureSnapshotRequest._();
  ConfigureSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<ConfigureSnapshotRequest> createRepeated() =>
      $pb.PbList<ConfigureSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static ConfigureSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConfigureSnapshotRequest>(create);
  static ConfigureSnapshotRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get automatic => $_getBF(1);
  @$pb.TagNumber(2)
  set automatic($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAutomatic() => $_has(1);
  @$pb.TagNumber(2)
  void clearAutomatic() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get keep => $_getIZ(2);
  @$pb.TagNumber(3)
  set keep($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasKeep() => $_has(2);
  @$pb.TagNumber(3)
  void clearKeep() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get threshold => $_getIZ(3);
  @$pb.TagNumber(4)
  set threshold($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasThreshold() => $_has(3);
  @$pb.TagNumber(4)
  void clearThreshold() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<SnapshotExpandFields> get expand => $_getList(4);
}

class ConfigureSnapshotResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ConfigureSnapshotResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<SnapshotMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
        subBuilder: SnapshotMeta.create)
    ..hasRequiredFields = false;

  ConfigureSnapshotResponse._() : super();
  factory ConfigureSnapshotResponse({
    $core.String? type,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    SnapshotMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory ConfigureSnapshotResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConfigureSnapshotResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConfigureSnapshotResponse clone() =>
      ConfigureSnapshotResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConfigureSnapshotResponse copyWith(
          void Function(ConfigureSnapshotResponse) updates) =>
      super.copyWith((message) => updates(message as ConfigureSnapshotResponse))
          as ConfigureSnapshotResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConfigureSnapshotResponse create() => ConfigureSnapshotResponse._();
  ConfigureSnapshotResponse createEmptyInstance() => create();
  static $pb.PbList<ConfigureSnapshotResponse> createRepeated() =>
      $pb.PbList<ConfigureSnapshotResponse>();
  @$core.pragma('dart2js:noInline')
  static ConfigureSnapshotResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConfigureSnapshotResponse>(create);
  static ConfigureSnapshotResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set statusCode($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatusCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(3)
  set reasonPhrase($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(3)
  void clearReasonPhrase() => clearField(3);

  @$pb.TagNumber(4)
  SnapshotMeta get meta => $_getN(3);
  @$pb.TagNumber(4)
  set meta(SnapshotMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(4)
  void clearMeta() => clearField(4);
  @$pb.TagNumber(4)
  SnapshotMeta ensureMeta() => $_ensure(3);
}

class SaveSnapshotRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SaveSnapshotRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'force')
    ..pc<SnapshotExpandFields>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: SnapshotExpandFields.valueOf,
        enumValues: SnapshotExpandFields.values)
    ..hasRequiredFields = false;

  SaveSnapshotRequest._() : super();
  factory SaveSnapshotRequest({
    $core.String? type,
    $core.bool? force,
    $core.Iterable<SnapshotExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (force != null) {
      _result.force = force;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory SaveSnapshotRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SaveSnapshotRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SaveSnapshotRequest clone() => SaveSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SaveSnapshotRequest copyWith(void Function(SaveSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as SaveSnapshotRequest))
          as SaveSnapshotRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SaveSnapshotRequest create() => SaveSnapshotRequest._();
  SaveSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<SaveSnapshotRequest> createRepeated() =>
      $pb.PbList<SaveSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static SaveSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveSnapshotRequest>(create);
  static SaveSnapshotRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get force => $_getBF(1);
  @$pb.TagNumber(2)
  set force($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasForce() => $_has(1);
  @$pb.TagNumber(2)
  void clearForce() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<SnapshotExpandFields> get expand => $_getList(2);
}

class SaveSnapshotResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SaveSnapshotResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<SnapshotMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
        subBuilder: SnapshotMeta.create)
    ..hasRequiredFields = false;

  SaveSnapshotResponse._() : super();
  factory SaveSnapshotResponse({
    $core.String? type,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    SnapshotMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory SaveSnapshotResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SaveSnapshotResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SaveSnapshotResponse clone() =>
      SaveSnapshotResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SaveSnapshotResponse copyWith(void Function(SaveSnapshotResponse) updates) =>
      super.copyWith((message) => updates(message as SaveSnapshotResponse))
          as SaveSnapshotResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SaveSnapshotResponse create() => SaveSnapshotResponse._();
  SaveSnapshotResponse createEmptyInstance() => create();
  static $pb.PbList<SaveSnapshotResponse> createRepeated() =>
      $pb.PbList<SaveSnapshotResponse>();
  @$core.pragma('dart2js:noInline')
  static SaveSnapshotResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveSnapshotResponse>(create);
  static SaveSnapshotResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set statusCode($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatusCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(3)
  set reasonPhrase($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(3)
  void clearReasonPhrase() => clearField(3);

  @$pb.TagNumber(4)
  SnapshotMeta get meta => $_getN(3);
  @$pb.TagNumber(4)
  set meta(SnapshotMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(4)
  void clearMeta() => clearField(4);
  @$pb.TagNumber(4)
  SnapshotMeta ensureMeta() => $_ensure(3);
}

class DownloadSnapshotRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DownloadSnapshotRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..a<$fixnum.Int64>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'chunkSize',
        $pb.PbFieldType.OU6,
        protoName: 'chunkSize',
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  DownloadSnapshotRequest._() : super();
  factory DownloadSnapshotRequest({
    $core.String? type,
    $fixnum.Int64? chunkSize,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (chunkSize != null) {
      _result.chunkSize = chunkSize;
    }
    return _result;
  }
  factory DownloadSnapshotRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DownloadSnapshotRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DownloadSnapshotRequest clone() =>
      DownloadSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DownloadSnapshotRequest copyWith(
          void Function(DownloadSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadSnapshotRequest))
          as DownloadSnapshotRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DownloadSnapshotRequest create() => DownloadSnapshotRequest._();
  DownloadSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<DownloadSnapshotRequest> createRepeated() =>
      $pb.PbList<DownloadSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static DownloadSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadSnapshotRequest>(create);
  static DownloadSnapshotRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get chunkSize => $_getI64(1);
  @$pb.TagNumber(2)
  set chunkSize($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasChunkSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunkSize() => clearField(2);
}

class SnapshotChunk extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SnapshotChunk',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOM<$3.FileChunk>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'chunk',
        subBuilder: $3.FileChunk.create)
    ..hasRequiredFields = false;

  SnapshotChunk._() : super();
  factory SnapshotChunk({
    $core.String? type,
    $3.FileChunk? chunk,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (chunk != null) {
      _result.chunk = chunk;
    }
    return _result;
  }
  factory SnapshotChunk.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SnapshotChunk.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SnapshotChunk clone() => SnapshotChunk()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SnapshotChunk copyWith(void Function(SnapshotChunk) updates) =>
      super.copyWith((message) => updates(message as SnapshotChunk))
          as SnapshotChunk; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SnapshotChunk create() => SnapshotChunk._();
  SnapshotChunk createEmptyInstance() => create();
  static $pb.PbList<SnapshotChunk> createRepeated() =>
      $pb.PbList<SnapshotChunk>();
  @$core.pragma('dart2js:noInline')
  static SnapshotChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotChunk>(create);
  static SnapshotChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(3)
  $3.FileChunk get chunk => $_getN(1);
  @$pb.TagNumber(3)
  set chunk($3.FileChunk v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasChunk() => $_has(1);
  @$pb.TagNumber(3)
  void clearChunk() => clearField(3);
  @$pb.TagNumber(3)
  $3.FileChunk ensureChunk() => $_ensure(1);
}

class UploadSnapshotResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'UploadSnapshotResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..a<$fixnum.Int64>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'chunkSize', $pb.PbFieldType.OU6,
        protoName: 'chunkSize', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode',
        $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase', protoName: 'reasonPhrase')
    ..aOM<SnapshotMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: SnapshotMeta.create)
    ..hasRequiredFields = false;

  UploadSnapshotResponse._() : super();
  factory UploadSnapshotResponse({
    $core.String? type,
    $fixnum.Int64? chunkSize,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    SnapshotMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (chunkSize != null) {
      _result.chunkSize = chunkSize;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory UploadSnapshotResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UploadSnapshotResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UploadSnapshotResponse clone() =>
      UploadSnapshotResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UploadSnapshotResponse copyWith(
          void Function(UploadSnapshotResponse) updates) =>
      super.copyWith((message) => updates(message as UploadSnapshotResponse))
          as UploadSnapshotResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UploadSnapshotResponse create() => UploadSnapshotResponse._();
  UploadSnapshotResponse createEmptyInstance() => create();
  static $pb.PbList<UploadSnapshotResponse> createRepeated() =>
      $pb.PbList<UploadSnapshotResponse>();
  @$core.pragma('dart2js:noInline')
  static UploadSnapshotResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadSnapshotResponse>(create);
  static UploadSnapshotResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get chunkSize => $_getI64(1);
  @$pb.TagNumber(2)
  set chunkSize($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasChunkSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunkSize() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  SnapshotMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(SnapshotMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  SnapshotMeta ensureMeta() => $_ensure(4);
}
