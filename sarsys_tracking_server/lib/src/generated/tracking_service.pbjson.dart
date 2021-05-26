///
//  Generated code. Do not modify.
//  source: tracking_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use trackingServerStatusDescriptor instead')
const TrackingServerStatus$json = const {
  '1': 'TrackingServerStatus',
  '2': const [
    const {'1': 'TRACKING_STATUS_NONE', '2': 0},
    const {'1': 'TRACKING_STATUS_READY', '2': 1},
    const {'1': 'TRACKING_STATUS_STARTED', '2': 2},
    const {'1': 'TRACKING_STATUS_STOPPED', '2': 3},
    const {'1': 'TRACKING_STATUS_DISPOSED', '2': 4},
  ],
};

/// Descriptor for `TrackingServerStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackingServerStatusDescriptor = $convert.base64Decode('ChRUcmFja2luZ1NlcnZlclN0YXR1cxIYChRUUkFDS0lOR19TVEFUVVNfTk9ORRAAEhkKFVRSQUNLSU5HX1NUQVRVU19SRUFEWRABEhsKF1RSQUNLSU5HX1NUQVRVU19TVEFSVEVEEAISGwoXVFJBQ0tJTkdfU1RBVFVTX1NUT1BQRUQQAxIcChhUUkFDS0lOR19TVEFUVVNfRElTUE9TRUQQBA==');
@$core.Deprecated('Use trackingExpandFieldsDescriptor instead')
const TrackingExpandFields$json = const {
  '1': 'TrackingExpandFields',
  '2': const [
    const {'1': 'TRACKING_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'TRACKING_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO', '2': 2},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_ITEMS', '2': 3},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_DATA', '2': 4},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_METRICS', '2': 5},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_QUEUE', '2': 6},
  ],
};

/// Descriptor for `TrackingExpandFields`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trackingExpandFieldsDescriptor = $convert.base64Decode('ChRUcmFja2luZ0V4cGFuZEZpZWxkcxIfChtUUkFDS0lOR19FWFBBTkRfRklFTERTX05PTkUQABIeChpUUkFDS0lOR19FWFBBTkRfRklFTERTX0FMTBABEh8KG1RSQUNLSU5HX0VYUEFORF9GSUVMRFNfUkVQTxACEiUKIVRSQUNLSU5HX0VYUEFORF9GSUVMRFNfUkVQT19JVEVNUxADEiQKIFRSQUNLSU5HX0VYUEFORF9GSUVMRFNfUkVQT19EQVRBEAQSJwojVFJBQ0tJTkdfRVhQQU5EX0ZJRUxEU19SRVBPX01FVFJJQ1MQBRIlCiFUUkFDS0lOR19FWFBBTkRfRklFTERTX1JFUE9fUVVFVUUQBg==');
@$core.Deprecated('Use addTrackingsRequestDescriptor instead')
const AddTrackingsRequest$json = const {
  '1': 'AddTrackingsRequest',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'expand', '3': 2, '4': 3, '5': 14, '6': '.app.sarsys.tracking.TrackingExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `AddTrackingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addTrackingsRequestDescriptor = $convert.base64Decode('ChNBZGRUcmFja2luZ3NSZXF1ZXN0EhQKBXV1aWRzGAEgAygJUgV1dWlkcxJBCgZleHBhbmQYAiADKA4yKS5hcHAuc2Fyc3lzLnRyYWNraW5nLlRyYWNraW5nRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use addTrackingsResponseDescriptor instead')
const AddTrackingsResponse$json = const {
  '1': 'AddTrackingsResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'failed', '3': 2, '4': 3, '5': 9, '10': 'failed'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.app.sarsys.tracking.GetTrackingMetaResponse', '10': 'meta'},
  ],
};

/// Descriptor for `AddTrackingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addTrackingsResponseDescriptor = $convert.base64Decode('ChRBZGRUcmFja2luZ3NSZXNwb25zZRIUCgV1dWlkcxgBIAMoCVIFdXVpZHMSFgoGZmFpbGVkGAIgAygJUgZmYWlsZWQSHgoKc3RhdHVzQ29kZRgDIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYBCABKAlSDHJlYXNvblBocmFzZRJACgRtZXRhGAUgASgLMiwuYXBwLnNhcnN5cy50cmFja2luZy5HZXRUcmFja2luZ01ldGFSZXNwb25zZVIEbWV0YQ==');
@$core.Deprecated('Use startTrackingRequestDescriptor instead')
const StartTrackingRequest$json = const {
  '1': 'StartTrackingRequest',
  '2': const [
    const {'1': 'expand', '3': 2, '4': 3, '5': 14, '6': '.app.sarsys.tracking.TrackingExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `StartTrackingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startTrackingRequestDescriptor = $convert.base64Decode('ChRTdGFydFRyYWNraW5nUmVxdWVzdBJBCgZleHBhbmQYAiADKA4yKS5hcHAuc2Fyc3lzLnRyYWNraW5nLlRyYWNraW5nRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use startTrackingResponseDescriptor instead')
const StartTrackingResponse$json = const {
  '1': 'StartTrackingResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.app.sarsys.tracking.GetTrackingMetaResponse', '10': 'meta'},
  ],
};

/// Descriptor for `StartTrackingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startTrackingResponseDescriptor = $convert.base64Decode('ChVTdGFydFRyYWNraW5nUmVzcG9uc2USFAoFdXVpZHMYASADKAlSBXV1aWRzEh4KCnN0YXR1c0NvZGUYAyABKAVSCnN0YXR1c0NvZGUSIgoMcmVhc29uUGhyYXNlGAQgASgJUgxyZWFzb25QaHJhc2USQAoEbWV0YRgFIAEoCzIsLmFwcC5zYXJzeXMudHJhY2tpbmcuR2V0VHJhY2tpbmdNZXRhUmVzcG9uc2VSBG1ldGE=');
@$core.Deprecated('Use stopTrackingRequestDescriptor instead')
const StopTrackingRequest$json = const {
  '1': 'StopTrackingRequest',
  '2': const [
    const {'1': 'expand', '3': 2, '4': 3, '5': 14, '6': '.app.sarsys.tracking.TrackingExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `StopTrackingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopTrackingRequestDescriptor = $convert.base64Decode('ChNTdG9wVHJhY2tpbmdSZXF1ZXN0EkEKBmV4cGFuZBgCIAMoDjIpLmFwcC5zYXJzeXMudHJhY2tpbmcuVHJhY2tpbmdFeHBhbmRGaWVsZHNSBmV4cGFuZA==');
@$core.Deprecated('Use stopTrackingResponseDescriptor instead')
const StopTrackingResponse$json = const {
  '1': 'StopTrackingResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.app.sarsys.tracking.GetTrackingMetaResponse', '10': 'meta'},
  ],
};

/// Descriptor for `StopTrackingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopTrackingResponseDescriptor = $convert.base64Decode('ChRTdG9wVHJhY2tpbmdSZXNwb25zZRIUCgV1dWlkcxgBIAMoCVIFdXVpZHMSHgoKc3RhdHVzQ29kZRgDIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYBCABKAlSDHJlYXNvblBocmFzZRJACgRtZXRhGAUgASgLMiwuYXBwLnNhcnN5cy50cmFja2luZy5HZXRUcmFja2luZ01ldGFSZXNwb25zZVIEbWV0YQ==');
@$core.Deprecated('Use removeTrackingsRequestDescriptor instead')
const RemoveTrackingsRequest$json = const {
  '1': 'RemoveTrackingsRequest',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'expand', '3': 2, '4': 3, '5': 14, '6': '.app.sarsys.tracking.TrackingExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `RemoveTrackingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeTrackingsRequestDescriptor = $convert.base64Decode('ChZSZW1vdmVUcmFja2luZ3NSZXF1ZXN0EhQKBXV1aWRzGAEgAygJUgV1dWlkcxJBCgZleHBhbmQYAiADKA4yKS5hcHAuc2Fyc3lzLnRyYWNraW5nLlRyYWNraW5nRXhwYW5kRmllbGRzUgZleHBhbmQ=');
@$core.Deprecated('Use removeTrackingsResponseDescriptor instead')
const RemoveTrackingsResponse$json = const {
  '1': 'RemoveTrackingsResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'failed', '3': 2, '4': 3, '5': 9, '10': 'failed'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {'1': 'meta', '3': 5, '4': 1, '5': 11, '6': '.app.sarsys.tracking.GetTrackingMetaResponse', '10': 'meta'},
  ],
};

/// Descriptor for `RemoveTrackingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeTrackingsResponseDescriptor = $convert.base64Decode('ChdSZW1vdmVUcmFja2luZ3NSZXNwb25zZRIUCgV1dWlkcxgBIAMoCVIFdXVpZHMSFgoGZmFpbGVkGAIgAygJUgZmYWlsZWQSHgoKc3RhdHVzQ29kZRgDIAEoBVIKc3RhdHVzQ29kZRIiCgxyZWFzb25QaHJhc2UYBCABKAlSDHJlYXNvblBocmFzZRJACgRtZXRhGAUgASgLMiwuYXBwLnNhcnN5cy50cmFja2luZy5HZXRUcmFja2luZ01ldGFSZXNwb25zZVIEbWV0YQ==');
@$core.Deprecated('Use getTrackingMetaRequestDescriptor instead')
const GetTrackingMetaRequest$json = const {
  '1': 'GetTrackingMetaRequest',
  '2': const [
    const {'1': 'expand', '3': 1, '4': 3, '5': 14, '6': '.app.sarsys.tracking.TrackingExpandFields', '10': 'expand'},
  ],
};

/// Descriptor for `GetTrackingMetaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTrackingMetaRequestDescriptor = $convert.base64Decode('ChZHZXRUcmFja2luZ01ldGFSZXF1ZXN0EkEKBmV4cGFuZBgBIAMoDjIpLmFwcC5zYXJzeXMudHJhY2tpbmcuVHJhY2tpbmdFeHBhbmRGaWVsZHNSBmV4cGFuZA==');
@$core.Deprecated('Use getTrackingMetaResponseDescriptor instead')
const GetTrackingMetaResponse$json = const {
  '1': 'GetTrackingMetaResponse',
  '2': const [
    const {'1': 'status', '3': 1, '4': 1, '5': 14, '6': '.app.sarsys.tracking.TrackingServerStatus', '10': 'status'},
    const {'1': 'trackings', '3': 2, '4': 1, '5': 11, '6': '.app.sarsys.tracking.TrackingsMeta', '10': 'trackings'},
    const {'1': 'positions', '3': 3, '4': 1, '5': 11, '6': '.app.sarsys.tracking.PositionsMeta', '10': 'positions'},
    const {'1': 'managerOf', '3': 4, '4': 3, '5': 11, '6': '.app.sarsys.tracking.TrackingMeta', '10': 'managerOf'},
    const {'1': 'repo', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.RepositoryMeta', '10': 'repo'},
  ],
};

/// Descriptor for `GetTrackingMetaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTrackingMetaResponseDescriptor = $convert.base64Decode('ChdHZXRUcmFja2luZ01ldGFSZXNwb25zZRJBCgZzdGF0dXMYASABKA4yKS5hcHAuc2Fyc3lzLnRyYWNraW5nLlRyYWNraW5nU2VydmVyU3RhdHVzUgZzdGF0dXMSQAoJdHJhY2tpbmdzGAIgASgLMiIuYXBwLnNhcnN5cy50cmFja2luZy5UcmFja2luZ3NNZXRhUgl0cmFja2luZ3MSQAoJcG9zaXRpb25zGAMgASgLMiIuYXBwLnNhcnN5cy50cmFja2luZy5Qb3NpdGlvbnNNZXRhUglwb3NpdGlvbnMSPwoJbWFuYWdlck9mGAQgAygLMiEuYXBwLnNhcnN5cy50cmFja2luZy5UcmFja2luZ01ldGFSCW1hbmFnZXJPZhIyCgRyZXBvGAUgASgLMh4ub3JnLmRpc2Nvb3MuZXMuUmVwb3NpdG9yeU1ldGFSBHJlcG8=');
@$core.Deprecated('Use trackingMetaDescriptor instead')
const TrackingMeta$json = const {
  '1': 'TrackingMeta',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'trackCount', '3': 2, '4': 1, '5': 3, '10': 'trackCount'},
    const {'1': 'positionCount', '3': 3, '4': 1, '5': 3, '10': 'positionCount'},
    const {'1': 'lastEvent', '3': 4, '4': 1, '5': 11, '6': '.org.discoos.es.EventMeta', '10': 'lastEvent'},
  ],
};

/// Descriptor for `TrackingMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackingMetaDescriptor = $convert.base64Decode('CgxUcmFja2luZ01ldGESEgoEdXVpZBgBIAEoCVIEdXVpZBIeCgp0cmFja0NvdW50GAIgASgDUgp0cmFja0NvdW50EiQKDXBvc2l0aW9uQ291bnQYAyABKANSDXBvc2l0aW9uQ291bnQSNwoJbGFzdEV2ZW50GAQgASgLMhkub3JnLmRpc2Nvb3MuZXMuRXZlbnRNZXRhUglsYXN0RXZlbnQ=');
@$core.Deprecated('Use trackingsMetaDescriptor instead')
const TrackingsMeta$json = const {
  '1': 'TrackingsMeta',
  '2': const [
    const {'1': 'total', '3': 1, '4': 1, '5': 3, '10': 'total'},
    const {'1': 'fractionManaged', '3': 2, '4': 1, '5': 1, '10': 'fractionManaged'},
    const {'1': 'eventsPerMinute', '3': 3, '4': 1, '5': 1, '10': 'eventsPerMinute'},
    const {'1': 'averageProcessingTimeMillis', '3': 4, '4': 1, '5': 5, '10': 'averageProcessingTimeMillis'},
    const {'1': 'lastEvent', '3': 5, '4': 1, '5': 11, '6': '.org.discoos.es.EventMeta', '10': 'lastEvent'},
  ],
};

/// Descriptor for `TrackingsMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackingsMetaDescriptor = $convert.base64Decode('Cg1UcmFja2luZ3NNZXRhEhQKBXRvdGFsGAEgASgDUgV0b3RhbBIoCg9mcmFjdGlvbk1hbmFnZWQYAiABKAFSD2ZyYWN0aW9uTWFuYWdlZBIoCg9ldmVudHNQZXJNaW51dGUYAyABKAFSD2V2ZW50c1Blck1pbnV0ZRJAChthdmVyYWdlUHJvY2Vzc2luZ1RpbWVNaWxsaXMYBCABKAVSG2F2ZXJhZ2VQcm9jZXNzaW5nVGltZU1pbGxpcxI3CglsYXN0RXZlbnQYBSABKAsyGS5vcmcuZGlzY29vcy5lcy5FdmVudE1ldGFSCWxhc3RFdmVudA==');
@$core.Deprecated('Use positionsMetaDescriptor instead')
const PositionsMeta$json = const {
  '1': 'PositionsMeta',
  '2': const [
    const {'1': 'total', '3': 1, '4': 1, '5': 3, '10': 'total'},
    const {'1': 'eventsPerMinute', '3': 2, '4': 1, '5': 1, '10': 'eventsPerMinute'},
    const {'1': 'averageProcessingTimeMillis', '3': 3, '4': 1, '5': 5, '10': 'averageProcessingTimeMillis'},
    const {'1': 'lastEvent', '3': 4, '4': 1, '5': 11, '6': '.org.discoos.es.EventMeta', '10': 'lastEvent'},
  ],
};

/// Descriptor for `PositionsMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List positionsMetaDescriptor = $convert.base64Decode('Cg1Qb3NpdGlvbnNNZXRhEhQKBXRvdGFsGAEgASgDUgV0b3RhbBIoCg9ldmVudHNQZXJNaW51dGUYAiABKAFSD2V2ZW50c1Blck1pbnV0ZRJAChthdmVyYWdlUHJvY2Vzc2luZ1RpbWVNaWxsaXMYAyABKAVSG2F2ZXJhZ2VQcm9jZXNzaW5nVGltZU1pbGxpcxI3CglsYXN0RXZlbnQYBCABKAsyGS5vcmcuZGlzY29vcy5lcy5FdmVudE1ldGFSCWxhc3RFdmVudA==');
