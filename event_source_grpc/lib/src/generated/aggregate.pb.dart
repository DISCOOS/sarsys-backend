///
//  Generated code. Do not modify.
//  source: aggregate.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'any.pb.dart' as $5;
import 'event.pb.dart' as $6;

import 'aggregate.pbenum.dart';

export 'aggregate.pbenum.dart';

class GetAggregateMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetAggregateMetaRequest',
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
    ..pc<AggregateExpandFields>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: AggregateExpandFields.valueOf,
        enumValues: AggregateExpandFields.values)
    ..hasRequiredFields = false;

  GetAggregateMetaRequest._() : super();
  factory GetAggregateMetaRequest({
    $core.String? type,
    $core.String? uuid,
    $core.Iterable<AggregateExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory GetAggregateMetaRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetAggregateMetaRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetAggregateMetaRequest clone() =>
      GetAggregateMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetAggregateMetaRequest copyWith(
          void Function(GetAggregateMetaRequest) updates) =>
      super.copyWith((message) => updates(message as GetAggregateMetaRequest))
          as GetAggregateMetaRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaRequest create() => GetAggregateMetaRequest._();
  GetAggregateMetaRequest createEmptyInstance() => create();
  static $pb.PbList<GetAggregateMetaRequest> createRepeated() =>
      $pb.PbList<GetAggregateMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAggregateMetaRequest>(create);
  static GetAggregateMetaRequest? _defaultInstance;

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

  @$pb.TagNumber(4)
  $core.List<AggregateExpandFields> get expand => $_getList(2);
}

class GetAggregateMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'GetAggregateMetaResponse',
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
    ..a<$core.int>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<AggregateMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  GetAggregateMetaResponse._() : super();
  factory GetAggregateMetaResponse({
    $core.String? type,
    $core.String? uuid,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    AggregateMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory GetAggregateMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetAggregateMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetAggregateMetaResponse clone() =>
      GetAggregateMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetAggregateMetaResponse copyWith(
          void Function(GetAggregateMetaResponse) updates) =>
      super.copyWith((message) => updates(message as GetAggregateMetaResponse))
          as GetAggregateMetaResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaResponse create() => GetAggregateMetaResponse._();
  GetAggregateMetaResponse createEmptyInstance() => create();
  static $pb.PbList<GetAggregateMetaResponse> createRepeated() =>
      $pb.PbList<GetAggregateMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static GetAggregateMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAggregateMetaResponse>(create);
  static GetAggregateMetaResponse? _defaultInstance;

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
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  AggregateMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(AggregateMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  AggregateMeta ensureMeta() => $_ensure(4);
}

class SearchAggregateMetaRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SearchAggregateMetaRequest',
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
            : 'query')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'limit',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'offset', $pb.PbFieldType.O3)
    ..pc<AggregateExpandFields>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE, valueOf: AggregateExpandFields.valueOf, enumValues: AggregateExpandFields.values)
    ..hasRequiredFields = false;

  SearchAggregateMetaRequest._() : super();
  factory SearchAggregateMetaRequest({
    $core.String? type,
    $core.String? query,
    $core.int? limit,
    $core.int? offset,
    $core.Iterable<AggregateExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (query != null) {
      _result.query = query;
    }
    if (limit != null) {
      _result.limit = limit;
    }
    if (offset != null) {
      _result.offset = offset;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory SearchAggregateMetaRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SearchAggregateMetaRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SearchAggregateMetaRequest clone() =>
      SearchAggregateMetaRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SearchAggregateMetaRequest copyWith(
          void Function(SearchAggregateMetaRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SearchAggregateMetaRequest))
          as SearchAggregateMetaRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SearchAggregateMetaRequest create() => SearchAggregateMetaRequest._();
  SearchAggregateMetaRequest createEmptyInstance() => create();
  static $pb.PbList<SearchAggregateMetaRequest> createRepeated() =>
      $pb.PbList<SearchAggregateMetaRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchAggregateMetaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchAggregateMetaRequest>(create);
  static SearchAggregateMetaRequest? _defaultInstance;

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
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<AggregateExpandFields> get expand => $_getList(4);
}

class SearchAggregateMetaResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SearchAggregateMetaResponse',
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
            : 'query')
    ..a<$core.int>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'limit',
        $pb.PbFieldType.O3)
    ..a<$core.int>(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'offset', $pb.PbFieldType.O3)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'total', $pb.PbFieldType.O3)
    ..a<$core.int>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'nextOffset', $pb.PbFieldType.O3, protoName: 'nextOffset')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3, protoName: 'statusCode')
    ..aOS(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase', protoName: 'reasonPhrase')
    ..aOM<AggregateMetaMatchList>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'matches', subBuilder: AggregateMetaMatchList.create)
    ..hasRequiredFields = false;

  SearchAggregateMetaResponse._() : super();
  factory SearchAggregateMetaResponse({
    $core.String? type,
    $core.String? query,
    $core.int? limit,
    $core.int? offset,
    $core.int? total,
    $core.int? nextOffset,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    AggregateMetaMatchList? matches,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (query != null) {
      _result.query = query;
    }
    if (limit != null) {
      _result.limit = limit;
    }
    if (offset != null) {
      _result.offset = offset;
    }
    if (total != null) {
      _result.total = total;
    }
    if (nextOffset != null) {
      _result.nextOffset = nextOffset;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (matches != null) {
      _result.matches = matches;
    }
    return _result;
  }
  factory SearchAggregateMetaResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SearchAggregateMetaResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SearchAggregateMetaResponse clone() =>
      SearchAggregateMetaResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SearchAggregateMetaResponse copyWith(
          void Function(SearchAggregateMetaResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SearchAggregateMetaResponse))
          as SearchAggregateMetaResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SearchAggregateMetaResponse create() =>
      SearchAggregateMetaResponse._();
  SearchAggregateMetaResponse createEmptyInstance() => create();
  static $pb.PbList<SearchAggregateMetaResponse> createRepeated() =>
      $pb.PbList<SearchAggregateMetaResponse>();
  @$core.pragma('dart2js:noInline')
  static SearchAggregateMetaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchAggregateMetaResponse>(create);
  static SearchAggregateMetaResponse? _defaultInstance;

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
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get total => $_getIZ(4);
  @$pb.TagNumber(5)
  set total($core.int v) {
    $_setSignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTotal() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotal() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get nextOffset => $_getIZ(5);
  @$pb.TagNumber(6)
  set nextOffset($core.int v) {
    $_setSignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasNextOffset() => $_has(5);
  @$pb.TagNumber(6)
  void clearNextOffset() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get statusCode => $_getIZ(6);
  @$pb.TagNumber(7)
  set statusCode($core.int v) {
    $_setSignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasStatusCode() => $_has(6);
  @$pb.TagNumber(7)
  void clearStatusCode() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get reasonPhrase => $_getSZ(7);
  @$pb.TagNumber(8)
  set reasonPhrase($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasReasonPhrase() => $_has(7);
  @$pb.TagNumber(8)
  void clearReasonPhrase() => clearField(8);

  @$pb.TagNumber(9)
  AggregateMetaMatchList get matches => $_getN(8);
  @$pb.TagNumber(9)
  set matches(AggregateMetaMatchList v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasMatches() => $_has(8);
  @$pb.TagNumber(9)
  void clearMatches() => clearField(9);
  @$pb.TagNumber(9)
  AggregateMetaMatchList ensureMatches() => $_ensure(8);
}

class AggregateMetaMatchList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AggregateMetaMatchList',
      package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'org.discoos.es'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'count',
        $pb.PbFieldType.O3)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'query')
    ..pc<AggregateMetaMatch>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'items',
        $pb.PbFieldType.PM,
        subBuilder: AggregateMetaMatch.create)
    ..hasRequiredFields = false;

  AggregateMetaMatchList._() : super();
  factory AggregateMetaMatchList({
    $core.int? count,
    $core.String? query,
    $core.Iterable<AggregateMetaMatch>? items,
  }) {
    final _result = create();
    if (count != null) {
      _result.count = count;
    }
    if (query != null) {
      _result.query = query;
    }
    if (items != null) {
      _result.items.addAll(items);
    }
    return _result;
  }
  factory AggregateMetaMatchList.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AggregateMetaMatchList.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AggregateMetaMatchList clone() =>
      AggregateMetaMatchList()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AggregateMetaMatchList copyWith(
          void Function(AggregateMetaMatchList) updates) =>
      super.copyWith((message) => updates(message as AggregateMetaMatchList))
          as AggregateMetaMatchList; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AggregateMetaMatchList create() => AggregateMetaMatchList._();
  AggregateMetaMatchList createEmptyInstance() => create();
  static $pb.PbList<AggregateMetaMatchList> createRepeated() =>
      $pb.PbList<AggregateMetaMatchList>();
  @$core.pragma('dart2js:noInline')
  static AggregateMetaMatchList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AggregateMetaMatchList>(create);
  static AggregateMetaMatchList? _defaultInstance;

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
  $core.String get query => $_getSZ(1);
  @$pb.TagNumber(2)
  set query($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<AggregateMetaMatch> get items => $_getList(2);
}

class AggregateMetaMatch extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AggregateMetaMatch',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'org.discoos.es'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'uuid')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'path')
    ..aOM<AggregateMeta>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'meta',
        subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  AggregateMetaMatch._() : super();
  factory AggregateMetaMatch({
    $core.String? uuid,
    $core.String? path,
    AggregateMeta? meta,
  }) {
    final _result = create();
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (path != null) {
      _result.path = path;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory AggregateMetaMatch.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AggregateMetaMatch.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AggregateMetaMatch clone() => AggregateMetaMatch()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AggregateMetaMatch copyWith(void Function(AggregateMetaMatch) updates) =>
      super.copyWith((message) => updates(message as AggregateMetaMatch))
          as AggregateMetaMatch; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AggregateMetaMatch create() => AggregateMetaMatch._();
  AggregateMetaMatch createEmptyInstance() => create();
  static $pb.PbList<AggregateMetaMatch> createRepeated() =>
      $pb.PbList<AggregateMetaMatch>();
  @$core.pragma('dart2js:noInline')
  static AggregateMetaMatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AggregateMetaMatch>(create);
  static AggregateMetaMatch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get uuid => $_getSZ(0);
  @$pb.TagNumber(1)
  set uuid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);

  @$pb.TagNumber(3)
  AggregateMeta get meta => $_getN(2);
  @$pb.TagNumber(3)
  set meta(AggregateMeta v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMeta() => $_has(2);
  @$pb.TagNumber(3)
  void clearMeta() => clearField(3);
  @$pb.TagNumber(3)
  AggregateMeta ensureMeta() => $_ensure(2);
}

class ReplayAggregateEventsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ReplayAggregateEventsRequest',
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
    ..pc<AggregateExpandFields>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: AggregateExpandFields.valueOf,
        enumValues: AggregateExpandFields.values)
    ..hasRequiredFields = false;

  ReplayAggregateEventsRequest._() : super();
  factory ReplayAggregateEventsRequest({
    $core.String? type,
    $core.String? uuid,
    $core.Iterable<AggregateExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory ReplayAggregateEventsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ReplayAggregateEventsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ReplayAggregateEventsRequest clone() =>
      ReplayAggregateEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ReplayAggregateEventsRequest copyWith(
          void Function(ReplayAggregateEventsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ReplayAggregateEventsRequest))
          as ReplayAggregateEventsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplayAggregateEventsRequest create() =>
      ReplayAggregateEventsRequest._();
  ReplayAggregateEventsRequest createEmptyInstance() => create();
  static $pb.PbList<ReplayAggregateEventsRequest> createRepeated() =>
      $pb.PbList<ReplayAggregateEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static ReplayAggregateEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplayAggregateEventsRequest>(create);
  static ReplayAggregateEventsRequest? _defaultInstance;

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
  $core.List<AggregateExpandFields> get expand => $_getList(2);
}

class ReplayAggregateEventsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ReplayAggregateEventsResponse',
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
    ..a<$core.int>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<AggregateMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  ReplayAggregateEventsResponse._() : super();
  factory ReplayAggregateEventsResponse({
    $core.String? type,
    $core.String? uuid,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    AggregateMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory ReplayAggregateEventsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ReplayAggregateEventsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ReplayAggregateEventsResponse clone() =>
      ReplayAggregateEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ReplayAggregateEventsResponse copyWith(
          void Function(ReplayAggregateEventsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ReplayAggregateEventsResponse))
          as ReplayAggregateEventsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplayAggregateEventsResponse create() =>
      ReplayAggregateEventsResponse._();
  ReplayAggregateEventsResponse createEmptyInstance() => create();
  static $pb.PbList<ReplayAggregateEventsResponse> createRepeated() =>
      $pb.PbList<ReplayAggregateEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static ReplayAggregateEventsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplayAggregateEventsResponse>(create);
  static ReplayAggregateEventsResponse? _defaultInstance;

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
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  AggregateMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(AggregateMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  AggregateMeta ensureMeta() => $_ensure(4);
}

class CatchupAggregateEventsRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'CatchupAggregateEventsRequest',
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
    ..pc<AggregateExpandFields>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'expand',
        $pb.PbFieldType.PE,
        valueOf: AggregateExpandFields.valueOf,
        enumValues: AggregateExpandFields.values)
    ..hasRequiredFields = false;

  CatchupAggregateEventsRequest._() : super();
  factory CatchupAggregateEventsRequest({
    $core.String? type,
    $core.String? uuid,
    $core.Iterable<AggregateExpandFields>? expand,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    return _result;
  }
  factory CatchupAggregateEventsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CatchupAggregateEventsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CatchupAggregateEventsRequest clone() =>
      CatchupAggregateEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CatchupAggregateEventsRequest copyWith(
          void Function(CatchupAggregateEventsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as CatchupAggregateEventsRequest))
          as CatchupAggregateEventsRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CatchupAggregateEventsRequest create() =>
      CatchupAggregateEventsRequest._();
  CatchupAggregateEventsRequest createEmptyInstance() => create();
  static $pb.PbList<CatchupAggregateEventsRequest> createRepeated() =>
      $pb.PbList<CatchupAggregateEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static CatchupAggregateEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CatchupAggregateEventsRequest>(create);
  static CatchupAggregateEventsRequest? _defaultInstance;

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
  $core.List<AggregateExpandFields> get expand => $_getList(2);
}

class CatchupAggregateEventsResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'CatchupAggregateEventsResponse',
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
    ..a<$core.int>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<AggregateMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  CatchupAggregateEventsResponse._() : super();
  factory CatchupAggregateEventsResponse({
    $core.String? type,
    $core.String? uuid,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    AggregateMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory CatchupAggregateEventsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CatchupAggregateEventsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CatchupAggregateEventsResponse clone() =>
      CatchupAggregateEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CatchupAggregateEventsResponse copyWith(
          void Function(CatchupAggregateEventsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CatchupAggregateEventsResponse))
          as CatchupAggregateEventsResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CatchupAggregateEventsResponse create() =>
      CatchupAggregateEventsResponse._();
  CatchupAggregateEventsResponse createEmptyInstance() => create();
  static $pb.PbList<CatchupAggregateEventsResponse> createRepeated() =>
      $pb.PbList<CatchupAggregateEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static CatchupAggregateEventsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CatchupAggregateEventsResponse>(create);
  static CatchupAggregateEventsResponse? _defaultInstance;

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
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  AggregateMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(AggregateMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  AggregateMeta ensureMeta() => $_ensure(4);
}

class ReplaceAggregateDataRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ReplaceAggregateDataRequest',
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
    ..pc<AggregateExpandFields>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expand', $pb.PbFieldType.PE,
        valueOf: AggregateExpandFields.valueOf,
        enumValues: AggregateExpandFields.values)
    ..aOM<$5.Any>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data',
        subBuilder: $5.Any.create)
    ..pc<$5.Any>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'patches', $pb.PbFieldType.PM, subBuilder: $5.Any.create)
    ..hasRequiredFields = false;

  ReplaceAggregateDataRequest._() : super();
  factory ReplaceAggregateDataRequest({
    $core.String? type,
    $core.String? uuid,
    $core.Iterable<AggregateExpandFields>? expand,
    $5.Any? data,
    $core.Iterable<$5.Any>? patches,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (expand != null) {
      _result.expand.addAll(expand);
    }
    if (data != null) {
      _result.data = data;
    }
    if (patches != null) {
      _result.patches.addAll(patches);
    }
    return _result;
  }
  factory ReplaceAggregateDataRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ReplaceAggregateDataRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataRequest clone() =>
      ReplaceAggregateDataRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataRequest copyWith(
          void Function(ReplaceAggregateDataRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ReplaceAggregateDataRequest))
          as ReplaceAggregateDataRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataRequest create() =>
      ReplaceAggregateDataRequest._();
  ReplaceAggregateDataRequest createEmptyInstance() => create();
  static $pb.PbList<ReplaceAggregateDataRequest> createRepeated() =>
      $pb.PbList<ReplaceAggregateDataRequest>();
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplaceAggregateDataRequest>(create);
  static ReplaceAggregateDataRequest? _defaultInstance;

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
  $core.List<AggregateExpandFields> get expand => $_getList(2);

  @$pb.TagNumber(4)
  $5.Any get data => $_getN(3);
  @$pb.TagNumber(4)
  set data($5.Any v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasData() => $_has(3);
  @$pb.TagNumber(4)
  void clearData() => clearField(4);
  @$pb.TagNumber(4)
  $5.Any ensureData() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<$5.Any> get patches => $_getList(4);
}

class ReplaceAggregateDataResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ReplaceAggregateDataResponse',
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
    ..a<$core.int>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusCode', $pb.PbFieldType.O3,
        protoName: 'statusCode')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reasonPhrase',
        protoName: 'reasonPhrase')
    ..aOM<AggregateMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'meta', subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  ReplaceAggregateDataResponse._() : super();
  factory ReplaceAggregateDataResponse({
    $core.String? type,
    $core.String? uuid,
    $core.int? statusCode,
    $core.String? reasonPhrase,
    AggregateMeta? meta,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (statusCode != null) {
      _result.statusCode = statusCode;
    }
    if (reasonPhrase != null) {
      _result.reasonPhrase = reasonPhrase;
    }
    if (meta != null) {
      _result.meta = meta;
    }
    return _result;
  }
  factory ReplaceAggregateDataResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ReplaceAggregateDataResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataResponse clone() =>
      ReplaceAggregateDataResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ReplaceAggregateDataResponse copyWith(
          void Function(ReplaceAggregateDataResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ReplaceAggregateDataResponse))
          as ReplaceAggregateDataResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataResponse create() =>
      ReplaceAggregateDataResponse._();
  ReplaceAggregateDataResponse createEmptyInstance() => create();
  static $pb.PbList<ReplaceAggregateDataResponse> createRepeated() =>
      $pb.PbList<ReplaceAggregateDataResponse>();
  @$core.pragma('dart2js:noInline')
  static ReplaceAggregateDataResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplaceAggregateDataResponse>(create);
  static ReplaceAggregateDataResponse? _defaultInstance;

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
  $core.int get statusCode => $_getIZ(2);
  @$pb.TagNumber(3)
  set statusCode($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get reasonPhrase => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasonPhrase($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReasonPhrase() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasonPhrase() => clearField(4);

  @$pb.TagNumber(5)
  AggregateMeta get meta => $_getN(4);
  @$pb.TagNumber(5)
  set meta(AggregateMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMeta() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeta() => clearField(5);
  @$pb.TagNumber(5)
  AggregateMeta ensureMeta() => $_ensure(4);
}

class AggregateMetaList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AggregateMetaList',
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
    ..pc<AggregateMeta>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'items',
        $pb.PbFieldType.PM,
        subBuilder: AggregateMeta.create)
    ..hasRequiredFields = false;

  AggregateMetaList._() : super();
  factory AggregateMetaList({
    $core.int? count,
    $core.Iterable<AggregateMeta>? items,
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
  factory AggregateMetaList.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AggregateMetaList.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AggregateMetaList clone() => AggregateMetaList()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AggregateMetaList copyWith(void Function(AggregateMetaList) updates) =>
      super.copyWith((message) => updates(message as AggregateMetaList))
          as AggregateMetaList; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AggregateMetaList create() => AggregateMetaList._();
  AggregateMetaList createEmptyInstance() => create();
  static $pb.PbList<AggregateMetaList> createRepeated() =>
      $pb.PbList<AggregateMetaList>();
  @$core.pragma('dart2js:noInline')
  static AggregateMetaList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AggregateMetaList>(create);
  static AggregateMetaList? _defaultInstance;

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
  $core.List<AggregateMeta> get items => $_getList(1);
}

class AggregateMeta extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AggregateMeta',
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
    ..aInt64(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'number')
    ..aInt64(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'position')
    ..aOM<$6.EventMeta>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdBy', protoName: 'createdBy', subBuilder: $6.EventMeta.create)
    ..aOM<$6.EventMeta>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'changedBy', protoName: 'changedBy', subBuilder: $6.EventMeta.create)
    ..aOM<$6.EventMeta>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deletedBy', protoName: 'deletedBy', subBuilder: $6.EventMeta.create)
    ..aOM<$6.EventMetaList>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'applied', subBuilder: $6.EventMetaList.create)
    ..aOM<$6.EventMetaList>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pending', subBuilder: $6.EventMetaList.create)
    ..aOM<$6.EventMetaList>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'skipped', subBuilder: $6.EventMetaList.create)
    ..aOM<$5.Any>(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'taint', subBuilder: $5.Any.create)
    ..aOM<$5.Any>(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cordon', subBuilder: $5.Any.create)
    ..aOM<$5.Any>(13, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', subBuilder: $5.Any.create)
    ..hasRequiredFields = false;

  AggregateMeta._() : super();
  factory AggregateMeta({
    $core.String? type,
    $core.String? uuid,
    $fixnum.Int64? number,
    $fixnum.Int64? position,
    $6.EventMeta? createdBy,
    $6.EventMeta? changedBy,
    $6.EventMeta? deletedBy,
    $6.EventMetaList? applied,
    $6.EventMetaList? pending,
    $6.EventMetaList? skipped,
    $5.Any? taint,
    $5.Any? cordon,
    $5.Any? data,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (uuid != null) {
      _result.uuid = uuid;
    }
    if (number != null) {
      _result.number = number;
    }
    if (position != null) {
      _result.position = position;
    }
    if (createdBy != null) {
      _result.createdBy = createdBy;
    }
    if (changedBy != null) {
      _result.changedBy = changedBy;
    }
    if (deletedBy != null) {
      _result.deletedBy = deletedBy;
    }
    if (applied != null) {
      _result.applied = applied;
    }
    if (pending != null) {
      _result.pending = pending;
    }
    if (skipped != null) {
      _result.skipped = skipped;
    }
    if (taint != null) {
      _result.taint = taint;
    }
    if (cordon != null) {
      _result.cordon = cordon;
    }
    if (data != null) {
      _result.data = data;
    }
    return _result;
  }
  factory AggregateMeta.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AggregateMeta.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AggregateMeta clone() => AggregateMeta()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AggregateMeta copyWith(void Function(AggregateMeta) updates) =>
      super.copyWith((message) => updates(message as AggregateMeta))
          as AggregateMeta; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AggregateMeta create() => AggregateMeta._();
  AggregateMeta createEmptyInstance() => create();
  static $pb.PbList<AggregateMeta> createRepeated() =>
      $pb.PbList<AggregateMeta>();
  @$core.pragma('dart2js:noInline')
  static AggregateMeta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AggregateMeta>(create);
  static AggregateMeta? _defaultInstance;

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
  $fixnum.Int64 get number => $_getI64(2);
  @$pb.TagNumber(3)
  set number($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get position => $_getI64(3);
  @$pb.TagNumber(4)
  set position($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => clearField(4);

  @$pb.TagNumber(5)
  $6.EventMeta get createdBy => $_getN(4);
  @$pb.TagNumber(5)
  set createdBy($6.EventMeta v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCreatedBy() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedBy() => clearField(5);
  @$pb.TagNumber(5)
  $6.EventMeta ensureCreatedBy() => $_ensure(4);

  @$pb.TagNumber(6)
  $6.EventMeta get changedBy => $_getN(5);
  @$pb.TagNumber(6)
  set changedBy($6.EventMeta v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasChangedBy() => $_has(5);
  @$pb.TagNumber(6)
  void clearChangedBy() => clearField(6);
  @$pb.TagNumber(6)
  $6.EventMeta ensureChangedBy() => $_ensure(5);

  @$pb.TagNumber(7)
  $6.EventMeta get deletedBy => $_getN(6);
  @$pb.TagNumber(7)
  set deletedBy($6.EventMeta v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDeletedBy() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeletedBy() => clearField(7);
  @$pb.TagNumber(7)
  $6.EventMeta ensureDeletedBy() => $_ensure(6);

  @$pb.TagNumber(8)
  $6.EventMetaList get applied => $_getN(7);
  @$pb.TagNumber(8)
  set applied($6.EventMetaList v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasApplied() => $_has(7);
  @$pb.TagNumber(8)
  void clearApplied() => clearField(8);
  @$pb.TagNumber(8)
  $6.EventMetaList ensureApplied() => $_ensure(7);

  @$pb.TagNumber(9)
  $6.EventMetaList get pending => $_getN(8);
  @$pb.TagNumber(9)
  set pending($6.EventMetaList v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasPending() => $_has(8);
  @$pb.TagNumber(9)
  void clearPending() => clearField(9);
  @$pb.TagNumber(9)
  $6.EventMetaList ensurePending() => $_ensure(8);

  @$pb.TagNumber(10)
  $6.EventMetaList get skipped => $_getN(9);
  @$pb.TagNumber(10)
  set skipped($6.EventMetaList v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasSkipped() => $_has(9);
  @$pb.TagNumber(10)
  void clearSkipped() => clearField(10);
  @$pb.TagNumber(10)
  $6.EventMetaList ensureSkipped() => $_ensure(9);

  @$pb.TagNumber(11)
  $5.Any get taint => $_getN(10);
  @$pb.TagNumber(11)
  set taint($5.Any v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasTaint() => $_has(10);
  @$pb.TagNumber(11)
  void clearTaint() => clearField(11);
  @$pb.TagNumber(11)
  $5.Any ensureTaint() => $_ensure(10);

  @$pb.TagNumber(12)
  $5.Any get cordon => $_getN(11);
  @$pb.TagNumber(12)
  set cordon($5.Any v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasCordon() => $_has(11);
  @$pb.TagNumber(12)
  void clearCordon() => clearField(12);
  @$pb.TagNumber(12)
  $5.Any ensureCordon() => $_ensure(11);

  @$pb.TagNumber(13)
  $5.Any get data => $_getN(12);
  @$pb.TagNumber(13)
  set data($5.Any v) {
    setField(13, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasData() => $_has(12);
  @$pb.TagNumber(13)
  void clearData() => clearField(13);
  @$pb.TagNumber(13)
  $5.Any ensureData() => $_ensure(12);
}
