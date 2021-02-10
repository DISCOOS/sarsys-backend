///
//  Generated code. Do not modify.
//  source: sarsys_tracking_service.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const TrackingServerStatus$json = const {
  '1': 'TrackingServerStatus',
  '2': const [
    const {'1': 'STATUS_NONE', '2': 0},
    const {'1': 'STATUS_READY', '2': 1},
    const {'1': 'STATUS_STARTED', '2': 2},
    const {'1': 'STATUS_STOPPED', '2': 3},
    const {'1': 'STATUS_DISPOSED', '2': 4},
  ],
};

const ExpandFields$json = const {
  '1': 'ExpandFields',
  '2': const [
    const {'1': 'EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'EXPAND_FIELDS_REPO', '2': 2},
  ],
};

const AddTrackingsRequest$json = const {
  '1': 'AddTrackingsRequest',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {
      '1': 'expand',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.app.sarsys.tracking.ExpandFields',
      '10': 'expand'
    },
  ],
};

const AddTrackingsResponse$json = const {
  '1': 'AddTrackingsResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'failed', '3': 2, '4': 3, '5': 9, '10': 'failed'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.GetMetaResponse',
      '10': 'meta'
    },
  ],
};

const StartTrackingRequest$json = const {
  '1': 'StartTrackingRequest',
  '2': const [
    const {
      '1': 'expand',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.app.sarsys.tracking.ExpandFields',
      '10': 'expand'
    },
  ],
};

const StartTrackingResponse$json = const {
  '1': 'StartTrackingResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.GetMetaResponse',
      '10': 'meta'
    },
  ],
};

const StopTrackingRequest$json = const {
  '1': 'StopTrackingRequest',
  '2': const [
    const {
      '1': 'expand',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.app.sarsys.tracking.ExpandFields',
      '10': 'expand'
    },
  ],
};

const StopTrackingResponse$json = const {
  '1': 'StopTrackingResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.GetMetaResponse',
      '10': 'meta'
    },
  ],
};

const RemoveTrackingsRequest$json = const {
  '1': 'RemoveTrackingsRequest',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {
      '1': 'expand',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.app.sarsys.tracking.ExpandFields',
      '10': 'expand'
    },
  ],
};

const RemoveTrackingsResponse$json = const {
  '1': 'RemoveTrackingsResponse',
  '2': const [
    const {'1': 'uuids', '3': 1, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'failed', '3': 2, '4': 3, '5': 9, '10': 'failed'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.GetMetaResponse',
      '10': 'meta'
    },
  ],
};

const GetMetaRequest$json = const {
  '1': 'GetMetaRequest',
  '2': const [
    const {
      '1': 'expand',
      '3': 1,
      '4': 3,
      '5': 14,
      '6': '.app.sarsys.tracking.ExpandFields',
      '10': 'expand'
    },
  ],
};

const GetMetaResponse$json = const {
  '1': 'GetMetaResponse',
  '2': const [
    const {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.app.sarsys.tracking.TrackingServerStatus',
      '10': 'status'
    },
    const {
      '1': 'trackings',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.TrackingsMeta',
      '10': 'trackings'
    },
    const {
      '1': 'positions',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.PositionsMeta',
      '10': 'positions'
    },
    const {
      '1': 'managerOf',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.app.sarsys.tracking.TrackingMeta',
      '10': 'managerOf'
    },
    const {
      '1': 'repo',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.RepositoryMeta',
      '10': 'repo'
    },
  ],
};

const TrackingMeta$json = const {
  '1': 'TrackingMeta',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'trackCount', '3': 2, '4': 1, '5': 3, '10': 'trackCount'},
    const {'1': 'positionCount', '3': 3, '4': 1, '5': 3, '10': 'positionCount'},
    const {
      '1': 'lastEvent',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.EventMeta',
      '10': 'lastEvent'
    },
  ],
};

const TrackingsMeta$json = const {
  '1': 'TrackingsMeta',
  '2': const [
    const {'1': 'total', '3': 1, '4': 1, '5': 3, '10': 'total'},
    const {
      '1': 'fractionManaged',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'fractionManaged'
    },
    const {
      '1': 'eventsPerMinute',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'eventsPerMinute'
    },
    const {
      '1': 'averageProcessingTimeMillis',
      '3': 4,
      '4': 1,
      '5': 5,
      '10': 'averageProcessingTimeMillis'
    },
    const {
      '1': 'lastEvent',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.EventMeta',
      '10': 'lastEvent'
    },
  ],
};

const PositionsMeta$json = const {
  '1': 'PositionsMeta',
  '2': const [
    const {'1': 'total', '3': 1, '4': 1, '5': 3, '10': 'total'},
    const {
      '1': 'eventsPerMinute',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'eventsPerMinute'
    },
    const {
      '1': 'averageProcessingTimeMillis',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'averageProcessingTimeMillis'
    },
    const {
      '1': 'lastEvent',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.EventMeta',
      '10': 'lastEvent'
    },
  ],
};

const EventMeta$json = const {
  '1': 'EventMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'remote', '3': 3, '4': 1, '5': 8, '10': 'remote'},
    const {'1': 'number', '3': 4, '4': 1, '5': 3, '10': 'number'},
    const {'1': 'position', '3': 5, '4': 1, '5': 3, '10': 'position'},
    const {'1': 'timestamp', '3': 6, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

const RepositoryMeta$json = const {
  '1': 'RepositoryMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {
      '1': 'lastEvent',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.EventMeta',
      '10': 'lastEvent'
    },
    const {
      '1': 'queue',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.RepositoryQueueMeta',
      '10': 'queue'
    },
  ],
};

const RepositoryQueueMeta$json = const {
  '1': 'RepositoryQueueMeta',
  '2': const [
    const {
      '1': 'pressure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.RepositoryQueuePressureMeta',
      '10': 'pressure'
    },
    const {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.app.sarsys.tracking.RepositoryQueueStatusMeta',
      '10': 'status'
    },
  ],
};

const RepositoryQueuePressureMeta$json = const {
  '1': 'RepositoryQueuePressureMeta',
  '2': const [
    const {'1': 'push', '3': 1, '4': 1, '5': 5, '10': 'push'},
    const {'1': 'commands', '3': 2, '4': 1, '5': 5, '10': 'commands'},
    const {'1': 'total', '3': 3, '4': 1, '5': 5, '10': 'total'},
    const {'1': 'maximum', '3': 4, '4': 1, '5': 5, '10': 'maximum'},
    const {'1': 'exceeded', '3': 5, '4': 1, '5': 8, '10': 'exceeded'},
  ],
};

const RepositoryQueueStatusMeta$json = const {
  '1': 'RepositoryQueueStatusMeta',
  '2': const [
    const {'1': 'idle', '3': 1, '4': 1, '5': 8, '10': 'idle'},
    const {'1': 'ready', '3': 2, '4': 1, '5': 8, '10': 'ready'},
    const {'1': 'disposed', '3': 3, '4': 1, '5': 8, '10': 'disposed'},
  ],
};
