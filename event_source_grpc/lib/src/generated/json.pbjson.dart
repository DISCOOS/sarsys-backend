///
//  Generated code. Do not modify.
//  source: json.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

const JsonDataCompression$json = const {
  '1': 'JsonDataCompression',
  '2': const [
    const {'1': 'JSON_DATA_COMPRESSION_NONE', '2': 0},
    const {'1': 'JSON_DATA_COMPRESSION_ZLIB', '2': 1},
    const {'1': 'JSON_DATA_COMPRESSION_GZIP', '2': 2},
  ],
};

const JsonValue$json = const {
  '1': 'JsonValue',
  '2': const [
    const {
      '1': 'compression',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.org.discoos.io.JsonDataCompression',
      '10': 'compression'
    },
    const {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

const JsonMatchList$json = const {
  '1': 'JsonMatchList',
  '2': const [
    const {'1': 'count', '3': 1, '4': 1, '5': 5, '10': 'count'},
    const {'1': 'query', '3': 2, '4': 1, '5': 9, '10': 'query'},
    const {
      '1': 'items',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.org.discoos.io.JsonMatch',
      '10': 'items'
    },
  ],
};

const JsonMatch$json = const {
  '1': 'JsonMatch',
  '2': const [
    const {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    const {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    const {
      '1': 'value',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.org.discoos.io.JsonValue',
      '10': 'value'
    },
  ],
};
