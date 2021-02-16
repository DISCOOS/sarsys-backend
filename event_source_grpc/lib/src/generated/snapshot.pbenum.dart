///
//  Generated code. Do not modify.
//  source: snapshot.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SnapshotExpandFields extends $pb.ProtobufEnum {
  static const SnapshotExpandFields SNAPSHOT_EXPAND_FIELDS_NONE =
      SnapshotExpandFields._(
          0,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'SNAPSHOT_EXPAND_FIELDS_NONE');
  static const SnapshotExpandFields SNAPSHOT_EXPAND_FIELDS_ALL =
      SnapshotExpandFields._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'SNAPSHOT_EXPAND_FIELDS_ALL');
  static const SnapshotExpandFields SNAPSHOT_EXPAND_FIELDS_ITEMS =
      SnapshotExpandFields._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'SNAPSHOT_EXPAND_FIELDS_ITEMS');
  static const SnapshotExpandFields SNAPSHOT_EXPAND_FIELDS_DATA =
      SnapshotExpandFields._(
          3,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'SNAPSHOT_EXPAND_FIELDS_DATA');
  static const SnapshotExpandFields SNAPSHOT_EXPAND_FIELDS_METRICS =
      SnapshotExpandFields._(
          4,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'SNAPSHOT_EXPAND_FIELDS_METRICS');
  static const SnapshotExpandFields SNAPSHOT_EXPAND_FIELDS_QUEUE =
      SnapshotExpandFields._(
          5,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'SNAPSHOT_EXPAND_FIELDS_QUEUE');
  static const SnapshotExpandFields SNAPSHOT_EXPAND_FIELDS_CONN =
      SnapshotExpandFields._(
          6,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'SNAPSHOT_EXPAND_FIELDS_CONN');

  static const $core.List<SnapshotExpandFields> values = <SnapshotExpandFields>[
    SNAPSHOT_EXPAND_FIELDS_NONE,
    SNAPSHOT_EXPAND_FIELDS_ALL,
    SNAPSHOT_EXPAND_FIELDS_ITEMS,
    SNAPSHOT_EXPAND_FIELDS_DATA,
    SNAPSHOT_EXPAND_FIELDS_METRICS,
    SNAPSHOT_EXPAND_FIELDS_QUEUE,
    SNAPSHOT_EXPAND_FIELDS_CONN,
  ];

  static final $core.Map<$core.int, SnapshotExpandFields> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static SnapshotExpandFields valueOf($core.int value) => _byValue[value];

  const SnapshotExpandFields._($core.int v, $core.String n) : super(v, n);
}
