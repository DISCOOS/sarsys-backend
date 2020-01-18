import 'package:sarsys_app_server/controllers/eventsource/aggregate_controller.dart';
import 'package:sarsys_app_server/domain/mission/mission.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/incidents/{uuid}/personnels](http://localhost/api/client.html#/Mission) requests
class MissionController extends AggregateController<MissionCommand, Mission> {
  MissionController(MissionRepository repository, RequestValidator validator) : super(repository, validator: validator);

  @override
  MissionCommand onCreate(Map<String, dynamic> data) => CreateMission(data);

  @override
  MissionCommand onUpdate(Map<String, dynamic> data) => UpdateMissionInformation(data);

  @override
  MissionCommand onDelete(Map<String, dynamic> data) => DeleteMission(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object(
        {
          "uuid": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Unique Mission id",
          "description": APISchemaObject.string()..description = "Mission description",
          "type": documentType(),
          "status": documentStatus(),
          "priority": documentPriority(),
          "resolution": documentResolution(),
          "transitions": documentTransition(),
          "parts": APISchemaObject.array(ofSchema: context.schema["MissionPart"])
            ..description = "Points, linestrings, rectangles and circles describing mission parts",
          "results": APISchemaObject.array(ofSchema: context.schema["MissionResult"])
            ..description = "Points, linestrings, rectangles and circles describing the results",
          "assignedTo": APISchemaObject.string()
            ..format = 'uuid'
            ..description = "Uuid of unit assigned to mission",
        },
      )
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
        ..required = [
          'uuid',
          'type',
        ];

  APISchemaObject documentTransition() => APISchemaObject.array(ofType: APIType.object)
    ..items = APISchemaObject.object({
      "status": documentStatus(),
      "resolution": documentResolution(),
      "timestamp": APISchemaObject.string()
        ..description = "When transition occured"
        ..format = 'date-time',
    })
    ..isReadOnly = true
    ..description = "State transitions (read only)"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  APISchemaObject documentType() => APISchemaObject.string()
    ..description = "Mission type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..enumerated = [
      'search',
      'rescue',
      'other',
    ];

  /// Mission Status - Value Object
  APISchemaObject documentStatus() => APISchemaObject.string()
    ..description = "Mission status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "created"
    ..enumerated = [
      'created',
      'planned',
      'assigned',
      'executed',
    ];

  /// Mission Priority - Value Object
  APISchemaObject documentPriority() => APISchemaObject.string()
    ..description = "Mission priority"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "medium"
    ..enumerated = [
      'highest',
      'high',
      'medium',
      'low',
      'lowest',
    ];

  /// Mission Resolution - Value Object
  APISchemaObject documentResolution() => APISchemaObject.string()
    ..description = "Mission status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "unresolved"
    ..enumerated = [
      'unresolved',
      'cancelled',
      'duplicate',
      'resolved',
    ];

  @override
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {
        "Coordinates": documentCoordinates(context),
        "Geometry": documentGeometry(context),
        "Point": documentPoint(context),
        "LineString": documentLineString(context),
        "Polygon": documentPolygon(context),
        "MultiPoint": documentMultiPoint(context),
        "MultiLineString": documentMultiLineString(context),
        "MultiPolygon": documentMultiPolygon(context),
        "GeometryCollection": documentGeometryCollection(context),
        "Feature": documentFeature(context),
        "FeatureCollection": documentFeatureCollection(context),
        "Circle": documentCircle(context),
        "Rectangle": documentRectangle(context),
      };

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

  APISchemaObject documentGeometryType(String type) => APISchemaObject.object({
        "type": APISchemaObject.string()
          ..description = "GeoJSON Geometry type"
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
          ..enumerated = [
            type,
          ]
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

  /// Document coordinates for given GeoJSON type
  APISchemaObject documentCoordinatesForType(APISchemaObject object) => APISchemaObject.object({"coordinates": object});

  /// Point - Value Object
  APISchemaObject documentPoint(APIDocumentContext context) => APISchemaObject.object({})
    ..description = "GeoJSON Point"
    ..allOf = [
      documentGeometryType('Point'),
      documentCoordinatesForType(context.schema['Coordinates']),
    ]
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// LineString - Value Object
  APISchemaObject documentLineString(APIDocumentContext context) => APISchemaObject.object({})
    ..description = "GeoJSON LineString"
    ..allOf = [
      documentGeometryType('LineString'),
      documentCoordinatesForType(
        APISchemaObject.array(ofSchema: context.schema['Coordinates']),
      ),
    ]
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Polygon - Value Object
  APISchemaObject documentPolygon(APIDocumentContext context) => APISchemaObject.object({})
    ..description = "GeoJSON Polygon"
    ..allOf = [
      documentGeometryType('Polygon'),
      documentCoordinatesForType(
        APISchemaObject.array(
          ofSchema: APISchemaObject.array(
            ofSchema: context.schema['Coordinates'],
          ),
        ),
      ),
    ]
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// MultiPoint - Value Object
  APISchemaObject documentMultiPoint(APIDocumentContext context) => APISchemaObject.object({})
    ..description = "GeoJSON MultiPoint"
    ..allOf = [
      documentGeometryType('MultiPoint'),
      documentCoordinatesForType(
        APISchemaObject.array(
          ofSchema: context.schema['Coordinates'],
        ),
      )
    ]
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// MultiLineString - Value Object
  APISchemaObject documentMultiLineString(APIDocumentContext context) => APISchemaObject.object({})
    ..description = "GeoJSON MultiLineString"
    ..allOf = [
      documentGeometryType('MultiLineString'),
      documentCoordinatesForType(
        APISchemaObject.array(
          ofSchema: APISchemaObject.array(
            ofSchema: context.schema['Coordinates'],
          ),
        ),
      )
    ]
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// MultiPolygon - Value Object
  APISchemaObject documentMultiPolygon(APIDocumentContext context) => APISchemaObject.object({})
    ..description = "GeoJSON MultiPolygon"
    ..allOf = [
      documentGeometryType('MultiPolygon'),
      documentCoordinatesForType(
        APISchemaObject.array(
          ofSchema: APISchemaObject.array(
            ofSchema: APISchemaObject.array(
              ofSchema: context.schema['Coordinates'],
            ),
          ),
        ),
      )
    ]
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// GeometryCollection - Value Object
  APISchemaObject documentGeometryCollection(APIDocumentContext context) => APISchemaObject.object({
        "type": APISchemaObject.string()
          ..description = "GeoJSON Geometry type"
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
          ..enumerated = [
            'GeometryCollection',
          ],
        "geometries": APISchemaObject.array(ofSchema: context.schema['Geometry'])
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
      })
        ..description = "GeoJSON GeometryCollection"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Feature - Value Object
  APISchemaObject documentFeature(APIDocumentContext context, {APISchemaObject geometry}) => APISchemaObject.object({
        "type": APISchemaObject.string()
          ..description = "GeoJSON Feature type"
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
          ..enumerated = [
            'Feature',
          ],
        "geometry": geometry ?? context.schema['Geometry'],
        "properties": APISchemaObject.object({
          "name": APISchemaObject.string()..description = "Feature name",
          "description": APISchemaObject.string()..description = "Feature description",
        })
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
        "features": APISchemaObject.array(ofSchema: context.schema['Feature'])
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
      })
        ..description = "GeoJSON FeatureCollection"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Rectangle - Value Object
  /// Based on https://medium.com/geoman-blog/how-to-handle-circles-in-geojson-d04dcd6cb2e6
  APISchemaObject documentRectangle(APIDocumentContext context) => APISchemaObject.object({})
    ..description = "Rectangle feature described by two GeoJSON points forming upper left and lower right corners"
    ..allOf = [
      documentFeature(
        context,
        geometry: APISchemaObject.array(ofSchema: context.schema['Point'])
          ..minItems = 2
          ..maxItems = 2,
      )
    ]
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Circle - Value Object
  /// Based on https://medium.com/geoman-blog/how-to-handle-circles-in-geojson-d04dcd6cb2e6
  APISchemaObject documentCircle(APIDocumentContext context) => APISchemaObject.object({
        "properties": APISchemaObject.object({
          "radius": APISchemaObject.number()..description = "Circle radius i meters",
        })
      })
        ..description = "Circle feature described by a GeoJSON point in center and a radius as an property"
        ..allOf = [
          documentFeature(
            context,
            geometry: context.schema['Point'],
          )
        ]
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
}
