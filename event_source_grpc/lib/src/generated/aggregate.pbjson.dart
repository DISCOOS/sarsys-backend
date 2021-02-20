///
//  Generated code. Do not modify.
//  source: aggregate.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const AggregateExpandFields$json = const {
  '1': 'AggregateExpandFields',
  '2': const [
    const {'1': 'AGGREGATE_EXPAND_FIELDS_NONE', '2': 0},
    const {'1': 'AGGREGATE_EXPAND_FIELDS_ALL', '2': 1},
    const {'1': 'AGGREGATE_EXPAND_FIELDS_DATA', '2': 2},
    const {'1': 'AGGREGATE_EXPAND_FIELDS_ITEMS', '2': 3},
  ],
};

const GetAggregateMetaRequest$json = const {
  '1': 'GetAggregateMetaRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
  ],
};

const GetAggregateMetaResponse$json = const {
  '1': 'GetAggregateMetaResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

const ReplayAggregateEventsRequest$json = const {
  '1': 'ReplayAggregateEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
  ],
};

const ReplayAggregateEventsResponse$json = const {
  '1': 'ReplayAggregateEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

const CatchupAggregateEventsRequest$json = const {
  '1': 'CatchupAggregateEventsRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
  ],
};

const CatchupAggregateEventsResponse$json = const {
  '1': 'CatchupAggregateEventsResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

const ReplaceAggregateDataRequest$json = const {
  '1': 'ReplaceAggregateDataRequest',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {
      '1': 'expand',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.org.discoos.es.AggregateExpandFields',
      '10': 'expand'
    },
    const {
      '1': 'data',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'data'
    },
    const {
      '1': 'patches',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'patches'
    },
  ],
};

const ReplaceAggregateDataResponse$json = const {
  '1': 'ReplaceAggregateDataResponse',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'statusCode', '3': 3, '4': 1, '5': 5, '10': 'statusCode'},
    const {'1': 'reasonPhrase', '3': 4, '4': 1, '5': 9, '10': 'reasonPhrase'},
    const {
      '1': 'meta',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'meta'
    },
  ],
};

const AggregateMetaList$json = const {
  '1': 'AggregateMetaList',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.org.discoos.es.AggregateMeta',
      '10': 'items'
    },
  ],
};

const AggregateMeta$json = const {
  '1': 'AggregateMeta',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'number', '3': 3, '4': 1, '5': 3, '10': 'number'},
    const {'1': 'position', '3': 4, '4': 1, '5': 3, '10': 'position'},
    const {
      '1': 'createdBy',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMeta',
      '10': 'createdBy'
    },
    const {
      '1': 'changedBy',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMeta',
      '10': 'changedBy'
    },
    const {
      '1': 'deletedBy',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMeta',
      '10': 'deletedBy'
    },
    const {
      '1': 'applied',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMetaList',
      '10': 'applied'
    },
    const {
      '1': 'pending',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMetaList',
      '10': 'pending'
    },
    const {
      '1': 'skipped',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.EventMetaList',
      '10': 'skipped'
    },
    const {
      '1': 'taint',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'taint'
    },
    const {
      '1': 'cordon',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'cordon'
    },
    const {
      '1': 'data',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Value',
      '10': 'data'
    },
  ],
};
