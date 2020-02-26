import 'package:aqueduct/aqueduct.dart';

APISchemaObject documentID() => APISchemaObject.string()..description = "An id unique in current collection";

APISchemaObject documentUUID() => APISchemaObject.string()
  ..format = "uuid"
  ..description = "A [universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).";

// TODO: Use https://pub.dev/packages/password to hash pass codes in streams?
APISchemaObject documentPassCodes() => APISchemaObject.object(
      {
        "commander": APISchemaObject.string()..description = "Passcode for access with Commander rights",
        "personnel": APISchemaObject.string()..description = "Passcode for access with Personnel rights",
      },
    )
      ..description = "Pass codes for access rights to spesific Incident instance"
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
      ..required = [
        'commander',
        'personnel',
      ];

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
      "accuracy": APISchemaObject.number()..description = "Position accuracy",
      "timestamp": APISchemaObject.string()
        ..description = "Timestamp in ISO8601 Date Time String Format"
        ..format = "date-time",
      "source": documentPositionSource()..isReadOnly = true,
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
    'tracking',
  ];

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
