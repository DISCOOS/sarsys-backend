import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// Implement controller for field `personnels` in [sar.Operation]
class OperationPersonnelController
    extends AggregateListController<PersonnelCommand, Personnel, OperationCommand, sar.Operation> {
  OperationPersonnelController(
    OperationRepository primary,
    PersonnelRepository foreign,
    this.persons,
    this.affiliations,
    JsonValidation validation,
  )   : _onboardController = AffiliationOnboardController(persons, affiliations, validation),
        super(
          'personnels',
          primary,
          foreign,
          validation,
          readOnly: const [
            'unit',
            'messages',
            'operation',
            'transitions',
          ],
          tag: 'Operations > Personnels',
        );

  final PersonRepository persons;
  final AffiliationRepository affiliations;
  final AffiliationOnboardController _onboardController;

  AffiliationOnboardController get onboardController => _onboardController..request = request;

  @override
  @Operation.get('uuid')
  Future<Response> get(
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
  }) async {
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: '$primaryType $uuid not found');
      }
      // Only use uuids that exists
      final uuids = await removeDeleted(uuid);
      final aggregates = uuids
          .toPage(
            offset: offset,
            limit: limit,
          )
          .map(foreign.get)
          .toList();
      return Response.ok(
        toDataPaged(
          uuids.length,
          offset,
          limit,
          // Merge personnel with person?
          aggregates.map(_shouldExpand(expand) ? merge : toAggregateData),
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  bool _shouldExpand(String expand) {
    if (expand != null) {
      if (expand.toLowerCase() == 'person') {
        return true;
      }
      if (expand.isNotEmpty) {
        throw "Invalid query parameter 'expand' values: $expand, expected any of: 'person'";
      }
    }
    return false;
  }

  /// Merge [Personnel] with [Person]
  Map<String, dynamic> merge(Personnel aggregate) {
    final entry = toAggregateData(aggregate);
    final personnel = entry.mapAt<String, dynamic>('data');
    final auuid = personnel.elementAt<String>('affiliation/uuid');
    if (auuid != null) {
      final affiliation = affiliations.get(auuid, createNew: false);
      if (affiliation != null) {
        final puuid = affiliation.elementAt<String>('person/uuid');
        if (puuid != null) {
          final person = persons.get(puuid, createNew: false);
          if (person != null) {
            // Do not overwrite personnel.uuid
            personnel.addAll({'person': person.data});
          }
        }
      }
    }
    entry.update('data', (value) => personnel);
    return entry;
  }

  @override
  @Operation.post('uuid')
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    final auuid = data.elementAt('affiliation/uuid');
    if (auuid is! String) {
      return Response.badRequest(
        body: 'Field [affiliation/uuid] is required',
      );
    }
    if (!await exists(affiliations, auuid as String)) {
      final affiliation = data.mapAt<String, dynamic>('affiliation');
      if (affiliation['person'] is! Map) {
        return Response.badRequest(
          body: 'Affiliation $auuid not found',
        );
      }
      final affiliate = await onboardController.create(
        affiliation,
      );
      // Failed?
      if (affiliate.statusCode >= 400) {
        return affiliate;
      }
    }
    // Mobilize personnel
    return super.create(uuid, data);
  }

  @override
  @visibleForOverriding
  Future<Iterable<DomainEvent>> doCreate(String fuuid, Map<String, dynamic> data) async {
    final isAssigned = data?.elementAt('unit/uuid') != null;
    final hasTracking = data?.elementAt('tracking/uuid') != null;
    final events = await super.doCreate(fuuid, data);
    if (hasTracking || isAssigned) {
      await PolicyUtils.waitForRuleResults(
        foreign,
        fail: true,
        expected: {
          TrackingCreated: hasTracking ? 1 : 0,
          PersonnelAddedToOperation: isAssigned ? 1 : 0,
        },
        timeout: const Duration(milliseconds: 1000),
      );
    }
    return events;
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> add(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.add(uuid, data);

  @override
  @Operation.delete('uuid')
  Future<Response> remove(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) =>
      super.remove(uuid, data);

  @override
  MobilizePersonnel onCreate(String uuid, Map<String, dynamic> data) => MobilizePersonnel(data);

  @override
  AddPersonnelToOperation onCreated(sar.Operation aggregate, String fuuid) => onAdd(aggregate, fuuid);

  @override
  AddPersonnelToOperation onAdd(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      AddPersonnelToOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdatePersonnelInformation onAdded(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdatePersonnelInformation(toForeignRef(
        aggregate,
        fuuid,
      ));

  @override
  RemovePersonnelFromOperation onRemove(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      RemovePersonnelFromOperation(
        aggregate,
        fuuid,
      );

  @override
  UpdatePersonnelInformation onRemoved(
    sar.Operation aggregate,
    String fuuid,
  ) =>
      UpdatePersonnelInformation(toForeignNullRef(
        fuuid,
      ));

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = super.documentOperationResponses(context, operation);
    switch (operation.method) {
      case 'POST':
        responses.addAll({
          '200': context.responses.getObject('200'),
        });
    }
    return responses;
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case 'GET':
        parameters
          ..add(
            APIParameter.query('filter')..description = 'Match values with given string',
          )
          ..add(
            APIParameter.query('uuids')
              ..description = 'Only get aggregates in list of given comma-separated uuids. '
                  'If filter is given, it is only applied on aggregates matching any uuids',
          )
          ..add(
            APIParameter.query('expand')
              ..description = "Expand response with information from references. Legal values are: 'person'",
          );
        break;
    }
    return parameters;
  }
}
