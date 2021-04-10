///
//  Generated code. Do not modify.
//  source: event.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'timestamp.pb.dart' as $4;

class EventMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EventMeta',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuid')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'remote')
    ..aInt64(4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'number')
    ..aInt64(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'position')
    ..aOM<$4.Timestamp>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp', subBuilder: $4.Timestamp.create)
    ..hasRequiredFields = false;

  EventMeta._() : super();
  factory EventMeta({
    $core.String? type,
    $core.String? uuid,
    $core.bool? remote,
    $fixnum.Int64? number,
    $fixnum.Int64? position,
    $4.Timestamp? timestamp,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (remote != null) {
      _result.remote = remote;
    }
    if (number != null) {
      _result.number = number;
    }
    if (position != null) {
      _result.position = position;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    return _result;
  }
  factory EventMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EventMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EventMeta clone() => EventMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EventMeta copyWith(void Function(EventMeta) updates) =>
      super.copyWith((message) => updates(message as EventMeta))
          as EventMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EventMeta create() => EventMeta._();
  EventMeta createEmptyInstance() => create();
  static $pb.PbList<EventMeta> createRepeated() => $pb.PbList<EventMeta>();
  @$core.pragma('dart2js:noInline')
  static EventMeta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EventMeta>(create);
  static EventMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get uuid => $_getSZ(1);
  @$pb.TagNumber(2)
  set uuid($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUuid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUuid() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get remote => $_getBF(2);
  @$pb.TagNumber(3)
  set remote($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasRemote() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemote() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get number => $_getI64(3);
  @$pb.TagNumber(4)
  set number($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasNumber() => $_has(3);
  @$pb.TagNumber(4)
  void clearNumber() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get position => $_getI64(4);
  @$pb.TagNumber(5)
  set position($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPosition() => $_has(4);
  @$pb.TagNumber(5)
  void clearPosition() => clearField(5);

  @$pb.TagNumber(6)
  $4.Timestamp get timestamp => $_getN(5);
  @$pb.TagNumber(6)
  set timestamp($4.Timestamp v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasTimestamp() => $_has(5);
  @$pb.TagNumber(6)
  void clearTimestamp() => clearField(6);
  @$pb.TagNumber(6)
  $4.Timestamp ensureTimestamp() => $_ensure(5);
}

class EventMetaList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EventMetaList',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'count',
        $pb.PbFieldType.O3)
    ..pc<EventMeta>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'items',
        $pb.PbFieldType.PM,
        subBuilder: EventMeta.create)
    ..hasRequiredFields = false;

  EventMetaList._() : super();
  factory EventMetaList({
    $core.int? count,
    $core.Iterable<EventMeta>? items,
  }) {
    final _result = create();
    if (count != null) {
      _result.count = count;
    }
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory EventMetaList.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EventMetaList.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EventMetaList clone() => EventMetaList()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EventMetaList copyWith(void Function(EventMetaList) updates) =>
      super.copyWith((message) => updates(message as EventMetaList))
          as EventMetaList; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EventMetaList create() => EventMetaList._();
  EventMetaList createEmptyInstance() => create();
  static $pb.PbList<EventMetaList> createRepeated() =>
      $pb.PbList<EventMetaList>();
  @$core.pragma('dart2js:noInline')
  static EventMetaList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventMetaList>(create);
  static EventMetaList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get count => $_getIZ(0);
  @$pb.TagNumber(1)
  set count($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearCount() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<EventMeta> get items => $_getList(1);
}
