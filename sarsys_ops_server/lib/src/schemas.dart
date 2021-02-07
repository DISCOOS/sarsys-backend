import 'package:sarsys_http_core/sarsys_http_core.dart';

//////////////////////////////////
// SARSys Domain documentation
//////////////////////////////////

APISchemaObject documentModuleStatus() => APISchemaObject.object(
      {
        'name': APISchemaObject.string()..description = 'Module name',
        'instances': APISchemaObject.array(
          ofSchema: APISchemaObject.object({
            'name': APISchemaObject.string()..description = 'Server instance name',
            'status': APISchemaObject.object({
              'type': APISchemaObject.string()..description = 'Server status type',
              'acceptable': APISchemaObject.string()
                ..description = 'Indicates whether that '
                    'status is applicable, with possible '
                    'values "True" and "False"',
              'reason': APISchemaObject.string()
                ..description = 'Machine-readable, '
                    'UpperCamelCase text indicating the reason '
                    "for the status's last transition'",
              'message': APISchemaObject.string()
                ..description = 'Human-readable message '
                    'indicating details about the last '
                    'status transition.',
            })
              ..description = 'Server instance status object',
            'health': APISchemaObject.object({
              'alive': APISchemaObject.boolean()..description = 'Server instance is alive',
              'ready': APISchemaObject.boolean()..description = 'Server instance is ready',
            })
              ..description = 'Server instance health object',
          })
            ..required = [
              'name',
              'health',
            ]
            ..description = 'Server instance object',
        )..description = 'Array of server instance objects',
      },
    )
      ..description = 'Module status object'
      ..isReadOnly = true
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
      ..required = [
        'name',
        'instances',
      ];
