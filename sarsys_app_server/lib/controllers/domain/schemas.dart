import 'package:meta/meta.dart';
import 'package:aqueduct/aqueduct.dart';

APISchemaObject documentID() => APISchemaObject.string()..description = "An id unique in current collection";

APISchemaObject documentUUID() => APISchemaObject.string()
  ..format = "uuid"
  ..description = "A [universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).";

// TODO: Use https://pub.dev/packages/password to hash pass codes in streams?
APISchemaObject documentAuthor() => APISchemaObject.object(
      {
        "userId": APISchemaObject.string()..description = "Author user id",
        "timestamp": APISchemaObject.string()
          ..description = "When modification occurred"
          ..format = 'date-time',
      },
    )
      ..description = "Pass codes for access rights to spesific Incident instance"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
      ..required = [
        'userId',
        'timestamp',
      ];

// TODO: Use https://pub.dev/packages/password to hash pass codes in streams?
APISchemaObject documentPassCodes() => APISchemaObject.object(
      {
        "commander": APISchemaObject.string()..description = "Passcode for access with Commander rights",
        "personnel": APISchemaObject.string()..description = "Passcode for access with Personnel rights",
      },
    )
      ..description = "Passcodes for Operation access rights"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
      ..required = [
        'commander',
        'personnel',
      ];

//////////////////////////////////
// Core documentation
//////////////////////////////////

APISchemaObject documentAggregateRef(
  APIDocumentContext context, {
  String defaultType,
  bool readOnly = true,
  String description = "Aggregate Root Reference",
}) =>
    APISchemaObject.object({
      "uuid": documentUUID()
        ..description = "${defaultType ?? "Aggregate Root"} UUID"
        ..isReadOnly = readOnly,
      "type": APISchemaObject.string()
        ..description = "${defaultType ?? "Aggregate Root"} Type"
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
  String description = "List of Aggregate Root uuids",
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
  @required String type,
}) =>
    APISchemaObject.object({
      "total": APISchemaObject.integer()
        ..description = "Number of aggregates"
        ..isReadOnly = true,
      "offset": APISchemaObject.integer()
        ..description = "Aggregate Page offset"
        ..isReadOnly = true,
      "limit": APISchemaObject.integer()
        ..description = "Aggregate Page size"
        ..isReadOnly = true,
      "next": APISchemaObject.integer()
        ..description = "Next Aggregate Page offset"
        ..isReadOnly = true,
      "entries": APISchemaObject.array(
        ofSchema: documentAggregateResponse(context, type: type),
      )
        ..description = "Array of ${type == null ? "Entity Object" : type}s"
        ..isReadOnly = true,
    })
      ..description = "Entities Response"
      ..isReadOnly = true;

APISchemaObject documentValuePageResponse(
  APIDocumentContext context, {
  @required String type,
  @required APISchemaObject schema,
}) =>
    APISchemaObject.object({
      "total": APISchemaObject.integer()
        ..description = "Number of ${type}s"
        ..isReadOnly = true,
      "offset": APISchemaObject.integer()
        ..description = "${type} Page offset"
        ..isReadOnly = true,
      "limit": APISchemaObject.integer()
        ..description = "${type} Page size"
        ..isReadOnly = true,
      "next": APISchemaObject.integer()
        ..description = "Next ${type} Page offset"
        ..isReadOnly = true,
      "entries": APISchemaObject.array(
        ofSchema: schema,
      )
        ..description = "Array of ${type}s"
        ..isReadOnly = true,
    })
      ..description = "Array Value Response"
      ..isReadOnly = true;

APISchemaObject documentAggregateResponse(
  APIDocumentContext context, {
  String type,
}) =>
    APISchemaObject.object({
      "type": APISchemaObject.string()
        ..description = "${type == null ? "Aggregate Root" : type} Type"
        ..defaultValue = type
        ..isReadOnly = true,
      "created": APISchemaObject.string()
        ..description = "When Aggregate was created"
        ..format = 'date-time'
        ..isReadOnly = true,
      "changed": APISchemaObject.string()
        ..description = "When Aggregate was created"
        ..format = 'date-time'
        ..isReadOnly = true,
      "deleted": APISchemaObject.string()
        ..description = "When Aggregate was created"
        ..format = 'date-time'
        ..isReadOnly = true,
      "data": type != null ? context.schema[type] : APISchemaObject.freeForm()
        ..description = "${type == null ? "Aggregate Root" : type}  Data"
        ..isReadOnly = true,
    })
      ..description = "${type == null ? "Aggregate Root" : type} Response"
      ..isReadOnly = true;

APISchemaObject documentEntityPageResponse(
  APIDocumentContext context, {
  String type,
}) =>
    APISchemaObject.object({
      "aggregate": context.schema["AggregateRef"],
      "type": APISchemaObject.string()
        ..description = "Entity Object Type"
        ..defaultValue = type
        ..isReadOnly = true,
      "total": APISchemaObject.integer()
        ..description = "Number of entities"
        ..isReadOnly = true,
      "entries": APISchemaObject.array(
        ofSchema: type == null ? APISchemaObject.freeForm() : context.schema[type],
      )
        ..description = "Array of ${type == null ? "Entity Object" : type}s"
        ..isReadOnly = true,
    })
      ..description = "Entities Response"
      ..isReadOnly = true;

APISchemaObject documentEntityResponse(
  APIDocumentContext context, {
  String type,
}) =>
    APISchemaObject.object({
      "aggregate": context.schema["AggregateRef"],
      "type": APISchemaObject.string()
        ..description = "${type == null ? "Entity Object" : type} Type"
        ..defaultValue = type
        ..isReadOnly = true,
      "data": type != null ? context.schema[type] : APISchemaObject.freeForm()
        ..description = "${type == null ? "Entity Object" : type}  Data"
        ..isReadOnly = true,
    })
      ..description = "${type == null ? "Entity Object" : type} Response"
      ..isReadOnly = true;

APISchemaObject documentValueResponse(
  APIDocumentContext context, {
  String type,
}) =>
    APISchemaObject.object({
      "aggregate": context.schema["AggregateRef"],
      "type": APISchemaObject.string()
        ..description = "${type == null ? "Value Object" : type} Type"
        ..defaultValue = type
        ..isReadOnly = true,
      "data": type != null ? context.schema[type] : APISchemaObject.freeForm()
        ..description = "${type == null ? "Value Object" : type}  Data"
        ..isReadOnly = true,
    })
      ..description = "Value Object Response"
      ..isReadOnly = true;

APISchemaObject documentConflict(
  APIDocumentContext context,
) =>
    APISchemaObject.object({
      "type": APISchemaObject.string()
        ..description = "Conflict type"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..isReadOnly = true
        ..enumerated = [
          'merge',
          'exists',
          'deleted',
        ],
      "mine": APISchemaObject.map(ofType: APIType.object)
        ..description = "JsonPatch diffs between remote base and head of event stream"
        ..isReadOnly = true,
      "yours": APISchemaObject.map(ofType: APIType.object)
        ..description = "JsonPatch diffs between remote base and request body"
        ..isReadOnly = true,
    })
      ..description = "Conflict Error object with JsonPatch diffs for "
          "manually applying mine or your changes locally before the "
          "operation trying again."
      ..isReadOnly = true;

//////////////////////////////////
// GeoJSON documentation
//////////////////////////////////

/// Geometry - Value Object
APISchemaObject documentGeometry(APIDocumentContext context) => APISchemaObject.object({
      "type": APISchemaObject.string()
        ..description = "GeoJSON Geometry type"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'Point',
          'LineString',
          'Polygon',
          'MultiPoint',
          'MultiLineString',
          'MultiPolygon',
        ]
    })
      ..description = "GeoJSon geometry"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

APISchemaObject documentGeometryType(String type, APISchemaObject coordinates) => APISchemaObject.object({
      "type": APISchemaObject.string()
        ..description = "GeoJSON Geometry type"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          type,
        ],
      "coordinates": coordinates,
    })
      ..description = "GeoJSon $type type"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

/// Coordinates - Value Object
APISchemaObject documentCoordinates(APIDocumentContext context) => APISchemaObject.array(ofType: APIType.number)
  ..description = "GeoJSON coordinate. There MUST be two or more elements. "
      "The first two elements are longitude and latitude, or easting and northing, "
      "precisely in that order and using decimal numbers. Altitude or elevation MAY "
      "be included as an optional third element."
  ..minItems = 2 // Longitude, Latitude
  ..maxItems = 3 // Longitude, Latitude, Altitude
  ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

/// Point - Value Object
APISchemaObject documentPoint(APIDocumentContext context) => documentGeometryType(
      'Point',
      context.schema['Coordinates'],
    )..description = "GeoJSON Point";

/// LineString - Value Object
APISchemaObject documentLineString(APIDocumentContext context) => documentGeometryType(
      'LineString',
      APISchemaObject.array(
        ofSchema: context.schema['Coordinates'],
      ),
    )..description = "GeoJSON LineString";

/// Polygon - Value Object
APISchemaObject documentPolygon(APIDocumentContext context) => documentGeometryType(
      'Polygon',
      APISchemaObject.array(
        ofSchema: APISchemaObject.array(
          ofSchema: context.schema['Coordinates'],
        ),
      ),
    )..description = "GeoJSON Polygon";

/// MultiPoint - Value Object
APISchemaObject documentMultiPoint(APIDocumentContext context) => documentGeometryType(
      'MultiPoint',
      APISchemaObject.array(
        ofSchema: documentCoordinates(context),
      ),
    )..description = "GeoJSON MultiPoint";

/// MultiLineString - Value Object
APISchemaObject documentMultiLineString(APIDocumentContext context) => documentGeometryType(
      'MultiLineString',
      APISchemaObject.array(
        ofSchema: APISchemaObject.array(
          ofSchema: context.schema['Coordinates'],
        ),
      ),
    )..description = "GeoJSON MultiLineString";

/// MultiPolygon - Value Object
APISchemaObject documentMultiPolygon(APIDocumentContext context) => documentGeometryType(
      'MultiPolygon',
      APISchemaObject.array(
        ofSchema: APISchemaObject.array(
          ofSchema: APISchemaObject.array(
            ofSchema: context.schema['Coordinates'],
          ),
        ),
      ),
    )..description = "GeoJSON MultiPolygon";

/// GeometryCollection - Value Object
APISchemaObject documentGeometryCollection(APIDocumentContext context) => APISchemaObject.object({
      "type": APISchemaObject.string()
        ..description = "GeoJSON Geometry type"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'GeometryCollection',
        ],
      "geometries": APISchemaObject.array(ofSchema: documentGeometry(context))
    })
      ..description = "GeoJSON GeometryCollection";

/// Feature - Value Object
APISchemaObject documentFeature(
  APIDocumentContext context, {
  APISchemaObject geometry,
  Map<String, APISchemaObject> properties = const {},
}) =>
    APISchemaObject.object({
      "type": APISchemaObject.string()
        ..description = "GeoJSON Feature type"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'Feature',
        ],
      "geometry": geometry ?? documentGeometry(context),
      "properties": APISchemaObject.object({
        "name": APISchemaObject.string()..description = "Feature name",
        "description": APISchemaObject.string()..description = "Feature description",
      }..addAll(properties))
    })
      ..description = "GeoJSON Feature"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

/// FeatureCollection - Value Object
APISchemaObject documentFeatureCollection(APIDocumentContext context) => APISchemaObject.object({
      "type": APISchemaObject.string()
        ..description = "GeoJSON Feature type"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'FeatureCollection',
        ],
      "features": APISchemaObject.array(ofSchema: context.schema['Feature']),
    })
      ..description = "GeoJSON FeatureCollection";

//////////////////////////////////
// GeoJSON features documentation
//////////////////////////////////

/// Rectangle - Value Object
/// Based on https://medium.com/geoman-blog/how-to-handle-circles-in-geojson-d04dcd6cb2e6
APISchemaObject documentRectangle(APIDocumentContext context) => documentFeature(
      context,
      geometry: APISchemaObject.array(ofSchema: context.schema['Point'])
        ..minItems = 2
        ..maxItems = 2,
    )..description = "Rectangle feature described by two GeoJSON points forming upper left and lower right corners";

/// Circle - Value Object
/// Based on https://medium.com/geoman-blog/how-to-handle-circles-in-geojson-d04dcd6cb2e6
APISchemaObject documentCircle(APIDocumentContext context) =>
    documentFeature(context, geometry: context.schema['Point'], properties: {
      "radius": APISchemaObject.number()..description = "Circle radius i meters",
    })
      ..description = "Circle feature described by a GeoJSON point in center and a radius as an property"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

/// Position - Value object
APISchemaObject documentPosition(
  APIDocumentContext context, {
  bool isReadyOnly = false,
  String description = "Position feature described by a GeoJSON point with accuracy, point type and timestamp",
}) =>
    documentFeature(context, geometry: context.schema['Point'], properties: {
      "timestamp": APISchemaObject.string()
        ..description = "Timestamp in ISO8601 Date Time String Format"
        ..format = "date-time",
      "source": documentPositionSource(),
      "activity": documentActivity(),
      "accuracy": APISchemaObject.number()..description = "Position accuracy",
      "bearing": APISchemaObject.number()..description = "Bearing at given position in degrees",
      "speed": APISchemaObject.number()..description = "Speed at given position in meter/seconds",
    })
      ..description = description
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

APISchemaObject documentPositionSource() => APISchemaObject.string()
  ..description = "Position source"
  ..defaultValue = "manual"
  ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
  ..enumerated = [
    'manual',
    'device',
    'aggregate',
  ];

APISchemaObject documentActivity() => APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = "Activity tyep"
        ..defaultValue = "unknown"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..enumerated = [
          'still',
          'on_foot',
          'walking',
          'running',
          'unknown',
          'on_bicycle',
          'in_vehicle',
        ],
      'confidence': APISchemaObject.integer()
        ..description = "Activity type confidence (0-100%)"
        ..defaultValue = "100"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
    })
      ..description = "Activity Value Object"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

APISchemaObject documentMessage(APIDocumentContext context) => APISchemaObject.object({
      "id": context.schema['ID']..description = "Message id (unique in aggregate only)",
      "type": documentMessageType(),
      "subject": APISchemaObject.string()..description = "Message subject",
      "body": APISchemaObject.freeForm()..description = "Message body",
    })
      ..description = "GeoJSON FeatureCollection";

APISchemaObject documentMessageType() => APISchemaObject.string()
  ..description = "Message type"
  ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
  ..enumerated = [
    'clue',
    'general',
    'objective',
    'personnel',
    'device',
    'subject',
    'unit',
  ];
