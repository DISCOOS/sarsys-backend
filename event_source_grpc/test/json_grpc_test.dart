import 'dart:convert';
import 'package:lzstring/lzstring.dart';

import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  test('JsonData is binary stable', () async {
    // Arrange
    var tic = DateTime.now();
    final data = _generateMap(10000);
    final json = jsonEncode(data);
    var toc = DateTime.now();
    print('>> Data creation took ${toc.difference(tic).inMilliseconds}ms\n\n');

    print('Encode utf8 uncompressed');
    tic = toc;
    final ubytes = utf8.encode(json);
    toc = DateTime.now();
    print('>> uncompressed:characters: ${json.length}');
    print('>> uncompressed:bytes ${ubytes.length}');
    print('>> utf8 decode took ${toc.difference(tic).inMilliseconds}ms\n\n');

    print('Encode compressed with lz');
    tic = toc;
    final lzs = await LZString.compress(json);
    print(
      '>> lz:compressed:characters: ${lzs.length} ('
      '${((1 - lzs.length / json.length) * 100).toStringAsFixed(1)} %'
      ')',
    );
    toc = DateTime.now();
    print('>> lz string took ${toc.difference(tic).inMilliseconds}ms\n\n');

    print('Encode utf8 gzip compressed');
    tic = toc;
    final gbytes = toJsonValueBytes(
      data,
      JsonDataCompression.JSON_DATA_COMPRESSION_GZIP,
    );
    print(
      '>> gzip:compressed:bytes ${gbytes.length} ('
      '${((1 - gbytes.length / ubytes.length) * 100).toStringAsFixed(1)}%'
      ')',
    );
    toc = DateTime.now();
    print('>> utf8+gzip encode took ${toc.difference(tic).inMilliseconds}ms\n\n');

    print('Decode utf8 zlib compressed');
    tic = toc;
    final data2 = fromJsonDataBytes(
      gbytes,
      JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
    );
    toc = DateTime.now();
    print('>> utf8+zlib decode took ${toc.difference(tic).inMilliseconds}ms\n\n');
    expect(data2, data);

    print('Encode utf8 zlib compressed');
    tic = toc;
    final zbytes = toJsonValueBytes(
      data,
      JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
    );
    print(
      '>> zlib:compressed:bytes ${zbytes.length} ('
      '${((1 - zbytes.length / ubytes.length) * 100).toStringAsFixed(1)}%'
      ')',
    );
    toc = DateTime.now();
    print('>> utf8+zlib encode took ${toc.difference(tic).inMilliseconds}ms\n\n');

    print('Decode utf8 zlib compressed');
    tic = toc;
    final data3 = fromJsonDataBytes(
      zbytes,
      JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
    );
    toc = DateTime.now();
    print('>> utf8+zlib decode took ${toc.difference(tic).inMilliseconds}ms\n\n');
    expect(data3, data);
  });

  test('toProto3Json map bytes to json data', () {
    final data = _generateMap();
    final value = toJsonValue(data);
    final actual = Map.from(
      value.toProto3Json(),
    );
    expect(actual['data'], data);
    expect(
      actual['compression'],
      JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB.name,
    );
  });

  test('mergeFromProto3Json map json data to bytes', () {
    final data = _generateMap();
    final value = JsonValueWrapper();
    value.mergeFromProto3Json({
      'compression': JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB.name,
      'data': data,
    });
    expect(
      value.data,
      toJsonValueBytes(data),
    );
    expect(
      value.compression,
      JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB,
    );
  });

  test('Any unpacks JsonValue to json data', () {
    final data = _generateMap();
    final value = toAnyFromJson(data);
    final actual = value.toProto3Json(
      typeRegistry: TypeRegistry([
        JsonValueWrapper(),
      ]),
    );

    expect((actual as Map)['data'], data);
    expect(
      (actual as Map)['compression'],
      JsonDataCompression.JSON_DATA_COMPRESSION_ZLIB.name,
    );
  });
}

Map<String, dynamic> _generateMap([int size]) {
  final data = <String, dynamic>{
    'list': _generateList(size),
  };
  return data;
}

List<dynamic> _generateList(int size) => List.generate(
      10000,
      (index) => <String, dynamic>{
        'value': index,
        'list': [1, 2, 3]
      },
    );
