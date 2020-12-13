import 'package:event_source/event_source.dart';
import 'package:json_patch/json_patch.dart';
import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/Trackings](http://localhost/api/client.html#/Tracking) requests
class TrackingController extends AggregateController<TrackingCommand, Tracking> {
  TrackingController(TrackingRepository repository, JsonValidation validation)
      : super(
          repository,
          readOnly: const [
            'speed',
            'effort',
            'tracks',
            'history',
            'distance',
            'position',
          ],
          tag: "Trackings",
          validation: validation,
        );

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('deleted') bool deleted = false,
  }) {
    return super.getAll(
      offset: offset,
      limit: limit,
      deleted: deleted,
    );
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) {
    return super.getByUuid(uuid);
  }

  @override
  @Scope(['roles:admin'])
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) {
    return super.create(data);
  }

  @override
  @Scope(['roles:commander'])
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, data);
  }

  @override
  @Scope(['roles:admin'])
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, data: data);
  }

  @override
  TrackingCommand onCreate(Map<String, dynamic> data) => CreateTracking(data);

  @override
  Iterable<TrackingCommand> onUpdate(Map<String, dynamic> data) {
    final uuid = toAggregateUuid(data);
    final commands = <TrackingCommand>[];
    final previous = repository.get(uuid);
    _checkStatusChanged(previous, data, commands);
    _checkSourcesChanged(previous, data, commands);

    // UpdateTrackingStatus(data)
    return commands;
  }

  void _checkStatusChanged(
    Tracking tracking,
    Map<String, dynamic> data,
    List<TrackingCommand<DomainEvent>> commands,
  ) {
    final status = data.elementAt<String>('status');
    if (status != null && status != tracking.elementAt<String>('status')) {
      commands.add(
        UpdateTrackingStatus({
          repository.uuidFieldName: tracking.uuid,
          'status': status,
        }),
      );
    }
  }

  void _checkSourcesChanged(
    Tracking tracking,
    Map<String, dynamic> data,
    List<TrackingCommand<DomainEvent>> commands,
  ) {
    final uuid = tracking.uuid;
    final next = data.listAt<Map<String, dynamic>>(
      'sources',
      defaultList: const [],
    );
    if (next != null) {
      final previous = tracking.listAt<Map<String, dynamic>>(
        'sources',
        defaultList: const [],
      );
      final patches = JsonPatch.diff(next, previous);
      // Remove current
      for (var patch in patches.where((patch) => const ['remove', 'replace'].contains(patch['op']))) {
        for (var value in _toList(patch, previous)) {
          commands.add(
            RemoveSourceFromTracking(uuid, value),
          );
        }
      }
      for (var patch in patches.where((patch) => const ['add', 'replace'].contains(patch['op']))) {
        for (var value in _toList(patch, next)) {
          commands.add(
            AddSourceToTracking(uuid, value),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> _toList(Map<String, dynamic> patch, List<Map<String, dynamic>> entries) {
    if (const ['remove', 'replace'].contains(patch['op'])) {
      final path = patch.elementAt<String>('path');
      if (path.isEmpty) {
        return entries;
      }
      final index = int.parse(path.split('/')[path.startsWith('/') ? 1 : 0]);
      return [entries.elementAt(index)];
    }
    return [patch.mapAt('value')];
  }

  @override
  TrackingCommand onDelete(Map<String, dynamic> data) => DeleteTracking(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique tracking id",
        "status": documentTrackingStatus()
          ..description = "Tracking status"
          ..isReadOnly = false,
        "position": documentPosition(context)
          ..description = "Current position"
          ..isReadOnly = true,
        "distance": APISchemaObject.number()
          ..description = "Total distance in meter"
          ..isReadOnly = true,
        "speed": APISchemaObject.number()
          ..description = "Average speed in m/s"
          ..isReadOnly = true,
        "effort": APISchemaObject.number()
          ..description = "Total effort in milliseconds"
          ..isReadOnly = true,
        "history": APISchemaObject.array(ofSchema: context.schema['Position'])
          ..description = "List of historical positions"
          ..isReadOnly = true
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
        "sources": APISchemaObject.array(ofSchema: context.schema['Source'])
          ..description = "Array of Source objects"
          ..isReadOnly = false,
        "tracks": APISchemaObject.array(ofSchema: context.schema['Track'])
          ..description = "Array of Track objects"
          ..isReadOnly = false,
      })
        ..description = "Tracking Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
        ];

  @override
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {
        'TrackingStatus': documentTrackingStatus(),
      };
}
