import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

import 'package:sarsys_app_server/controllers/event_source/controllers.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that onboard
/// new person with given affiliation
class AffiliationPersonController extends AggregateController<AffiliationCommand, Affiliation> {
  AffiliationPersonController(
    this.persons,
    AffiliationRepository affiliations,
    JsonValidation validation,
  ) : super(affiliations, validation: validation, tag: 'Affiliations > Onboard');

  final PersonRepository persons;

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    try {
      final puuid = data.elementAt('person/uuid') as String;
      if (puuid == null) {
        return Response.badRequest(body: "Field [person/uuid] in required");
      }
      final current = persons.get(puuid, createNew: false);
      final person = validate<Map<String, dynamic>>("${typeOf<Person>()}", data['person']);
      final temporary = person.elementAt<bool>('temporary');
      if (current == null) {
        await persons.execute(
          CreatePerson(person),
        );
      } else if (current.data.elementAt('temporary') != temporary) {
        return conflict(
          ConflictType.exists,
          'Person $puuid already exists as ${temporary ? 'permanent' : 'temporary'}',
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
          description: "Onboard Affiliation Request",
          required: true,
        );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }
}
