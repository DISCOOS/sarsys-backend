import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';

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
              'conditions': APISchemaObject.array(
                ofSchema: documentServerCondition(),
              )..description = 'Array of server instance condition objects',
              'health': documentServerHealth(),
            })
              ..description = 'Server instance status object',
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

APISchemaObject documentServerCondition() {
  return APISchemaObject.object({
    'type': APISchemaObject.string()..description = 'Server status type',
    'status': APISchemaObject.string()
      ..description = 'Indicates whether that '
          'status is applicable, with possible '
          'values "True", "False" or "Unknown"',
    'reason': APISchemaObject.string()
      ..description = 'Machine-readable, '
          'UpperCamelCase text indicating the reason '
          "for the status's last transition'",
    'message': APISchemaObject.string()
      ..description = 'Human-readable message '
          'indicating details about the last '
          'status transition.',
  })
    ..description = 'Server instance condition object';
}

APISchemaObject documentServerHealth() {
  return APISchemaObject.object({
    'alive': APISchemaObject.boolean()..description = 'Server instance api is alive',
    'ready': APISchemaObject.boolean()..description = 'Server instance api is ready',
  })
    ..description = 'Server instance api health object';
}
