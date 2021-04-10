///
//  Generated code. Do not modify.
//  source: json.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use jsonDataCompressionDescriptor instead')
const JsonDataCompression$json = const {
  '1': 'JsonDataCompression',
  '2': const [
    const {'1': 'JSON_DATA_COMPRESSION_NONE', '2': 0},
    const {'1': 'JSON_DATA_COMPRESSION_ZLIB', '2': 1},
    const {'1': 'JSON_DATA_COMPRESSION_GZIP', '2': 2},
  ],
};

/// Descriptor for `JsonDataCompression`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List jsonDataCompressionDescriptor = $convert.base64Decode(
    'ChNKc29uRGF0YUNvbXByZXNzaW9uEh4KGkpTT05fREFUQV9DT01QUkVTU0lPTl9OT05FEAASHgoaSlNPTl9EQVRBX0NPTVBSRVNTSU9OX1pMSUIQARIeChpKU09OX0RBVEFfQ09NUFJFU1NJT05fR1pJUBAC');
@$core.Deprecated('Use jsonValueDescriptor instead')
const JsonValue$json = const {
  '1': 'JsonValue',
  '2': const [
    const {
      '1': 'compression',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.org.discoos.io.JsonDataCompression',
      '10': 'compression'
    },
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `JsonValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jsonValueDescriptor = $convert.base64Decode(
    'CglKc29uVmFsdWUSRQoLY29tcHJlc3Npb24YASABKA4yIy5vcmcuZGlzY29vcy5pby5Kc29uRGF0YUNvbXByZXNzaW9uUgtjb21wcmVzc2lvbhISCgRkYXRhGAIgASgMUgRkYXRh');
@$core.Deprecated('Use jsonMatchListDescriptor instead')
const JsonMatchList$json = const {
  '1': 'JsonMatchList',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    const {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.org.discoos.io.JsonMatch',
      '10': 'items'
    },
  ],
};

/// Descriptor for `JsonMatchList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jsonMatchListDescriptor = $convert.base64Decode(
    'Cg1Kc29uTWF0Y2hMaXN0EhQKBWNvdW50GAEgASgFUgVjb3VudBIUCgVxdWVyeRgCIAEoCVIFcXVlcnkSLwoFaXRlbXMYAyADKAsyGS5vcmcuZGlzY29vcy5pby5Kc29uTWF0Y2hSBWl0ZW1z');
@$core.Deprecated('Use jsonMatchDescriptor instead')
const JsonMatch$json = const {
  '1': 'JsonMatch',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    const {
      '1': 'value',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.io.JsonValue',
      '10': 'value'
    },
  ],
};

/// Descriptor for `JsonMatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jsonMatchDescriptor = $convert.base64Decode(
    'CglKc29uTWF0Y2gSEgoEdXVpZBgBIAEoCVIEdXVpZBISCgRwYXRoGAIgASgJUgRwYXRoEi8KBXZhbHVlGAMgASgLMhkub3JnLmRpc2Nvb3MuaW8uSnNvblZhbHVlUgV2YWx1ZQ==');
