///
//  Generated code. Do not modify.
//  source: event.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use eventMetaDescriptor instead')
const EventMeta$json = const {
  '1': 'EventMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'remote', '3': 3, '4': 1, '5': 8, '10': 'remote'},
    const {'1': 'number', '3': 4, '4': 1, '5': 3, '10': 'number'},
    const {'1': 'position', '3': 5, '4': 1, '5': 3, '10': 'position'},
    const {
      '1': 'timestamp',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
  ],
};

/// Descriptor for `EventMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventMetaDescriptor = $convert.base64Decode(
    'CglFdmVudE1ldGESEgoEdHlwZRgBIAEoCVIEdHlwZRISCgR1dWlkGAIgASgJUgR1dWlkEhYKBnJlbW90ZRgDIAEoCFIGcmVtb3RlEhYKBm51bWJlchgEIAEoA1IGbnVtYmVyEhoKCHBvc2l0aW9uGAUgASgDUghwb3NpdGlvbhI4Cgl0aW1lc3RhbXAYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgl0aW1lc3RhbXA=');
@$core.Deprecated('Use eventMetaListDescriptor instead')
const EventMetaList$json = const {
  '1': 'EventMetaList',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.org.discoos.es.EventMeta',
      '10': 'items'
    },
  ],
};

/// Descriptor for `EventMetaList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventMetaListDescriptor = $convert.base64Decode(
    'Cg1FdmVudE1ldGFMaXN0EhQKBWNvdW50GAEgASgFUgVjb3VudBIvCgVpdGVtcxgCIAMoCzIZLm9yZy5kaXNjb29zLmVzLkV2ZW50TWV0YVIFaXRlbXM=');
