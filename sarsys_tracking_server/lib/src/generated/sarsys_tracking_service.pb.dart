///
//  Generated code. Do not modify.
//  source: sarsys_tracking_service.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'sarsys_tracking_service.pbenum.dart';

export 'sarsys_tracking_service.pbenum.dart';

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
    ..pc<ExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: ExpandFields.valueOf,
        enumValues: ExpandFields.values)
    ..hasRequiredFields = false;

  AddTrackingsRequest._() : super();
  factory AddTrackingsRequest() => create();
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
      super.copyWith((message) => updates(
          message as AddTrackingsRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddTrackingsRequest create() => AddTrackingsRequest._();
  AddTrackingsRequest createEmptyInstance() => create();
  static $pb.PbList<AddTrackingsRequest> createRepeated() =>
      $pb.PbList<AddTrackingsRequest>();
  @$core.pragma('dart2js:noInline')
  static AddTrackingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddTrackingsRequest>(create);
  static AddTrackingsRequest _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<ExpandFields> get expand => $_getList(1);
}

class AddTrackingsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AddTrackingsResponse',
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
    ..a<$core.int>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<GetMetaResponse>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: GetMetaResponse.create)
    ..hasRequiredFields = false;

  AddTrackingsResponse._() : super();
  factory AddTrackingsResponse() => create();
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
      super.copyWith((message) => updates(
          message as AddTrackingsResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddTrackingsResponse create() => AddTrackingsResponse._();
  AddTrackingsResponse createEmptyInstance() => create();
  static $pb.PbList<AddTrackingsResponse> createRepeated() =>
      $pb.PbList<AddTrackingsResponse>();
  @$core.pragma('dart2js:noInline')
  static AddTrackingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddTrackingsResponse>(create);
  static AddTrackingsResponse _defaultInstance;

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
  GetMetaResponse get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(GetMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetMetaResponse ensureMeta() => $_ensure(4);
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
    ..pc<ExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: ExpandFields.valueOf,
        enumValues: ExpandFields.values)
    ..hasRequiredFields = false;

  StartTrackingRequest._() : super();
  factory StartTrackingRequest() => create();
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
      super.copyWith((message) => updates(
          message as StartTrackingRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StartTrackingRequest create() => StartTrackingRequest._();
  StartTrackingRequest createEmptyInstance() => create();
  static $pb.PbList<StartTrackingRequest> createRepeated() =>
      $pb.PbList<StartTrackingRequest>();
  @$core.pragma('dart2js:noInline')
  static StartTrackingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartTrackingRequest>(create);
  static StartTrackingRequest _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<ExpandFields> get expand => $_getList(0);
}

class StartTrackingResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StartTrackingResponse',
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
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<GetMetaResponse>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
        subBuilder: GetMetaResponse.create)
    ..hasRequiredFields = false;

  StartTrackingResponse._() : super();
  factory StartTrackingResponse() => create();
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
      super.copyWith((message) => updates(
          message as StartTrackingResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StartTrackingResponse create() => StartTrackingResponse._();
  StartTrackingResponse createEmptyInstance() => create();
  static $pb.PbList<StartTrackingResponse> createRepeated() =>
      $pb.PbList<StartTrackingResponse>();
  @$core.pragma('dart2js:noInline')
  static StartTrackingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartTrackingResponse>(create);
  static StartTrackingResponse _defaultInstance;

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
  GetMetaResponse get meta => $_getN(3);
  @$pb.TagNumber(5)
  set meta(GetMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetMetaResponse ensureMeta() => $_ensure(3);
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
    ..pc<ExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: ExpandFields.valueOf,
        enumValues: ExpandFields.values)
    ..hasRequiredFields = false;

  StopTrackingRequest._() : super();
  factory StopTrackingRequest() => create();
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
      super.copyWith((message) => updates(
          message as StopTrackingRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StopTrackingRequest create() => StopTrackingRequest._();
  StopTrackingRequest createEmptyInstance() => create();
  static $pb.PbList<StopTrackingRequest> createRepeated() =>
      $pb.PbList<StopTrackingRequest>();
  @$core.pragma('dart2js:noInline')
  static StopTrackingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopTrackingRequest>(create);
  static StopTrackingRequest _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<ExpandFields> get expand => $_getList(0);
}

class StopTrackingResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StopTrackingResponse',
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
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<GetMetaResponse>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta',
        subBuilder: GetMetaResponse.create)
    ..hasRequiredFields = false;

  StopTrackingResponse._() : super();
  factory StopTrackingResponse() => create();
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
      super.copyWith((message) => updates(
          message as StopTrackingResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StopTrackingResponse create() => StopTrackingResponse._();
  StopTrackingResponse createEmptyInstance() => create();
  static $pb.PbList<StopTrackingResponse> createRepeated() =>
      $pb.PbList<StopTrackingResponse>();
  @$core.pragma('dart2js:noInline')
  static StopTrackingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopTrackingResponse>(create);
  static StopTrackingResponse _defaultInstance;

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
  GetMetaResponse get meta => $_getN(3);
  @$pb.TagNumber(5)
  set meta(GetMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(3);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetMetaResponse ensureMeta() => $_ensure(3);
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
    ..pc<ExpandFields>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: ExpandFields.valueOf,
        enumValues: ExpandFields.values)
    ..hasRequiredFields = false;

  RemoveTrackingsRequest._() : super();
  factory RemoveTrackingsRequest() => create();
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
      super.copyWith((message) => updates(
          message as RemoveTrackingsRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsRequest create() => RemoveTrackingsRequest._();
  RemoveTrackingsRequest createEmptyInstance() => create();
  static $pb.PbList<RemoveTrackingsRequest> createRepeated() =>
      $pb.PbList<RemoveTrackingsRequest>();
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveTrackingsRequest>(create);
  static RemoveTrackingsRequest _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get uuids => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<ExpandFields> get expand => $_getList(1);
}

class RemoveTrackingsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RemoveTrackingsResponse',
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
    ..a<$core.int>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<GetMetaResponse>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: GetMetaResponse.create)
    ..hasRequiredFields = false;

  RemoveTrackingsResponse._() : super();
  factory RemoveTrackingsResponse() => create();
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
      super.copyWith((message) => updates(
          message as RemoveTrackingsResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsResponse create() => RemoveTrackingsResponse._();
  RemoveTrackingsResponse createEmptyInstance() => create();
  static $pb.PbList<RemoveTrackingsResponse> createRepeated() =>
      $pb.PbList<RemoveTrackingsResponse>();
  @$core.pragma('dart2js:noInline')
  static RemoveTrackingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveTrackingsResponse>(create);
  static RemoveTrackingsResponse _defaultInstance;

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
  GetMetaResponse get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(GetMetaResponse v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  GetMetaResponse ensureMeta() => $_ensure(4);
}

class GetMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetMetaRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..pc<ExpandFields>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: ExpandFields.valueOf,
        enumValues: ExpandFields.values)
    ..hasRequiredFields = false;

  GetMetaRequest._() : super();
  factory GetMetaRequest() => create();
  factory GetMetaRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetMetaRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetMetaRequest clone() => GetMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetMetaRequest copyWith(void Function(GetMetaRequest) updates) =>
      super.copyWith((message) =>
          updates(message as GetMetaRequest)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetMetaRequest create() => GetMetaRequest._();
  GetMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetMetaRequest> createRepeated() =>
      $pb.PbList<GetMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMetaRequest>(create);
  static GetMetaRequest _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ExpandFields> get expand => $_getList(0);
}

class GetMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetMetaResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..e<TrackingServerStatus>(
        1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: TrackingServerStatus.STATUS_NONE,
        valueOf: TrackingServerStatus.valueOf,
        enumValues: TrackingServerStatus.values)
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'total',
        $pb.PbFieldType.O3)
    ..a<$core.double>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fractionManaged',
        $pb.PbFieldType.OD,
        protoName: 'fractionManaged')
    ..aOM<PositionsMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'positions', subBuilder: PositionsMeta.create)
    ..pc<TrackingMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'managerOf', $pb.PbFieldType.PM, protoName: 'managerOf', subBuilder: TrackingMeta.create)
    ..aOM<RepositoryMeta>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'repo', subBuilder: RepositoryMeta.create)
    ..hasRequiredFields = false;

  GetMetaResponse._() : super();
  factory GetMetaResponse() => create();
  factory GetMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetMetaResponse clone() => GetMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetMetaResponse copyWith(void Function(GetMetaResponse) updates) =>
      super.copyWith((message) =>
          updates(message as GetMetaResponse)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetMetaResponse create() => GetMetaResponse._();
  GetMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetMetaResponse> createRepeated() =>
      $pb.PbList<GetMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMetaResponse>(create);
  static GetMetaResponse _defaultInstance;

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
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get fractionManaged => $_getN(2);
  @$pb.TagNumber(3)
  set fractionManaged($core.double v) {
    $_setDouble(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasFractionManaged() => $_has(2);
  @$pb.TagNumber(3)
  void clearFractionManaged() => clearField(3);

  @$pb.TagNumber(4)
  PositionsMeta get positions => $_getN(3);
  @$pb.TagNumber(4)
  set positions(PositionsMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPositions() => $_has(3);
  @$pb.TagNumber(4)
  void clearPositions() => clearField(4);
  @$pb.TagNumber(4)
  PositionsMeta ensurePositions() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<TrackingMeta> get managerOf => $_getList(4);

  @$pb.TagNumber(6)
  RepositoryMeta get repo => $_getN(5);
  @$pb.TagNumber(6)
  set repo(RepositoryMeta v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasRepo() => $_has(5);
  @$pb.TagNumber(6)
  void clearRepo() => clearField(6);
  @$pb.TagNumber(6)
  RepositoryMeta ensureRepo() => $_ensure(5);
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
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackCount', $pb.PbFieldType.O3,
        protoName: 'trackCount')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'positionCount', $pb.PbFieldType.O3,
        protoName: 'positionCount')
    ..aOM<EventMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent',
        protoName: 'lastEvent', subBuilder: EventMeta.create)
    ..hasRequiredFields = false;

  TrackingMeta._() : super();
  factory TrackingMeta() => create();
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
      super.copyWith((message) =>
          updates(message as TrackingMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackingMeta create() => TrackingMeta._();
  TrackingMeta createEmptyInstance() => create();
  static $pb.PbList<TrackingMeta> createRepeated() =>
      $pb.PbList<TrackingMeta>();
  @$core.pragma('dart2js:noInline')
  static TrackingMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackingMeta>(create);
  static TrackingMeta _defaultInstance;

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
  $core.int get trackCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set trackCount($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTrackCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackCount() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get positionCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set positionCount($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPositionCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearPositionCount() => clearField(3);

  @$pb.TagNumber(4)
  EventMeta get lastEvent => $_getN(3);
  @$pb.TagNumber(4)
  set lastEvent(EventMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLastEvent() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastEvent() => clearField(4);
  @$pb.TagNumber(4)
  EventMeta ensureLastEvent() => $_ensure(3);
}

class PositionsMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i =
      $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PositionsMeta',
          package: const $pb.PackageName(
              const $core.bool.fromEnvironment('protobuf.omit_message_names')
                  ? ''
                  : 'app.sarsys.tracking'),
          createEmptyInstance: create)
        ..a<$core.int>(
            1,
            const $core.bool.fromEnvironment('protobuf.omit_field_names')
                ? ''
                : 'total',
            $pb.PbFieldType.O3)
        ..a<$core.double>(
            2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'positionsPerMinute', $pb.PbFieldType.OD,
            protoName: 'positionsPerMinute')
        ..a<$core.double>(
            3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'averageProcessingTimeMillis', $pb.PbFieldType.OD,
            protoName: 'averageProcessingTimeMillis')
        ..aOM<EventMeta>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent',
            protoName: 'lastEvent', subBuilder: EventMeta.create)
        ..hasRequiredFields = false;

  PositionsMeta._() : super();
  factory PositionsMeta() => create();
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
      super.copyWith((message) =>
          updates(message as PositionsMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PositionsMeta create() => PositionsMeta._();
  PositionsMeta createEmptyInstance() => create();
  static $pb.PbList<PositionsMeta> createRepeated() =>
      $pb.PbList<PositionsMeta>();
  @$core.pragma('dart2js:noInline')
  static PositionsMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PositionsMeta>(create);
  static PositionsMeta _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get total => $_getIZ(0);
  @$pb.TagNumber(1)
  set total($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => clearField(1);

  @$pb.TagNumber(2)
  $core.double get positionsPerMinute => $_getN(1);
  @$pb.TagNumber(2)
  set positionsPerMinute($core.double v) {
    $_setDouble(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPositionsPerMinute() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionsPerMinute() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get averageProcessingTimeMillis => $_getN(2);
  @$pb.TagNumber(3)
  set averageProcessingTimeMillis($core.double v) {
    $_setDouble(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAverageProcessingTimeMillis() => $_has(2);
  @$pb.TagNumber(3)
  void clearAverageProcessingTimeMillis() => clearField(3);

  @$pb.TagNumber(4)
  EventMeta get lastEvent => $_getN(3);
  @$pb.TagNumber(4)
  set lastEvent(EventMeta v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasLastEvent() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastEvent() => clearField(4);
  @$pb.TagNumber(4)
  EventMeta ensureLastEvent() => $_ensure(3);
}

class EventMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EventMeta',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'app.sarsys.tracking'),
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
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'remote')
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'number',
        $pb.PbFieldType.O3)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'position', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  EventMeta._() : super();
  factory EventMeta() => create();
  factory EventMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EventMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EventMeta clone() => EventMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EventMeta copyWith(void Function(EventMeta) updates) =>
      super.copyWith((message) =>
          updates(message as EventMeta)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EventMeta create() => EventMeta._();
  EventMeta createEmptyInstance() => create();
  static $pb.PbList<EventMeta> createRepeated() => $pb.PbList<EventMeta>();
  @$core.pragma('dart2js:noInline')
  static EventMeta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventMeta>(create);
  static EventMeta _defaultInstance;

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
  $core.bool get remote => $_getBF(2);
  @$pb.TagNumber(3)
  set remote($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasRemote() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemote() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get number => $_getIZ(3);
  @$pb.TagNumber(4)
  set number($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasNumber() => $_has(3);
  @$pb.TagNumber(4)
  void clearNumber() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get position => $_getIZ(4);
  @$pb.TagNumber(5)
  set position($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPosition() => $_has(4);
  @$pb.TagNumber(5)
  void clearPosition() => clearField(5);
}

class RepositoryMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RepositoryMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOM<EventMeta>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastEvent',
        protoName: 'lastEvent', subBuilder: EventMeta.create)
    ..aOM<RepositoryQueueMeta>(3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'queue',
        subBuilder: RepositoryQueueMeta.create)
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
  EventMeta get lastEvent => $_getN(1);
  @$pb.TagNumber(2)
  set lastEvent(EventMeta v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLastEvent() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastEvent() => clearField(2);
  @$pb.TagNumber(2)
  EventMeta ensureLastEvent() => $_ensure(1);

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
}

class RepositoryQueueMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RepositoryQueueMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
      createEmptyInstance: create)
    ..aOM<RepositoryQueuePressureMeta>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'pressure',
        subBuilder: RepositoryQueuePressureMeta.create)
    ..aOM<RepositoryQueueStatusMeta>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status',
        subBuilder: RepositoryQueueStatusMeta.create)
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
}

class RepositoryQueuePressureMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RepositoryQueuePressureMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'app.sarsys.tracking'),
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
              : 'app.sarsys.tracking'),
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
