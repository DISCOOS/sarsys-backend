import 'package:grpc/grpc.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';

import 'generated/sarsys_tracking_service.pbgrpc.dart';

class SarSysTrackingGrpcService extends SarSysTrackingServiceBase {
  SarSysTrackingGrpcService(this.server);
  final SarSysTrackingServer server;
  TrackingService get service => server.service;
  final logger = Logger('$SarSysTrackingGrpcService');

  @override
  Future<GetMetaResponse> getMeta(ServiceCall call, GetMetaRequest request) async {
    final response = await _getMetaData(request.expand);
    _ok('getMeta');
    return response;
  }

  Future<GetMetaResponse> _getMetaData(List<ExpandFields> expand) async {
    logger.fine(
      Context.toMethod('_getMetaData', ['expand: ${expand.map(enumName).join(',')}']),
    );
    var positionsTotal = 0;
    final repo = service.repo;
    final store = repo.store;
    final total = repo.count();
    final managed = service.managed;
    final response = GetMetaResponse()
      ..total = total
      ..status = toServiceStatus()
      ..managerOf.addAll(managed.map((uuid) {
        final tracking = repo.get(uuid);
        final data = tracking.data;
        final tracks = data.listAt<Map>('tracks', defaultList: []);
        final positionCount = tracks.fold<int>(
          0,
          (previous, track) => previous + track.listAt('positions', defaultList: []).length,
        );
        positionsTotal += positionCount;
        return TrackingMeta()
          ..uuid = uuid
          ..lastEvent = toEventMeta(
            tracking.baseEvent,
            store,
          )
          ..trackCount = tracks.length
          ..positionCount = positionCount;
      }))
      ..positions = (PositionsMeta()
        ..positionsPerMinute = 0
        ..total = positionsTotal
        ..averageProcessingTimeMillis = 0
        ..lastEvent = toEventMeta(
          service.lastEvent,
          store,
        ))
      ..fractionManaged = total > 0 ? managed.length / total : 0;
    if (expand.contains(ExpandFields.EXPAND_FIELDS_REPO)) {
      final meta = await repo.toMeta(
        data: false,
        metrics: false,
        snapshot: false,
        connection: false,
        subscriptions: false,
      );
      final status = meta.mapAt<String, dynamic>('queue/status');
      final pressure = meta.mapAt<String, dynamic>('queue/pressure');
      final lastEvent = store.isEmpty ? null : store.getEvent(store.eventMap.keys.last);
      response.repo = RepositoryMeta()
        ..type = meta.elementAt<String>('type')
        ..lastEvent = toEventMeta(lastEvent, store)
        ..queue = (RepositoryQueueMeta()
          ..status = (RepositoryQueueStatusMeta()
            ..idle = status.elementAt<bool>('idle')
            ..ready = status.elementAt<bool>('ready')
            ..disposed = status.elementAt<bool>('disposed'))
          ..pressure = (RepositoryQueuePressureMeta()
            ..total = pressure.elementAt<int>('total')
            ..maximum = pressure.elementAt<int>('maximum')
            ..commands = pressure.elementAt<int>('command')
            ..exceeded = pressure.elementAt<bool>('exceeded')));
    }
    return response;
  }

  TrackingServerStatus toServiceStatus() {
    if (service == null) {
      return TrackingServerStatus.STATUS_NONE;
    }
    if (service.isPaused) {
      return TrackingServerStatus.STATUS_STOPPED;
    }
    if (service.isCompeting) {
      return TrackingServerStatus.STATUS_COMPETING;
    }
    if (service.isDisposed) {
      return TrackingServerStatus.STATUS_DISPOSED;
    }
    return TrackingServerStatus.STATUS_READY;
  }

  EventMeta toEventMeta(Event event, EventStore store) {
    final meta = EventMeta()
      ..number = EventNumber.none.value
      ..position = EventNumber.none.value;
    if (event != null) {
      meta
        ..uuid = event.uuid
        ..type = event.type
        ..remote = event.remote
        ..number = event.number.value
        ..position = store.toPosition(event);
    }
    return meta;
  }

  @override
  Future<StartTrackingResponse> start(ServiceCall call, StartTrackingRequest request) async {
    logger.fine(
      Context.toMethod('start', ['expand: ${request.expand.map(enumName).join(',')}']),
    );
    final ok = await service.start();
    final response = StartTrackingResponse()
      ..meta = await _getMetaData(request.expand)
      ..statusCode = ok ? HttpStatus.ok : HttpStatus.internalServerError
      ..reasonPhrase = ok ? 'OK' : 'Unable to start tracking service';
    _log(
      'start',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  @override
  Future<StopTrackingResponse> stop(ServiceCall call, StopTrackingRequest request) async {
    logger.fine(
      Context.toMethod('start', ['expand: ${request.expand.map(enumName).join(',')}']),
    );
    final ok = await service.stop();
    final response = StopTrackingResponse()
      ..meta = await _getMetaData(request.expand)
      ..statusCode = ok ? HttpStatus.ok : HttpStatus.internalServerError
      ..reasonPhrase = ok ? 'OK' : 'Unable to stop tracking service';
    _log(
      'start',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  @override
  Future<AddTrackingsResponse> addTrackings(ServiceCall call, AddTrackingsRequest request) async {
    final failed = <String>[];
    final uuids = request.uuids;
    logger.fine(
      Context.toMethod('addTrackings', [
        'uuids: ${uuids.join(',')}',
        'expand: ${request.expand.map(enumName).join(',')}',
      ]),
    );
    for (var uuid in uuids) {
      if (!service.isManagerOf(uuid)) {
        final ok = await service.addTracking(uuid);
        if (!ok) {
          failed.add(uuid);
        }
      }
    }
    final response = AddTrackingsResponse()
      ..uuids.addAll(uuids)
      ..failed.addAll(failed)
      ..meta = await _getMetaData(request.expand);
    if (failed.isEmpty) {
      _ok('addTrackings');
      return response
        ..statusCode = HttpStatus.ok
        ..reasonPhrase = 'OK';
    } else if (failed.length < uuids.length) {
      _partial(
        'addTrackings',
        'Failed to add: ${failed.join(',')}',
      );
      return response
        ..statusCode = HttpStatus.partialContent
        ..reasonPhrase = 'Failed to add: ${failed.join(',')}';
    }
    _notFound(
      'addTrackings',
      'Not found: ${failed.join(',')}',
    );
    return response
      ..failed.addAll(failed)
      ..reasonPhrase = 'Not found: ${failed.join(',')}'
      ..statusCode = HttpStatus.notFound;
  }

  @override
  Future<RemoveTrackingsResponse> removeTrackings(ServiceCall call, RemoveTrackingsRequest request) async {
    final failed = <String>[];
    final uuids = request.uuids;
    logger.fine(
      Context.toMethod('removeTrackings', [
        'uuids: ${uuids.join(',')}',
        'expand: ${request.expand.map(enumName).join(',')}',
      ]),
    );

    for (var uuid in uuids) {
      final ok = await service.removeTracking(uuid);
      if (!ok) {
        failed.add(uuid);
      }
    }
    final response = RemoveTrackingsResponse()
      ..uuids.addAll(uuids)
      ..failed.addAll(failed)
      ..meta = await _getMetaData(request.expand);
    if (failed.isEmpty) {
      _ok('removeTrackings');
      return response
        ..statusCode = HttpStatus.ok
        ..reasonPhrase = 'OK';
    }
    if (failed.length < uuids.length) {
      _partial(
        'removeTrackings',
        'Failed to remove: ${failed.join(',')}',
      );
      return response
        ..statusCode = HttpStatus.partialContent
        ..reasonPhrase = 'Failed to remove: ${failed.join(',')}';
    }
    _notFound(
      'removeTrackings',
      'Not found: ${uuids.join(',')}',
    );
    return response
      ..statusCode = HttpStatus.notFound
      ..reasonPhrase = 'Not found: ${uuids.join(',')}';
  }

  String _ok(String method) {
    return _log(
      method,
      HttpStatus.ok,
      'OK',
    );
  }

  String _partial(String method, String message) {
    return _log(
      method,
      HttpStatus.partialContent,
      message,
    );
  }

  String _notFound(String method, String message) {
    return _log(
      method,
      HttpStatus.notFound,
      message,
    );
  }

  String _log(String method, int statusCode, String reasonPhrase, [Object error, StackTrace stackTrace]) {
    final message = '$method $statusCode $reasonPhrase';
    if (statusCode > 500) {
      logger.severe(
        message,
        error,
        stackTrace,
      );
    } else {
      logger.info(
        '$method $statusCode $reasonPhrase',
        error,
        stackTrace,
      );
    }
    return message;
  }
}
