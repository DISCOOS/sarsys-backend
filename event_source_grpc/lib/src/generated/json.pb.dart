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
