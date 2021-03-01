///
//  Generated code. Do not modify.
//  source: json.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'json.pbenum.dart';

export 'json.pbenum.dart';

class JsonValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'JsonValue',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.io'),
      createEmptyInstance: create)
    ..e<JsonDataCompression>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'compression',
        $pb.PbFieldType.OE,
        defaultOrMaker: JsonDataCompression.JSON_DATA_COMPRESSION_NONE,
        valueOf: JsonDataCompression.valueOf,
        enumValues: JsonDataCompression.values)
    ..a<$core.List<$core.int>>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data',
        $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  JsonValue._() : super();
  factory JsonValue() => create();
  factory JsonValue.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory JsonValue.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  JsonValue clone() => JsonValue()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  JsonValue copyWith(void Function(JsonValue) updates) =>
      super.copyWith((message) =>
          updates(message as JsonValue)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static JsonValue create() => JsonValue._();
  JsonValue createEmptyInstance() => create();
  static $pb.PbList<JsonValue> createRepeated() => $pb.PbList<JsonValue>();
  @$core.pragma('dart2js:noInline')
  static JsonValue getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JsonValue>(create);
  static JsonValue _defaultInstance;

  @$pb.TagNumber(1)
  JsonDataCompression get compression => $_getN(0);
  @$pb.TagNumber(1)
  set compression(JsonDataCompression v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCompression() => $_has(0);
  @$pb.TagNumber(1)
  void clearCompression() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

class JsonMatchList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'JsonMatchList',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'org.discoos.io'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'count',
        $pb.PbFieldType.O3)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'query')
    ..pc<JsonMatch>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items',
        $pb.PbFieldType.PM,
        subBuilder: JsonMatch.create)
    ..hasRequiredFields = false;

  JsonMatchList._() : super();
  factory JsonMatchList() => create();
  factory JsonMatchList.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory JsonMatchList.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  JsonMatchList clone() => JsonMatchList()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  JsonMatchList copyWith(void Function(JsonMatchList) updates) =>
      super.copyWith((message) =>
          updates(message as JsonMatchList)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static JsonMatchList create() => JsonMatchList._();
  JsonMatchList createEmptyInstance() => create();
  static $pb.PbList<JsonMatchList> createRepeated() =>
      $pb.PbList<JsonMatchList>();
  @$core.pragma('dart2js:noInline')
  static JsonMatchList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JsonMatchList>(create);
  static JsonMatchList _defaultInstance;

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
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<JsonMatch> get items => $_getList(2);
}

class JsonMatch extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'JsonMatch',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.io'),
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
            : 'path')
    ..aOM<JsonValue>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'value',
        subBuilder: JsonValue.create)
    ..hasRequiredFields = false;

  JsonMatch._() : super();
  factory JsonMatch() => create();
  factory JsonMatch.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory JsonMatch.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  JsonMatch clone() => JsonMatch()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  JsonMatch copyWith(void Function(JsonMatch) updates) =>
      super.copyWith((message) =>
          updates(message as JsonMatch)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static JsonMatch create() => JsonMatch._();
  JsonMatch createEmptyInstance() => create();
  static $pb.PbList<JsonMatch> createRepeated() => $pb.PbList<JsonMatch>();
  @$core.pragma('dart2js:noInline')
  static JsonMatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JsonMatch>(create);
  static JsonMatch _defaultInstance;

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
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);

  @$pb.TagNumber(3)
  JsonValue get value => $_getN(2);
  @$pb.TagNumber(3)
  set value(JsonValue v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => clearField(3);
  @$pb.TagNumber(3)
  JsonValue ensureValue() => $_ensure(2);
}
