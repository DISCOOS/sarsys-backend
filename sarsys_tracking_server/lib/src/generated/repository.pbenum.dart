///
//  Generated code. Do not modify.
//  source: repository.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class RepoExpandFields extends $pb.ProtobufEnum {
  static const RepoExpandFields REPO_EXPAND_FIELDS_NONE = RepoExpandFields._(
      0,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'REPO_EXPAND_FIELDS_NONE');
  static const RepoExpandFields REPO_EXPAND_FIELDS_ALL = RepoExpandFields._(
      1,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'REPO_EXPAND_FIELDS_ALL');
  static const RepoExpandFields REPO_EXPAND_FIELDS_ITEMS = RepoExpandFields._(
      2,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'REPO_EXPAND_FIELDS_ITEMS');
  static const RepoExpandFields REPO_EXPAND_FIELDS_DATA = RepoExpandFields._(
      3,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'REPO_EXPAND_FIELDS_DATA');
  static const RepoExpandFields REPO_EXPAND_FIELDS_METRICS = RepoExpandFields._(
      4,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'REPO_EXPAND_FIELDS_METRICS');
  static const RepoExpandFields REPO_EXPAND_FIELDS_QUEUE = RepoExpandFields._(
      5,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'REPO_EXPAND_FIELDS_QUEUE');
  static const RepoExpandFields REPO_EXPAND_FIELDS_CONN = RepoExpandFields._(
      6,
      const $core.bool.fromEnvironment('protobuf.omit_enum_names')
          ? ''
          : 'REPO_EXPAND_FIELDS_CONN');
  static const RepoExpandFields REPO_EXPAND_FIELDS_SNAPSHOT =
      RepoExpandFields._(
          7,
          const $core.bool.fromEnvironment('protobuf.omit_enum_names')
              ? ''
              : 'REPO_EXPAND_FIELDS_SNAPSHOT');

  static const $core.List<RepoExpandFields> values = <RepoExpandFields>[
    REPO_EXPAND_FIELDS_NONE,
    REPO_EXPAND_FIELDS_ALL,
    REPO_EXPAND_FIELDS_ITEMS,
    REPO_EXPAND_FIELDS_DATA,
    REPO_EXPAND_FIELDS_METRICS,
    REPO_EXPAND_FIELDS_QUEUE,
    REPO_EXPAND_FIELDS_CONN,
    REPO_EXPAND_FIELDS_SNAPSHOT,
  ];

  static final $core.Map<$core.int, RepoExpandFields> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static RepoExpandFields? valueOf($core.int value) => _byValue[value];

  const RepoExpandFields._($core.int v, $core.String n) : super(v, n);
}
