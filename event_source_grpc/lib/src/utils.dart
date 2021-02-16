import 'dart:convert';

import 'package:event_source/event_source.dart';
import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:fixnum/fixnum.dart';
import 'generated/any.pb.dart';
import 'generated/aggregate.pb.dart';
import 'generated/event.pb.dart';
import 'generated/repository.pb.dart';
import 'generated/snapshot.pb.dart';
import 'generated/timestamp.pb.dart';

const _codec = Utf8Codec();

Any toAnyFromJson(
  dynamic json, {
  String scheme = 'org.discoos.es',
  String type,
}) =>
    Any()
      ..typeUrl = '$scheme/${type ?? (json is List ? 'json.list' : 'json.map')}'
      ..value = _codec.encode(jsonEncode(json));

dynamic toJsonFromAny<T>(Any json) {
  final type = json.typeUrl.split('/').last;
  switch (type) {
    case 'json.list':
      return List.from(
        jsonDecode(_codec.decode(json.value)),
      );
    case 'json.map':
    default:
      return Map.from(
        jsonDecode(_codec.decode(json.value)),
      );
  }
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
    )
    ..connection = toConnectionMetricsMeta(
      repo.mapAt<String, dynamic>('connection'),
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
    meta..events = Int64(metrics.elementAt<int>('events'));
    final aggregates = metrics.mapAt<String, dynamic>('aggregates');
    if (aggregates != null) {
      meta.aggregates = (RepositoryMetricsAggregateMeta()
        ..count = aggregates.elementAt<int>('count')
        ..changed = aggregates.elementAt<int>('changed')
        ..tainted = toAggregateMetaList(
          type,
          metrics.elementAt<int>('tainted/count', defaultValue: 0),
          metrics.listAt('tainted/items', defaultList: []),
          (item) => AggregateMeta()
            ..uuid = item['uuid']
            ..tainted = toAnyFromJson(item['value']),
        )
        ..cordoned = toAggregateMetaList(
          type,
          metrics.elementAt<int>('cordoned/count', defaultValue: 0),
          metrics.listAt('cordoned/items', defaultList: []),
          (item) => AggregateMeta()
            ..uuid = item['uuid']
            ..cordoned = toAnyFromJson(item['value']),
        ));
    }
    final push = metrics.mapAt<String, dynamic>('push');
    if (push != null) {
      meta.push = toDurationMetricMeta(push);
    }
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
    meta.tainted = toAnyFromJson(store.tainted[uuid]);
  } else if (store.isCordoned(uuid)) {
    meta.cordoned = toAnyFromJson(store.cordoned[uuid]);
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
    meta.data = toAnyFromJson(
      aggregate.data,
    );
  }
  return meta;
}

AggregateMeta toAggregateMetaFromMap(
  Map<String, dynamic> aggregate, {
  EventStore store,
  List<AggregateExpandFields> expand = const [],
}) {
  final uuid = aggregate.elementAt<String>('uuid');
  final meta = AggregateMeta()
    ..uuid = uuid
    ..type = '${aggregate.runtimeType}'
    ..createdBy = toEventMetaFromMap(
      aggregate.mapAt<String, dynamic>('created'),
    )
    ..changedBy = toEventMetaFromMap(
      aggregate.mapAt<String, dynamic>('changed'),
    );
  var withItems = withAggregateField(
    expand,
    AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_ITEMS,
  );
  if (withItems) {
    final applied = aggregate.listAt('applied', defaultList: []);
    final skipped = aggregate.listAt('skipped', defaultList: []);
    final pending = aggregate.listAt('changed', defaultList: []);
    if (applied.isNotEmpty) {
      meta.applied = EventMetaList()
        ..count = applied.length
        ..items.addAll(
          applied.map((e) => toEventMetaFromMap(e)).toList(),
        );
    }
    if (pending.isNotEmpty) {
      meta.pending = EventMetaList()
        ..count = pending.length
        ..items.addAll(
          pending.map((e) => toEventMetaFromMap(e)).toList(),
        );
    }
    if (skipped.isNotEmpty) {
      meta.skipped = EventMetaList()
        ..count = skipped.length
        ..items.addAll(
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
    meta.data = toAnyFromJson(
      aggregate.mapAt('data'),
    );
  }
  return meta;
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
  final meta = EventMeta()
    ..uuid = event.elementAt<String>('uuid')
    ..type = event.elementAt<String>('type')
    ..number = Int64(event.elementAt<int>('number', defaultValue: -1))
    ..position = Int64(event.elementAt<int>('position', defaultValue: -1));
  if (event.hasPath('remote')) {
    meta.remote = event.elementAt<bool>('remote');
  }
  if (event.hasPath('created')) {
    meta.timestamp = Timestamp.fromDateTime(DateTime.parse(event.elementAt<String>('created')));
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
  final meta = SnapshotMeta()
    ..type = type
    ..number = Int64(repo.elementAt<int>('number'))
    ..position = Int64(repo.elementAt<int>('position'))
    ..metrics = toSnapshotMetricsMeta(
      repo.mapAt<String, dynamic>('metrics'),
    )
    ..aggregates = toAggregateMetaList(
      type,
      repo.elementAt<int>('aggregates/count', defaultValue: 0),
      repo.listAt('aggregates/items', defaultList: []),
      (item) => toAggregateMetaFromMap(
        Map.from(item),
        store: store,
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
    if (metrics.hasPath('unsaved')) {
      meta.unsaved = Int64(metrics.elementAt<int>('unsaved'));
    }
    if (metrics.hasPath('missing')) {
      meta.missing = Int64(metrics.elementAt<int>('missing'));
    }
    final save = metrics.mapAt<String, dynamic>('save');
    if (save != null) {
      meta.save = toDurationMetricMeta(save);
    }
  }
  return meta;
}
