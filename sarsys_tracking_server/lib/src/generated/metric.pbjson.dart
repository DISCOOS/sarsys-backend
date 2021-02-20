///
//  Generated code. Do not modify.
//  source: metric.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const DurationMetricMeta$json = const {
  '1': 'DurationMetricMeta',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 3, '10': 'count'},
    const {
      '1': 't0',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 't0'
    },
    const {
      '1': 'tn',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'tn'
    },
    const {'1': 'last', '3': 4, '4': 1, '5': 3, '10': 'last'},
    const {'1': 'total', '3': 5, '4': 1, '5': 3, '10': 'total'},
    const {
      '1': 'cumulative',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.DurationCumulativeAverage',
      '10': 'cumulative'
    },
    const {
      '1': 'exponential',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.es.DurationExponentialAverage',
      '10': 'exponential'
    },
  ],
};

const DurationCumulativeAverage$json = const {
  '1': 'DurationCumulativeAverage',
  '2': const [
    const {'1': 'rate', '3': 1, '4': 1, '5': 1, '10': 'rate'},
    const {'1': 'mean', '3': 2, '4': 1, '5': 3, '10': 'mean'},
    const {'1': 'variance', '3': 3, '4': 1, '5': 1, '10': 'variance'},
    const {'1': 'deviation', '3': 4, '4': 1, '5': 1, '10': 'deviation'},
  ],
};

const DurationExponentialAverage$json = const {
  '1': 'DurationExponentialAverage',
  '2': const [
    const {'1': 'alpha', '3': 1, '4': 1, '5': 1, '10': 'alpha'},
    const {'1': 'beta', '3': 2, '4': 1, '5': 1, '10': 'beta'},
    const {'1': 'rate', '3': 3, '4': 1, '5': 1, '10': 'rate'},
    const {'1': 'mean', '3': 4, '4': 1, '5': 3, '10': 'mean'},
    const {'1': 'variance', '3': 5, '4': 1, '5': 1, '10': 'variance'},
    const {'1': 'deviation', '3': 6, '4': 1, '5': 1, '10': 'deviation'},
  ],
};
