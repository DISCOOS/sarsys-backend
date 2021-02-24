import 'dart:convert';
import 'dart:io';

import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:grpc/grpc.dart';
import 'package:test/test.dart';

void main() {
  test('ReplaceData is binary stable', () async {
    // Arrange
    const uuid = '72c3812c-8099-4939-99e3-911fdcdb7695';
    const path = '/Users/kengu/src/git/sarsys-backend/sarsys_ops_cli/tracking-app-0.json';
    final json = File(path).readAsStringSync();
    final data = jsonDecode(json);

    final channel = ClientChannel(
      InternetAddress.anyIPv4,
      port: 8888,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    final client = AggregateGrpcServiceClient(
      channel,
      options: CallOptions(
        timeout: const Duration(
          seconds: 10,
        ),
      ),
    );

    // Act
    final response = await client.replaceData(
      ReplaceAggregateDataRequest()
        ..type = 'Tracking'
        ..uuid = uuid
        ..data = toAnyFromJson(data)
        ..expand.add(
          AggregateExpandFields.AGGREGATE_EXPAND_FIELDS_DATA,
        ),
    );

    // Assert
    expect(response.type, 'Tracking');
    expect(response.uuid, uuid);
    expect(response.statusCode, 200);
    expect(response.reasonPhrase, 'OK');
    expect(toJsonFromAny(response.meta.data), equals(data));

    await channel.shutdown();
  });
}
