///
//  Generated code. Do not modify.
//  source: snapshot.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use snapshotExpandFieldsDescriptor instead')
const SnapshotExpandFields$json = const {
  '1': 'SnapshotExpandFields',
  '2': const [
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_ITEMS', '2': 2},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_DATA', '2': 3},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_METRICS', '2': 4},
  ],
};

/// Descriptor for `SnapshotExpandFields`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List snapshotExpandFieldsDescriptor = $convert.base64Decode(
    'ChRTbmFwc2hvdEV4cGFuZEZpZWxkcxIfChtTTkFQU0hPVF9FWFBBTkRfRklFTERTX05PTkUQABIeChpTTkFQU0hPVF9FWFBBTkRfRklFTERTX0FMTBABEiAKHFNOQVBTSE9UX0VYUEFORF9GSUVMRFNfSVRFTVMQAhIfChtTTkFQU0hPVF9FWFBBTkRfRklFTERTX0RBVEEQAxIiCh5TTkFQU0hPVF9FWFBBTkRfRklFTERTX01FVFJJQ1MQBA==');
@$core.Deprecated('Use getSnapshotMetaRequestDescriptor instead')
const GetSnapshotMetaRequest$json = const {
  '1': 'GetSnapshotMetaRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {
      '1': 'expand',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.SnapshotExpandFields',
      '10': 'expand'
    },
  ],
};

/// Descriptor for `GetSnapshotMetaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSnapshotMetaRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRTbmFwc2hvdE1ldGFSZXF1ZXN0EhIKBHR5cGUYASABKAlSBHR5cGUSPAoGZXhwYW5kGAIgAygOMiQub3JnLmRpc2Nvb3MuZXMuU25hcHNob3RFeHBhbmRGaWVsZHNSBmV4cGFuZA==');
@$core.Deprecated('Use getSnapshotMetaResponseDescriptor instead')
const GetSnapshotMetaResponse$json = const {
  '1': 'GetSnapshotMetaResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `GetSnapshotMetaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSnapshotMetaResponseDescriptor =
    $convert.base64Decode(
        'ChdHZXRTbmFwc2hvdE1ldGFSZXNwb25zZRISCgR0eXBlGAEgASgJUgR0eXBlEh4KCnN0YXR1c0NvZGUYAiABKAVSCnN0YXR1c0NvZGUSIgoMcmVhc29uUGhyYXNlGAMgASgJUgxyZWFzb25QaHJhc2USMAoEbWV0YRgEIAEoCzIcLm9yZy5kaXNjb29zLmVzLlNuYXBzaG90TWV0YVIEbWV0YQ==');
@$core.Deprecated('Use snapshotMetaDescriptor instead')
const SnapshotMeta$json = const {
  '1': 'SnapshotMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'last', '3': 3, '4': 1, '5': 9, '10': 'last'},
    const {'1': 'number', '3': 4, '4': 1, '5': 3, '10': 'number'},
    const {'1': 'position', '3': 5, '4': 1, '5': 3, '10': 'position'},
    const {
      '1': 'config',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotConfig',
      '10': 'config'
    },
    const {
      '1': 'metrics',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMetricsMeta',
      '10': 'metrics'
    },
    const {
      '1': 'aggregates',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMetaList',
      '10': 'aggregates'
    },
  ],
};

/// Descriptor for `SnapshotMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotMetaDescriptor = $convert.base64Decode(
    'CgxTbmFwc2hvdE1ldGESEgoEdHlwZRgBIAEoCVIEdHlwZRISCgR1dWlkGAIgASgJUgR1dWlkEhIKBGxhc3QYAyABKAlSBGxhc3QSFgoGbnVtYmVyGAQgASgDUgZudW1iZXISGgoIcG9zaXRpb24YBSABKANSCHBvc2l0aW9uEjYKBmNvbmZpZxgGIAEoCzIeLm9yZy5kaXNjb29zLmVzLlNuYXBzaG90Q29uZmlnUgZjb25maWcSPQoHbWV0cmljcxgHIAEoCzIjLm9yZy5kaXNjb29zLmVzLlNuYXBzaG90TWV0cmljc01ldGFSB21ldHJpY3MSQQoKYWdncmVnYXRlcxgIIAEoCzIhLm9yZy5kaXNjb29zLmVzLkFnZ3JlZ2F0ZU1ldGFMaXN0UgphZ2dyZWdhdGVz');
@$core.Deprecated('Use snapshotConfigDescriptor instead')
const SnapshotConfig$json = const {
  '1': 'SnapshotConfig',
  '2': const [
    const {'1': 'keep', '3': 1, '4': 1, '5': 5, '10': 'keep'},
    const {'1': 'threshold', '3': 2, '4': 1, '5': 5, '10': 'threshold'},
    const {'1': 'automatic', '3': 3, '4': 1, '5': 8, '10': 'automatic'},
  ],
};

/// Descriptor for `SnapshotConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotConfigDescriptor = $convert.base64Decode(
    'Cg5TbmFwc2hvdENvbmZpZxISCgRrZWVwGAEgASgFUgRrZWVwEhwKCXRocmVzaG9sZBgCIAEoBVIJdGhyZXNob2xkEhwKCWF1dG9tYXRpYxgDIAEoCFIJYXV0b21hdGlj');
@$core.Deprecated('Use snapshotMetricsMetaDescriptor instead')
const SnapshotMetricsMeta$json = const {
  '1': 'SnapshotMetricsMeta',
  '2': const [
    const {'1': 'snapshots', '3': 1, '4': 1, '5': 3, '10': 'snapshots'},
    const {'1': 'unsaved', '3': 2, '4': 1, '5': 3, '10': 'unsaved'},
    const {'1': 'missing', '3': 3, '4': 1, '5': 3, '10': 'missing'},
    const {'1': 'isPartial', '3': 4, '4': 1, '5': 8, '10': 'isPartial'},
    const {
      '1': 'save',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.DurationMetricMeta',
      '10': 'save'
    },
  ],
};

/// Descriptor for `SnapshotMetricsMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotMetricsMetaDescriptor = $convert.base64Decode(
    'ChNTbmFwc2hvdE1ldHJpY3NNZXRhEhwKCXNuYXBzaG90cxgBIAEoA1IJc25hcHNob3RzEhgKB3Vuc2F2ZWQYAiABKANSB3Vuc2F2ZWQSGAoHbWlzc2luZxgDIAEoA1IHbWlzc2luZxIcCglpc1BhcnRpYWwYBCABKAhSCWlzUGFydGlhbBI2CgRzYXZlGAUgASgLMiIub3JnLmRpc2Nvb3MuZXMuRHVyYXRpb25NZXRyaWNNZXRhUgRzYXZl');
@$core.Deprecated('Use configureSnapshotRequestDescriptor instead')
const ConfigureSnapshotRequest$json = const {
  '1': 'ConfigureSnapshotRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'automatic', '3': 2, '4': 1, '5': 8, '10': 'automatic'},
    const {'1': 'keep', '3': 3, '4': 1, '5': 5, '10': 'keep'},
    const {'1': 'threshold', '3': 4, '4': 1, '5': 5, '10': 'threshold'},
    const {
      '1': 'expand',
      '3': 5,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.SnapshotExpandFields',
      '10': 'expand'
    },
  ],
};

/// Descriptor for `ConfigureSnapshotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List configureSnapshotRequestDescriptor =
    $convert.base64Decode(
        'ChhDb25maWd1cmVTbmFwc2hvdFJlcXVlc3QSEgoEdHlwZRgBIAEoCVIEdHlwZRIcCglhdXRvbWF0aWMYAiABKAhSCWF1dG9tYXRpYxISCgRrZWVwGAMgASgFUgRrZWVwEhwKCXRocmVzaG9sZBgEIAEoBVIJdGhyZXNob2xkEjwKBmV4cGFuZBgFIAMoDjIkLm9yZy5kaXNjb29zLmVzLlNuYXBzaG90RXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use configureSnapshotResponseDescriptor instead')
const ConfigureSnapshotResponse$json = const {
  '1': 'ConfigureSnapshotResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `ConfigureSnapshotResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List configureSnapshotResponseDescriptor =
    $convert.base64Decode(
        'ChlDb25maWd1cmVTbmFwc2hvdFJlc3BvbnNlEhIKBHR5cGUYASABKAlSBHR5cGUSHgoKc3RhdHVzQ29kZRgCIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYAyABKAlSDHJlYXNvblBocmFzZRIwCgRtZXRhGAQgASgLMhwub3JnLmRpc2Nvb3MuZXMuU25hcHNob3RNZXRhUgRtZXRh');
@$core.Deprecated('Use saveSnapshotRequestDescriptor instead')
const SaveSnapshotRequest$json = const {
  '1': 'SaveSnapshotRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'force', '3': 2, '4': 1, '5': 8, '10': 'force'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.SnapshotExpandFields',
      '10': 'expand'
    },
  ],
};

/// Descriptor for `SaveSnapshotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveSnapshotRequestDescriptor = $convert.base64Decode(
    'ChNTYXZlU25hcHNob3RSZXF1ZXN0EhIKBHR5cGUYASABKAlSBHR5cGUSFAoFZm9yY2UYAiABKAhSBWZvcmNlEjwKBmV4cGFuZBgDIAMoDjIkLm9yZy5kaXNjb29zLmVzLlNuYXBzaG90RXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use saveSnapshotResponseDescriptor instead')
const SaveSnapshotResponse$json = const {
  '1': 'SaveSnapshotResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `SaveSnapshotResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveSnapshotResponseDescriptor = $convert.base64Decode(
    'ChRTYXZlU25hcHNob3RSZXNwb25zZRISCgR0eXBlGAEgASgJUgR0eXBlEh4KCnN0YXR1c0NvZGUYAiABKAVSCnN0YXR1c0NvZGUSIgoMcmVhc29uUGhyYXNlGAMgASgJUgxyZWFzb25QaHJhc2USMAoEbWV0YRgEIAEoCzIcLm9yZy5kaXNjb29zLmVzLlNuYXBzaG90TWV0YVIEbWV0YQ==');
@$core.Deprecated('Use downloadSnapshotRequestDescriptor instead')
const DownloadSnapshotRequest$json = const {
  '1': 'DownloadSnapshotRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'chunkSize', '3': 2, '4': 1, '5': 4, '10': 'chunkSize'},
  ],
};

/// Descriptor for `DownloadSnapshotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadSnapshotRequestDescriptor =
    $convert.base64Decode(
        'ChdEb3dubG9hZFNuYXBzaG90UmVxdWVzdBISCgR0eXBlGAEgASgJUgR0eXBlEhwKCWNodW5rU2l6ZRgCIAEoBFIJY2h1bmtTaXpl');
@$core.Deprecated('Use snapshotChunkDescriptor instead')
const SnapshotChunk$json = const {
  '1': 'SnapshotChunk',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {
      '1': 'chunk',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.io.FileChunk',
      '10': 'chunk'
    },
  ],
};

/// Descriptor for `SnapshotChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snapshotChunkDescriptor = $convert.base64Decode(
    'Cg1TbmFwc2hvdENodW5rEhIKBHR5cGUYASABKAlSBHR5cGUSLwoFY2h1bmsYAyABKAsyGS5vcmcuZGlzY29vcy5pby5GaWxlQ2h1bmtSBWNodW5r');
@$core.Deprecated('Use uploadSnapshotResponseDescriptor instead')
const UploadSnapshotResponse$json = const {
  '1': 'UploadSnapshotResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'chunkSize', '3': 2, '4': 1, '5': 4, '10': 'chunkSize'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};

/// Descriptor for `UploadSnapshotResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadSnapshotResponseDescriptor =
    $convert.base64Decode(
        'ChZVcGxvYWRTbmFwc2hvdFJlc3BvbnNlEhIKBHR5cGUYASABKAlSBHR5cGUSHAoJY2h1bmtTaXplGAIgASgEUgljaHVua1NpemUSHgoKc3RhdHVzQ29kZRgDIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYBCABKAlSDHJlYXNvblBocmFzZRIwCgRtZXRhGAUgASgLMhwub3JnLmRpc2Nvb3MuZXMuU25hcHNob3RNZXRhUgRtZXRh');
