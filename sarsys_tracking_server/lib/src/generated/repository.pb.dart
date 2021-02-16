///
//  Generated code. Do not modify.
//  source: repository.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'event.pb.dart' as $5;
import 'metric.pb.dart' as $6;
import 'aggregate.pb.dart' as $0;

import 'repository.pbenum.dart';

export 'repository.pbenum.dart';

class GetRepoMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetRepoMetaRequest',
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
    ..e<RepoExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.OE,
        defaultOrMaker: RepoExpandFields.REPO_EXPAND_FIELDS_NONE,
        valueOf: RepoExpandFields.valueOf,
        enumValues: RepoExpandFields.values)
    ..hasRequiredFields = false;

  GetRepoMetaRequest._() : super();
  factory GetRepoMetaRequest() => create();
  factory GetRepoMetaRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetRepoMetaRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetRepoMetaRequest clone() => GetRepoMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetRepoMetaRequest copyWith(void Function(GetRepoMetaRequest) updates) =>
      super.copyWith((message) => updates(
          message as GetRepoMetaRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaRequest create() => GetRepoMetaRequest._();
  GetRepoMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetRepoMetaRequest> createRepeated() =>
      $pb.PbList<GetRepoMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRepoMetaRequest>(create);
  static GetRepoMetaRequest _defaultInstance;

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
  RepoExpandFields get expand => $_getN(1);
  @$pb.TagNumber(2)
  set expand(RepoExpandFields v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasExpand() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpand() => clearField(2);
}

class GetRepoMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetRepoMetaResponse',
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
    ..aOM<RepositoryMeta>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'meta',
        subBuilder: RepositoryMeta.create)
    ..hasRequiredFields = false;

  GetRepoMetaResponse._() : super();
  factory GetRepoMetaResponse() => create();
  factory GetRepoMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetRepoMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetRepoMetaResponse clone() => GetRepoMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetRepoMetaResponse copyWith(void Function(GetRepoMetaResponse) updates) =>
      super.copyWith((message) => updates(
          message as GetRepoMetaResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaResponse create() => GetRepoMetaResponse._();
  GetRepoMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetRepoMetaResponse> createRepeated() =>
      $pb.PbList<GetRepoMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRepoMetaResponse>(create);
  static GetRepoMetaResponse _defaultInstance;

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
  RepositoryMeta get meta => $_getN(1);
  @$pb.TagNumber(2)
  set meta(RepositoryMeta v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMeta() => $_has(1);
  @$pb.TagNumber(2)
  void clearMeta() => clearField(2);
  @$pb.TagNumber(2)
  RepositoryMeta ensureMeta() => $_ensure(1);
}

class RepositoryMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i =
      $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryMeta',
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
        ..aOM<$5.EventMeta>(
            2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent',
            protoName: 'lastEvent', subBuilder: $5.EventMeta.create)
        ..aOM<RepositoryQueueMeta>(
            3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'queue',
            subBuilder: RepositoryQueueMeta.create)
        ..aOM<RepositoryMetricsMeta>(
            4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'metrics',
            subBuilder: RepositoryMetricsMeta.create)
        ..hasRequiredFields = false;

  RepositoryMeta._() : super();
  factory RepositoryMeta() => create();
  factory RepositoryMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RepositoryMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RepositoryMeta clone() => RepositoryMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RepositoryMeta copyWith(void Function(RepositoryMeta) updates) =>
      super.copyWith((message) =>
          updates(message as RepositoryMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryMeta create() => RepositoryMeta._();
  RepositoryMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryMeta> createRepeated() =>
      $pb.PbList<RepositoryMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepositoryMeta>(create);
  static RepositoryMeta _defaultInstance;

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
  $5.EventMeta get lastEvent => $_getN(1);
  @$pb.TagNumber(2)
  set lastEvent($5.EventMeta v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLastEvent() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastEvent() => clearField(2);
  @$pb.TagNumber(2)
  $5.EventMeta ensureLastEvent() => $_ensure(1);

  @$pb.TagNumber(3)
  RepositoryQueueMeta get queue => $_getN(2);
  @$pb.TagNumber(3)
  set queue(RepositoryQueueMeta v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasQueue() => $_has(2);
  @$pb.TagNumber(3)
  void clearQueue() => clearField(3);
  @$pb.TagNumber(3)
  RepositoryQueueMeta ensureQueue() => $_ensure(2);

  @$pb.TagNumber(4)
  RepositoryMetricsMeta get metrics => $_getN(3);
  @$pb.TagNumber(4)
  set metrics(RepositoryMetricsMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMetrics() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetrics() => clearField(4);
  @$pb.TagNumber(4)
  RepositoryMetricsMeta ensureMetrics() => $_ensure(3);
}

class RepositoryQueueMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RepositoryQueueMeta',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOM<RepositoryQueuePressureMeta>(
        1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pressure',
        subBuilder: RepositoryQueuePressureMeta.create)
    ..aOM<RepositoryQueueStatusMeta>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status',
        subBuilder: RepositoryQueueStatusMeta.create)
    ..aOM<RepositoryMetricsMeta>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'metrics',
        subBuilder: RepositoryMetricsMeta.create)
    ..hasRequiredFields = false;

  RepositoryQueueMeta._() : super();
  factory RepositoryQueueMeta() => create();
  factory RepositoryQueueMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RepositoryQueueMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RepositoryQueueMeta clone() => RepositoryQueueMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RepositoryQueueMeta copyWith(void Function(RepositoryQueueMeta) updates) =>
      super.copyWith((message) => updates(
          message as RepositoryQueueMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueMeta create() => RepositoryQueueMeta._();
  RepositoryQueueMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryQueueMeta> createRepeated() =>
      $pb.PbList<RepositoryQueueMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepositoryQueueMeta>(create);
  static RepositoryQueueMeta _defaultInstance;

  @$pb.TagNumber(1)
  RepositoryQueuePressureMeta get pressure => $_getN(0);
  @$pb.TagNumber(1)
  set pressure(RepositoryQueuePressureMeta v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPressure() => $_has(0);
  @$pb.TagNumber(1)
  void clearPressure() => clearField(1);
  @$pb.TagNumber(1)
  RepositoryQueuePressureMeta ensurePressure() => $_ensure(0);

  @$pb.TagNumber(2)
  RepositoryQueueStatusMeta get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(RepositoryQueueStatusMeta v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);
  @$pb.TagNumber(2)
  RepositoryQueueStatusMeta ensureStatus() => $_ensure(1);

  @$pb.TagNumber(3)
  RepositoryMetricsMeta get metrics => $_getN(2);
  @$pb.TagNumber(3)
  set metrics(RepositoryMetricsMeta v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMetrics() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetrics() => clearField(3);
  @$pb.TagNumber(3)
  RepositoryMetricsMeta ensureMetrics() => $_ensure(2);
}

class RepositoryQueuePressureMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RepositoryQueuePressureMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'push',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'commands',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'total',
        $pb.PbFieldType.O3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'maximum', $pb.PbFieldType.O3)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exceeded')
    ..hasRequiredFields = false;

  RepositoryQueuePressureMeta._() : super();
  factory RepositoryQueuePressureMeta() => create();
  factory RepositoryQueuePressureMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RepositoryQueuePressureMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RepositoryQueuePressureMeta clone() =>
      RepositoryQueuePressureMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RepositoryQueuePressureMeta copyWith(
          void Function(RepositoryQueuePressureMeta) updates) =>
      super.copyWith((message) => updates(message
          as RepositoryQueuePressureMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryQueuePressureMeta create() =>
      RepositoryQueuePressureMeta._();
  RepositoryQueuePressureMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryQueuePressureMeta> createRepeated() =>
      $pb.PbList<RepositoryQueuePressureMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryQueuePressureMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepositoryQueuePressureMeta>(create);
  static RepositoryQueuePressureMeta _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get push => $_getIZ(0);
  @$pb.TagNumber(1)
  set push($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPush() => $_has(0);
  @$pb.TagNumber(1)
  void clearPush() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get commands => $_getIZ(1);
  @$pb.TagNumber(2)
  set commands($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCommands() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommands() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get total => $_getIZ(2);
  @$pb.TagNumber(3)
  set total($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get maximum => $_getIZ(3);
  @$pb.TagNumber(4)
  set maximum($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasMaximum() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaximum() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get exceeded => $_getBF(4);
  @$pb.TagNumber(5)
  set exceeded($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasExceeded() => $_has(4);
  @$pb.TagNumber(5)
  void clearExceeded() => clearField(5);
}

class RepositoryQueueStatusMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RepositoryQueueStatusMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'idle')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'ready')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'disposed')
    ..hasRequiredFields = false;

  RepositoryQueueStatusMeta._() : super();
  factory RepositoryQueueStatusMeta() => create();
  factory RepositoryQueueStatusMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RepositoryQueueStatusMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RepositoryQueueStatusMeta clone() =>
      RepositoryQueueStatusMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RepositoryQueueStatusMeta copyWith(
          void Function(RepositoryQueueStatusMeta) updates) =>
      super.copyWith((message) => updates(message
          as RepositoryQueueStatusMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueStatusMeta create() => RepositoryQueueStatusMeta._();
  RepositoryQueueStatusMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryQueueStatusMeta> createRepeated() =>
      $pb.PbList<RepositoryQueueStatusMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueStatusMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepositoryQueueStatusMeta>(create);
  static RepositoryQueueStatusMeta _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get idle => $_getBF(0);
  @$pb.TagNumber(1)
  set idle($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIdle() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdle() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get ready => $_getBF(1);
  @$pb.TagNumber(2)
  set ready($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasReady() => $_has(1);
  @$pb.TagNumber(2)
  void clearReady() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get disposed => $_getBF(2);
  @$pb.TagNumber(3)
  set disposed($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDisposed() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisposed() => clearField(3);
}

class RepositoryMetricsMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i =
      $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryMetricsMeta',
          package: const $pb.PackageName(
              const $core.bool.fromEnvironment('protobuf.omit_message_names')
                  ? ''
                  : 'org.discoos.es'),
          createEmptyInstance: create)
        ..aInt64(
            1,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'events')
        ..a<$core.int>(
            2,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'transactions',
            $pb.PbFieldType.O3)
        ..aOM<RepositoryMetricsAggregateMeta>(
            4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'aggregates',
            subBuilder: RepositoryMetricsAggregateMeta.create)
        ..aOM<$6.DurationMetricMeta>(
            5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'push',
            subBuilder: $6.DurationMetricMeta.create)
        ..hasRequiredFields = false;

  RepositoryMetricsMeta._() : super();
  factory RepositoryMetricsMeta() => create();
  factory RepositoryMetricsMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RepositoryMetricsMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RepositoryMetricsMeta clone() =>
      RepositoryMetricsMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RepositoryMetricsMeta copyWith(
          void Function(RepositoryMetricsMeta) updates) =>
      super.copyWith((message) => updates(
          message as RepositoryMetricsMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsMeta create() => RepositoryMetricsMeta._();
  RepositoryMetricsMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryMetricsMeta> createRepeated() =>
      $pb.PbList<RepositoryMetricsMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepositoryMetricsMeta>(create);
  static RepositoryMetricsMeta _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get events => $_getI64(0);
  @$pb.TagNumber(1)
  set events($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEvents() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvents() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get transactions => $_getIZ(1);
  @$pb.TagNumber(2)
  set transactions($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTransactions() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransactions() => clearField(2);

  @$pb.TagNumber(4)
  RepositoryMetricsAggregateMeta get aggregates => $_getN(2);
  @$pb.TagNumber(4)
  set aggregates(RepositoryMetricsAggregateMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAggregates() => $_has(2);
  @$pb.TagNumber(4)
  void clearAggregates() => clearField(4);
  @$pb.TagNumber(4)
  RepositoryMetricsAggregateMeta ensureAggregates() => $_ensure(2);

  @$pb.TagNumber(5)
  $6.DurationMetricMeta get push => $_getN(3);
  @$pb.TagNumber(5)
  set push($6.DurationMetricMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPush() => $_has(3);
  @$pb.TagNumber(5)
  void clearPush() => clearField(5);
  @$pb.TagNumber(5)
  $6.DurationMetricMeta ensurePush() => $_ensure(3);
}

class RepositoryMetricsAggregateMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RepositoryMetricsAggregateMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'count',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'changed',
        $pb.PbFieldType.O3)
    ..aOM<$0.AggregateMetaList>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tainted',
        subBuilder: $0.AggregateMetaList.create)
    ..aOM<$0.AggregateMetaList>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cordoned', subBuilder: $0.AggregateMetaList.create)
    ..hasRequiredFields = false;

  RepositoryMetricsAggregateMeta._() : super();
  factory RepositoryMetricsAggregateMeta() => create();
  factory RepositoryMetricsAggregateMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RepositoryMetricsAggregateMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RepositoryMetricsAggregateMeta clone() =>
      RepositoryMetricsAggregateMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RepositoryMetricsAggregateMeta copyWith(
          void Function(RepositoryMetricsAggregateMeta) updates) =>
      super.copyWith((message) => updates(message
          as RepositoryMetricsAggregateMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsAggregateMeta create() =>
      RepositoryMetricsAggregateMeta._();
  RepositoryMetricsAggregateMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryMetricsAggregateMeta> createRepeated() =>
      $pb.PbList<RepositoryMetricsAggregateMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsAggregateMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RepositoryMetricsAggregateMeta>(create);
  static RepositoryMetricsAggregateMeta _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get count => $_getIZ(0);
  @$pb.TagNumber(1)
  set count($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get changed => $_getIZ(1);
  @$pb.TagNumber(2)
  set changed($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasChanged() => $_has(1);
  @$pb.TagNumber(2)
  void clearChanged() => clearField(2);

  @$pb.TagNumber(3)
  $0.AggregateMetaList get tainted => $_getN(2);
  @$pb.TagNumber(3)
  set tainted($0.AggregateMetaList v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTainted() => $_has(2);
  @$pb.TagNumber(3)
  void clearTainted() => clearField(3);
  @$pb.TagNumber(3)
  $0.AggregateMetaList ensureTainted() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.AggregateMetaList get cordoned => $_getN(3);
  @$pb.TagNumber(4)
  set cordoned($0.AggregateMetaList v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCordoned() => $_has(3);
  @$pb.TagNumber(4)
  void clearCordoned() => clearField(4);
  @$pb.TagNumber(4)
  $0.AggregateMetaList ensureCordoned() => $_ensure(3);
}
