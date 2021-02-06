import 'package:aqueduct/aqueduct.dart';

//////////////////////////////////
// Event Source documentation
//////////////////////////////////

APISchemaObject documentID() => APISchemaObject.string()..description = 'An id unique in current collection';

APISchemaObject documentUUID() => APISchemaObject.string()
  ..format = 'uuid'
  ..description = 'A [universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).';

APISchemaObject documentAggregateRef(
  APIDocumentContext context, {
  String defaultType,
  bool readOnly = true,
  String description = 'Aggregate Root Reference',
}) =>
    APISchemaObject.object({
      'uuid': documentUUID()
        ..description = '${defaultType ?? 'Aggregate Root'} UUID'
        ..isReadOnly = readOnly,
      'type': APISchemaObject.string()
        ..description = '${defaultType ?? 'Aggregate Root'} Type'
        ..isReadOnly = readOnly
        ..defaultValue = defaultType,
    })
      ..description = description
      ..isReadOnly = readOnly
      ..required = ['uuid']
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

APISchemaObject documentAggregateList(
  APIDocumentContext context, {
  String defaultType,
  String description = 'List of Aggregate Root uuids',
}) =>
    APISchemaObject.array(ofSchema: documentUUID())
      ..description = description
      ..isReadOnly = true
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

//////////////////////////////////
// Response documentation
//////////////////////////////////

APISchemaObject documentAggregatePageResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'total': APISchemaObject.integer()
        ..description = 'Number of aggregates'
        ..isReadOnly = true,
      'offset': APISchemaObject.integer()
        ..description = 'Aggregate Page offset'
        ..isReadOnly = true,
      'limit': APISchemaObject.integer()
        ..description = 'Aggregate Page size'
        ..isReadOnly = true,
      'next': APISchemaObject.integer()
        ..description = 'Next Aggregate Page offset'
        ..isReadOnly = true,
      'entries': APISchemaObject.array(
        ofSchema: documentAggregateResponse(
          context,
          type: type,
          schema: schema,
        ),
      )
        ..description = 'Array of ${type ?? 'Aggregate Object'}s'
        ..isReadOnly = true,
    })
      ..description = 'Entities Response'
      ..isReadOnly = true;

APISchemaObject documentEntityPageResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = 'Entity Object Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'total': APISchemaObject.integer()
        ..description = 'Number of entities'
        ..isReadOnly = true,
      'offset': APISchemaObject.integer()
        ..description = '${type} Page offset'
        ..isReadOnly = true,
      'limit': APISchemaObject.integer()
        ..description = '${type} Page size'
        ..isReadOnly = true,
      'next': APISchemaObject.integer()
        ..description = 'Next ${type} Page offset'
        ..isReadOnly = true,
      'path': APISchemaObject.string()
        ..description = 'Path to Entity Object List'
        ..isReadOnly = true,
      'entries': APISchemaObject.array(
        ofSchema: schema ?? (type != null ? context.schema[type] : APISchemaObject.freeForm()),
      )
        ..description = 'Array of ${type ?? 'Entity Object'}s'
        ..isReadOnly = true,
    })
      ..description = 'Entities Response'
      ..isReadOnly = true;

APISchemaObject documentValuePageResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = 'Value Object Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'total': APISchemaObject.integer()
        ..description = 'Number of ${type}s'
        ..isReadOnly = true,
      'offset': APISchemaObject.integer()
        ..description = '${type} Page offset'
        ..isReadOnly = true,
      'limit': APISchemaObject.integer()
        ..description = '${type} Page size'
        ..isReadOnly = true,
      'next': APISchemaObject.integer()
        ..description = 'Next ${type} Page offset'
        ..isReadOnly = true,
      'path': APISchemaObject.string()
        ..description = 'Path to Value Object List'
        ..isReadOnly = true,
      'entries': APISchemaObject.array(
        ofSchema: schema ?? (type != null ? context.schema[type] : APISchemaObject.freeForm()),
      )
        ..description = 'Array of ${type ?? 'Value Object'}s'
        ..isReadOnly = true,
    })
      ..description = 'Array Value Response'
      ..isReadOnly = true;

APISchemaObject documentAggregateResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Aggregate Root'} Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'created': APISchemaObject.string()
        ..description = 'When Aggregate was created'
        ..format = 'date-time'
        ..isReadOnly = true,
      'changed': APISchemaObject.string()
        ..description = 'When Aggregate was created'
        ..format = 'date-time'
        ..isReadOnly = true,
      'deleted': APISchemaObject.string()
        ..description = 'When Aggregate was created'
        ..format = 'date-time'
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Last event applied to aggregate (can be used as version)'
        ..isReadOnly = true,
      'data': (schema ?? (type != null ? context.schema[type] : APISchemaObject.freeForm()))
        ..description = '${type ?? 'Aggregate Root'} Data'
        ..isReadOnly = true,
    })
      ..description = '${type ?? 'Aggregate Root'} Response'
      ..isReadOnly = true;

APISchemaObject documentEntityResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Entity Object'} Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Last event applied to aggregate (can be used as version)'
        ..isReadOnly = true,
      'data': schema ?? (type != null ? context.schema[type] : APISchemaObject.freeForm())
        ..description = '${type ?? 'Entity Object'}  Data'
        ..isReadOnly = true,
    })
      ..description = '${type ?? 'Entity Object'} Response'
      ..isReadOnly = true;

APISchemaObject documentValueResponse(
  APIDocumentContext context, {
  String type,
  APISchemaObject schema,
}) =>
    APISchemaObject.object({
      'aggregate': context.schema['AggregateRef'],
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Value Object'} Type'
        ..defaultValue = type
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Last event applied to aggregate (can be used as version)'
        ..isReadOnly = true,
      'data': schema ?? (type != null ? context.schema[type] : APISchemaObject.freeForm())
        ..description = '${type ?? 'Value Object'}  Data'
        ..isReadOnly = true,
    })
      ..description = 'Value Object Response'
      ..isReadOnly = true;

APISchemaObject documentEvent(
  APIDocumentContext context, {
  String type,
  bool readOnly = true,
}) =>
    APISchemaObject.object({
      'uuid': documentUUID()
        ..description = 'Globally unique event id'
        ..isReadOnly = readOnly,
      'type': APISchemaObject.string()
        ..description = '${type ?? 'Event'} Type'
        ..isReadOnly = readOnly,
      'number': APISchemaObject.integer()
        ..description = 'Event number in instance stream'
        ..isReadOnly = readOnly,
      'remote': APISchemaObject.boolean()
        ..description = 'True if event origin is remote'
        ..isReadOnly = readOnly,
      'position': APISchemaObject.integer()
        ..description = 'Event position in canonical (projection or instance) stream'
        ..isReadOnly = readOnly,
      'timestamp': APISchemaObject.string()
        ..description = 'When event occurred'
        ..format = 'date-time'
        ..isReadOnly = readOnly,
    });

APISchemaObject documentConflict(
  APIDocumentContext context,
) =>
    APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = 'Conflict type'
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..isReadOnly = true
        ..enumerated = [
          'merge',
          'exists',
          'deleted',
        ],
      'mine': APISchemaObject.map(ofType: APIType.object)
        ..description = 'JsonPatch diffs between remote base and head of event stream'
        ..isReadOnly = true,
      'yours': APISchemaObject.map(ofType: APIType.object)
        ..description = 'JsonPatch diffs between remote base and request body'
        ..isReadOnly = true,
    })
      ..description = 'Conflict Error object with JsonPatch diffs for '
          'manually applying mine or your changes locally before the '
          'operation trying again.'
      ..isReadOnly = true;
