import 'package:sarsys_app_server/controllers/aggregate_controller.dart';
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
          "plan": context.schema['GeometryBag'],
          "results": context.schema['GeometryBag'],
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
        "Circle": documentCircle(context),
        "Rectangle": documentRectangle(context),
        "LineString": documentLineString(context),
        "GeometryBag": documentGeometryBag(context),
      };

  APISchemaObject documentGeometryBag(APIDocumentContext context) => APISchemaObject.object({
        "name": APISchemaObject.string()..description = "Geometry name",
        "description": APISchemaObject.string()..description = "Geometry description",
        "points": APISchemaObject.array(ofSchema: context.schema["Point"]),
        "lines": APISchemaObject.array(ofSchema: context.schema["LineString"]),
        "rectangles": APISchemaObject.array(ofSchema: context.schema["Rectangle"]),
        "circles": APISchemaObject.array(ofSchema: context.schema["Circle"]),
      })
        ..description = "Bag of points, linestrings, rectangles and circles"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// LineString - Value Object
  APISchemaObject documentLineString(APIDocumentContext context) => APISchemaObject.object({
        "name": APISchemaObject.string()..description = "Geometry name",
        "description": APISchemaObject.string()..description = "Geometry description",
        "points": APISchemaObject.array(ofType: APIType.object)
          ..items = context.schema['Point']
          ..description = "Collection of points on polyline"
          ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
        "closed": APISchemaObject.boolean()..description = "First and last point is connected forming a polygon"
      })
        ..description = "String of points forming a polyline (open) or polygon (closed) path"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Rectangle - Value Object
  APISchemaObject documentRectangle(APIDocumentContext context) => APISchemaObject.object({
        "name": APISchemaObject.string()..description = "Geometry name",
        "description": APISchemaObject.string()..description = "Geometry description",
        "nw": context.schema['Point']..description = "Upper left corner",
        "se": context.schema['Point']..description = "Lower right corner"
      })
        ..description = "Rectangle geometry"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  /// Rectangle - Value Object
  APISchemaObject documentCircle(APIDocumentContext context) => APISchemaObject.object({
        "name": APISchemaObject.string()..description = "Geometry name",
        "description": APISchemaObject.string()..description = "Geometry description",
        "center": context.schema['Point']..description = "Circle center",
        "radius": APISchemaObject.number()..description = "Circle radius"
      })
        ..description = "Circle geometry"
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
}
