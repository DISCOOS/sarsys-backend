///
//  Generated code. Do not modify.
//  source: snapshot.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const SnapshotExpandFields$json = const {
  '1': 'SnapshotExpandFields',
  '2': const [
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_ITEMS', '2': 2},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_DATA', '2': 3},
    const {'1': 'SNAPSHOT_EXPAND_FIELDS_METRICS', '2': 4},
  ],
};

const GetSnapshotMetaRequest$json = const {
  '1': 'GetSnapshotMetaRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {
      '1': 'expand',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.SnapshotExpandFields',
      '10': 'expand'
    },
  ],
};

const GetSnapshotMetaResponse$json = const {
  '1': 'GetSnapshotMetaResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};

const SnapshotMeta$json = const {
  '1': 'SnapshotMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'last', '3': 3, '4': 1, '5': 9, '10': 'last'},
    const {'1': 'number', '3': 4, '4': 1, '5': 3, '10': 'number'},
    const {'1': 'position', '3': 5, '4': 1, '5': 3, '10': 'position'},
    const {
      '1': 'config',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotConfig',
      '10': 'config'
    },
    const {
      '1': 'metrics',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMetricsMeta',
      '10': 'metrics'
    },
    const {
      '1': 'aggregates',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMetaList',
      '10': 'aggregates'
    },
  ],
};

const SnapshotConfig$json = const {
  '1': 'SnapshotConfig',
  '2': const [
    const {'1': 'keep', '3': 1, '4': 1, '5': 5, '10': 'keep'},
    const {'1': 'threshold', '3': 2, '4': 1, '5': 5, '10': 'threshold'},
    const {'1': 'automatic', '3': 3, '4': 1, '5': 8, '10': 'automatic'},
  ],
};

const SnapshotMetricsMeta$json = const {
  '1': 'SnapshotMetricsMeta',
  '2': const [
    const {'1': 'snapshots', '3': 1, '4': 1, '5': 3, '10': 'snapshots'},
    const {'1': 'unsaved', '3': 2, '4': 1, '5': 3, '10': 'unsaved'},
    const {'1': 'missing', '3': 3, '4': 1, '5': 3, '10': 'missing'},
    const {'1': 'isPartial', '3': 4, '4': 1, '5': 8, '10': 'isPartial'},
    const {
      '1': 'save',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.DurationMetricMeta',
      '10': 'save'
    },
  ],
};

const ConfigureSnapshotRequest$json = const {
  '1': 'ConfigureSnapshotRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'automatic', '3': 2, '4': 1, '5': 8, '10': 'automatic'},
    const {'1': 'keep', '3': 3, '4': 1, '5': 5, '10': 'keep'},
    const {'1': 'threshold', '3': 4, '4': 1, '5': 5, '10': 'threshold'},
    const {
      '1': 'expand',
      '3': 5,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.SnapshotExpandFields',
      '10': 'expand'
    },
  ],
};

const ConfigureSnapshotResponse$json = const {
  '1': 'ConfigureSnapshotResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};

const SaveSnapshotRequest$json = const {
  '1': 'SaveSnapshotRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'force', '3': 2, '4': 1, '5': 8, '10': 'force'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.SnapshotExpandFields',
      '10': 'expand'
    },
  ],
};

const SaveSnapshotResponse$json = const {
  '1': 'SaveSnapshotResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};

const DownloadSnapshotRequest$json = const {
  '1': 'DownloadSnapshotRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'chunkSize', '3': 2, '4': 1, '5': 4, '10': 'chunkSize'},
  ],
};

const SnapshotChunk$json = const {
  '1': 'SnapshotChunk',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {
      '1': 'chunk',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.io.FileChunk',
      '10': 'chunk'
    },
  ],
};

const UploadSnapshotResponse$json = const {
  '1': 'UploadSnapshotResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'chunkSize', '3': 2, '4': 1, '5': 4, '10': 'chunkSize'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.SnapshotMeta',
      '10': 'meta'
    },
  ],
};
