import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/units](http://localhost/api/client.html#/Unit) requests
class UnitController extends AggregateController<UnitCommand, Unit> {
  UnitController(
    this.trackings,
    this.personnels,
    UnitRepository repository,
    JsonValidation validation,
  )   : _trackingController = TrackingController(trackings, validation),
        super(
          repository,
          validation: validation,
          readOnly: const [
            'messages',
            'operation',
            'transitions',
          ],
          tag: 'Units',
        );

  final TrackingRepository trackings;
  final PersonnelRepository personnels;
  final TrackingController _trackingController;

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
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    final _personnels = List<String>.from(
      data.elementAt('personnels') ?? <String>[],
    );
    final notFound = _personnels.where((puuid) => !personnels.exists(puuid));
    if (notFound.isNotEmpty) {
      return Response.notFound(
        body: "Personnels not found: ${notFound.join(', ')}",
      );
    }
    final tuuid = data.elementAt<String>('tracking/uuid');
    if (tuuid != null) {
      final unit = repository.peek(uuid);
      if (unit == null) {
        return Response.notFound(
          body: '$aggregateType $uuid not found',
        );
      }
      // Ensure only one tracking object per personnel
      final existing = unit.elementAt<String>('tracking/uuid');
      if (existing != null && tuuid != existing) {
        return conflict(
          ConflictType.exists,
          '$aggregateType $uuid is already tracked by $existing',
          base: unit.data,
          code: 'duplicate_tracking_uuid',
        );
      }
      // Create tracking if not exists
      if (!await exists(tuuid, repo: trackings)) {
        _trackingController.request = request;
        final result = await _trackingController.create({
          'uuid': tuuid,
          'sources': [
            {'uuid': uuid, 'type': 'trackable'},
          ],
        });
        if (result.statusCode >= 400) {
          return result;
        }
      }
    }
    return super.update(uuid, data);
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    final hasTracking = repository.peek(uuid)?.data?.elementAt('tracking/uuid') != null;
    final response = await super.delete(uuid, data: data);
    if (hasTracking) {
      return await withResponseWaitForRuleResults(response, expected: {
        UnitRemovedFromOperation: 1,
        TrackingDeleted: 1,
      });
    }
    return await withResponseWaitForRuleResult<UnitRemovedFromOperation>(
      response,
    );
  }

  @override
  UnitCommand onCreate(Map<String, dynamic> data) => CreateUnit(data);

  @override
  Iterable<UnitCommand> onUpdate(Map<String, dynamic> data) => [
        UpdateUnitInformation(data),
      ];

  @override
  UnitCommand onDelete(Map<String, dynamic> data) => DeleteUnit(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique unit id",
          "type": documentType(),
          "number": APISchemaObject.integer()..description = "Unit number",
          "affiliation": context.schema["Affiliation"],
          "phone": APISchemaObject.string()..description = "Unit phone number",
          "callsign": APISchemaObject.string()..description = "Unit callsign",
          "status": documentStatus(),
          "tracking": documentAggregateRef(
            context,
            readOnly: false,
            defaultType: 'Tracking',
            description: 'Unique id of tracking object created for this unit.',
          ),
          'operation': documentAggregateRef(
            context,
            defaultType: 'Operation',
            description: 'Operation which this unit is mobilized for',
          ),
          "transitions": APISchemaObject.array(ofSchema: documentTransition())
            ..isReadOnly = true
            ..description = "State transitions (read only)",
          "personnels": APISchemaObject.array(ofSchema: context.schema['UUID'])
            ..description = "List of uuid of Personnels assigned to this unit",
          "messages": APISchemaObject.array(ofSchema: context.schema['Message'])
            ..isReadOnly = true
            ..description = "List of messages added to Incident",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'type',
          'status',
          'number',
          'callsign',
        ];

  APISchemaObject documentTransition() => APISchemaObject.object({
        "status": documentStatus(),
        "timestamp": APISchemaObject.string()
          ..description = "When transition occurred"
          ..format = 'date-time',
      })
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Unit type - Value Object
  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Unit type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'team',
      'k9',
      'boat',
      'vehicle',
      'snowmobile',
      'atv',
      'commandpost',
      'other',
    ];

  /// Unit Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Unit status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "mobilized"
    ..enumerated = [
      'mobilized',
      'deployed',
      'retired',
    ];
}
