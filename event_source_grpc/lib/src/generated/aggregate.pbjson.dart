///
//  Generated code. Do not modify.
//  source: aggregate.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use aggregateExpandFieldsDescriptor instead')
const AggregateExpandFields$json = const {
  '1': 'AggregateExpandFields',
  '2': const [
    const {'1': 'AGGREGATE_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'AGGREGATE_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'AGGREGATE_EXPAND_FIELDS_DATA', '2': 2},
    const {'1': 'AGGREGATE_EXPAND_FIELDS_ITEMS', '2': 3},
  ],
};

/// Descriptor for `AggregateExpandFields`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List aggregateExpandFieldsDescriptor = $convert.base64Decode(
    'ChVBZ2dyZWdhdGVFeHBhbmRGaWVsZHMSIAocQUdHUkVHQVRFX0VYUEFORF9GSUVMRFNfTk9ORRAAEh8KG0FHR1JFR0FURV9FWFBBTkRfRklFTERTX0FMTBABEiAKHEFHR1JFR0FURV9FWFBBTkRfRklFTERTX0RBVEEQAhIhCh1BR0dSRUdBVEVfRVhQQU5EX0ZJRUxEU19JVEVNUxAD');
@$core.Deprecated('Use getAggregateMetaRequestDescriptor instead')
const GetAggregateMetaRequest$json = const {
  '1': 'GetAggregateMetaRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 4,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
  ],
};

/// Descriptor for `GetAggregateMetaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAggregateMetaRequestDescriptor =
    $convert.base64Decode(
        'ChdHZXRBZ2dyZWdhdGVNZXRhUmVxdWVzdBISCgR0eXBlGAEgASgJUgR0eXBlEhIKBHV1aWQYAiABKAlSBHV1aWQSPQoGZXhwYW5kGAQgAygOMiUub3JnLmRpc2Nvb3MuZXMuQWdncmVnYXRlRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use getAggregateMetaResponseDescriptor instead')
const GetAggregateMetaResponse$json = const {
  '1': 'GetAggregateMetaResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `GetAggregateMetaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAggregateMetaResponseDescriptor =
    $convert.base64Decode(
        'ChhHZXRBZ2dyZWdhdGVNZXRhUmVzcG9uc2USEgoEdHlwZRgBIAEoCVIEdHlwZRISCgR1dWlkGAIgASgJUgR1dWlkEh4KCnN0YXR1c0NvZGUYAyABKAVSCnN0YXR1c0NvZGUSIgoMcmVhc29uUGhyYXNlGAQgASgJUgxyZWFzb25QaHJhc2USMQoEbWV0YRgFIAEoCzIdLm9yZy5kaXNjb29zLmVzLkFnZ3JlZ2F0ZU1ldGFSBG1ldGE=');
@$core.Deprecated('Use searchAggregateMetaRequestDescriptor instead')
const SearchAggregateMetaRequest$json = const {
  '1': 'SearchAggregateMetaRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    const {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
    const {'1': 'offset', '3': 4, '4': 1, '5': 5, '10': 'offset'},
    const {
      '1': 'expand',
      '3': 5,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
  ],
};

/// Descriptor for `SearchAggregateMetaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchAggregateMetaRequestDescriptor =
    $convert.base64Decode(
        'ChpTZWFyY2hBZ2dyZWdhdGVNZXRhUmVxdWVzdBISCgR0eXBlGAEgASgJUgR0eXBlEhQKBXF1ZXJ5GAIgASgJUgVxdWVyeRIUCgVsaW1pdBgDIAEoBVIFbGltaXQSFgoGb2Zmc2V0GAQgASgFUgZvZmZzZXQSPQoGZXhwYW5kGAUgAygOMiUub3JnLmRpc2Nvb3MuZXMuQWdncmVnYXRlRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use searchAggregateMetaResponseDescriptor instead')
const SearchAggregateMetaResponse$json = const {
  '1': 'SearchAggregateMetaResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    const {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
    const {'1': 'offset', '3': 4, '4': 1, '5': 5, '10': 'offset'},
    const {'1': 'total', '3': 5, '4': 1, '5': 5, '10': 'total'},
    const {'1': 'nextOffset', '3': 6, '4': 1, '5': 5, '10': 'nextOffset'},
    const {'1': 'statusCode', '3': 7, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 8, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'matches',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMetaMatchList',
      '10': 'matches'
    },
  ],
};

/// Descriptor for `SearchAggregateMetaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchAggregateMetaResponseDescriptor =
    $convert.base64Decode(
        'ChtTZWFyY2hBZ2dyZWdhdGVNZXRhUmVzcG9uc2USEgoEdHlwZRgBIAEoCVIEdHlwZRIUCgVxdWVyeRgCIAEoCVIFcXVlcnkSFAoFbGltaXQYAyABKAVSBWxpbWl0EhYKBm9mZnNldBgEIAEoBVIGb2Zmc2V0EhQKBXRvdGFsGAUgASgFUgV0b3RhbBIeCgpuZXh0T2Zmc2V0GAYgASgFUgpuZXh0T2Zmc2V0Eh4KCnN0YXR1c0NvZGUYByABKAVSCnN0YXR1c0NvZGUSIgoMcmVhc29uUGhyYXNlGAggASgJUgxyZWFzb25QaHJhc2USQAoHbWF0Y2hlcxgJIAEoCzImLm9yZy5kaXNjb29zLmVzLkFnZ3JlZ2F0ZU1ldGFNYXRjaExpc3RSB21hdGNoZXM=');
@$core.Deprecated('Use aggregateMetaMatchListDescriptor instead')
const AggregateMetaMatchList$json = const {
  '1': 'AggregateMetaMatchList',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    const {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.org.discoos.es.AggregateMetaMatch',
      '10': 'items'
    },
  ],
};

/// Descriptor for `AggregateMetaMatchList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aggregateMetaMatchListDescriptor =
    $convert.base64Decode(
        'ChZBZ2dyZWdhdGVNZXRhTWF0Y2hMaXN0EhQKBWNvdW50GAEgASgFUgVjb3VudBIUCgVxdWVyeRgCIAEoCVIFcXVlcnkSOAoFaXRlbXMYAyADKAsyIi5vcmcuZGlzY29vcy5lcy5BZ2dyZWdhdGVNZXRhTWF0Y2hSBWl0ZW1z');
@$core.Deprecated('Use aggregateMetaMatchDescriptor instead')
const AggregateMetaMatch$json = const {
  '1': 'AggregateMetaMatch',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    const {
      '1': 'meta',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `AggregateMetaMatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aggregateMetaMatchDescriptor = $convert.base64Decode(
    'ChJBZ2dyZWdhdGVNZXRhTWF0Y2gSEgoEdXVpZBgBIAEoCVIEdXVpZBISCgRwYXRoGAIgASgJUgRwYXRoEjEKBG1ldGEYAyABKAsyHS5vcmcuZGlzY29vcy5lcy5BZ2dyZWdhdGVNZXRhUgRtZXRh');
@$core.Deprecated('Use replayAggregateEventsRequestDescriptor instead')
const ReplayAggregateEventsRequest$json = const {
  '1': 'ReplayAggregateEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
  ],
};

/// Descriptor for `ReplayAggregateEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replayAggregateEventsRequestDescriptor =
    $convert.base64Decode(
        'ChxSZXBsYXlBZ2dyZWdhdGVFdmVudHNSZXF1ZXN0EhIKBHR5cGUYASABKAlSBHR5cGUSEgoEdXVpZBgCIAEoCVIEdXVpZBI9CgZleHBhbmQYAyADKA4yJS5vcmcuZGlzY29vcy5lcy5BZ2dyZWdhdGVFeHBhbmRGaWVsZHNSBmV4cGFuZA==');
@$core.Deprecated('Use replayAggregateEventsResponseDescriptor instead')
const ReplayAggregateEventsResponse$json = const {
  '1': 'ReplayAggregateEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `ReplayAggregateEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replayAggregateEventsResponseDescriptor =
    $convert.base64Decode(
        'Ch1SZXBsYXlBZ2dyZWdhdGVFdmVudHNSZXNwb25zZRISCgR0eXBlGAEgASgJUgR0eXBlEhIKBHV1aWQYAiABKAlSBHV1aWQSHgoKc3RhdHVzQ29kZRgDIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYBCABKAlSDHJlYXNvblBocmFzZRIxCgRtZXRhGAUgASgLMh0ub3JnLmRpc2Nvb3MuZXMuQWdncmVnYXRlTWV0YVIEbWV0YQ==');
@$core.Deprecated('Use catchupAggregateEventsRequestDescriptor instead')
const CatchupAggregateEventsRequest$json = const {
  '1': 'CatchupAggregateEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
  ],
};

/// Descriptor for `CatchupAggregateEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List catchupAggregateEventsRequestDescriptor =
    $convert.base64Decode(
        'Ch1DYXRjaHVwQWdncmVnYXRlRXZlbnRzUmVxdWVzdBISCgR0eXBlGAEgASgJUgR0eXBlEhIKBHV1aWQYAiABKAlSBHV1aWQSPQoGZXhwYW5kGAMgAygOMiUub3JnLmRpc2Nvb3MuZXMuQWdncmVnYXRlRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use catchupAggregateEventsResponseDescriptor instead')
const CatchupAggregateEventsResponse$json = const {
  '1': 'CatchupAggregateEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `CatchupAggregateEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List catchupAggregateEventsResponseDescriptor =
    $convert.base64Decode(
        'Ch5DYXRjaHVwQWdncmVnYXRlRXZlbnRzUmVzcG9uc2USEgoEdHlwZRgBIAEoCVIEdHlwZRISCgR1dWlkGAIgASgJUgR1dWlkEh4KCnN0YXR1c0NvZGUYAyABKAVSCnN0YXR1c0NvZGUSIgoMcmVhc29uUGhyYXNlGAQgASgJUgxyZWFzb25QaHJhc2USMQoEbWV0YRgFIAEoCzIdLm9yZy5kaXNjb29zLmVzLkFnZ3JlZ2F0ZU1ldGFSBG1ldGE=');
@$core.Deprecated('Use replaceAggregateDataRequestDescriptor instead')
const ReplaceAggregateDataRequest$json = const {
  '1': 'ReplaceAggregateDataRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
    const {
      '1': 'data',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'data'
    },
    const {
      '1': 'patches',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'patches'
    },
  ],
};

/// Descriptor for `ReplaceAggregateDataRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replaceAggregateDataRequestDescriptor =
    $convert.base64Decode(
        'ChtSZXBsYWNlQWdncmVnYXRlRGF0YVJlcXVlc3QSEgoEdHlwZRgBIAEoCVIEdHlwZRISCgR1dWlkGAIgASgJUgR1dWlkEj0KBmV4cGFuZBgDIAMoDjIlLm9yZy5kaXNjb29zLmVzLkFnZ3JlZ2F0ZUV4cGFuZEZpZWxkc1IGZXhwYW5kEigKBGRhdGEYBCABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgRkYXRhEi4KB3BhdGNoZXMYBSADKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgdwYXRjaGVz');
@$core.Deprecated('Use replaceAggregateDataResponseDescriptor instead')
const ReplaceAggregateDataResponse$json = const {
  '1': 'ReplaceAggregateDataResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `ReplaceAggregateDataResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replaceAggregateDataResponseDescriptor =
    $convert.base64Decode(
        'ChxSZXBsYWNlQWdncmVnYXRlRGF0YVJlc3BvbnNlEhIKBHR5cGUYASABKAlSBHR5cGUSEgoEdXVpZBgCIAEoCVIEdXVpZBIeCgpzdGF0dXNDb2RlGAMgASgFUgpzdGF0dXNDb2RlEiIKDHJlYXNvblBocmFzZRgEIAEoCVIMcmVhc29uUGhyYXNlEjEKBG1ldGEYBSABKAsyHS5vcmcuZGlzY29vcy5lcy5BZ2dyZWdhdGVNZXRhUgRtZXRh');
@$core.Deprecated('Use aggregateMetaListDescriptor instead')
const AggregateMetaList$json = const {
  '1': 'AggregateMetaList',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'items'
    },
  ],
};

/// Descriptor for `AggregateMetaList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aggregateMetaListDescriptor = $convert.base64Decode(
    'ChFBZ2dyZWdhdGVNZXRhTGlzdBIUCgVjb3VudBgBIAEoBVIFY291bnQSMwoFaXRlbXMYAiADKAsyHS5vcmcuZGlzY29vcy5lcy5BZ2dyZWdhdGVNZXRhUgVpdGVtcw==');
@$core.Deprecated('Use aggregateMetaDescriptor instead')
const AggregateMeta$json = const {
  '1': 'AggregateMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'number', '3': 3, '4': 1, '5': 3, '10': 'number'},
    const {'1': 'position', '3': 4, '4': 1, '5': 3, '10': 'position'},
    const {
      '1': 'createdBy',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMeta',
      '10': 'createdBy'
    },
    const {
      '1': 'changedBy',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMeta',
      '10': 'changedBy'
    },
    const {
      '1': 'deletedBy',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMeta',
      '10': 'deletedBy'
    },
    const {
      '1': 'applied',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMetaList',
      '10': 'applied'
    },
    const {
      '1': 'pending',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMetaList',
      '10': 'pending'
    },
    const {
      '1': 'skipped',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMetaList',
      '10': 'skipped'
    },
    const {
      '1': 'taint',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'taint'
    },
    const {
      '1': 'cordon',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'cordon'
    },
    const {
      '1': 'data',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'data'
    },
  ],
};

/// Descriptor for `AggregateMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aggregateMetaDescriptor = $convert.base64Decode(
    'Cg1BZ2dyZWdhdGVNZXRhEhIKBHR5cGUYASABKAlSBHR5cGUSEgoEdXVpZBgCIAEoCVIEdXVpZBIWCgZudW1iZXIYAyABKANSBm51bWJlchIaCghwb3NpdGlvbhgEIAEoA1IIcG9zaXRpb24SNwoJY3JlYXRlZEJ5GAUgASgLMhkub3JnLmRpc2Nvb3MuZXMuRXZlbnRNZXRhUgljcmVhdGVkQnkSNwoJY2hhbmdlZEJ5GAYgASgLMhkub3JnLmRpc2Nvb3MuZXMuRXZlbnRNZXRhUgljaGFuZ2VkQnkSNwoJZGVsZXRlZEJ5GAcgASgLMhkub3JnLmRpc2Nvb3MuZXMuRXZlbnRNZXRhUglkZWxldGVkQnkSNwoHYXBwbGllZBgIIAEoCzIdLm9yZy5kaXNjb29zLmVzLkV2ZW50TWV0YUxpc3RSB2FwcGxpZWQSNwoHcGVuZGluZxgJIAEoCzIdLm9yZy5kaXNjb29zLmVzLkV2ZW50TWV0YUxpc3RSB3BlbmRpbmcSNwoHc2tpcHBlZBgKIAEoCzIdLm9yZy5kaXNjb29zLmVzLkV2ZW50TWV0YUxpc3RSB3NraXBwZWQSKgoFdGFpbnQYCyABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgV0YWludBIsCgZjb3Jkb24YDCABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgZjb3Jkb24SKAoEZGF0YRgNIAEoCzIULmdvb2dsZS5wcm90b2J1Zi5BbnlSBGRhdGE=');
