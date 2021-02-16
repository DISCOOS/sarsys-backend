///
//  Generated code. Do not modify.
//  source: tracking_service.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const TrackingServerStatus$json = const {
  '1': 'TrackingServerStatus',
  '2': const [
    const {'1': 'TRACKING_STATUS_NONE', '2': 0},
    const {'1': 'TRACKING_STATUS_READY', '2': 1},
    const {'1': 'TRACKING_STATUS_STARTED', '2': 2},
    const {'1': 'TRACKING_STATUS_STOPPED', '2': 3},
    const {'1': 'TRACKING_STATUS_DISPOSED', '2': 4},
  ],
};

const TrackingExpandFields$json = const {
  '1': 'TrackingExpandFields',
  '2': const [
    const {'1': 'TRACKING_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'TRACKING_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO', '2': 2},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_ITEMS', '2': 3},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_DATA', '2': 4},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_METRICS', '2': 5},
    const {'1': 'TRACKING_EXPAND_FIELDS_REPO_QUEUE', '2': 6},
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
      '6': '.app.sarsys.tracking.TrackingExpandFields',
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
      '6': '.app.sarsys.tracking.GetTrackingMetaResponse',
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
      '6': '.app.sarsys.tracking.TrackingExpandFields',
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
      '6': '.app.sarsys.tracking.GetTrackingMetaResponse',
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
      '6': '.app.sarsys.tracking.TrackingExpandFields',
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
      '6': '.app.sarsys.tracking.GetTrackingMetaResponse',
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
      '6': '.app.sarsys.tracking.TrackingExpandFields',
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
      '6': '.app.sarsys.tracking.GetTrackingMetaResponse',
      '10': 'meta'
    },
  ],
};

const GetTrackingMetaRequest$json = const {
  '1': 'GetTrackingMetaRequest',
  '2': const [
    const {
      '1': 'expand',
      '3': 1,
      '4': 3,
      '5': 14,
      '6': '.app.sarsys.tracking.TrackingExpandFields',
      '10': 'expand'
    },
  ],
};

const GetTrackingMetaResponse$json = const {
  '1': 'GetTrackingMetaResponse',
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
      '6': '.org.discoos.es.RepositoryMeta',
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
      '6': '.org.discoos.es.EventMeta',
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
      '6': '.org.discoos.es.EventMeta',
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
      '6': '.org.discoos.es.EventMeta',
      '10': 'lastEvent'
    },
  ],
};
