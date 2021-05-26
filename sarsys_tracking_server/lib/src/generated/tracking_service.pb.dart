///
//  Generated code. Do not modify.
//  source: tracking_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'repository.pb.dart' as $1;
import 'event.pb.dart' as $4;

import 'tracking_service.pbenum.dart';

export 'tracking_service.pbenum.dart';

class AddTrackingsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AddTrackingsRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuids')
    ..pc<TrackingExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: TrackingExpandFields.valueOf,
        enumValues: TrackingExpandFields.values)
    ..hasRequiredFields = false;

  AddTrackingsRequest._() : super();
  factory AddTrackingsRequest({
    $core.Iterable<$core.String>? uuids,
    $core.Iterable<TrackingExpandFields>? expand,
  }) {
    final _result = create();
    if (uuids != null) {
      _result.uuids.addAll(uuids);
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory AddTrackingsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AddTrackingsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AddTrackingsRequest clone() => AddTrackingsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AddTrackingsRequest copyWith(void Function(AddTrackingsRequest) updates) =>
      super.copyWith((message) => updates(message as AddTrackingsRequest))
          as AddTrackingsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddTrackingsRequest create() => AddTrackingsRequest._();
  AddTrackingsRequest createEmptyInstance() => create();
  static $pb.PbList<AddTrackingsRequest> createRepeated() =>
      $pb.PbList<AddTrackingsRequest>();
  @$core.pragma('dart2js:noInline')
  static AddTrackingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddTrackingsRequest>(create);
  static AddTrackingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<TrackingExpandFields> get expand => $_getList(1);
}

class AddTrackingsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i =
      $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AddTrackingsResponse',
          package: const $pb.PackageName(
              const $core.bool.fromEnvironment('protobuf.omit_message_names')
                  ? ''
                  : 'app.sarsys.tracking'),
          createEmptyInstance: create)
        ..pPS(
            1,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'uuids')
        ..pPS(
            2,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'failed')
        ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
            protoName: 'statusCode')
        ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
            protoName: 'reasonPhrase')
        ..aOM<GetTrackingMetaResponse>(
            5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
            subBuilder: GetTrackingMetaResponse.create)
        ..hasRequiredFields = false;

  AddTrackingsResponse._() : super();
  factory AddTrackingsResponse({
    $core.Iterable<$core.String>? uuids,
    $core.Iterable<$core.String>? failed,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    GetTrackingMetaResponse? meta,
  }) {
    final _result = create();
    if (uuids != null) {
      _result.uuids.addAll(uuids);
    }
    if (failed != null) {
      _result.failed.addAll(failed);
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
  factory AddTrackingsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AddTrackingsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AddTrackingsResponse clone() =>
      AddTrackingsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AddTrackingsResponse copyWith(void Function(AddTrackingsResponse) updates) =>
      super.copyWith((message) => updates(message as AddTrackingsResponse))
          as AddTrackingsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddTrackingsResponse create() => AddTrackingsResponse._();
  AddTrackingsResponse createEmptyInstance() => create();
  static $pb.PbList<AddTrackingsResponse> createRepeated() =>
      $pb.PbList<AddTrackingsResponse>();
  @$core.pragma('dart2js:noInline')
  static AddTrackingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddTrackingsResponse>(create);
  static AddTrackingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get failed => $_getList(1);

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
  GetTrackingMetaResponse get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(GetTrackingMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetTrackingMetaResponse ensureMeta() => $_ensure(4);
}

class StartTrackingRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StartTrackingRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pc<TrackingExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: TrackingExpandFields.valueOf,
        enumValues: TrackingExpandFields.values)
    ..hasRequiredFields = false;

  StartTrackingRequest._() : super();
  factory StartTrackingRequest({
    $core.Iterable<TrackingExpandFields>? expand,
  }) {
    final _result = create();
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory StartTrackingRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartTrackingRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StartTrackingRequest clone() =>
      StartTrackingRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StartTrackingRequest copyWith(void Function(StartTrackingRequest) updates) =>
      super.copyWith((message) => updates(message as StartTrackingRequest))
          as StartTrackingRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StartTrackingRequest create() => StartTrackingRequest._();
  StartTrackingRequest createEmptyInstance() => create();
  static $pb.PbList<StartTrackingRequest> createRepeated() =>
      $pb.PbList<StartTrackingRequest>();
  @$core.pragma('dart2js:noInline')
  static StartTrackingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartTrackingRequest>(create);
  static StartTrackingRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<TrackingExpandFields> get expand => $_getList(0);
}

class StartTrackingResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StartTrackingResponse',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuids')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<GetTrackingMetaResponse>(
        5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
        subBuilder: GetTrackingMetaResponse.create)
    ..hasRequiredFields = false;

  StartTrackingResponse._() : super();
  factory StartTrackingResponse({
    $core.Iterable<$core.String>? uuids,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    GetTrackingMetaResponse? meta,
  }) {
    final _result = create();
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
  factory StartTrackingResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartTrackingResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StartTrackingResponse clone() =>
      StartTrackingResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StartTrackingResponse copyWith(
          void Function(StartTrackingResponse) updates) =>
      super.copyWith((message) => updates(message as StartTrackingResponse))
          as StartTrackingResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StartTrackingResponse create() => StartTrackingResponse._();
  StartTrackingResponse createEmptyInstance() => create();
  static $pb.PbList<StartTrackingResponse> createRepeated() =>
      $pb.PbList<StartTrackingResponse>();
  @$core.pragma('dart2js:noInline')
  static StartTrackingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartTrackingResponse>(create);
  static StartTrackingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(3)
  set statusCode($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  GetTrackingMetaResponse get meta => $_getN(3);
  @$pb.TagNumber(5)
  set meta(GetTrackingMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetTrackingMetaResponse ensureMeta() => $_ensure(3);
}

class StopTrackingRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StopTrackingRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pc<TrackingExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: TrackingExpandFields.valueOf,
        enumValues: TrackingExpandFields.values)
    ..hasRequiredFields = false;

  StopTrackingRequest._() : super();
  factory StopTrackingRequest({
    $core.Iterable<TrackingExpandFields>? expand,
  }) {
    final _result = create();
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory StopTrackingRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StopTrackingRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StopTrackingRequest clone() => StopTrackingRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StopTrackingRequest copyWith(void Function(StopTrackingRequest) updates) =>
      super.copyWith((message) => updates(message as StopTrackingRequest))
          as StopTrackingRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StopTrackingRequest create() => StopTrackingRequest._();
  StopTrackingRequest createEmptyInstance() => create();
  static $pb.PbList<StopTrackingRequest> createRepeated() =>
      $pb.PbList<StopTrackingRequest>();
  @$core.pragma('dart2js:noInline')
  static StopTrackingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopTrackingRequest>(create);
  static StopTrackingRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<TrackingExpandFields> get expand => $_getList(0);
}

class StopTrackingResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StopTrackingResponse',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuids')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<GetTrackingMetaResponse>(
        5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
        subBuilder: GetTrackingMetaResponse.create)
    ..hasRequiredFields = false;

  StopTrackingResponse._() : super();
  factory StopTrackingResponse({
    $core.Iterable<$core.String>? uuids,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    GetTrackingMetaResponse? meta,
  }) {
    final _result = create();
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
  factory StopTrackingResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StopTrackingResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StopTrackingResponse clone() =>
      StopTrackingResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StopTrackingResponse copyWith(void Function(StopTrackingResponse) updates) =>
      super.copyWith((message) => updates(message as StopTrackingResponse))
          as StopTrackingResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StopTrackingResponse create() => StopTrackingResponse._();
  StopTrackingResponse createEmptyInstance() => create();
  static $pb.PbList<StopTrackingResponse> createRepeated() =>
      $pb.PbList<StopTrackingResponse>();
  @$core.pragma('dart2js:noInline')
  static StopTrackingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopTrackingResponse>(create);
  static StopTrackingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(3)
  $core.int get statusCode => $_getIZ(1);
  @$pb.TagNumber(3)
  set statusCode($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(1);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(2);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(2);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  GetTrackingMetaResponse get meta => $_getN(3);
  @$pb.TagNumber(5)
  set meta(GetTrackingMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetTrackingMetaResponse ensureMeta() => $_ensure(3);
}

class RemoveTrackingsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RemoveTrackingsRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuids')
    ..pc<TrackingExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: TrackingExpandFields.valueOf,
        enumValues: TrackingExpandFields.values)
    ..hasRequiredFields = false;

  RemoveTrackingsRequest._() : super();
  factory RemoveTrackingsRequest({
    $core.Iterable<$core.String>? uuids,
    $core.Iterable<TrackingExpandFields>? expand,
  }) {
    final _result = create();
    if (uuids != null) {
      _result.uuids.addAll(uuids);
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory RemoveTrackingsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RemoveTrackingsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RemoveTrackingsRequest clone() =>
      RemoveTrackingsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RemoveTrackingsRequest copyWith(
          void Function(RemoveTrackingsRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveTrackingsRequest))
          as RemoveTrackingsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsRequest create() => RemoveTrackingsRequest._();
  RemoveTrackingsRequest createEmptyInstance() => create();
  static $pb.PbList<RemoveTrackingsRequest> createRepeated() =>
      $pb.PbList<RemoveTrackingsRequest>();
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveTrackingsRequest>(create);
  static RemoveTrackingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<TrackingExpandFields> get expand => $_getList(1);
}

class RemoveTrackingsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i =
      $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RemoveTrackingsResponse',
          package: const $pb.PackageName(
              const $core.bool.fromEnvironment('protobuf.omit_message_names')
                  ? ''
                  : 'app.sarsys.tracking'),
          createEmptyInstance: create)
        ..pPS(
            1,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'uuids')
        ..pPS(
            2,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'failed')
        ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
            protoName: 'statusCode')
        ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
            protoName: 'reasonPhrase')
        ..aOM<GetTrackingMetaResponse>(
            5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
            subBuilder: GetTrackingMetaResponse.create)
        ..hasRequiredFields = false;

  RemoveTrackingsResponse._() : super();
  factory RemoveTrackingsResponse({
    $core.Iterable<$core.String>? uuids,
    $core.Iterable<$core.String>? failed,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    GetTrackingMetaResponse? meta,
  }) {
    final _result = create();
    if (uuids != null) {
      _result.uuids.addAll(uuids);
    }
    if (failed != null) {
      _result.failed.addAll(failed);
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
  factory RemoveTrackingsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RemoveTrackingsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RemoveTrackingsResponse clone() =>
      RemoveTrackingsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RemoveTrackingsResponse copyWith(
          void Function(RemoveTrackingsResponse) updates) =>
      super.copyWith((message) => updates(message as RemoveTrackingsResponse))
          as RemoveTrackingsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsResponse create() => RemoveTrackingsResponse._();
  RemoveTrackingsResponse createEmptyInstance() => create();
  static $pb.PbList<RemoveTrackingsResponse> createRepeated() =>
      $pb.PbList<RemoveTrackingsResponse>();
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveTrackingsResponse>(create);
  static RemoveTrackingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get failed => $_getList(1);

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
  GetTrackingMetaResponse get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(GetTrackingMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetTrackingMetaResponse ensureMeta() => $_ensure(4);
}

class GetTrackingMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetTrackingMetaRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pc<TrackingExpandFields>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: TrackingExpandFields.valueOf,
        enumValues: TrackingExpandFields.values)
    ..hasRequiredFields = false;

  GetTrackingMetaRequest._() : super();
  factory GetTrackingMetaRequest({
    $core.Iterable<TrackingExpandFields>? expand,
  }) {
    final _result = create();
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory GetTrackingMetaRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetTrackingMetaRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetTrackingMetaRequest clone() =>
      GetTrackingMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetTrackingMetaRequest copyWith(
          void Function(GetTrackingMetaRequest) updates) =>
      super.copyWith((message) => updates(message as GetTrackingMetaRequest))
          as GetTrackingMetaRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetTrackingMetaRequest create() => GetTrackingMetaRequest._();
  GetTrackingMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetTrackingMetaRequest> createRepeated() =>
      $pb.PbList<GetTrackingMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetTrackingMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTrackingMetaRequest>(create);
  static GetTrackingMetaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<TrackingExpandFields> get expand => $_getList(0);
}

class GetTrackingMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetTrackingMetaResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..e<TrackingServerStatus>(
        1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: TrackingServerStatus.TRACKING_STATUS_NONE,
        valueOf: TrackingServerStatus.valueOf,
        enumValues: TrackingServerStatus.values)
    ..aOM<TrackingsMeta>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackings',
        subBuilder: TrackingsMeta.create)
    ..aOM<PositionsMeta>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'positions',
        subBuilder: PositionsMeta.create)
    ..pc<TrackingMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'managerOf', $pb.PbFieldType.PM,
        protoName: 'managerOf', subBuilder: TrackingMeta.create)
    ..aOM<$1.RepositoryMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'repo', subBuilder: $1.RepositoryMeta.create)
    ..hasRequiredFields = false;

  GetTrackingMetaResponse._() : super();
  factory GetTrackingMetaResponse({
    TrackingServerStatus? status,
    TrackingsMeta? trackings,
    PositionsMeta? positions,
    $core.Iterable<TrackingMeta>? managerOf,
    $1.RepositoryMeta? repo,
  }) {
    final _result = create();
    if (status != null) {
      _result.status = status;
    }
    if (trackings != null) {
      _result.trackings = trackings;
    }
    if (positions != null) {
      _result.positions = positions;
    }
    if (managerOf != null) {
      _result.managerOf.addAll(managerOf);
    }
    if (repo != null) {
      _result.repo = repo;
    }
    return _result;
  }
  factory GetTrackingMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetTrackingMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetTrackingMetaResponse clone() =>
      GetTrackingMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetTrackingMetaResponse copyWith(
          void Function(GetTrackingMetaResponse) updates) =>
      super.copyWith((message) => updates(message as GetTrackingMetaResponse))
          as GetTrackingMetaResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetTrackingMetaResponse create() => GetTrackingMetaResponse._();
  GetTrackingMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetTrackingMetaResponse> createRepeated() =>
      $pb.PbList<GetTrackingMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetTrackingMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTrackingMetaResponse>(create);
  static GetTrackingMetaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  TrackingServerStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(TrackingServerStatus v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => clearField(1);

  @$pb.TagNumber(2)
  TrackingsMeta get trackings => $_getN(1);
  @$pb.TagNumber(2)
  set trackings(TrackingsMeta v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTrackings() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackings() => clearField(2);
  @$pb.TagNumber(2)
  TrackingsMeta ensureTrackings() => $_ensure(1);

  @$pb.TagNumber(3)
  PositionsMeta get positions => $_getN(2);
  @$pb.TagNumber(3)
  set positions(PositionsMeta v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPositions() => $_has(2);
  @$pb.TagNumber(3)
  void clearPositions() => clearField(3);
  @$pb.TagNumber(3)
  PositionsMeta ensurePositions() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<TrackingMeta> get managerOf => $_getList(3);

  @$pb.TagNumber(5)
  $1.RepositoryMeta get repo => $_getN(4);
  @$pb.TagNumber(5)
  set repo($1.RepositoryMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasRepo() => $_has(4);
  @$pb.TagNumber(5)
  void clearRepo() => clearField(5);
  @$pb.TagNumber(5)
  $1.RepositoryMeta ensureRepo() => $_ensure(4);
}

class TrackingMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TrackingMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuid')
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackCount',
        protoName: 'trackCount')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'positionCount',
        protoName: 'positionCount')
    ..aOM<$4.EventMeta>(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent',
        protoName: 'lastEvent', subBuilder: $4.EventMeta.create)
    ..hasRequiredFields = false;

  TrackingMeta._() : super();
  factory TrackingMeta({
    $core.String? uuid,
    $fixnum.Int64? trackCount,
    $fixnum.Int64? positionCount,
    $4.EventMeta? lastEvent,
  }) {
    final _result = create();
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (trackCount != null) {
      _result.trackCount = trackCount;
    }
    if (positionCount != null) {
      _result.positionCount = positionCount;
    }
    if (lastEvent != null) {
      _result.lastEvent = lastEvent;
    }
    return _result;
  }
  factory TrackingMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackingMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackingMeta clone() => TrackingMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackingMeta copyWith(void Function(TrackingMeta) updates) =>
      super.copyWith((message) => updates(message as TrackingMeta))
          as TrackingMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackingMeta create() => TrackingMeta._();
  TrackingMeta createEmptyInstance() => create();
  static $pb.PbList<TrackingMeta> createRepeated() =>
      $pb.PbList<TrackingMeta>();
  @$core.pragma('dart2js:noInline')
  static TrackingMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackingMeta>(create);
  static TrackingMeta? _defaultInstance;

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
  $fixnum.Int64 get trackCount => $_getI64(1);
  @$pb.TagNumber(2)
  set trackCount($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTrackCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackCount() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get positionCount => $_getI64(2);
  @$pb.TagNumber(3)
  set positionCount($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPositionCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearPositionCount() => clearField(3);

  @$pb.TagNumber(4)
  $4.EventMeta get lastEvent => $_getN(3);
  @$pb.TagNumber(4)
  set lastEvent($4.EventMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLastEvent() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastEvent() => clearField(4);
  @$pb.TagNumber(4)
  $4.EventMeta ensureLastEvent() => $_ensure(3);
}

class TrackingsMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TrackingsMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'total')
    ..a<$core.double>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fractionManaged', $pb.PbFieldType.OD,
        protoName: 'fractionManaged')
    ..a<$core.double>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'eventsPerMinute', $pb.PbFieldType.OD,
        protoName: 'eventsPerMinute')
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'averageProcessingTimeMillis', $pb.PbFieldType.O3,
        protoName: 'averageProcessingTimeMillis')
    ..aOM<$4.EventMeta>(
        5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent',
        protoName: 'lastEvent', subBuilder: $4.EventMeta.create)
    ..hasRequiredFields = false;

  TrackingsMeta._() : super();
  factory TrackingsMeta({
    $fixnum.Int64? total,
    $core.double? fractionManaged,
    $core.double? eventsPerMinute,
    $core.int? averageProcessingTimeMillis,
    $4.EventMeta? lastEvent,
  }) {
    final _result = create();
    if (total != null) {
      _result.total = total;
    }
    if (fractionManaged != null) {
      _result.fractionManaged = fractionManaged;
    }
    if (eventsPerMinute != null) {
      _result.eventsPerMinute = eventsPerMinute;
    }
    if (averageProcessingTimeMillis != null) {
      _result.averageProcessingTimeMillis = averageProcessingTimeMillis;
    }
    if (lastEvent != null) {
      _result.lastEvent = lastEvent;
    }
    return _result;
  }
  factory TrackingsMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackingsMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackingsMeta clone() => TrackingsMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackingsMeta copyWith(void Function(TrackingsMeta) updates) =>
      super.copyWith((message) => updates(message as TrackingsMeta))
          as TrackingsMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackingsMeta create() => TrackingsMeta._();
  TrackingsMeta createEmptyInstance() => create();
  static $pb.PbList<TrackingsMeta> createRepeated() =>
      $pb.PbList<TrackingsMeta>();
  @$core.pragma('dart2js:noInline')
  static TrackingsMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackingsMeta>(create);
  static TrackingsMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get total => $_getI64(0);
  @$pb.TagNumber(1)
  set total($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get fractionManaged => $_getN(1);
  @$pb.TagNumber(2)
  set fractionManaged($core.double v) {
    $_setDouble(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFractionManaged() => $_has(1);
  @$pb.TagNumber(2)
  void clearFractionManaged() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get eventsPerMinute => $_getN(2);
  @$pb.TagNumber(3)
  set eventsPerMinute($core.double v) {
    $_setDouble(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEventsPerMinute() => $_has(2);
  @$pb.TagNumber(3)
  void clearEventsPerMinute() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get averageProcessingTimeMillis => $_getIZ(3);
  @$pb.TagNumber(4)
  set averageProcessingTimeMillis($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAverageProcessingTimeMillis() => $_has(3);
  @$pb.TagNumber(4)
  void clearAverageProcessingTimeMillis() => clearField(4);

  @$pb.TagNumber(5)
  $4.EventMeta get lastEvent => $_getN(4);
  @$pb.TagNumber(5)
  set lastEvent($4.EventMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasLastEvent() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastEvent() => clearField(5);
  @$pb.TagNumber(5)
  $4.EventMeta ensureLastEvent() => $_ensure(4);
}

class PositionsMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PositionsMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..aInt64(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'total')
    ..a<$core.double>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'eventsPerMinute', $pb.PbFieldType.OD,
        protoName: 'eventsPerMinute')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'averageProcessingTimeMillis',
        $pb.PbFieldType.O3,
        protoName: 'averageProcessingTimeMillis')
    ..aOM<$4.EventMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent',
        protoName: 'lastEvent', subBuilder: $4.EventMeta.create)
    ..hasRequiredFields = false;

  PositionsMeta._() : super();
  factory PositionsMeta({
    $fixnum.Int64? total,
    $core.double? eventsPerMinute,
    $core.int? averageProcessingTimeMillis,
    $4.EventMeta? lastEvent,
  }) {
    final _result = create();
    if (total != null) {
      _result.total = total;
    }
    if (eventsPerMinute != null) {
      _result.eventsPerMinute = eventsPerMinute;
    }
    if (averageProcessingTimeMillis != null) {
      _result.averageProcessingTimeMillis = averageProcessingTimeMillis;
    }
    if (lastEvent != null) {
      _result.lastEvent = lastEvent;
    }
    return _result;
  }
  factory PositionsMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PositionsMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PositionsMeta clone() => PositionsMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PositionsMeta copyWith(void Function(PositionsMeta) updates) =>
      super.copyWith((message) => updates(message as PositionsMeta))
          as PositionsMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PositionsMeta create() => PositionsMeta._();
  PositionsMeta createEmptyInstance() => create();
  static $pb.PbList<PositionsMeta> createRepeated() =>
      $pb.PbList<PositionsMeta>();
  @$core.pragma('dart2js:noInline')
  static PositionsMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PositionsMeta>(create);
  static PositionsMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get total => $_getI64(0);
  @$pb.TagNumber(1)
  set total($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get eventsPerMinute => $_getN(1);
  @$pb.TagNumber(2)
  set eventsPerMinute($core.double v) {
    $_setDouble(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEventsPerMinute() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventsPerMinute() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get averageProcessingTimeMillis => $_getIZ(2);
  @$pb.TagNumber(3)
  set averageProcessingTimeMillis($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAverageProcessingTimeMillis() => $_has(2);
  @$pb.TagNumber(3)
  void clearAverageProcessingTimeMillis() => clearField(3);

  @$pb.TagNumber(4)
  $4.EventMeta get lastEvent => $_getN(3);
  @$pb.TagNumber(4)
  set lastEvent($4.EventMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLastEvent() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastEvent() => clearField(4);
  @$pb.TagNumber(4)
  $4.EventMeta ensureLastEvent() => $_ensure(3);
}
