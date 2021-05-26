///
//  Generated code. Do not modify.
//  source: repository.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use repoExpandFieldsDescriptor instead')
const RepoExpandFields$json = const {
  '1': 'RepoExpandFields',
  '2': const [
    const {'1': 'REPO_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'REPO_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'REPO_EXPAND_FIELDS_ITEMS', '2': 2},
    const {'1': 'REPO_EXPAND_FIELDS_DATA', '2': 3},
    const {'1': 'REPO_EXPAND_FIELDS_METRICS', '2': 4},
    const {'1': 'REPO_EXPAND_FIELDS_QUEUE', '2': 5},
    const {'1': 'REPO_EXPAND_FIELDS_CONN', '2': 6},
    const {'1': 'REPO_EXPAND_FIELDS_SNAPSHOT', '2': 7},
  ],
};

/// Descriptor for `RepoExpandFields`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List repoExpandFieldsDescriptor = $convert.base64Decode('ChBSZXBvRXhwYW5kRmllbGRzEhsKF1JFUE9fRVhQQU5EX0ZJRUxEU19OT05FEAASGgoWUkVQT19FWFBBTkRfRklFTERTX0FMTBABEhwKGFJFUE9fRVhQQU5EX0ZJRUxEU19JVEVNUxACEhsKF1JFUE9fRVhQQU5EX0ZJRUxEU19EQVRBEAMSHgoaUkVQT19FWFBBTkRfRklFTERTX01FVFJJQ1MQBBIcChhSRVBPX0VYUEFORF9GSUVMRFNfUVVFVUUQBRIbChdSRVBPX0VYUEFORF9GSUVMRFNfQ09OThAGEh8KG1JFUE9fRVhQQU5EX0ZJRUxEU19TTkFQU0hPVBAH');
@$core.Deprecated('Use getRepoMetaRequestDescriptor instead')
const GetRepoMetaRequest$json = const {
  '1': 'GetRepoMetaRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'expand', '3': 2, '4': 3, '5': 14, '6': '.org.discoos.es.RepoExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `GetRepoMetaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRepoMetaRequestDescriptor = $convert.base64Decode('ChJHZXRSZXBvTWV0YVJlcXVlc3QSEgoEdHlwZRgBIAEoCVIEdHlwZRI4CgZleHBhbmQYAiADKA4yIC5vcmcuZGlzY29vcy5lcy5SZXBvRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use getRepoMetaResponseDescriptor instead')
const GetRepoMetaResponse$json = const {
  '1': 'GetRepoMetaResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 4, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMeta', '10': 'meta'},
  ],
};

/// Descriptor for `GetRepoMetaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRepoMetaResponseDescriptor = $convert.base64Decode('ChNHZXRSZXBvTWV0YVJlc3BvbnNlEhIKBHR5cGUYASABKAlSBHR5cGUSHgoKc3RhdHVzQ29kZRgCIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYAyABKAlSDHJlYXNvblBocmFzZRIyCgRtZXRhGAQgASgLMh4ub3JnLmRpc2Nvb3MuZXMuUmVwb3NpdG9yeU1ldGFSBG1ldGE=');
@$core.Deprecated('Use replayRepoEventsRequestDescriptor instead')
const ReplayRepoEventsRequest$json = const {
  '1': 'ReplayRepoEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'expand', '3': 3, '4': 3, '5': 14, '6': '.org.discoos.es.RepoExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `ReplayRepoEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replayRepoEventsRequestDescriptor = $convert.base64Decode('ChdSZXBsYXlSZXBvRXZlbnRzUmVxdWVzdBISCgR0eXBlGAEgASgJUgR0eXBlEhQKBXV1aWRzGAIgAygJUgV1dWlkcxI4CgZleHBhbmQYAyADKA4yIC5vcmcuZGlzY29vcy5lcy5SZXBvRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use replayRepoEventsResponseDescriptor instead')
const ReplayRepoEventsResponse$json = const {
  '1': 'ReplayRepoEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMeta', '10': 'meta'},
  ],
};

/// Descriptor for `ReplayRepoEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replayRepoEventsResponseDescriptor = $convert.base64Decode('ChhSZXBsYXlSZXBvRXZlbnRzUmVzcG9uc2USEgoEdHlwZRgBIAEoCVIEdHlwZRIUCgV1dWlkcxgCIAMoCVIFdXVpZHMSHgoKc3RhdHVzQ29kZRgDIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYBCABKAlSDHJlYXNvblBocmFzZRIyCgRtZXRhGAUgASgLMh4ub3JnLmRpc2Nvb3MuZXMuUmVwb3NpdG9yeU1ldGFSBG1ldGE=');
@$core.Deprecated('Use catchupRepoEventsRequestDescriptor instead')
const CatchupRepoEventsRequest$json = const {
  '1': 'CatchupRepoEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'expand', '3': 3, '4': 3, '5': 14, '6': '.org.discoos.es.RepoExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `CatchupRepoEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List catchupRepoEventsRequestDescriptor = $convert.base64Decode('ChhDYXRjaHVwUmVwb0V2ZW50c1JlcXVlc3QSEgoEdHlwZRgBIAEoCVIEdHlwZRIUCgV1dWlkcxgCIAMoCVIFdXVpZHMSOAoGZXhwYW5kGAMgAygOMiAub3JnLmRpc2Nvb3MuZXMuUmVwb0V4cGFuZEZpZWxkc1IGZXhwYW5k');
@$core.Deprecated('Use catchupRepoEventsResponseDescriptor instead')
const CatchupRepoEventsResponse$json = const {
  '1': 'CatchupRepoEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMeta', '10': 'meta'},
  ],
};

/// Descriptor for `CatchupRepoEventsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List catchupRepoEventsResponseDescriptor = $convert.base64Decode('ChlDYXRjaHVwUmVwb0V2ZW50c1Jlc3BvbnNlEhIKBHR5cGUYASABKAlSBHR5cGUSFAoFdXVpZHMYAiADKAlSBXV1aWRzEh4KCnN0YXR1c0NvZGUYAyABKAVSCnN0YXR1c0NvZGUSIgoMcmVhc29uUGhyYXNlGAQgASgJUgxyZWFzb25QaHJhc2USMgoEbWV0YRgFIAEoCzIeLm9yZy5kaXNjb29zLmVzLlJlcG9zaXRvcnlNZXRhUgRtZXRh');
@$core.Deprecated('Use repairRepoRequestDescriptor instead')
const RepairRepoRequest$json = const {
  '1': 'RepairRepoRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'master', '3': 2, '4': 1, '5': 8, '10': 'master'},
    const {'1': 'expand', '3': 3, '4': 3, '5': 14, '6': '.org.discoos.es.RepoExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `RepairRepoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repairRepoRequestDescriptor = $convert.base64Decode('ChFSZXBhaXJSZXBvUmVxdWVzdBISCgR0eXBlGAEgASgJUgR0eXBlEhYKBm1hc3RlchgCIAEoCFIGbWFzdGVyEjgKBmV4cGFuZBgDIAMoDjIgLm9yZy5kaXNjb29zLmVzLlJlcG9FeHBhbmRGaWVsZHNSBmV4cGFuZA==');
@$core.Deprecated('Use repairRepoResponseDescriptor instead')
const RepairRepoResponse$json = const {
  '1': 'RepairRepoResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMeta', '10': 'meta'},
    const {'1': 'before', '3': 6, '4': 1, '5': 11, '6': '.org.discoos.es.AnalysisMeta', '10': 'before'},
    const {'1': 'after', '3': 7, '4': 1, '5': 11, '6': '.org.discoos.es.AnalysisMeta', '10': 'after'},
  ],
};

/// Descriptor for `RepairRepoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repairRepoResponseDescriptor = $convert.base64Decode('ChJSZXBhaXJSZXBvUmVzcG9uc2USEgoEdHlwZRgBIAEoCVIEdHlwZRIeCgpzdGF0dXNDb2RlGAMgASgFUgpzdGF0dXNDb2RlEiIKDHJlYXNvblBocmFzZRgEIAEoCVIMcmVhc29uUGhyYXNlEjIKBG1ldGEYBSABKAsyHi5vcmcuZGlzY29vcy5lcy5SZXBvc2l0b3J5TWV0YVIEbWV0YRI0CgZiZWZvcmUYBiABKAsyHC5vcmcuZGlzY29vcy5lcy5BbmFseXNpc01ldGFSBmJlZm9yZRIyCgVhZnRlchgHIAEoCzIcLm9yZy5kaXNjb29zLmVzLkFuYWx5c2lzTWV0YVIFYWZ0ZXI=');
@$core.Deprecated('Use analysisMetaDescriptor instead')
const AnalysisMeta$json = const {
  '1': 'AnalysisMeta',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {'1': 'wrong', '3': 2, '4': 1, '5': 5, '10': 'wrong'},
    const {'1': 'multiple', '3': 3, '4': 1, '5': 5, '10': 'multiple'},
    const {'1': 'summary', '3': 4, '4': 3, '5': 9, '10': 'summary'},
  ],
};

/// Descriptor for `AnalysisMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List analysisMetaDescriptor = $convert.base64Decode('CgxBbmFseXNpc01ldGESFAoFY291bnQYASABKAVSBWNvdW50EhQKBXdyb25nGAIgASgFUgV3cm9uZxIaCghtdWx0aXBsZRgDIAEoBVIIbXVsdGlwbGUSGAoHc3VtbWFyeRgEIAMoCVIHc3VtbWFyeQ==');
@$core.Deprecated('Use rebuildRepoRequestDescriptor instead')
const RebuildRepoRequest$json = const {
  '1': 'RebuildRepoRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'master', '3': 2, '4': 1, '5': 8, '10': 'master'},
    const {'1': 'expand', '3': 3, '4': 3, '5': 14, '6': '.org.discoos.es.RepoExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `RebuildRepoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rebuildRepoRequestDescriptor = $convert.base64Decode('ChJSZWJ1aWxkUmVwb1JlcXVlc3QSEgoEdHlwZRgBIAEoCVIEdHlwZRIWCgZtYXN0ZXIYAiABKAhSBm1hc3RlchI4CgZleHBhbmQYAyADKA4yIC5vcmcuZGlzY29vcy5lcy5SZXBvRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use rebuildRepoResponseDescriptor instead')
const RebuildRepoResponse$json = const {
  '1': 'RebuildRepoResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMeta', '10': 'meta'},
  ],
};

/// Descriptor for `RebuildRepoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rebuildRepoResponseDescriptor = $convert.base64Decode('ChNSZWJ1aWxkUmVwb1Jlc3BvbnNlEhIKBHR5cGUYASABKAlSBHR5cGUSHgoKc3RhdHVzQ29kZRgDIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYBCABKAlSDHJlYXNvblBocmFzZRIyCgRtZXRhGAUgASgLMh4ub3JnLmRpc2Nvb3MuZXMuUmVwb3NpdG9yeU1ldGFSBG1ldGE=');
@$core.Deprecated('Use repositoryMetaDescriptor instead')
const RepositoryMeta$json = const {
  '1': 'RepositoryMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'lastEvent', '3': 2, '4': 1, '5': 11, '6': '.org.discoos.es.EventMeta', '10': 'lastEvent'},
    const {'1': 'queue', '3': 3, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryQueueMeta', '10': 'queue'},
    const {'1': 'metrics', '3': 4, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMetricsMeta', '10': 'metrics'},
    const {'1': 'connection', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.ConnectionMetricsMeta', '10': 'connection'},
  ],
};

/// Descriptor for `RepositoryMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryMetaDescriptor = $convert.base64Decode('Cg5SZXBvc2l0b3J5TWV0YRISCgR0eXBlGAEgASgJUgR0eXBlEjcKCWxhc3RFdmVudBgCIAEoCzIZLm9yZy5kaXNjb29zLmVzLkV2ZW50TWV0YVIJbGFzdEV2ZW50EjkKBXF1ZXVlGAMgASgLMiMub3JnLmRpc2Nvb3MuZXMuUmVwb3NpdG9yeVF1ZXVlTWV0YVIFcXVldWUSPwoHbWV0cmljcxgEIAEoCzIlLm9yZy5kaXNjb29zLmVzLlJlcG9zaXRvcnlNZXRyaWNzTWV0YVIHbWV0cmljcxJFCgpjb25uZWN0aW9uGAUgASgLMiUub3JnLmRpc2Nvb3MuZXMuQ29ubmVjdGlvbk1ldHJpY3NNZXRhUgpjb25uZWN0aW9u');
@$core.Deprecated('Use repositoryQueueMetaDescriptor instead')
const RepositoryQueueMeta$json = const {
  '1': 'RepositoryQueueMeta',
  '2': const [
    const {'1': 'pressure', '3': 1, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryQueuePressureMeta', '10': 'pressure'},
    const {'1': 'status', '3': 2, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryQueueStatusMeta', '10': 'status'},
    const {'1': 'metrics', '3': 3, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMetricsMeta', '10': 'metrics'},
  ],
};

/// Descriptor for `RepositoryQueueMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryQueueMetaDescriptor = $convert.base64Decode('ChNSZXBvc2l0b3J5UXVldWVNZXRhEkcKCHByZXNzdXJlGAEgASgLMisub3JnLmRpc2Nvb3MuZXMuUmVwb3NpdG9yeVF1ZXVlUHJlc3N1cmVNZXRhUghwcmVzc3VyZRJBCgZzdGF0dXMYAiABKAsyKS5vcmcuZGlzY29vcy5lcy5SZXBvc2l0b3J5UXVldWVTdGF0dXNNZXRhUgZzdGF0dXMSPwoHbWV0cmljcxgDIAEoCzIlLm9yZy5kaXNjb29zLmVzLlJlcG9zaXRvcnlNZXRyaWNzTWV0YVIHbWV0cmljcw==');
@$core.Deprecated('Use repositoryQueuePressureMetaDescriptor instead')
const RepositoryQueuePressureMeta$json = const {
  '1': 'RepositoryQueuePressureMeta',
  '2': const [
    const {'1': 'push', '3': 1, '4': 1, '5': 5, '10': 'push'},
    const {'1': 'commands', '3': 2, '4': 1, '5': 5, '10': 'commands'},
    const {'1': 'total', '3': 3, '4': 1, '5': 5, '10': 'total'},
    const {'1': 'maximum', '3': 4, '4': 1, '5': 5, '10': 'maximum'},
    const {'1': 'exceeded', '3': 5, '4': 1, '5': 8, '10': 'exceeded'},
  ],
};

/// Descriptor for `RepositoryQueuePressureMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryQueuePressureMetaDescriptor = $convert.base64Decode('ChtSZXBvc2l0b3J5UXVldWVQcmVzc3VyZU1ldGESEgoEcHVzaBgBIAEoBVIEcHVzaBIaCghjb21tYW5kcxgCIAEoBVIIY29tbWFuZHMSFAoFdG90YWwYAyABKAVSBXRvdGFsEhgKB21heGltdW0YBCABKAVSB21heGltdW0SGgoIZXhjZWVkZWQYBSABKAhSCGV4Y2VlZGVk');
@$core.Deprecated('Use repositoryQueueStatusMetaDescriptor instead')
const RepositoryQueueStatusMeta$json = const {
  '1': 'RepositoryQueueStatusMeta',
  '2': const [
    const {'1': 'idle', '3': 1, '4': 1, '5': 8, '10': 'idle'},
    const {'1': 'ready', '3': 2, '4': 1, '5': 8, '10': 'ready'},
    const {'1': 'disposed', '3': 3, '4': 1, '5': 8, '10': 'disposed'},
  ],
};

/// Descriptor for `RepositoryQueueStatusMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryQueueStatusMetaDescriptor = $convert.base64Decode('ChlSZXBvc2l0b3J5UXVldWVTdGF0dXNNZXRhEhIKBGlkbGUYASABKAhSBGlkbGUSFAoFcmVhZHkYAiABKAhSBXJlYWR5EhoKCGRpc3Bvc2VkGAMgASgIUghkaXNwb3NlZA==');
@$core.Deprecated('Use repositoryMetricsMetaDescriptor instead')
const RepositoryMetricsMeta$json = const {
  '1': 'RepositoryMetricsMeta',
  '2': const [
    const {'1': 'events', '3': 1, '4': 1, '5': 3, '10': 'events'},
    const {'1': 'transactions', '3': 2, '4': 1, '5': 5, '10': 'transactions'},
    const {'1': 'aggregates', '3': 4, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMetricsAggregateMeta', '10': 'aggregates'},
    const {'1': 'push', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.DurationMetricMeta', '10': 'push'},
  ],
};

/// Descriptor for `RepositoryMetricsMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryMetricsMetaDescriptor = $convert.base64Decode('ChVSZXBvc2l0b3J5TWV0cmljc01ldGESFgoGZXZlbnRzGAEgASgDUgZldmVudHMSIgoMdHJhbnNhY3Rpb25zGAIgASgFUgx0cmFuc2FjdGlvbnMSTgoKYWdncmVnYXRlcxgEIAEoCzIuLm9yZy5kaXNjb29zLmVzLlJlcG9zaXRvcnlNZXRyaWNzQWdncmVnYXRlTWV0YVIKYWdncmVnYXRlcxI2CgRwdXNoGAUgASgLMiIub3JnLmRpc2Nvb3MuZXMuRHVyYXRpb25NZXRyaWNNZXRhUgRwdXNo');
@$core.Deprecated('Use repositoryMetricsAggregateMetaDescriptor instead')
const RepositoryMetricsAggregateMeta$json = const {
  '1': 'RepositoryMetricsAggregateMeta',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {'1': 'changed', '3': 2, '4': 1, '5': 5, '10': 'changed'},
    const {'1': 'tainted', '3': 3, '4': 1, '5': 11, '6': '.org.discoos.es.AggregateMetaList', '10': 'tainted'},
    const {'1': 'cordoned', '3': 4, '4': 1, '5': 11, '6': '.org.discoos.es.AggregateMetaList', '10': 'cordoned'},
  ],
};

/// Descriptor for `RepositoryMetricsAggregateMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List repositoryMetricsAggregateMetaDescriptor = $convert.base64Decode('Ch5SZXBvc2l0b3J5TWV0cmljc0FnZ3JlZ2F0ZU1ldGESFAoFY291bnQYASABKAVSBWNvdW50EhgKB2NoYW5nZWQYAiABKAVSB2NoYW5nZWQSOwoHdGFpbnRlZBgDIAEoCzIhLm9yZy5kaXNjb29zLmVzLkFnZ3JlZ2F0ZU1ldGFMaXN0Ugd0YWludGVkEj0KCGNvcmRvbmVkGAQgASgLMiEub3JnLmRpc2Nvb3MuZXMuQWdncmVnYXRlTWV0YUxpc3RSCGNvcmRvbmVk');
@$core.Deprecated('Use connectionMetricsMetaDescriptor instead')
const ConnectionMetricsMeta$json = const {
  '1': 'ConnectionMetricsMeta',
  '2': const [
    const {'1': 'read', '3': 1, '4': 1, '5': 11, '6': '.org.discoos.es.DurationMetricMeta', '10': 'read'},
    const {'1': 'write', '3': 2, '4': 1, '5': 11, '6': '.org.discoos.es.DurationMetricMeta', '10': 'write'},
  ],
};

/// Descriptor for `ConnectionMetricsMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionMetricsMetaDescriptor = $convert.base64Decode('ChVDb25uZWN0aW9uTWV0cmljc01ldGESNgoEcmVhZBgBIAEoCzIiLm9yZy5kaXNjb29zLmVzLkR1cmF0aW9uTWV0cmljTWV0YVIEcmVhZBI4CgV3cml0ZRgCIAEoCzIiLm9yZy5kaXNjb29zLmVzLkR1cmF0aW9uTWV0cmljTWV0YVIFd3JpdGU=');
