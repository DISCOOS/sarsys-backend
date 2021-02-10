///
//  Generated code. Do not modify.
//  source: sarsys_tracking_service.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class TrackingServerStatus extends $pb.ProtobufEnum {
  static const TrackingServerStatus STATUS_NONE = TrackingServerStatus._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STATUS_NONE');
  static const TrackingServerStatus STATUS_READY = TrackingServerStatus._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STATUS_READY');
  static const TrackingServerStatus STATUS_STARTED = TrackingServerStatus._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STATUS_STARTED');
  static const TrackingServerStatus STATUS_STOPPED = TrackingServerStatus._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STATUS_STOPPED');
  static const TrackingServerStatus STATUS_DISPOSED = TrackingServerStatus._(
      4,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'STATUS_DISPOSED');

  static const $core.List<TrackingServerStatus> values = <TrackingServerStatus>[
    STATUS_NONE,
    STATUS_READY,
    STATUS_STARTED,
    STATUS_STOPPED,
    STATUS_DISPOSED,
  ];

  static final $core.Map<$core.int, TrackingServerStatus> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TrackingServerStatus valueOf($core.int value) => _byValue[value];

  const TrackingServerStatus._($core.int v, $core.String n) : super(v, n);
}

class ExpandFields extends $pb.ProtobufEnum {
  static const ExpandFields EXPAND_FIELDS_NONE = ExpandFields._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'EXPAND_FIELDS_NONE');
  static const ExpandFields EXPAND_FIELDS_ALL = ExpandFields._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'EXPAND_FIELDS_ALL');
  static const ExpandFields EXPAND_FIELDS_REPO = ExpandFields._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'EXPAND_FIELDS_REPO');

  static const $core.List<ExpandFields> values = <ExpandFields>[
    EXPAND_FIELDS_NONE,
    EXPAND_FIELDS_ALL,
    EXPAND_FIELDS_REPO,
  ];

  static final $core.Map<$core.int, ExpandFields> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ExpandFields valueOf($core.int value) => _byValue[value];

  const ExpandFields._($core.int v, $core.String n) : super(v, n);
}
