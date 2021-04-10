///
//  Generated code. Do not modify.
//  source: json.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class JsonDataCompression extends $pb.ProtobufEnum {
  static const JsonDataCompression JSON_DATA_COMPRESSION_NONE =
      JsonDataCompression._(
          0,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'JSON_DATA_COMPRESSION_NONE');
  static const JsonDataCompression JSON_DATA_COMPRESSION_ZLIB =
      JsonDataCompression._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'JSON_DATA_COMPRESSION_ZLIB');
  static const JsonDataCompression JSON_DATA_COMPRESSION_GZIP =
      JsonDataCompression._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'JSON_DATA_COMPRESSION_GZIP');

  static const $core.List<JsonDataCompression> values = <JsonDataCompression>[
    JSON_DATA_COMPRESSION_NONE,
    JSON_DATA_COMPRESSION_ZLIB,
    JSON_DATA_COMPRESSION_GZIP,
  ];

  static final $core.Map<$core.int, JsonDataCompression> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static JsonDataCompression? valueOf($core.int value) => _byValue[value];

  const JsonDataCompression._($core.int v, $core.String n) : super(v, n);
}
