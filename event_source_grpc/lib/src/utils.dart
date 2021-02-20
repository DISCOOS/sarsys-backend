import 'dart:ffi';

export 'package:strings/strings.dart';
import 'package:event_source/event_source.dart';
import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'generated/aggregate.pb.dart';
import 'generated/event.pb.dart';
import 'generated/repository.pb.dart';
import 'generated/snapshot.pb.dart';
import 'generated/timestamp.pb.dart';

Value toValueFromJson(dynamic json) {
  if (json is List) {
    return Value()..listValue = (ListValue()..values.addAll(json.map(toValueFromJson)));
  }
  if (json is Map<String, dynamic>) {
    return Value()..mergeFromProto3Json(Map<String, dynamic>.from(json));
  }
  throw ArgumentError(
    'Only List and Map<String,dynamic> are supported types, found type ${json?.runtimeType}',
  );
}

bool withRepoField(List<RepoExpandFields> expand, RepoExpandFields field) =>
    expand.contains(RepoExpandFields.REPO_EXPAND_FIELDS_ALL) || expand.contains(field);

AnalysisMeta toAnalysisMeta(
  Map<String, dynamic> meta,
) {
  return AnalysisMeta()
    ..count = meta.elementAt<int>('count')
    ..wrong = meta.elementAt<int>('wrong')
    ..multiple = meta.elementAt<int>('multiple')
    ..summary.addAll(
      meta.listAt<String>('summary'),
    );
}

RepositoryMeta toRepoMeta(
  Map<String, dynamic> repo,
  EventStore store,
) {
  final type = repo.elementAt<String>('type');
  return RepositoryMeta()
    ..type = type
    ..lastEvent = toEventMetaFromMap(
      repo.mapAt<String, dynamic>('lastEvent'),
    )
    ..queue = toRepoQueueMeta(
      repo.mapAt<String, dynamic>('queue'),
    )
    ..metrics = toRepoMetricsMeta(
      type,
      repo.mapAt<String, dynamic>('metrics'),
    )
    ..connection = toConnectionMetricsMeta(
      repo.mapAt<String, dynamic>('connection/metrics'),
    );
}

ConnectionMetricsMeta toConnectionMetricsMeta(Map<String, dynamic> metrics) {
  final meta = ConnectionMetricsMeta();
  if (metrics != null) {
    meta
      ..read = toDurationMetricMeta(
        metrics.mapAt<String, dynamic>('read'),
      )
      ..write = toDurationMetricMeta(
        metrics.mapAt<String, dynamic>('write'),
      );
  }
  return meta;
}

RepositoryQueueMeta toRepoQueueMeta(Map<String, dynamic> queue) {
  final meta = RepositoryQueueMeta();
  if (queue != null) {
    meta.setIfExists<Map>(queue, 'status', (status) {
      meta.status = (RepositoryQueueStatusMeta()
        ..idle = status.elementAt<bool>('idle')
        ..ready = status.elementAt<bool>('ready')
        ..disposed = status.elementAt<bool>('disposed'));
    });
    meta.setIfExists<Map>(queue, 'pressure', (pressure) {
      meta.pressure = (RepositoryQueuePressureMeta()
        ..total = pressure.elementAt<int>('total')
        ..maximum = pressure.elementAt<int>('maximum')
        ..commands = pressure.elementAt<int>('command')
        ..exceeded = pressure.elementAt<bool>('exceeded'));
    });
  }
  return meta;
}

RepositoryMetricsMeta toRepoMetricsMeta(
  String type,
  Map<String, dynamic> metrics,
) {
  final meta = RepositoryMetricsMeta();
  if (metrics != null) {
    meta..events = Int64(metrics.elementAt<int>('events'));
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
            ..taint = toValueFromJson(item['taint']),
        )
        ..cordoned = toAggregateMetaList(
          type,
          metrics.elementAt<int>('cordoned/count', defaultValue: 0),
          metrics.listAt('cordoned/items', defaultList: []),
          (item) => AggregateMeta()
            ..uuid = item['uuid']
            ..cordon = toValueFromJson(item['cordon']),
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

bool withAggregateField(List<AggregateExpandFields> expand, AggregateExpandFields field) =>
    expand.contains(AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ALL) || expand.contains(field);

AggregateMeta toAggregateMetaFromRoot(
  AggregateRoot aggregate,
  EventStore store, {
  List<AggregateExpandFields> expand = const [],
}) {
  final uuid = aggregate.uuid;
  final meta = AggregateMeta()
    ..uuid = uuid
    ..type = '${aggregate.runtimeType}'
    ..createdBy = toEventMetaFromEvent(aggregate.createdBy, store)
    ..changedBy = toEventMetaFromEvent(aggregate.changedBy, store);
  if (store.isTainted(uuid)) {
    meta.taint = toValueFromJson(store.tainted[uuid]);
  } else if (store.isCordoned(uuid)) {
    meta.cordon = toValueFromJson(store.cordoned[uuid]);
  }
  final applied = aggregate.applied;
  final skipped = aggregate.skipped;
  final pending = aggregate.getLocalEvents();
  meta.applied = EventMetaList()..count = applied.length;
  meta.skipped = EventMetaList()..count = skipped.length;
  meta.pending = EventMetaList()..count = pending.length;
  var withItems = withAggregateField(
    expand,
    AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ITEMS,
  );
  if (withItems) {
    if (applied.isNotEmpty) {
      meta.applied.items.addAll(
        applied.map((e) => toEventMetaFromEvent(e, store)).toList(),
      );
    }
    if (pending.isNotEmpty) {
      meta.pending.items.addAll(
        pending.map((e) => toEventMetaFromEvent(e, store)),
      );
    }
    if (skipped.isNotEmpty) {
      meta.skipped.items.addAll(
        skipped.map(
          (uuid) => toEventMetaFromEvent(store.getEvent(uuid), store),
        ),
      );
    }
  }
  var withData = withAggregateField(
    expand,
    AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_DATA,
  );
  if (withData) {
    meta.data = toValueFromJson(
      aggregate.data,
    );
  }
  return meta;
}

AggregateMeta toAggregateMetaFromMap(
  Map<String, dynamic> aggregate,
) {
  return AggregateMeta()..mergeFromProto3Json(aggregate);
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

EventMeta toEventMetaFromMap(Map<String, dynamic> event) {
  final meta = EventMeta();
  if (event != null) {
    meta
      ..uuid = event.elementAt<String>('uuid')
      ..type = event.elementAt<String>('type')
      ..number = Int64(event.elementAt<int>('number', defaultValue: -1))
      ..position = Int64(event.elementAt<int>('position', defaultValue: -1));
    meta.setIfExists<bool>(event, 'remote', (remote) => meta.remote = remote);
    meta.setIfExists<String>(event, 'created', (ts) => meta.timestamp = Timestamp.fromDateTime(DateTime.parse(ts)));
  }
  return meta;
}

bool withSnapshotField(List<SnapshotExpandFields> expand, SnapshotExpandFields field) =>
    expand.contains(SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ALL) || expand.contains(field);

SnapshotMeta toSnapshotMeta(
  String type,
  Map<String, dynamic> repo,
  EventStore store,
) {
  final meta = SnapshotMeta()..type = capitalize(type);
  meta.setIfExists<int>(repo, 'number', (value) => meta.number = Int64(value));
  meta.setIfExists<int>(repo, 'position', (value) => meta.number = Int64(value));
  meta
    ..metrics = toSnapshotMetricsMeta(
      repo.mapAt<String, dynamic>('metrics'),
    )
    ..aggregates = toAggregateMetaList(
      type,
      repo.elementAt<int>('aggregates/count', defaultValue: 0),
      repo.listAt('aggregates/items', defaultList: []),
      (item) => toAggregateMetaFromMap(
        Map<String, dynamic>.from(item),
      ),
    );
  if (repo.hasPath('uuid')) {
    meta.uuid = repo.elementAt<String>('uuid');
  }
  return meta;
}

SnapshotMetricsMeta toSnapshotMetricsMeta(
  Map<String, dynamic> metrics,
) {
  final meta = SnapshotMetricsMeta();
  if (metrics != null) {
    meta.snapshots = Int64(metrics.elementAt<int>('snapshots'));
    meta.isPartial = metrics.elementAt<bool>('partial', defaultValue: false);
    meta.setIfExists<int>(metrics, 'unsaved', (unsaved) => meta.unsaved = Int64(unsaved));
    meta.setIfExists<Map>(metrics, 'partial', (partial) => meta.missing = Int64(partial.elementAt<int>('missing')));
    meta.setIfExists<Map>(metrics, 'save', (save) => meta.save = toDurationMetricMeta(save));
  }
  return meta;
}

extension GeneratedMessageX on GeneratedMessage {
  void setIfExists<T>(Map<String, dynamic> map, String path, void Function(T) set) {
    if (map.hasPath(path)) {
      set(map.elementAt<T>(path));
    }
  }
}
