///
//  Generated code. Do not modify.
//  source: snapshot.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'aggregate.pb.dart' as $0;
import 'metric.pb.dart' as $6;

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
    ..e<SnapshotExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.OE,
        defaultOrMaker: SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_NONE,
        valueOf: SnapshotExpandFields.valueOf,
        enumValues: SnapshotExpandFields.values)
    ..hasRequiredFields = false;

  GetSnapshotMetaRequest._() : super();
  factory GetSnapshotMetaRequest() => create();
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
      super.copyWith((message) => updates(
          message as GetSnapshotMetaRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetSnapshotMetaRequest create() => GetSnapshotMetaRequest._();
  GetSnapshotMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetSnapshotMetaRequest> createRepeated() =>
      $pb.PbList<GetSnapshotMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetSnapshotMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSnapshotMetaRequest>(create);
  static GetSnapshotMetaRequest _defaultInstance;

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
  SnapshotExpandFields get expand => $_getN(1);
  @$pb.TagNumber(2)
  set expand(SnapshotExpandFields v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasExpand() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpand() => clearField(2);
}

class GetSnapshotsMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetSnapshotsMetaResponse',
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
    ..aOM<SnapshotMeta>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'meta',
        subBuilder: SnapshotMeta.create)
    ..hasRequiredFields = false;

  GetSnapshotsMetaResponse._() : super();
  factory GetSnapshotsMetaResponse() => create();
  factory GetSnapshotsMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetSnapshotsMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetSnapshotsMetaResponse clone() =>
      GetSnapshotsMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetSnapshotsMetaResponse copyWith(
          void Function(GetSnapshotsMetaResponse) updates) =>
      super.copyWith((message) => updates(message
          as GetSnapshotsMetaResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetSnapshotsMetaResponse create() => GetSnapshotsMetaResponse._();
  GetSnapshotsMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetSnapshotsMetaResponse> createRepeated() =>
      $pb.PbList<GetSnapshotsMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetSnapshotsMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSnapshotsMetaResponse>(create);
  static GetSnapshotsMetaResponse _defaultInstance;

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
  SnapshotMeta get meta => $_getN(1);
  @$pb.TagNumber(2)
  set meta(SnapshotMeta v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMeta() => $_has(1);
  @$pb.TagNumber(2)
  void clearMeta() => clearField(2);
  @$pb.TagNumber(2)
  SnapshotMeta ensureMeta() => $_ensure(1);
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
            : 'uuid')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'last')
    ..aInt64(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'number')
    ..aInt64(4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'position')
    ..aOM<SnapshotConfig>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'config', subBuilder: SnapshotConfig.create)
    ..aOM<SnapshotMetricsMeta>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'metrics', subBuilder: SnapshotMetricsMeta.create)
    ..aOM<$0.AggregateMetaList>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'aggregates', subBuilder: $0.AggregateMetaList.create)
    ..hasRequiredFields = false;

  SnapshotMeta._() : super();
  factory SnapshotMeta() => create();
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
      super.copyWith((message) =>
          updates(message as SnapshotMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SnapshotMeta create() => SnapshotMeta._();
  SnapshotMeta createEmptyInstance() => create();
  static $pb.PbList<SnapshotMeta> createRepeated() =>
      $pb.PbList<SnapshotMeta>();
  @$core.pragma('dart2js:noInline')
  static SnapshotMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotMeta>(create);
  static SnapshotMeta _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uuid => $_getSZ(0);
  @$pb.TagNumber(1)
  set uuid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get last => $_getSZ(1);
  @$pb.TagNumber(2)
  set last($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLast() => $_has(1);
  @$pb.TagNumber(2)
  void clearLast() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get number => $_getI64(2);
  @$pb.TagNumber(3)
  set number($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get position => $_getI64(3);
  @$pb.TagNumber(4)
  set position($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => clearField(4);

  @$pb.TagNumber(5)
  SnapshotConfig get config => $_getN(4);
  @$pb.TagNumber(5)
  set config(SnapshotConfig v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasConfig() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfig() => clearField(5);
  @$pb.TagNumber(5)
  SnapshotConfig ensureConfig() => $_ensure(4);

  @$pb.TagNumber(6)
  SnapshotMetricsMeta get metrics => $_getN(5);
  @$pb.TagNumber(6)
  set metrics(SnapshotMetricsMeta v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasMetrics() => $_has(5);
  @$pb.TagNumber(6)
  void clearMetrics() => clearField(6);
  @$pb.TagNumber(6)
  SnapshotMetricsMeta ensureMetrics() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.AggregateMetaList get aggregates => $_getN(6);
  @$pb.TagNumber(7)
  set aggregates($0.AggregateMetaList v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasAggregates() => $_has(6);
  @$pb.TagNumber(7)
  void clearAggregates() => clearField(7);
  @$pb.TagNumber(7)
  $0.AggregateMetaList ensureAggregates() => $_ensure(6);
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
  factory SnapshotConfig() => create();
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
      super.copyWith((message) =>
          updates(message as SnapshotConfig)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SnapshotConfig create() => SnapshotConfig._();
  SnapshotConfig createEmptyInstance() => create();
  static $pb.PbList<SnapshotConfig> createRepeated() =>
      $pb.PbList<SnapshotConfig>();
  @$core.pragma('dart2js:noInline')
  static SnapshotConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotConfig>(create);
  static SnapshotConfig _defaultInstance;

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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SnapshotMetricsMeta',
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
    ..aOM<$6.DurationMetricMeta>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'save',
        subBuilder: $6.DurationMetricMeta.create)
    ..hasRequiredFields = false;

  SnapshotMetricsMeta._() : super();
  factory SnapshotMetricsMeta() => create();
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
      super.copyWith((message) => updates(
          message as SnapshotMetricsMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SnapshotMetricsMeta create() => SnapshotMetricsMeta._();
  SnapshotMetricsMeta createEmptyInstance() => create();
  static $pb.PbList<SnapshotMetricsMeta> createRepeated() =>
      $pb.PbList<SnapshotMetricsMeta>();
  @$core.pragma('dart2js:noInline')
  static SnapshotMetricsMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SnapshotMetricsMeta>(create);
  static SnapshotMetricsMeta _defaultInstance;

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

  @$pb.TagNumber(5)
  $6.DurationMetricMeta get save => $_getN(1);
  @$pb.TagNumber(5)
  set save($6.DurationMetricMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasSave() => $_has(1);
  @$pb.TagNumber(5)
  void clearSave() => clearField(5);
  @$pb.TagNumber(5)
  $6.DurationMetricMeta ensureSave() => $_ensure(1);
}
