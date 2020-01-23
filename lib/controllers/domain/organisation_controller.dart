import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/organisation/organisation.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/organisations](http://localhost/api/client.html#/Organisation) requests
class OrganisationController extends AggregateController<OrganisationCommand, Organisation> {
  OrganisationController(
    OrganisationRepository organisations,
    RequestValidator validator,
  ) : super(organisations, validator: validator, tag: 'Affiliations');

  @override
  OrganisationCommand onCreate(Map<String, dynamic> data) => CreateOrganisation(data);

  @override
  OrganisationCommand onUpdate(Map<String, dynamic> data) => UpdateOrganisation(data);

  @override
  OrganisationCommand onDelete(Map<String, dynamic> data) => DeleteOrganisation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Organisation - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": context.schema['UUID']..description = "Unique Organisation id",
          "name": APISchemaObject.string()..description = "Organisation name",
          "alias": APISchemaObject.string()..description = "Organisation alias",
          "icon": APISchemaObject.string()
            ..format = "uri"
            ..description = "Organisation icon",
          "divisions": APISchemaObject.array(
            ofSchema: context.schema['UUID'],
          )..description = "List of division uuids"
        },
      )
        ..description = "Organisation Schema (aggregate root)"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'name',
        ];
}
