///
//  Generated code. Do not modify.
//  source: repository.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const RepoExpandFields$json = const {
  '1': 'RepoExpandFields',
  '2': const [
    const {'1': 'REPO_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'REPO_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'REPO_EXPAND_FIELDS_ITEMS', '2': 2},
    const {'1': 'REPO_EXPAND_FIELDS_DATA', '2': 3},
    const {'1': 'REPO_EXPAND_FIELDS_METRICS', '2': 4},
    const {'1': 'REPO_EXPAND_FIELDS_QUEUE', '2': 5},
    const {'1': 'REPO_EXPAND_FIELDS_CONN', '2': 6},
    const {'1': 'REPO_EXPAND_FIELDS_SNAPSHOT', '2': 7},
  ],
};

const GetRepoMetaRequest$json = const {
  '1': 'GetRepoMetaRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {
      '1': 'expand',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.RepoExpandFields',
      '10': 'expand'
    },
  ],
};

const GetRepoMetaResponse$json = const {
  '1': 'GetRepoMetaResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 2, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 3, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMeta',
      '10': 'meta'
    },
  ],
};

const ReplayRepoEventsRequest$json = const {
  '1': 'ReplayRepoEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.RepoExpandFields',
      '10': 'expand'
    },
  ],
};

const ReplayRepoEventsResponse$json = const {
  '1': 'ReplayRepoEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMeta',
      '10': 'meta'
    },
  ],
};

const CatchupRepoEventsRequest$json = const {
  '1': 'CatchupRepoEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.RepoExpandFields',
      '10': 'expand'
    },
  ],
};

const CatchupRepoEventsResponse$json = const {
  '1': 'CatchupRepoEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuids', '3': 2, '4': 3, '5': 9, '10': 'uuids'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMeta',
      '10': 'meta'
    },
  ],
};

const RepairRepoRequest$json = const {
  '1': 'RepairRepoRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'master', '3': 2, '4': 1, '5': 8, '10': 'master'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.RepoExpandFields',
      '10': 'expand'
    },
  ],
};

const RepairRepoResponse$json = const {
  '1': 'RepairRepoResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMeta',
      '10': 'meta'
    },
    const {
      '1': 'before',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AnalysisMeta',
      '10': 'before'
    },
    const {
      '1': 'after',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AnalysisMeta',
      '10': 'after'
    },
  ],
};

const AnalysisMeta$json = const {
  '1': 'AnalysisMeta',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {'1': 'wrong', '3': 2, '4': 1, '5': 5, '10': 'wrong'},
    const {'1': 'multiple', '3': 3, '4': 1, '5': 5, '10': 'multiple'},
    const {'1': 'summary', '3': 4, '4': 3, '5': 9, '10': 'summary'},
  ],
};

const RebuildRepoRequest$json = const {
  '1': 'RebuildRepoRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'master', '3': 2, '4': 1, '5': 8, '10': 'master'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.RepoExpandFields',
      '10': 'expand'
    },
  ],
};

const RebuildRepoResponse$json = const {
  '1': 'RebuildRepoResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMeta',
      '10': 'meta'
    },
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
      '6': '.org.discoos.es.EventMeta',
      '10': 'lastEvent'
    },
    const {
      '1': 'queue',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryQueueMeta',
      '10': 'queue'
    },
    const {
      '1': 'metrics',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMetricsMeta',
      '10': 'metrics'
    },
    const {
      '1': 'connection',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.ConnectionMetricsMeta',
      '10': 'connection'
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
      '6': '.org.discoos.es.RepositoryQueuePressureMeta',
      '10': 'pressure'
    },
    const {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryQueueStatusMeta',
      '10': 'status'
    },
    const {
      '1': 'metrics',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMetricsMeta',
      '10': 'metrics'
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

const RepositoryMetricsMeta$json = const {
  '1': 'RepositoryMetricsMeta',
  '2': const [
    const {'1': 'events', '3': 1, '4': 1, '5': 3, '10': 'events'},
    const {'1': 'transactions', '3': 2, '4': 1, '5': 5, '10': 'transactions'},
    const {
      '1': 'aggregates',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.RepositoryMetricsAggregateMeta',
      '10': 'aggregates'
    },
    const {
      '1': 'push',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.DurationMetricMeta',
      '10': 'push'
    },
  ],
};

const RepositoryMetricsAggregateMeta$json = const {
  '1': 'RepositoryMetricsAggregateMeta',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {'1': 'changed', '3': 2, '4': 1, '5': 5, '10': 'changed'},
    const {
      '1': 'tainted',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMetaList',
      '10': 'tainted'
    },
    const {
      '1': 'cordoned',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMetaList',
      '10': 'cordoned'
    },
  ],
};

const ConnectionMetricsMeta$json = const {
  '1': 'ConnectionMetricsMeta',
  '2': const [
    const {
      '1': 'read',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.DurationMetricMeta',
      '10': 'read'
    },
    const {
      '1': 'write',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.DurationMetricMeta',
      '10': 'write'
    },
  ],
};
