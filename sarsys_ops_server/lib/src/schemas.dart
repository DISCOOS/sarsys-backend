import 'package:sarsys_http_core/sarsys_http_core.dart';

//////////////////////////////////
// SARSys Domain documentation
//////////////////////////////////

APISchemaObject documentModuleStatus() => APISchemaObject.object(
      {
        "name": APISchemaObject.string()..description = "Module name",
        'instances': APISchemaObject.array(
          ofSchema: APISchemaObject.object({
            "name": APISchemaObject.string()..description = "Server instance name",
            "health": APISchemaObject.object({
              'alive': APISchemaObject.boolean()..description = 'Server is alive',
              'ready': APISchemaObject.boolean()..description = 'Server is ready',
            })
          })
            ..required = [
              'name',
              'health',
            ],
        )..description = 'Array of server instances',
      },
    )
      ..description = "Module status"
      ..isReadOnly = true
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
      ..required = [
        'name',
        'instances',
      ];
