import 'package:aqueduct/aqueduct.dart';

//////////////////////////////////
// Event Source documentation
//////////////////////////////////

APISchemaObject documentID() => APISchemaObject.string()
  ..description = 'An id unique in current collection';

APISchemaObject documentUUID() => APISchemaObject.string()
  ..format = 'uuid'
  ..description =
      'A [universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).';

APISchemaObject documentAggregateRef(
  APIDocumentContext context, {
  String defaultType,
  bool readOnly = true,
  String description = 'Aggregate Root Reference',
}) =>
    APISchemaObject.object({
      'uuid': documentUUID()
        ..description = '${defaultType ?? 'Aggregate Root'} UUID'
        ..isReadOnly = readOnly,
      'type': APISchemaObject.string()
        ..description = '${defaultType ?? 'Aggregate Root'} Type'
        ..isReadOnly = readOnly
        ..defaultValue = defaultType,
    })
      ..description = description
      ..isReadOnly = readOnly
      ..required = ['uuid']
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

APISchemaObject documentAggregateList(
  APIDocumentContext context, {
  String defaultType,
  String description = 'List of Aggregate Root uuids',
}) =>
    APISchemaObject.array(ofSchema: documentUUID())
      ..description = description
      ..isReadOnly = true
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

//////////////////////////////////
// Response documentation
//////////////////////////////////

APISchemaObject documentAggregatePageResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'total': APISchemaObject.integer()
        ..description = 'Number of aggregates'
        ..isReadOnly = true,
      'offset': APISchemaObject.integer()
        ..description = 'Aggregate Page offset'
        ..isReadOnly = true,
      'limit': APISchemaObject.integer()
        ..description = 'Aggregate Page size'
        ..isReadOnly = true,
      'next': APISchemaObject.integer()
        ..description = 'Next Aggregate Page offset'
        ..isReadOnly = true,
      'entries': APISchemaObject.array(
        ofSchema: documentAggregateResponse(
          context,
          type: type,
          schema: schema,
        ),
      )
        ..description = 'Array of ${type ?? 'Aggregate Object'}s'
        ..isReadOnly = true,
    })
      ..description = 'Entities Response'
      ..isReadOnly = true;

APISchemaObject documentEntityPageResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = 'Entity Object Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'total': APISchemaObject.integer()
        ..description = 'Number of entities'
        ..isReadOnly = true,
      'offset': APISchemaObject.integer()
        ..description = '$type Page offset'
        ..isReadOnly = true,
      'limit': APISchemaObject.integer()
        ..description = '$type Page size'
        ..isReadOnly = true,
      'next': APISchemaObject.integer()
        ..description = 'Next $type Page offset'
        ..isReadOnly = true,
      'path': APISchemaObject.string()
        ..description = 'Path to Entity Object List'
        ..isReadOnly = true,
      'entries': APISchemaObject.array(
        ofSchema: schema ??
            (type != null ? context.schema[type] : APISchemaObject.freeForm()),
      )
        ..description = 'Array of ${type ?? 'Entity Object'}s'
        ..isReadOnly = true,
    })
      ..description = 'Entities Response'
      ..isReadOnly = true;

APISchemaObject documentValuePageResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = 'Value Object Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'total': APISchemaObject.integer()
        ..description = 'Number of ${type}s'
        ..isReadOnly = true,
      'offset': APISchemaObject.integer()
        ..description = '$type Page offset'
        ..isReadOnly = true,
      'limit': APISchemaObject.integer()
        ..description = '$type Page size'
        ..isReadOnly = true,
      'next': APISchemaObject.integer()
        ..description = 'Next $type Page offset'
        ..isReadOnly = true,
      'path': APISchemaObject.string()
        ..description = 'Path to Value Object List'
        ..isReadOnly = true,
      'entries': APISchemaObject.array(
        ofSchema: schema ??
            (type != null ? context.schema[type] : APISchemaObject.freeForm()),
      )
        ..description = 'Array of ${type ?? 'Value Object'}s'
        ..isReadOnly = true,
    })
      ..description = 'Array Value Response'
      ..isReadOnly = true;

APISchemaObject documentAggregateResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Aggregate Root'} Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'created': APISchemaObject.string()
        ..description = 'When Aggregate was created'
        ..format = 'date-time'
        ..isReadOnly = true,
      'changed': APISchemaObject.string()
        ..description = 'When Aggregate was created'
        ..format = 'date-time'
        ..isReadOnly = true,
      'deleted': APISchemaObject.string()
        ..description = 'When Aggregate was created'
        ..format = 'date-time'
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description =
            'Last event applied to aggregate (can be used as version)'
        ..isReadOnly = true,
      'data': (schema ??
          (type != null ? context.schema[type] : APISchemaObject.freeForm()))
        ..description = '${type ?? 'Aggregate Root'} Data'
        ..isReadOnly = true,
    })
      ..description = '${type ?? 'Aggregate Root'} Response'
      ..isReadOnly = true;

APISchemaObject documentEntityResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Entity Object'} Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description =
            'Last event applied to aggregate (can be used as version)'
        ..isReadOnly = true,
      'data': schema ??
          (type != null ? context.schema[type] : APISchemaObject.freeForm())
        ..description = '${type ?? 'Entity Object'}  Data'
        ..isReadOnly = true,
    })
      ..description = '${type ?? 'Entity Object'} Response'
      ..isReadOnly = true;

APISchemaObject documentValueResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Value Object'} Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description =
            'Last event applied to aggregate (can be used as version)'
        ..isReadOnly = true,
      'data': schema ??
          (type != null ? context.schema[type] : APISchemaObject.freeForm())
        ..description = '${type ?? 'Value Object'}  Data'
        ..isReadOnly = true,
    })
      ..description = 'Value Object Response'
      ..isReadOnly = true;

APISchemaObject documentAggregate(
  APIDocumentContext context, {
  String type,
  bool readOnly = true,
}) =>
    APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Aggregate'} Type'
        ..isReadOnly = readOnly,
      'uuid': documentUUID()
        ..description = 'Globally unique aggregate id'
        ..isReadOnly = readOnly,
      'number': APISchemaObject.integer()
        ..description =
            'Number of last event applied to aggregate (can be used as version)'
        ..isReadOnly = true,
      'position': APISchemaObject.integer()
        ..description =
            'Position in canonical stream of last event applied to aggregate'
        ..isReadOnly = true,
      'modifications': APISchemaObject.integer()
        ..description = 'Number of modifications since creation'
        ..isReadOnly = true,
      'createdBy': documentEvent(context)
        ..description = 'Event that created this aggregate'
        ..isReadOnly = readOnly,
      'changedBy': documentEvent(context)
        ..description = 'Event that last changed this aggregate'
        ..isReadOnly = readOnly,
      'deletedBy': documentEvent(context)
        ..description = 'Event that deleted this aggregate (optional)'
        ..isReadOnly = readOnly,
      'applied': documentEventList(context)
        ..description = 'All events applied to this aggregate (optional)'
        ..isReadOnly = readOnly,
      'pending': documentEventList(context)
        ..description = 'Events pending push to remote stream (optional)'
        ..isReadOnly = readOnly,
      'skipped': documentEventList(context)
        ..description =
            'Events skipped because of unreconciled errors (optional)'
        ..isReadOnly = readOnly,
      'taint': APISchemaObject.freeForm()
        ..description = ' Aggregate taint information'
        ..isReadOnly = readOnly,
      'cordon': APISchemaObject.freeForm()
        ..description = ' Aggregate cordon information'
        ..isReadOnly = readOnly,
      'data': APISchemaObject.freeForm()
        ..description = 'Aggregate data'
        ..isReadOnly = readOnly,
    });

APISchemaObject documentRepositoryMeta(APIDocumentContext context) {
  return APISchemaObject.object({
    'type': APISchemaObject.string()
      ..description = 'Aggregate Type'
      ..isReadOnly = true,
    'lastEvent': documentEvent(context)
      ..description = 'Last event applied to repository'
      ..isReadOnly = true,
    'queue': documentRepositoryQueue(),
    'metrics': documentRepositoryMetrics(),
    'snapshot': documentSnapshot(context),
    'connection': documentConnection(context),
    'subscriptions': documentRepositorySubscriptions(context),
  });
}

APISchemaObject documentRepositoryQueue() {
  return APISchemaObject.object({
    'pressure': APISchemaObject.object({
      'push': APISchemaObject.integer()
        ..description = 'Number of pending pushes'
        ..isReadOnly = true,
      'command': APISchemaObject.integer()
        ..description = 'Number of pending commands'
        ..isReadOnly = true,
      'total': APISchemaObject.integer()
        ..description = 'Total pressure'
        ..isReadOnly = true,
      'maximum': APISchemaObject.integer()
        ..description = 'Maximum allowed pressure'
        ..isReadOnly = true,
      'exceeded': APISchemaObject.boolean()
        ..description = 'True if maximum pressure is exceeded'
        ..isReadOnly = true,
    })
      ..description = 'Queue pressure data'
      ..isReadOnly = true,
    'status': APISchemaObject.object({
      'idle': APISchemaObject.boolean()
        ..description = 'True if queue is idle'
        ..isReadOnly = true,
      'ready': APISchemaObject.boolean()
        ..description = 'True if queue is ready to process requests'
        ..isReadOnly = true,
      'disposed': APISchemaObject.boolean()
        ..description = 'True if queue is disposed'
        ..isReadOnly = true,
    })
      ..description = 'Queue status'
      ..isReadOnly = true,
  })
    ..description = 'Queue metadata'
    ..isReadOnly = true;
}

APISchemaObject documentRepositoryMetrics() {
  return APISchemaObject.object({
    'events': APISchemaObject.integer()
      ..description = 'Number of events'
      ..isReadOnly = true,
    'aggregates': APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Number of aggregates'
        ..isReadOnly = true,
      'changed': APISchemaObject.integer()
        ..description = 'Number of aggregates with local changes'
        ..isReadOnly = true,
      'tainted': APISchemaObject.object({
        'count': APISchemaObject.integer()
          ..description = 'Number of tainted aggregates'
          ..isReadOnly = true,
        'items': APISchemaObject.array(
          ofSchema: APISchemaObject.object({
            'uuid': documentUUID()
              ..description = 'Globally unique aggregate id'
              ..isReadOnly = true,
            'taint': APISchemaObject.freeForm()
              ..description = 'Taint reason'
              ..isReadOnly = true,
          })
            ..description = 'Tainted aggregate'
            ..isReadOnly = true,
        )
          ..description = 'List of tainted aggregates'
          ..isReadOnly = true,
      })
        ..description = 'Tainted aggregates'
        ..isReadOnly = true,
      'cordoned': APISchemaObject.object({
        'count': APISchemaObject.integer()
          ..description = 'Number of cordoned aggregates'
          ..isReadOnly = true,
        'items': APISchemaObject.array(
          ofSchema: APISchemaObject.object({
            'uuid': documentUUID()
              ..description = 'Globally unique aggregate id'
              ..isReadOnly = true,
            'cordon': APISchemaObject.freeForm()
              ..description = 'Cordon reason'
              ..isReadOnly = true,
          })
            ..description = 'Cordoned aggregate'
            ..isReadOnly = true,
        )
          ..description = 'List of cordoned aggregates'
          ..isReadOnly = true,
      })
        ..description = 'Cordoned aggregates'
        ..isReadOnly = true,
    })
      ..description = 'Aggregates metrics metadata'
      ..isReadOnly = true,
    'transactions': APISchemaObject.integer()
      ..description = 'Number of open transactions'
      ..isReadOnly = true,
    'push': documentDurationMetric('push')
      ..description = 'Number of open transactions'
      ..isReadOnly = true,
  })
    ..description = 'Repository metrics metadata'
    ..isReadOnly = true;
}

APISchemaObject documentSnapshot(APIDocumentContext context) {
  return APISchemaObject.object({
    'uuid': documentUUID()
      ..description = 'Globally unique Snapshot id'
      ..isReadOnly = true,
    'number': APISchemaObject.integer()
      ..description = 'Snapshot event number'
      ..isReadOnly = true,
    'position': APISchemaObject.integer()
      ..description =
          'Snapshot event position in projection if using instance streams'
      ..isReadOnly = true,
    'config': APISchemaObject.object({
      'keep': APISchemaObject.integer()
        ..description = 'Number of snapshots to keep until deleting oldest'
        ..isReadOnly = true,
      'threshold': APISchemaObject.integer()
        ..description =
            'Number of unsaved events before saving to next snapshot'
        ..isReadOnly = true,
      'automatic': APISchemaObject.integer()
        ..description =
            'Control flag for automatic snapshots when threshold is reached'
        ..isReadOnly = true,
    })
      ..description = 'Snapshot configuration'
      ..isReadOnly = true,
    'metrics': APISchemaObject.object({
      'snapshots': APISchemaObject.integer()
        ..description = 'Number of snapshots stored'
        ..isReadOnly = true,
      'unsaved': APISchemaObject.integer()
        ..description = 'Number of unsaved events'
        ..isReadOnly = true,
      'partial': APISchemaObject.object({
        'missing': APISchemaObject.integer()
          ..description = 'Number of missing events in snapshot'
          ..isReadOnly = true,
      })
        ..description = 'Snapshot contains partial state if defined'
        ..isReadOnly = true,
      'save': documentDurationMetric('Save'),
    })
      ..description = 'Snapshot metrics'
      ..isReadOnly = true,
    'aggregates': APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Total number aggregates in snapshot'
        ..isReadOnly = true,
      'items': APISchemaObject.array(
        ofSchema: documentAggregate(context),
      )..description = 'Array of skipped events',
    }),
  })
    ..description = 'Queue pressure data'
    ..isReadOnly = true;
}

APISchemaObject documentConnection(APIDocumentContext context) {
  return APISchemaObject.object({
    'metrics': APISchemaObject.object({
      'read': documentDurationMetric('Read'),
      'write': documentDurationMetric('Write'),
    })
      ..description = 'Connection metrics'
      ..isReadOnly = true,
  });
}

APISchemaObject documentRepositorySubscriptions(APIDocumentContext context) {
  return APISchemaObject.object({
    'catchup': APISchemaObject.object({
      'isAutomatic': APISchemaObject.boolean()
        ..description = 'True if automatic catchup is activated'
        ..isReadOnly = true,
      'exists': APISchemaObject.boolean()
        ..description = 'True if subscription exists'
        ..isReadOnly = true,
      'last': documentEvent(context)
        ..description = 'Last event processed'
        ..isReadOnly = true,
      'status': APISchemaObject.object({
        'isPaused': APISchemaObject.boolean()
          ..description = 'True if subscription is paused'
          ..isReadOnly = true,
        'isCancelled': APISchemaObject.boolean()
          ..description = 'True if subscription is cancelled'
          ..isReadOnly = true,
        'isCompeting': APISchemaObject.boolean()
          ..description =
              'True if subscription is competing (pulling when false)'
          ..isReadOnly = true,
      })
        ..description = 'Catchup subscription status'
        ..isReadOnly = true,
      'metrics': APISchemaObject.object({
        'processed': APISchemaObject.integer()
          ..description = 'Number of events processed'
          ..isReadOnly = true,
        'reconnects': APISchemaObject.integer()
          ..description = 'Number of reconnections'
          ..isReadOnly = true,
      })
        ..description = 'Catchup subscription statistics'
        ..isReadOnly = true
    })
      ..description = 'Catchup subscription'
      ..isReadOnly = true,
    'push': APISchemaObject.object({
      'exists': APISchemaObject.boolean()
        ..description = 'True if subscription exists'
        ..isReadOnly = true,
      'isPaused': APISchemaObject.boolean()
        ..description = 'True if subscription is paused'
        ..isReadOnly = true,
    })
      ..description = 'Request queue subscription status'
      ..isReadOnly = true,
  });
}

APISchemaObject documentSnapshotMeta(APIDocumentContext context) {
  return APISchemaObject.object({
    'last': documentUUID()
      ..description = 'Uuid of snapshot last saved'
      ..isReadOnly = true,
    'uuid': documentUUID()
      ..description = 'Snapshot uuid'
      ..isReadOnly = true,
    'number': APISchemaObject.integer()
      ..description = 'Snapshot event number '
          '(or position in projection if using instance-streams)'
      ..isReadOnly = true,
    'timestamp': APISchemaObject.string()
      ..description = 'When snapshot was saved'
      ..format = 'date-time',
    'unsaved': APISchemaObject.integer()
      ..description = 'Number of unsaved events'
      ..isReadOnly = true,
    'partial': APISchemaObject.object({
      'missing': APISchemaObject.integer()
        ..description = 'Number of missing events in snapshot'
        ..isReadOnly = true,
    })
      ..description = 'Snapshot contains partial state if defined'
      ..isReadOnly = true,
    'config': APISchemaObject.object({
      'keep': APISchemaObject.integer()
        ..description = 'Number of snapshots to keep until deleting oldest'
        ..isReadOnly = true,
      'threshold': APISchemaObject.integer()
        ..description =
            'Number of unsaved events before saving to next snapshot'
        ..isReadOnly = true,
      'automatic': APISchemaObject.integer()
        ..description =
            'Control flag for automatic snapshots when threshold is reached'
        ..isReadOnly = true,
    })
      ..description = 'Snapshots configuration'
      ..isReadOnly = true,
    'metrics': APISchemaObject.object({
      'snapshots': APISchemaObject.integer()
        ..description = 'Number of snapshots'
        ..isReadOnly = true,
      'save': documentDurationMetric('Save'),
    })
      ..description = 'Snapshot metrics'
      ..isReadOnly = true,
    'aggregates': APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Total number aggregates in snapshot'
        ..isReadOnly = true,
      'items': APISchemaObject.array(
        ofSchema: documentAggregate(context),
      )..description = 'Array of skipped events',
    }),
  })
    ..description = 'Queue pressure data'
    ..isReadOnly = true;
}

APISchemaObject documentEventList(
  APIDocumentContext context, {
  String type,
  bool readOnly = true,
}) =>
    APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Number of events'
        ..isReadOnly = readOnly,
      'items': APISchemaObject.array(
        ofSchema: documentEvent(context, type: type, readOnly: readOnly),
      )
        ..description = 'Events in list'
        ..isReadOnly = readOnly
    })
      ..description = 'List of events'
      ..isReadOnly = readOnly;

APISchemaObject documentEvent(
  APIDocumentContext context, {
  String type,
  bool readOnly = true,
}) =>
    APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Event'} Type'
        ..isReadOnly = readOnly,
      'uuid': documentUUID()
        ..description = 'Globally unique event id'
        ..isReadOnly = readOnly,
      'number': APISchemaObject.integer()
        ..description = 'Event number in instance stream'
        ..isReadOnly = readOnly,
      'remote': APISchemaObject.boolean()
        ..description = 'True if event origin is remote'
        ..isReadOnly = readOnly,
      'position': APISchemaObject.integer()
        ..description =
            'Event position in canonical (projection or instance) stream'
        ..isReadOnly = readOnly,
      'timestamp': APISchemaObject.string()
        ..description = 'When event occurred'
        ..format = 'date-time'
        ..isReadOnly = readOnly,
    });

APISchemaObject documentDurationMetric(String name) => APISchemaObject.object({
      'count': APISchemaObject.integer()
        ..description = 'Number of measurements'
        ..isReadOnly = true,
      'duration': APISchemaObject.integer()
        ..description = 'Last $name time in ms'
        ..isReadOnly = true,
      'durationAverage': APISchemaObject.integer()
        ..description = '$name time average'
        ..isReadOnly = true,
    })
      ..description = '$name metrics'
      ..isReadOnly = true;

APISchemaObject documentConflict(
  APIDocumentContext context,
) =>
    APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = 'Conflict type'
        ..additionalPropertyPolicy =
            APISchemaAdditionalPropertyPolicy.disallowed
        ..isReadOnly = true
        ..enumerated = [
          'merge',
          'exists',
          'deleted',
        ],
      'mine': APISchemaObject.map(ofType: APIType.object)
        ..description =
            'JsonPatch diffs between remote base and head of event stream'
        ..isReadOnly = true,
      'yours': APISchemaObject.map(ofType: APIType.object)
        ..description = 'JsonPatch diffs between remote base and request body'
        ..isReadOnly = true,
    })
      ..description = 'Conflict Error object with JsonPatch diffs for '
          'manually applying mine or your changes locally before the '
          'operation trying again.'
      ..isReadOnly = true;
