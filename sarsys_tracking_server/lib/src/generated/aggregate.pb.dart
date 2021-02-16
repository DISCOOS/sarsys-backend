///
//  Generated code. Do not modify.
//  source: aggregate.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'any.pb.dart' as $4;
import 'event.pb.dart' as $5;

import 'aggregate.pbenum.dart';

export 'aggregate.pbenum.dart';

class GetAggregateMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetAggregateMetaRequest',
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
    ..pc<AggregateExpandFields>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: AggregateExpandFields.valueOf,
        enumValues: AggregateExpandFields.values)
    ..hasRequiredFields = false;

  GetAggregateMetaRequest._() : super();
  factory GetAggregateMetaRequest() => create();
  factory GetAggregateMetaRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetAggregateMetaRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetAggregateMetaRequest clone() =>
      GetAggregateMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetAggregateMetaRequest copyWith(
          void Function(GetAggregateMetaRequest) updates) =>
      super.copyWith((message) => updates(
          message as GetAggregateMetaRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaRequest create() => GetAggregateMetaRequest._();
  GetAggregateMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetAggregateMetaRequest> createRepeated() =>
      $pb.PbList<GetAggregateMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAggregateMetaRequest>(create);
  static GetAggregateMetaRequest _defaultInstance;

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
  $core.List<AggregateExpandFields> get expand => $_getList(2);
}

class GetAggregateMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetAggregateMetaResponse',
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
    ..aOM<AggregateMeta>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'meta',
        subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  GetAggregateMetaResponse._() : super();
  factory GetAggregateMetaResponse() => create();
  factory GetAggregateMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetAggregateMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetAggregateMetaResponse clone() =>
      GetAggregateMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetAggregateMetaResponse copyWith(
          void Function(GetAggregateMetaResponse) updates) =>
      super.copyWith((message) => updates(message
          as GetAggregateMetaResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaResponse create() => GetAggregateMetaResponse._();
  GetAggregateMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetAggregateMetaResponse> createRepeated() =>
      $pb.PbList<GetAggregateMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAggregateMetaResponse>(create);
  static GetAggregateMetaResponse _defaultInstance;

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
  AggregateMeta get meta => $_getN(2);
  @$pb.TagNumber(3)
  set meta(AggregateMeta v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMeta() => $_has(2);
  @$pb.TagNumber(3)
  void clearMeta() => clearField(3);
  @$pb.TagNumber(3)
  AggregateMeta ensureMeta() => $_ensure(2);
}

class ReplaceAggregateDataRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ReplaceAggregateDataRequest',
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
    ..pc<AggregateExpandFields>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE,
        valueOf: AggregateExpandFields.valueOf,
        enumValues: AggregateExpandFields.values)
    ..aOM<$4.Any>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data',
        subBuilder: $4.Any.create)
    ..hasRequiredFields = false;

  ReplaceAggregateDataRequest._() : super();
  factory ReplaceAggregateDataRequest() => create();
  factory ReplaceAggregateDataRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ReplaceAggregateDataRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataRequest clone() =>
      ReplaceAggregateDataRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataRequest copyWith(
          void Function(ReplaceAggregateDataRequest) updates) =>
      super.copyWith((message) => updates(message
          as ReplaceAggregateDataRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataRequest create() =>
      ReplaceAggregateDataRequest._();
  ReplaceAggregateDataRequest createEmptyInstance() => create();
  static $pb.PbList<ReplaceAggregateDataRequest> createRepeated() =>
      $pb.PbList<ReplaceAggregateDataRequest>();
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplaceAggregateDataRequest>(create);
  static ReplaceAggregateDataRequest _defaultInstance;

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
  $core.List<AggregateExpandFields> get expand => $_getList(2);

  @$pb.TagNumber(4)
  $4.Any get data => $_getN(3);
  @$pb.TagNumber(4)
  set data($4.Any v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasData() => $_has(3);
  @$pb.TagNumber(4)
  void clearData() => clearField(4);
  @$pb.TagNumber(4)
  $4.Any ensureData() => $_ensure(3);
}

class ReplaceAggregateDataResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ReplaceAggregateDataResponse',
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
    ..a<$core.int>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<AggregateMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  ReplaceAggregateDataResponse._() : super();
  factory ReplaceAggregateDataResponse() => create();
  factory ReplaceAggregateDataResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ReplaceAggregateDataResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataResponse clone() =>
      ReplaceAggregateDataResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataResponse copyWith(
          void Function(ReplaceAggregateDataResponse) updates) =>
      super.copyWith((message) => updates(message
          as ReplaceAggregateDataResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataResponse create() =>
      ReplaceAggregateDataResponse._();
  ReplaceAggregateDataResponse createEmptyInstance() => create();
  static $pb.PbList<ReplaceAggregateDataResponse> createRepeated() =>
      $pb.PbList<ReplaceAggregateDataResponse>();
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplaceAggregateDataResponse>(create);
  static ReplaceAggregateDataResponse _defaultInstance;

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
  AggregateMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(AggregateMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  AggregateMeta ensureMeta() => $_ensure(4);
}

class AggregateMetaList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AggregateMetaList',
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
    ..pc<AggregateMeta>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'items',
        $pb.PbFieldType.PM,
        subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  AggregateMetaList._() : super();
  factory AggregateMetaList() => create();
  factory AggregateMetaList.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AggregateMetaList.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AggregateMetaList clone() => AggregateMetaList()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AggregateMetaList copyWith(void Function(AggregateMetaList) updates) =>
      super.copyWith((message) => updates(
          message as AggregateMetaList)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AggregateMetaList create() => AggregateMetaList._();
  AggregateMetaList createEmptyInstance() => create();
  static $pb.PbList<AggregateMetaList> createRepeated() =>
      $pb.PbList<AggregateMetaList>();
  @$core.pragma('dart2js:noInline')
  static AggregateMetaList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AggregateMetaList>(create);
  static AggregateMetaList _defaultInstance;

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
  $core.List<AggregateMeta> get items => $_getList(1);
}

class AggregateMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AggregateMeta',
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
    ..aOM<$5.EventMeta>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdBy',
        protoName: 'createdBy', subBuilder: $5.EventMeta.create)
    ..aOM<$5.EventMeta>(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'changedBy',
        protoName: 'changedBy', subBuilder: $5.EventMeta.create)
    ..aOM<$5.EventMeta>(
        5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedBy',
        protoName: 'deletedBy', subBuilder: $5.EventMeta.create)
    ..pc<$5.EventMeta>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'applied', $pb.PbFieldType.PM, subBuilder: $5.EventMeta.create)
    ..pc<$5.EventMeta>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pending', $pb.PbFieldType.PM, subBuilder: $5.EventMeta.create)
    ..pc<$5.EventMeta>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'skipped', $pb.PbFieldType.PM, subBuilder: $5.EventMeta.create)
    ..aOM<$4.Any>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', subBuilder: $4.Any.create)
    ..aOM<$4.Any>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tainted', subBuilder: $4.Any.create)
    ..aOM<$4.Any>(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cordoned', subBuilder: $4.Any.create)
    ..hasRequiredFields = false;

  AggregateMeta._() : super();
  factory AggregateMeta() => create();
  factory AggregateMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AggregateMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AggregateMeta clone() => AggregateMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AggregateMeta copyWith(void Function(AggregateMeta) updates) =>
      super.copyWith((message) =>
          updates(message as AggregateMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AggregateMeta create() => AggregateMeta._();
  AggregateMeta createEmptyInstance() => create();
  static $pb.PbList<AggregateMeta> createRepeated() =>
      $pb.PbList<AggregateMeta>();
  @$core.pragma('dart2js:noInline')
  static AggregateMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AggregateMeta>(create);
  static AggregateMeta _defaultInstance;

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
  $5.EventMeta get createdBy => $_getN(2);
  @$pb.TagNumber(3)
  set createdBy($5.EventMeta v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCreatedBy() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedBy() => clearField(3);
  @$pb.TagNumber(3)
  $5.EventMeta ensureCreatedBy() => $_ensure(2);

  @$pb.TagNumber(4)
  $5.EventMeta get changedBy => $_getN(3);
  @$pb.TagNumber(4)
  set changedBy($5.EventMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasChangedBy() => $_has(3);
  @$pb.TagNumber(4)
  void clearChangedBy() => clearField(4);
  @$pb.TagNumber(4)
  $5.EventMeta ensureChangedBy() => $_ensure(3);

  @$pb.TagNumber(5)
  $5.EventMeta get deletedBy => $_getN(4);
  @$pb.TagNumber(5)
  set deletedBy($5.EventMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDeletedBy() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeletedBy() => clearField(5);
  @$pb.TagNumber(5)
  $5.EventMeta ensureDeletedBy() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.List<$5.EventMeta> get applied => $_getList(5);

  @$pb.TagNumber(7)
  $core.List<$5.EventMeta> get pending => $_getList(6);

  @$pb.TagNumber(8)
  $core.List<$5.EventMeta> get skipped => $_getList(7);

  @$pb.TagNumber(9)
  $4.Any get data => $_getN(8);
  @$pb.TagNumber(9)
  set data($4.Any v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasData() => $_has(8);
  @$pb.TagNumber(9)
  void clearData() => clearField(9);
  @$pb.TagNumber(9)
  $4.Any ensureData() => $_ensure(8);

  @$pb.TagNumber(10)
  $4.Any get tainted => $_getN(9);
  @$pb.TagNumber(10)
  set tainted($4.Any v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasTainted() => $_has(9);
  @$pb.TagNumber(10)
  void clearTainted() => clearField(10);
  @$pb.TagNumber(10)
  $4.Any ensureTainted() => $_ensure(9);

  @$pb.TagNumber(11)
  $4.Any get cordoned => $_getN(10);
  @$pb.TagNumber(11)
  set cordoned($4.Any v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasCordoned() => $_has(10);
  @$pb.TagNumber(11)
  void clearCordoned() => clearField(11);
  @$pb.TagNumber(11)
  $4.Any ensureCordoned() => $_ensure(10);
}
