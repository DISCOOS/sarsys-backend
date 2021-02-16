///
//  Generated code. Do not modify.
//  source: aggregate.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class AggregateExpandFields extends $pb.ProtobufEnum {
  static const AggregateExpandFields AGGREGATE_EXPAND_FIELDS_NONE =
      AggregateExpandFields._(
          0,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'AGGREGATE_EXPAND_FIELDS_NONE');
  static const AggregateExpandFields AGGREGATE_EXPAND_FIELDS_ALL =
      AggregateExpandFields._(
          1,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'AGGREGATE_EXPAND_FIELDS_ALL');
  static const AggregateExpandFields AGGREGATE_EXPAND_FIELDS_DATA =
      AggregateExpandFields._(
          2,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'AGGREGATE_EXPAND_FIELDS_DATA');
  static const AggregateExpandFields AGGREGATE_EXPAND_FIELDS_ITEMS =
      AggregateExpandFields._(
          3,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'AGGREGATE_EXPAND_FIELDS_ITEMS');

  static const $core.List<AggregateExpandFields> values =
      <AggregateExpandFields>[
    AGGREGATE_EXPAND_FIELDS_NONE,
    AGGREGATE_EXPAND_FIELDS_ALL,
    AGGREGATE_EXPAND_FIELDS_DATA,
    AGGREGATE_EXPAND_FIELDS_ITEMS,
  ];

  static final $core.Map<$core.int, AggregateExpandFields> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static AggregateExpandFields valueOf($core.int value) => _byValue[value];

  const AggregateExpandFields._($core.int v, $core.String n) : super(v, n);
}
