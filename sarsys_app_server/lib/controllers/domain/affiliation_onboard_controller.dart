import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that onboard
/// new person with given affiliation
class AffiliationOnboardController extends AggregateController<AffiliationCommand, Affiliation> {
  AffiliationOnboardController(
    this.persons,
    AffiliationRepository affiliations,
    JsonValidation validation,
  ) : super(
          affiliations,
          validation: validation,
          tag: 'Affiliations > Onboard',
          schemaName: 'Affiliate',
        );

  final PersonRepository persons;

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    try {
      // Validate
      final onboard = validate<Map<String, dynamic>>(schemaName, data);
      final person = onboard.mapAt<String, dynamic>('person');

      // Is user authorized?
      if (isUser(person) || AllowedScopes.isCommander(request.authorization)) {
        // Create or update person
        final puuid = person.elementAt<String>('uuid');
        if (await exists(puuid)) {
          await persons.execute(
            UpdatePersonInformation(person),
            context: request.toContext(logger),
          );
          return super.create(onboard
            ..addAll({
              'person': {'uuid': puuid}
            }));
        }

        // Look for existing user
        final userId = person.elementAt('userId');
        final existing = persons.aggregates.firstWhere(
          (person) => person.data.elementAt('userId') == userId,
          orElse: () => null,
        );

        // Onboard person allowed?
        if (existing == null) {
          await persons.execute(
            CreatePerson(person),
            context: request.toContext(logger),
          );
          // Create affiliation
          return super.create(onboard
            ..addAll({
              'person': {'uuid': puuid}
            }));
        }

        // Create affiliation
        await super.create(onboard
          ..addAll({
            'person': {
              // Replace person with existing
              'uuid': existing.elementAt<String>('uuid'),
            }
          }));

        // Return affiliate with replaced person
        return okAggregate(
          repository.get(onboard.elementAt('uuid')),
          data: onboard
            ..addAll({
              // Ensure person as reference
              'person': existing.data
            }),
        );
      }
      return Response.unauthorized();
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
        base: e.base,
        mine: e.mine,
        yours: e.yours,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Exception catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @override
  AffiliationCommand onCreate(Map<String, dynamic> data) => CreateAffiliation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Affiliation - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(
    APIDocumentContext context,
  ) =>
      AffiliationController.documentAffiliation(
        context,
        person: context.schema['person'],
      );

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
}
