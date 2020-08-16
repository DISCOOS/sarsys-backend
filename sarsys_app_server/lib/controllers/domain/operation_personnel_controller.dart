import 'package:aqueduct/aqueduct.dart';
import 'package:meta/meta.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_app_server/controllers/event_source/policy.dart';
import 'package:sarsys_app_server/responses.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_domain/sarsys_domain.dart' as sar show Operation;
import 'package:sarsys_app_server/validation/validation.dart';

/// Implement controller for field `missions` in [sar.Operation]
class OperationPersonnelController
    extends AggregateListController<PersonnelCommand, Personnel, OperationCommand, sar.Operation> {
  OperationPersonnelController(
    OperationRepository primary,
    PersonnelRepository foreign,
    this.persons,
    this.affiliations,
    JsonValidation validation,
  ) : super('personnels', primary, foreign, validation,
            readOnly: const [
              'unit',
              'messages',
              'operation',
              'transitions',
            ],
            tag: 'Operations > Personnels');

  final PersonRepository persons;
  final AffiliationRepository affiliations;

  @override
  @Operation.get('uuid')
  Future<Response> get(
    @Bind.path('uuid') String uuid, {
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
    @Bind.query('expand') List<String> expand = const [],
  }) async {
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: "$primaryType $uuid not found");
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
      return serverError(e, stackTrace);
    }
  }

  bool _shouldExpand(List<String> expand) {
    if (expand.any((element) => element.toLowerCase() == 'person')) {
      return true;
    }
    if (expand.isNotEmpty) {
      throw "Invalid query parameter 'expand' values: $expand, expected any of: {person}";
    }
    return false;
  }

  /// Merge [Personnel] with [Person]
  Map<String, dynamic> merge(Personnel aggregate) {
    final entry = toAggregateData(aggregate);
    final personnel = entry.elementAt<Map<String, dynamic>>('data');
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
        body: "Field [affiliation/uuid] is required",
      );
    } else if (!await exists(affiliations, auuid as String)) {
      return Response.badRequest(
        body: "Affiliation $uuid not found",
      );
    }
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
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case "GET":
        parameters.add(
          APIParameter.query('expand')
            ..description = "Expand response with information from references. Legal values are: 'person'",
        );
        break;
    }
    return parameters;
  }
}
