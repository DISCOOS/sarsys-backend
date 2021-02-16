import 'package:grpc/grpc.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_tracking_server/sarsys_tracking_server.dart';

import 'package:fixnum/fixnum.dart';

import 'generated/tracking_service.pbgrpc.dart';
import 'utils.dart';

class SarSysTrackingGrpcService extends SarSysTrackingServiceBase {
  SarSysTrackingGrpcService(this.server);
  final SarSysTrackingServer server;
  TrackingService get service => server.service;
  final logger = Logger('$SarSysTrackingGrpcService');

  @override
  Future<GetTrackingMetaResponse> getMeta(ServiceCall call, GetTrackingMetaRequest request) async {
    final response = await _getMetaData(request.expand);
    _ok('getMeta');
    return response;
  }

  Future<GetTrackingMetaResponse> _getMetaData(List<TrackingExpandFields> expand) async {
    logger.fine(
      Context.toMethod('_getMetaData', ['expand: ${expand.map(enumName).join(',')}']),
    );
    var positionsTotal = 0;
    final repo = service.repo;
    final store = repo.store;
    final total = repo.count();
    final managed = service.managed;
    final response = GetTrackingMetaResponse()
      ..status = _toServiceStatus()
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
          ..lastEvent = toEventMetaFromEvent(
            tracking.baseEvent,
            store,
          )
          ..trackCount = Int64(tracks.length)
          ..positionCount = Int64(positionCount);
      }))
      ..positions = (PositionsMeta()
        ..total = Int64(positionsTotal)
        ..eventsPerMinute = service.positionMetrics.rateExp * 60.0
        ..averageProcessingTimeMillis = service.positionMetrics.meanExp.inMilliseconds
        ..lastEvent = toEventMetaFromEvent(
          service.lastPositionEvent,
          store,
        ))
      ..trackings = (TrackingsMeta()
        ..total = Int64(total)
        ..eventsPerMinute = service.trackingMetrics.rateExp * 60.0
        ..averageProcessingTimeMillis = service.trackingMetrics.meanExp.inMilliseconds
        ..lastEvent = toEventMetaFromEvent(
          service.lastTrackingEvent,
          store,
        )
        ..fractionManaged = total > 0 ? managed.length / total : 0);
    if (withRepoField(expand, TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO)) {
      final meta = await repo.toMeta(
        data: withRepoField(
          expand,
          TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_DATA,
        ),
        items: withRepoField(
          expand,
          TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_ITEMS,
        ),
        queue: withRepoField(
          expand,
          TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_QUEUE,
        ),
        metrics: withRepoField(
          expand,
          TrackingExpandFields.TRACKING_EXPAND_FIELDS_REPO_METRICS,
        ),
        snapshot: false,
        connection: false,
        subscriptions: false,
      );
      response.repo = toRepoMeta(
        meta,
        store,
      );
    }
    return response;
  }

  bool withRepoField(List<TrackingExpandFields> expand, TrackingExpandFields field) =>
      expand.contains(TrackingExpandFields.TRACKING_EXPAND_FIELDS_ALL) || expand.contains(field);

  TrackingServerStatus _toServiceStatus() {
    if (service == null) {
      return TrackingServerStatus.TRACKING_STATUS_NONE;
    }
    if (service.isPaused) {
      return TrackingServerStatus.TRACKING_STATUS_STOPPED;
    }
    if (service.isStarted) {
      return TrackingServerStatus.TRACKING_STATUS_STARTED;
    }
    if (service.isDisposed) {
      return TrackingServerStatus.TRACKING_STATUS_DISPOSED;
    }
    return TrackingServerStatus.TRACKING_STATUS_READY;
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
    final response = StopTrackingResponse();
    if (service.isStarted) {
      final ok = await service.stop();
      response
        ..meta = await _getMetaData(request.expand)
        ..statusCode = ok ? HttpStatus.ok : HttpStatus.internalServerError
        ..reasonPhrase = ok ? 'OK' : 'Unable to stop tracking service';
    } else {
      response
        ..meta = await _getMetaData(request.expand)
        ..statusCode = HttpStatus.badRequest
        ..reasonPhrase = 'Not started';
    }
    _log(
      'stop',
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
