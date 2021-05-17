import 'package:meta/meta.dart';
import 'package:event_source/event_source.dart';

import 'models/subscription_model.dart';

class WebSocketMessage extends Event {
  WebSocketMessage({
    @required this.appId,
    @required String uuid,
    @required String type,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
          local: false,
          created: DateTime.now(),
          number: EventNumber.none,
        );

  final String appId;

  @override
  String toString() {
    return '$runtimeType {appId: $appId, uuid: $uuid, type: $type, data: $data}';
  }
}

class WebSocketSubscribeMessage extends WebSocketMessage {
  WebSocketSubscribeMessage({
    @required String appId,
    @required String uuid,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          data: data,
          appId: appId,
          type: 'Subscribe',
        );

  SubscriptionModel get config => SubscriptionModel.fromJson(data);

  @override
  String toString() {
    return '$runtimeType {uuid: $uuid, type: $type, data: $data}';
  }
}

class WebSocketStatusMessage extends WebSocketMessage {
  WebSocketStatusMessage({
    @required String appId,
    @required String uuid,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          data: data,
          appId: appId,
          type: 'Status',
        );

  @override
  String toString() {
    return '$runtimeType {uuid: $uuid, type: $type, data: $data}';
  }
}

class WebSocketErrorMessage extends WebSocketMessage {
  WebSocketErrorMessage({
    @required int code,
    @required String uuid,
    @required String appId,
    @required String reason,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) : super(
          appId: appId,
          uuid: uuid,
          type: 'Error',
          data: Map.from(data)
            ..addAll({
              'code': code,
              'reason': reason,
            }),
        );

  static const invalidFormat = 4001;

  @override
  String toString() {
    return '$runtimeType {uuid: $uuid, type: $type, data: $data}';
  }
}
