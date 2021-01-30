import 'package:sarsys_http_core/sarsys_http_core.dart';

//////////////////////////////////
// SARSys Domain documentation
//////////////////////////////////

APISchemaObject documentServerStatus() => APISchemaObject.object(
      {
        "type": APISchemaObject.string()..description = "Server type",
        "health": APISchemaObject.object({
          'alive': APISchemaObject.boolean()..description = 'Server is alive',
          'ready': APISchemaObject.boolean()..description = 'Server is ready',
        })
          ..description = "Server health status",
      },
    )
      ..description = "Server status"
      ..isReadOnly = true
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
      ..required = [
        'type',
        'health',
      ];
