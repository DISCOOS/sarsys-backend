import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that creates
/// affiliations for temporary persons
class AffiliationTemporaryController extends AggregateController<AffiliationCommand, Affiliation> {
  AffiliationTemporaryController(
    this.persons,
    AffiliationRepository affiliations,
    JsonValidation validation,
  ) : super(affiliations, validation: validation, tag: 'Affiliations > Temporary');

  final PersonRepository persons;

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    try {
      final puuid = data.elementAt('person/uuid') as String;
      if (puuid == null) {
        return Response.badRequest(body: "Field [person/uuid] in required");
      }
      final person = persons.get(puuid, createNew: false);
      if (person == null) {
        await persons.execute(
          CreatePerson(validate(
              "${typeOf<Person>()}",
              Map.from(data['person'] as Map)
                ..addAll({
                  // Ensure person is temporary
                  'temporary': true,
                }))),
        );
      } else if (person.data.elementAt('temporary') != true) {
        return conflict(
          ConflictType.exists,
          'Person $puuid already exists as permanent',
        );
      }
      final affiliation = data.elementAt('affiliation');
      if (affiliation is! Map) {
        return Response.badRequest(body: "Field [affiliation] in required");
      }
      return super.create(Map.from(affiliation as Map)
        ..addAll({
          // Ensure person is given
          'person': {'uuid': puuid}
        }));
    } on UUIDIsNull {
      return Response.badRequest(body: "Field [uuid] in $aggregateType is required");
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on AggregateExists catch (e) {
      return conflict(
        ConflictType.exists,
        e.message,
      );
    } on ConflictNotReconcilable catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
        mine: e.mine,
        yours: e.yours,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      return Response.serverError(body: e);
    }
  }

  @override
  AffiliationCommand onCreate(Map<String, dynamic> data) => CreateAffiliation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Affiliation - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => context.schema['affiliation'];

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "POST":
        return APIRequestBody.schema(
          APISchemaObject.object({
            "person": context.schema["Person"],
            "affiliation": context.schema["Affiliation"],
          })
            ..required = [
              'person',
              'affiliation',
            ],
          description: "Temporary Affiliation Request",
          required: true,
        );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }
}
