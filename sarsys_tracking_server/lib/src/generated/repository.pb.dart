///
//  Generated code. Do not modify.
//  source: repository.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'event.pb.dart' as $4;
import 'metric.pb.dart' as $5;
import 'aggregate.pb.dart' as $0;

import 'repository.pbenum.dart';

export 'repository.pbenum.dart';

class GetRepoMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetRepoMetaRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..pc<RepoExpandFields>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE, valueOf: RepoExpandFields.valueOf, enumValues: RepoExpandFields.values)
    ..hasRequiredFields = false
  ;

  GetRepoMetaRequest._() : super();
  factory GetRepoMetaRequest({
    $core.String? type,
    $core.Iterable<RepoExpandFields>? expand,
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
  factory GetRepoMetaRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetRepoMetaRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetRepoMetaRequest clone() => GetRepoMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetRepoMetaRequest copyWith(void Function(GetRepoMetaRequest) updates) => super.copyWith((message) => updates(message as GetRepoMetaRequest)) as GetRepoMetaRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaRequest create() => GetRepoMetaRequest._();
  GetRepoMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetRepoMetaRequest> createRepeated() => $pb.PbList<GetRepoMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRepoMetaRequest>(create);
  static GetRepoMetaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<RepoExpandFields> get expand => $_getList(1);
}

class GetRepoMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetRepoMetaResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3, protoName: 'statusCode')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase', protoName: 'reasonPhrase')
    ..aOM<RepositoryMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: RepositoryMeta.create)
    ..hasRequiredFields = false
  ;

  GetRepoMetaResponse._() : super();
  factory GetRepoMetaResponse({
    $core.String? type,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    RepositoryMeta? meta,
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
  factory GetRepoMetaResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetRepoMetaResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetRepoMetaResponse clone() => GetRepoMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetRepoMetaResponse copyWith(void Function(GetRepoMetaResponse) updates) => super.copyWith((message) => updates(message as GetRepoMetaResponse)) as GetRepoMetaResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaResponse create() => GetRepoMetaResponse._();
  GetRepoMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetRepoMetaResponse> createRepeated() => $pb.PbList<GetRepoMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetRepoMetaResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRepoMetaResponse>(create);
  static GetRepoMetaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set statusCode($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatusCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(3)
  set reasonPhrase($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(3)
  void clearReasonPhrase() => clearField(3);

  @$pb.TagNumber(4)
  RepositoryMeta get meta => $_getN(3);
  @$pb.TagNumber(4)
  set meta(RepositoryMeta v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(4)
  void clearMeta() => clearField(4);
  @$pb.TagNumber(4)
  RepositoryMeta ensureMeta() => $_ensure(3);
}

class ReplayRepoEventsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ReplayRepoEventsRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'uuids')
    ..pc<RepoExpandFields>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE, valueOf: RepoExpandFields.valueOf, enumValues: RepoExpandFields.values)
    ..hasRequiredFields = false
  ;

  ReplayRepoEventsRequest._() : super();
  factory ReplayRepoEventsRequest({
    $core.String? type,
    $core.Iterable<$core.String>? uuids,
    $core.Iterable<RepoExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuids != null) {
      _result.uuids.addAll(uuids);
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory ReplayRepoEventsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReplayRepoEventsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReplayRepoEventsRequest clone() => ReplayRepoEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReplayRepoEventsRequest copyWith(void Function(ReplayRepoEventsRequest) updates) => super.copyWith((message) => updates(message as ReplayRepoEventsRequest)) as ReplayRepoEventsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplayRepoEventsRequest create() => ReplayRepoEventsRequest._();
  ReplayRepoEventsRequest createEmptyInstance() => create();
  static $pb.PbList<ReplayRepoEventsRequest> createRepeated() => $pb.PbList<ReplayRepoEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static ReplayRepoEventsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReplayRepoEventsRequest>(create);
  static ReplayRepoEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get uuids => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<RepoExpandFields> get expand => $_getList(2);
}

class ReplayRepoEventsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ReplayRepoEventsResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'uuids')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3, protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase', protoName: 'reasonPhrase')
    ..aOM<RepositoryMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: RepositoryMeta.create)
    ..hasRequiredFields = false
  ;

  ReplayRepoEventsResponse._() : super();
  factory ReplayRepoEventsResponse({
    $core.String? type,
    $core.Iterable<$core.String>? uuids,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    RepositoryMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuids != null) {
      _result.uuids.addAll(uuids);
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
  factory ReplayRepoEventsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReplayRepoEventsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReplayRepoEventsResponse clone() => ReplayRepoEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReplayRepoEventsResponse copyWith(void Function(ReplayRepoEventsResponse) updates) => super.copyWith((message) => updates(message as ReplayRepoEventsResponse)) as ReplayRepoEventsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplayRepoEventsResponse create() => ReplayRepoEventsResponse._();
  ReplayRepoEventsResponse createEmptyInstance() => create();
  static $pb.PbList<ReplayRepoEventsResponse> createRepeated() => $pb.PbList<ReplayRepoEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static ReplayRepoEventsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReplayRepoEventsResponse>(create);
  static ReplayRepoEventsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get uuids => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  RepositoryMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(RepositoryMeta v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  RepositoryMeta ensureMeta() => $_ensure(4);
}

class CatchupRepoEventsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CatchupRepoEventsRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'uuids')
    ..pc<RepoExpandFields>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE, valueOf: RepoExpandFields.valueOf, enumValues: RepoExpandFields.values)
    ..hasRequiredFields = false
  ;

  CatchupRepoEventsRequest._() : super();
  factory CatchupRepoEventsRequest({
    $core.String? type,
    $core.Iterable<$core.String>? uuids,
    $core.Iterable<RepoExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuids != null) {
      _result.uuids.addAll(uuids);
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory CatchupRepoEventsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CatchupRepoEventsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CatchupRepoEventsRequest clone() => CatchupRepoEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CatchupRepoEventsRequest copyWith(void Function(CatchupRepoEventsRequest) updates) => super.copyWith((message) => updates(message as CatchupRepoEventsRequest)) as CatchupRepoEventsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CatchupRepoEventsRequest create() => CatchupRepoEventsRequest._();
  CatchupRepoEventsRequest createEmptyInstance() => create();
  static $pb.PbList<CatchupRepoEventsRequest> createRepeated() => $pb.PbList<CatchupRepoEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static CatchupRepoEventsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CatchupRepoEventsRequest>(create);
  static CatchupRepoEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get uuids => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<RepoExpandFields> get expand => $_getList(2);
}

class CatchupRepoEventsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CatchupRepoEventsResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'uuids')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3, protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase', protoName: 'reasonPhrase')
    ..aOM<RepositoryMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: RepositoryMeta.create)
    ..hasRequiredFields = false
  ;

  CatchupRepoEventsResponse._() : super();
  factory CatchupRepoEventsResponse({
    $core.String? type,
    $core.Iterable<$core.String>? uuids,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    RepositoryMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuids != null) {
      _result.uuids.addAll(uuids);
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
  factory CatchupRepoEventsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CatchupRepoEventsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CatchupRepoEventsResponse clone() => CatchupRepoEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CatchupRepoEventsResponse copyWith(void Function(CatchupRepoEventsResponse) updates) => super.copyWith((message) => updates(message as CatchupRepoEventsResponse)) as CatchupRepoEventsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CatchupRepoEventsResponse create() => CatchupRepoEventsResponse._();
  CatchupRepoEventsResponse createEmptyInstance() => create();
  static $pb.PbList<CatchupRepoEventsResponse> createRepeated() => $pb.PbList<CatchupRepoEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static CatchupRepoEventsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CatchupRepoEventsResponse>(create);
  static CatchupRepoEventsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get uuids => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  RepositoryMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(RepositoryMeta v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  RepositoryMeta ensureMeta() => $_ensure(4);
}

class RepairRepoRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepairRepoRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'master')
    ..pc<RepoExpandFields>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE, valueOf: RepoExpandFields.valueOf, enumValues: RepoExpandFields.values)
    ..hasRequiredFields = false
  ;

  RepairRepoRequest._() : super();
  factory RepairRepoRequest({
    $core.String? type,
    $core.bool? master,
    $core.Iterable<RepoExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (master != null) {
      _result.master = master;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory RepairRepoRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepairRepoRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepairRepoRequest clone() => RepairRepoRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepairRepoRequest copyWith(void Function(RepairRepoRequest) updates) => super.copyWith((message) => updates(message as RepairRepoRequest)) as RepairRepoRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepairRepoRequest create() => RepairRepoRequest._();
  RepairRepoRequest createEmptyInstance() => create();
  static $pb.PbList<RepairRepoRequest> createRepeated() => $pb.PbList<RepairRepoRequest>();
  @$core.pragma('dart2js:noInline')
  static RepairRepoRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepairRepoRequest>(create);
  static RepairRepoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get master => $_getBF(1);
  @$pb.TagNumber(2)
  set master($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMaster() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaster() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<RepoExpandFields> get expand => $_getList(2);
}

class RepairRepoResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepairRepoResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3, protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase', protoName: 'reasonPhrase')
    ..aOM<RepositoryMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: RepositoryMeta.create)
    ..aOM<AnalysisMeta>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'before', subBuilder: AnalysisMeta.create)
    ..aOM<AnalysisMeta>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'after', subBuilder: AnalysisMeta.create)
    ..hasRequiredFields = false
  ;

  RepairRepoResponse._() : super();
  factory RepairRepoResponse({
    $core.String? type,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    RepositoryMeta? meta,
    AnalysisMeta? before,
    AnalysisMeta? after,
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
    if (before != null) {
      _result.before = before;
    }
    if (after != null) {
      _result.after = after;
    }
    return _result;
  }
  factory RepairRepoResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepairRepoResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepairRepoResponse clone() => RepairRepoResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepairRepoResponse copyWith(void Function(RepairRepoResponse) updates) => super.copyWith((message) => updates(message as RepairRepoResponse)) as RepairRepoResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepairRepoResponse create() => RepairRepoResponse._();
  RepairRepoResponse createEmptyInstance() => create();
  static $pb.PbList<RepairRepoResponse> createRepeated() => $pb.PbList<RepairRepoResponse>();
  @$core.pragma('dart2js:noInline')
  static RepairRepoResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepairRepoResponse>(create);
  static RepairRepoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(3)
  set statusCode($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  RepositoryMeta get meta => $_getN(3);
  @$pb.TagNumber(5)
  set meta(RepositoryMeta v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  RepositoryMeta ensureMeta() => $_ensure(3);

  @$pb.TagNumber(6)
  AnalysisMeta get before => $_getN(4);
  @$pb.TagNumber(6)
  set before(AnalysisMeta v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBefore() => $_has(4);
  @$pb.TagNumber(6)
  void clearBefore() => clearField(6);
  @$pb.TagNumber(6)
  AnalysisMeta ensureBefore() => $_ensure(4);

  @$pb.TagNumber(7)
  AnalysisMeta get after => $_getN(5);
  @$pb.TagNumber(7)
  set after(AnalysisMeta v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasAfter() => $_has(5);
  @$pb.TagNumber(7)
  void clearAfter() => clearField(7);
  @$pb.TagNumber(7)
  AnalysisMeta ensureAfter() => $_ensure(5);
}

class AnalysisMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AnalysisMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'count', $pb.PbFieldType.O3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'wrong', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'multiple', $pb.PbFieldType.O3)
    ..pPS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'summary')
    ..hasRequiredFields = false
  ;

  AnalysisMeta._() : super();
  factory AnalysisMeta({
    $core.int? count,
    $core.int? wrong,
    $core.int? multiple,
    $core.Iterable<$core.String>? summary,
  }) {
    final _result = create();
    if (count != null) {
      _result.count = count;
    }
    if (wrong != null) {
      _result.wrong = wrong;
    }
    if (multiple != null) {
      _result.multiple = multiple;
    }
    if (summary != null) {
      _result.summary.addAll(summary);
    }
    return _result;
  }
  factory AnalysisMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AnalysisMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AnalysisMeta clone() => AnalysisMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AnalysisMeta copyWith(void Function(AnalysisMeta) updates) => super.copyWith((message) => updates(message as AnalysisMeta)) as AnalysisMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AnalysisMeta create() => AnalysisMeta._();
  AnalysisMeta createEmptyInstance() => create();
  static $pb.PbList<AnalysisMeta> createRepeated() => $pb.PbList<AnalysisMeta>();
  @$core.pragma('dart2js:noInline')
  static AnalysisMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AnalysisMeta>(create);
  static AnalysisMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get count => $_getIZ(0);
  @$pb.TagNumber(1)
  set count($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get wrong => $_getIZ(1);
  @$pb.TagNumber(2)
  set wrong($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWrong() => $_has(1);
  @$pb.TagNumber(2)
  void clearWrong() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get multiple => $_getIZ(2);
  @$pb.TagNumber(3)
  set multiple($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMultiple() => $_has(2);
  @$pb.TagNumber(3)
  void clearMultiple() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.String> get summary => $_getList(3);
}

class RebuildRepoRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RebuildRepoRequest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'master')
    ..pc<RepoExpandFields>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE, valueOf: RepoExpandFields.valueOf, enumValues: RepoExpandFields.values)
    ..hasRequiredFields = false
  ;

  RebuildRepoRequest._() : super();
  factory RebuildRepoRequest({
    $core.String? type,
    $core.bool? master,
    $core.Iterable<RepoExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (master != null) {
      _result.master = master;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory RebuildRepoRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RebuildRepoRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RebuildRepoRequest clone() => RebuildRepoRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RebuildRepoRequest copyWith(void Function(RebuildRepoRequest) updates) => super.copyWith((message) => updates(message as RebuildRepoRequest)) as RebuildRepoRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RebuildRepoRequest create() => RebuildRepoRequest._();
  RebuildRepoRequest createEmptyInstance() => create();
  static $pb.PbList<RebuildRepoRequest> createRepeated() => $pb.PbList<RebuildRepoRequest>();
  @$core.pragma('dart2js:noInline')
  static RebuildRepoRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RebuildRepoRequest>(create);
  static RebuildRepoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get master => $_getBF(1);
  @$pb.TagNumber(2)
  set master($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMaster() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaster() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<RepoExpandFields> get expand => $_getList(2);
}

class RebuildRepoResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RebuildRepoResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3, protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase', protoName: 'reasonPhrase')
    ..aOM<RepositoryMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: RepositoryMeta.create)
    ..hasRequiredFields = false
  ;

  RebuildRepoResponse._() : super();
  factory RebuildRepoResponse({
    $core.String? type,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    RepositoryMeta? meta,
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
  factory RebuildRepoResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RebuildRepoResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RebuildRepoResponse clone() => RebuildRepoResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RebuildRepoResponse copyWith(void Function(RebuildRepoResponse) updates) => super.copyWith((message) => updates(message as RebuildRepoResponse)) as RebuildRepoResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RebuildRepoResponse create() => RebuildRepoResponse._();
  RebuildRepoResponse createEmptyInstance() => create();
  static $pb.PbList<RebuildRepoResponse> createRepeated() => $pb.PbList<RebuildRepoResponse>();
  @$core.pragma('dart2js:noInline')
  static RebuildRepoResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RebuildRepoResponse>(create);
  static RebuildRepoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(3)
  set statusCode($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  RepositoryMeta get meta => $_getN(3);
  @$pb.TagNumber(5)
  set meta(RepositoryMeta v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  RepositoryMeta ensureMeta() => $_ensure(3);
}

class RepositoryMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..aOM<$4.EventMeta>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent', protoName: 'lastEvent', subBuilder: $4.EventMeta.create)
    ..aOM<RepositoryQueueMeta>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'queue', subBuilder: RepositoryQueueMeta.create)
    ..aOM<RepositoryMetricsMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'metrics', subBuilder: RepositoryMetricsMeta.create)
    ..aOM<ConnectionMetricsMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'connection', subBuilder: ConnectionMetricsMeta.create)
    ..hasRequiredFields = false
  ;

  RepositoryMeta._() : super();
  factory RepositoryMeta({
    $core.String? type,
    $4.EventMeta? lastEvent,
    RepositoryQueueMeta? queue,
    RepositoryMetricsMeta? metrics,
    ConnectionMetricsMeta? connection,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (lastEvent != null) {
      _result.lastEvent = lastEvent;
    }
    if (queue != null) {
      _result.queue = queue;
    }
    if (metrics != null) {
      _result.metrics = metrics;
    }
    if (connection != null) {
      _result.connection = connection;
    }
    return _result;
  }
  factory RepositoryMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepositoryMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepositoryMeta clone() => RepositoryMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepositoryMeta copyWith(void Function(RepositoryMeta) updates) => super.copyWith((message) => updates(message as RepositoryMeta)) as RepositoryMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryMeta create() => RepositoryMeta._();
  RepositoryMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryMeta> createRepeated() => $pb.PbList<RepositoryMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepositoryMeta>(create);
  static RepositoryMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $4.EventMeta get lastEvent => $_getN(1);
  @$pb.TagNumber(2)
  set lastEvent($4.EventMeta v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLastEvent() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastEvent() => clearField(2);
  @$pb.TagNumber(2)
  $4.EventMeta ensureLastEvent() => $_ensure(1);

  @$pb.TagNumber(3)
  RepositoryQueueMeta get queue => $_getN(2);
  @$pb.TagNumber(3)
  set queue(RepositoryQueueMeta v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasQueue() => $_has(2);
  @$pb.TagNumber(3)
  void clearQueue() => clearField(3);
  @$pb.TagNumber(3)
  RepositoryQueueMeta ensureQueue() => $_ensure(2);

  @$pb.TagNumber(4)
  RepositoryMetricsMeta get metrics => $_getN(3);
  @$pb.TagNumber(4)
  set metrics(RepositoryMetricsMeta v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasMetrics() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetrics() => clearField(4);
  @$pb.TagNumber(4)
  RepositoryMetricsMeta ensureMetrics() => $_ensure(3);

  @$pb.TagNumber(5)
  ConnectionMetricsMeta get connection => $_getN(4);
  @$pb.TagNumber(5)
  set connection(ConnectionMetricsMeta v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasConnection() => $_has(4);
  @$pb.TagNumber(5)
  void clearConnection() => clearField(5);
  @$pb.TagNumber(5)
  ConnectionMetricsMeta ensureConnection() => $_ensure(4);
}

class RepositoryQueueMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryQueueMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOM<RepositoryQueuePressureMeta>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pressure', subBuilder: RepositoryQueuePressureMeta.create)
    ..aOM<RepositoryQueueStatusMeta>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status', subBuilder: RepositoryQueueStatusMeta.create)
    ..aOM<RepositoryMetricsMeta>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'metrics', subBuilder: RepositoryMetricsMeta.create)
    ..hasRequiredFields = false
  ;

  RepositoryQueueMeta._() : super();
  factory RepositoryQueueMeta({
    RepositoryQueuePressureMeta? pressure,
    RepositoryQueueStatusMeta? status,
    RepositoryMetricsMeta? metrics,
  }) {
    final _result = create();
    if (pressure != null) {
      _result.pressure = pressure;
    }
    if (status != null) {
      _result.status = status;
    }
    if (metrics != null) {
      _result.metrics = metrics;
    }
    return _result;
  }
  factory RepositoryQueueMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepositoryQueueMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepositoryQueueMeta clone() => RepositoryQueueMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepositoryQueueMeta copyWith(void Function(RepositoryQueueMeta) updates) => super.copyWith((message) => updates(message as RepositoryQueueMeta)) as RepositoryQueueMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueMeta create() => RepositoryQueueMeta._();
  RepositoryQueueMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryQueueMeta> createRepeated() => $pb.PbList<RepositoryQueueMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepositoryQueueMeta>(create);
  static RepositoryQueueMeta? _defaultInstance;

  @$pb.TagNumber(1)
  RepositoryQueuePressureMeta get pressure => $_getN(0);
  @$pb.TagNumber(1)
  set pressure(RepositoryQueuePressureMeta v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPressure() => $_has(0);
  @$pb.TagNumber(1)
  void clearPressure() => clearField(1);
  @$pb.TagNumber(1)
  RepositoryQueuePressureMeta ensurePressure() => $_ensure(0);

  @$pb.TagNumber(2)
  RepositoryQueueStatusMeta get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(RepositoryQueueStatusMeta v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);
  @$pb.TagNumber(2)
  RepositoryQueueStatusMeta ensureStatus() => $_ensure(1);

  @$pb.TagNumber(3)
  RepositoryMetricsMeta get metrics => $_getN(2);
  @$pb.TagNumber(3)
  set metrics(RepositoryMetricsMeta v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasMetrics() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetrics() => clearField(3);
  @$pb.TagNumber(3)
  RepositoryMetricsMeta ensureMetrics() => $_ensure(2);
}

class RepositoryQueuePressureMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryQueuePressureMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'push', $pb.PbFieldType.O3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'commands', $pb.PbFieldType.O3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'total', $pb.PbFieldType.O3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'maximum', $pb.PbFieldType.O3)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exceeded')
    ..hasRequiredFields = false
  ;

  RepositoryQueuePressureMeta._() : super();
  factory RepositoryQueuePressureMeta({
    $core.int? push,
    $core.int? commands,
    $core.int? total,
    $core.int? maximum,
    $core.bool? exceeded,
  }) {
    final _result = create();
    if (push != null) {
      _result.push = push;
    }
    if (commands != null) {
      _result.commands = commands;
    }
    if (total != null) {
      _result.total = total;
    }
    if (maximum != null) {
      _result.maximum = maximum;
    }
    if (exceeded != null) {
      _result.exceeded = exceeded;
    }
    return _result;
  }
  factory RepositoryQueuePressureMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepositoryQueuePressureMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepositoryQueuePressureMeta clone() => RepositoryQueuePressureMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepositoryQueuePressureMeta copyWith(void Function(RepositoryQueuePressureMeta) updates) => super.copyWith((message) => updates(message as RepositoryQueuePressureMeta)) as RepositoryQueuePressureMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryQueuePressureMeta create() => RepositoryQueuePressureMeta._();
  RepositoryQueuePressureMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryQueuePressureMeta> createRepeated() => $pb.PbList<RepositoryQueuePressureMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryQueuePressureMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepositoryQueuePressureMeta>(create);
  static RepositoryQueuePressureMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get push => $_getIZ(0);
  @$pb.TagNumber(1)
  set push($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPush() => $_has(0);
  @$pb.TagNumber(1)
  void clearPush() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get commands => $_getIZ(1);
  @$pb.TagNumber(2)
  set commands($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCommands() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommands() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get total => $_getIZ(2);
  @$pb.TagNumber(3)
  set total($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get maximum => $_getIZ(3);
  @$pb.TagNumber(4)
  set maximum($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMaximum() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaximum() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get exceeded => $_getBF(4);
  @$pb.TagNumber(5)
  set exceeded($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasExceeded() => $_has(4);
  @$pb.TagNumber(5)
  void clearExceeded() => clearField(5);
}

class RepositoryQueueStatusMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryQueueStatusMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'idle')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ready')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disposed')
    ..hasRequiredFields = false
  ;

  RepositoryQueueStatusMeta._() : super();
  factory RepositoryQueueStatusMeta({
    $core.bool? idle,
    $core.bool? ready,
    $core.bool? disposed,
  }) {
    final _result = create();
    if (idle != null) {
      _result.idle = idle;
    }
    if (ready != null) {
      _result.ready = ready;
    }
    if (disposed != null) {
      _result.disposed = disposed;
    }
    return _result;
  }
  factory RepositoryQueueStatusMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepositoryQueueStatusMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepositoryQueueStatusMeta clone() => RepositoryQueueStatusMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepositoryQueueStatusMeta copyWith(void Function(RepositoryQueueStatusMeta) updates) => super.copyWith((message) => updates(message as RepositoryQueueStatusMeta)) as RepositoryQueueStatusMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueStatusMeta create() => RepositoryQueueStatusMeta._();
  RepositoryQueueStatusMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryQueueStatusMeta> createRepeated() => $pb.PbList<RepositoryQueueStatusMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryQueueStatusMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepositoryQueueStatusMeta>(create);
  static RepositoryQueueStatusMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get idle => $_getBF(0);
  @$pb.TagNumber(1)
  set idle($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIdle() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdle() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get ready => $_getBF(1);
  @$pb.TagNumber(2)
  set ready($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReady() => $_has(1);
  @$pb.TagNumber(2)
  void clearReady() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get disposed => $_getBF(2);
  @$pb.TagNumber(3)
  set disposed($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDisposed() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisposed() => clearField(3);
}

class RepositoryMetricsMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryMetricsMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aInt64(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'events')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transactions', $pb.PbFieldType.O3)
    ..aOM<RepositoryMetricsAggregateMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'aggregates', subBuilder: RepositoryMetricsAggregateMeta.create)
    ..aOM<$5.DurationMetricMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'push', subBuilder: $5.DurationMetricMeta.create)
    ..hasRequiredFields = false
  ;

  RepositoryMetricsMeta._() : super();
  factory RepositoryMetricsMeta({
    $fixnum.Int64? events,
    $core.int? transactions,
    RepositoryMetricsAggregateMeta? aggregates,
    $5.DurationMetricMeta? push,
  }) {
    final _result = create();
    if (events != null) {
      _result.events = events;
    }
    if (transactions != null) {
      _result.transactions = transactions;
    }
    if (aggregates != null) {
      _result.aggregates = aggregates;
    }
    if (push != null) {
      _result.push = push;
    }
    return _result;
  }
  factory RepositoryMetricsMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepositoryMetricsMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepositoryMetricsMeta clone() => RepositoryMetricsMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepositoryMetricsMeta copyWith(void Function(RepositoryMetricsMeta) updates) => super.copyWith((message) => updates(message as RepositoryMetricsMeta)) as RepositoryMetricsMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsMeta create() => RepositoryMetricsMeta._();
  RepositoryMetricsMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryMetricsMeta> createRepeated() => $pb.PbList<RepositoryMetricsMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepositoryMetricsMeta>(create);
  static RepositoryMetricsMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get events => $_getI64(0);
  @$pb.TagNumber(1)
  set events($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEvents() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvents() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get transactions => $_getIZ(1);
  @$pb.TagNumber(2)
  set transactions($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTransactions() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransactions() => clearField(2);

  @$pb.TagNumber(4)
  RepositoryMetricsAggregateMeta get aggregates => $_getN(2);
  @$pb.TagNumber(4)
  set aggregates(RepositoryMetricsAggregateMeta v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasAggregates() => $_has(2);
  @$pb.TagNumber(4)
  void clearAggregates() => clearField(4);
  @$pb.TagNumber(4)
  RepositoryMetricsAggregateMeta ensureAggregates() => $_ensure(2);

  @$pb.TagNumber(5)
  $5.DurationMetricMeta get push => $_getN(3);
  @$pb.TagNumber(5)
  set push($5.DurationMetricMeta v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasPush() => $_has(3);
  @$pb.TagNumber(5)
  void clearPush() => clearField(5);
  @$pb.TagNumber(5)
  $5.DurationMetricMeta ensurePush() => $_ensure(3);
}

class RepositoryMetricsAggregateMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RepositoryMetricsAggregateMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'count', $pb.PbFieldType.O3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'changed', $pb.PbFieldType.O3)
    ..aOM<$0.AggregateMetaList>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tainted', subBuilder: $0.AggregateMetaList.create)
    ..aOM<$0.AggregateMetaList>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cordoned', subBuilder: $0.AggregateMetaList.create)
    ..hasRequiredFields = false
  ;

  RepositoryMetricsAggregateMeta._() : super();
  factory RepositoryMetricsAggregateMeta({
    $core.int? count,
    $core.int? changed,
    $0.AggregateMetaList? tainted,
    $0.AggregateMetaList? cordoned,
  }) {
    final _result = create();
    if (count != null) {
      _result.count = count;
    }
    if (changed != null) {
      _result.changed = changed;
    }
    if (tainted != null) {
      _result.tainted = tainted;
    }
    if (cordoned != null) {
      _result.cordoned = cordoned;
    }
    return _result;
  }
  factory RepositoryMetricsAggregateMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RepositoryMetricsAggregateMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RepositoryMetricsAggregateMeta clone() => RepositoryMetricsAggregateMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RepositoryMetricsAggregateMeta copyWith(void Function(RepositoryMetricsAggregateMeta) updates) => super.copyWith((message) => updates(message as RepositoryMetricsAggregateMeta)) as RepositoryMetricsAggregateMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsAggregateMeta create() => RepositoryMetricsAggregateMeta._();
  RepositoryMetricsAggregateMeta createEmptyInstance() => create();
  static $pb.PbList<RepositoryMetricsAggregateMeta> createRepeated() => $pb.PbList<RepositoryMetricsAggregateMeta>();
  @$core.pragma('dart2js:noInline')
  static RepositoryMetricsAggregateMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RepositoryMetricsAggregateMeta>(create);
  static RepositoryMetricsAggregateMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get count => $_getIZ(0);
  @$pb.TagNumber(1)
  set count($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get changed => $_getIZ(1);
  @$pb.TagNumber(2)
  set changed($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChanged() => $_has(1);
  @$pb.TagNumber(2)
  void clearChanged() => clearField(2);

  @$pb.TagNumber(3)
  $0.AggregateMetaList get tainted => $_getN(2);
  @$pb.TagNumber(3)
  set tainted($0.AggregateMetaList v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasTainted() => $_has(2);
  @$pb.TagNumber(3)
  void clearTainted() => clearField(3);
  @$pb.TagNumber(3)
  $0.AggregateMetaList ensureTainted() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.AggregateMetaList get cordoned => $_getN(3);
  @$pb.TagNumber(4)
  set cordoned($0.AggregateMetaList v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCordoned() => $_has(3);
  @$pb.TagNumber(4)
  void clearCordoned() => clearField(4);
  @$pb.TagNumber(4)
  $0.AggregateMetaList ensureCordoned() => $_ensure(3);
}

class ConnectionMetricsMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ConnectionMetricsMeta', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'org.discoos.es'), createEmptyInstance: create)
    ..aOM<$5.DurationMetricMeta>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'read', subBuilder: $5.DurationMetricMeta.create)
    ..aOM<$5.DurationMetricMeta>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'write', subBuilder: $5.DurationMetricMeta.create)
    ..hasRequiredFields = false
  ;

  ConnectionMetricsMeta._() : super();
  factory ConnectionMetricsMeta({
    $5.DurationMetricMeta? read,
    $5.DurationMetricMeta? write,
  }) {
    final _result = create();
    if (read != null) {
      _result.read = read;
    }
    if (write != null) {
      _result.write = write;
    }
    return _result;
  }
  factory ConnectionMetricsMeta.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConnectionMetricsMeta.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConnectionMetricsMeta clone() => ConnectionMetricsMeta()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConnectionMetricsMeta copyWith(void Function(ConnectionMetricsMeta) updates) => super.copyWith((message) => updates(message as ConnectionMetricsMeta)) as ConnectionMetricsMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConnectionMetricsMeta create() => ConnectionMetricsMeta._();
  ConnectionMetricsMeta createEmptyInstance() => create();
  static $pb.PbList<ConnectionMetricsMeta> createRepeated() => $pb.PbList<ConnectionMetricsMeta>();
  @$core.pragma('dart2js:noInline')
  static ConnectionMetricsMeta getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectionMetricsMeta>(create);
  static ConnectionMetricsMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $5.DurationMetricMeta get read => $_getN(0);
  @$pb.TagNumber(1)
  set read($5.DurationMetricMeta v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRead() => $_has(0);
  @$pb.TagNumber(1)
  void clearRead() => clearField(1);
  @$pb.TagNumber(1)
  $5.DurationMetricMeta ensureRead() => $_ensure(0);

  @$pb.TagNumber(2)
  $5.DurationMetricMeta get write => $_getN(1);
  @$pb.TagNumber(2)
  set write($5.DurationMetricMeta v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasWrite() => $_has(1);
  @$pb.TagNumber(2)
  void clearWrite() => clearField(2);
  @$pb.TagNumber(2)
  $5.DurationMetricMeta ensureWrite() => $_ensure(1);
}

