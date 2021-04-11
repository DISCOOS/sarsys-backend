import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:collection_x/collection_x.dart';
import 'package:event_source/event_source.dart';

import 'generated/any.pb.dart';
import 'generated/json.pb.dart';
import 'generated/metric.pb.dart';
import 'generated/aggregate.pb.dart';
import 'generated/event.pb.dart';
import 'generated/repository.pb.dart';
import 'generated/timestamp.pb.dart';
import 'json.dart';

Any toAny(GeneratedMessage value) {
  return Any.pack(value, typeUrlPrefix: 'type.discoos.io');
}

Any toAnyFromJson(
  dynamic data, [
  JsonDataCompression compression = JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
]) {
  return Any.pack(
    toJsonValue(data, compression),
    typeUrlPrefix: 'type.discoos.io',
  );
}

JsonValue toJsonValue(
  dynamic data, [
  JsonDataCompression compression = JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
]) {
  return JsonValueWrapper()
    ..compression = compression
    ..data = toJsonValueBytes(data);
}

List<int> toJsonValueBytes(
  dynamic data, [
  JsonDataCompression compression = JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
]) {
  switch (compression) {
    case JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB:
      return utf8.fuse(zlib).encode(jsonEncode(data));
    case JsonDataCompression.JSON_DATA_COMPRESSION_GZIP:
      return utf8.fuse(gzip).encode(jsonEncode(data));
  }
  return utf8.encode(
    jsonEncode(data),
  );
}

dynamic toJsonFromAny(Any value) {
  return fromJsonValue(
    value.unpackInto<JsonValue>(JsonValueWrapper()),
  );
}

JsonValue toJsonValueFromAny(Any value) {
  return value.unpackInto<JsonValue>(JsonValueWrapper());
}

dynamic fromJsonValue(JsonValue value) {
  return fromJsonDataBytes(
    value.data,
    value.compression,
  );
}

dynamic fromJsonDataBytes(
  List<int> data, [
  JsonDataCompression compression = JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
]) {
  switch (compression) {
    case JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB:
      return jsonDecode(utf8.fuse(zlib).decode(data));
    case JsonDataCompression.JSON_DATA_COMPRESSION_GZIP:
      return jsonDecode(utf8.fuse(gzip).decode(data));
  }
  return jsonDecode(utf8.decode(data));
}

RepositoryMeta toRepoMeta(
  Map<String, dynamic> repo,
  EventStore store,
) {
  final type = repo.elementAt<String>('type');
  final lastEvent = store.isEmpty ? null : store.getEvent(store.eventMap.keys.last);
  return RepositoryMeta()
    ..type = repo.elementAt<String>('type')
    ..lastEvent = toEventMetaFromEvent(lastEvent, store)
    ..queue = toRepoQueueMeta(
      repo.mapAt<String, dynamic>('queue'),
    )
    ..metrics = toRepoMetricsMeta(
      type,
      repo.mapAt<String, dynamic>('metrics'),
    );
}

RepositoryQueueMeta toRepoQueueMeta(Map<String, dynamic> queue) {
  final meta = RepositoryQueueMeta();
  if (queue != null) {
    final status = queue.mapAt<String, dynamic>('status');
    if (status != null) {
      meta.status = (RepositoryQueueStatusMeta()
        ..idle = status.elementAt<bool>('idle')
        ..ready = status.elementAt<bool>('ready')
        ..disposed = status.elementAt<bool>('disposed'));
    }
    final pressure = queue.mapAt<String, dynamic>('pressure');
    if (pressure != null) {
      meta.pressure = (RepositoryQueuePressureMeta()
        ..total = pressure.elementAt<int>('total')
        ..maximum = pressure.elementAt<int>('maximum')
        ..commands = pressure.elementAt<int>('command')
        ..exceeded = pressure.elementAt<bool>('exceeded'));
    }
  }
  return meta;
}

RepositoryMetricsMeta toRepoMetricsMeta(
  String type,
  Map<String, dynamic> metrics,
) {
  final meta = RepositoryMetricsMeta();
  if (metrics != null) {
    meta.events = Int64(metrics.elementAt<int>('events'));
    meta.setIfExists<Map>(metrics, 'aggregates', (aggregates) {
      meta.aggregates = (RepositoryMetricsAggregateMeta()
        ..count = aggregates.elementAt<int>('count')
        ..changed = aggregates.elementAt<int>('changed')
        ..tainted = toAggregateMetaList(
          type,
          metrics.elementAt<int>('tainted/count', defaultValue: 0),
          metrics.listAt('tainted/items', defaultList: []),
          (item) => AggregateMeta()
            ..uuid = item['uuid']
            ..taint = toAnyFromJson(item['taint']),
        )
        ..cordoned = toAggregateMetaList(
          type,
          metrics.elementAt<int>('cordoned/count', defaultValue: 0),
          metrics.listAt('cordoned/items', defaultList: []),
          (item) => AggregateMeta()
            ..uuid = item['uuid']
            ..cordon = toAnyFromJson(item['cordon']),
        ));
    });
    meta.setIfExists<Map>(metrics, 'push', (push) => meta.push = toDurationMetricMeta(push));
  }
  return meta;
}

DurationMetricMeta toDurationMetricMeta(Map<String, dynamic> metrics) {
  final meta = DurationMetricMeta()
    ..last = Int64(metrics.elementAt<int>('last'))
    ..count = Int64(metrics.elementAt<int>('count'))
    ..total = Int64(metrics.elementAt<int>('total'))
    ..cumulative = (DurationCumulativeAverage()
      ..rate = metrics.elementAt<double>('cumulative/rate')
      ..mean = Int64(metrics.elementAt<int>('cumulative/mean'))
      ..variance = metrics.elementAt<double>('cumulative/variance')
      ..deviation = metrics.elementAt<double>('cumulative/deviation'))
    ..exponential = (DurationExponentialAverage()
      ..beta = metrics.elementAt<double>('exponential/beta')
      ..alpha = metrics.elementAt<double>('exponential/alpha')
      ..rate = metrics.elementAt<double>('exponential/rate')
      ..mean = Int64(metrics.elementAt<int>('exponential/mean'))
      ..variance = metrics.elementAt<double>('exponential/variance')
      ..deviation = metrics.elementAt<double>('exponential/deviation'));

  if (metrics.hasPath('t0')) {
    meta.t0 = Timestamp.fromDateTime(
      DateTime.parse(metrics.elementAt<String>('t0')),
    );
  }
  if (metrics.hasPath('tn')) {
    meta.tn = Timestamp.fromDateTime(
      DateTime.parse(metrics.elementAt<String>('tn')),
    );
  }

  return meta;
}

AggregateMetaList toAggregateMetaList(
  String type,
  int count,
  List items,
  AggregateMeta Function(dynamic) map,
) {
  final list = AggregateMetaList()
    ..count = count
    ..items.addAll([
      if (items.isNotEmpty) ...items.map(map),
    ]);

  return list;
}

EventMeta toEventMetaFromEvent(Event event, EventStore store) {
  final meta = EventMeta()
    ..number = Int64(EventNumber.none.value)
    ..position = Int64(EventNumber.none.value);
  if (event != null) {
    meta
      ..uuid = event.uuid
      ..type = event.type
      ..remote = event.remote
      ..number = Int64(event.number.value)
      ..position = Int64(store.toPosition(event))
      ..timestamp = Timestamp.fromDateTime(event.created);
  }
  return meta;
}

//
// EventMeta toEventMetaFromMap(Map<String, dynamic> event) {
//   final meta = EventMeta()
//     ..number = Int64(EventNumber.none.value)
//     ..position = Int64(EventNumber.none.value);
//   if (event != null) {
//     meta
//       ..uuid = event.uuid
//       ..type = event.type
//       ..remote = event.remote
//       ..number = Int64(event.number.value)
//       ..position = Int64(store.toPosition(event))
//       ..timestamp = toTimestamp(event.created);
//   }
//   return meta;
// }

extension GeneratedMessageX on GeneratedMessage {
  void setIfExists<T>(Map<String, dynamic> map, String path, void Function(T) set) {
    if (map.hasPath(path)) {
      set(map.elementAt<T>(path));
    }
  }
}
