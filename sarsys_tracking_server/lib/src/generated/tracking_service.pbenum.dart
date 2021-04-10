///
//  Generated code. Do not modify.
//  source: tracking_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class TrackingServerStatus extends $pb.ProtobufEnum {
  static const TrackingServerStatus TRACKING_STATUS_NONE =
      TrackingServerStatus._(
          0,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_STATUS_NONE');
  static const TrackingServerStatus TRACKING_STATUS_READY =
      TrackingServerStatus._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_STATUS_READY');
  static const TrackingServerStatus TRACKING_STATUS_STARTED =
      TrackingServerStatus._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_STATUS_STARTED');
  static const TrackingServerStatus TRACKING_STATUS_STOPPED =
      TrackingServerStatus._(
          3,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_STATUS_STOPPED');
  static const TrackingServerStatus TRACKING_STATUS_DISPOSED =
      TrackingServerStatus._(
          4,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_STATUS_DISPOSED');

  static const $core.List<TrackingServerStatus> values = <TrackingServerStatus>[
    TRACKING_STATUS_NONE,
    TRACKING_STATUS_READY,
    TRACKING_STATUS_STARTED,
    TRACKING_STATUS_STOPPED,
    TRACKING_STATUS_DISPOSED,
  ];

  static final $core.Map<$core.int, TrackingServerStatus> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TrackingServerStatus? valueOf($core.int value) => _byValue[value];

  const TrackingServerStatus._($core.int v, $core.String n) : super(v, n);
}

class TrackingExpandFields extends $pb.ProtobufEnum {
  static const TrackingExpandFields TRACKING_EXPAND_FIELDS_NONE =
      TrackingExpandFields._(
          0,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_EXPAND_FIELDS_NONE');
  static const TrackingExpandFields TRACKING_EXPAND_FIELDS_ALL =
      TrackingExpandFields._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_EXPAND_FIELDS_ALL');
  static const TrackingExpandFields TRACKING_EXPAND_FIELDS_REPO =
      TrackingExpandFields._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_EXPAND_FIELDS_REPO');
  static const TrackingExpandFields TRACKING_EXPAND_FIELDS_REPO_ITEMS =
      TrackingExpandFields._(
          3,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_EXPAND_FIELDS_REPO_ITEMS');
  static const TrackingExpandFields TRACKING_EXPAND_FIELDS_REPO_DATA =
      TrackingExpandFields._(
          4,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_EXPAND_FIELDS_REPO_DATA');
  static const TrackingExpandFields TRACKING_EXPAND_FIELDS_REPO_METRICS =
      TrackingExpandFields._(
          5,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_EXPAND_FIELDS_REPO_METRICS');
  static const TrackingExpandFields TRACKING_EXPAND_FIELDS_REPO_QUEUE =
      TrackingExpandFields._(
          6,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'TRACKING_EXPAND_FIELDS_REPO_QUEUE');

  static const $core.List<TrackingExpandFields> values = <TrackingExpandFields>[
    TRACKING_EXPAND_FIELDS_NONE,
    TRACKING_EXPAND_FIELDS_ALL,
    TRACKING_EXPAND_FIELDS_REPO,
    TRACKING_EXPAND_FIELDS_REPO_ITEMS,
    TRACKING_EXPAND_FIELDS_REPO_DATA,
    TRACKING_EXPAND_FIELDS_REPO_METRICS,
    TRACKING_EXPAND_FIELDS_REPO_QUEUE,
  ];

  static final $core.Map<$core.int, TrackingExpandFields> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TrackingExpandFields? valueOf($core.int value) => _byValue[value];

  const TrackingExpandFields._($core.int v, $core.String n) : super(v, n);
}
