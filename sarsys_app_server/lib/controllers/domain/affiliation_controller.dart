import 'package:event_source/event_source.dart';
import 'package:sarsys_app_server/controllers/domain/schemas.dart';
import 'package:sarsys_app_server/controllers/event_source/aggregate_controller.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

/// A ResourceController that handles
/// [/api/affiliations](http://localhost/api/client.html#/Affiliations) requests
class AffiliationController extends AggregateController<AffiliationCommand, Affiliation> {
  AffiliationController(
    this.persons,
    AffiliationRepository affiliations,
    JsonValidation validation,
  ) : super(affiliations, validation: validation, tag: 'Affiliations');

  final PersonRepository persons;

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('filter') String filter,
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
    @Bind.query('deleted') bool deleted = false,
    @Bind.query('expand') List<String> expand = const [],
  }) async {
    try {
      final shouldMerge = _shouldMerge(expand);
      final shouldFilter = filter?.isNotEmpty == true;

      // Get aggregates
      final aggregates = repository.aggregates
          .where((a) => deleted || !a.isDeleted)
          .where((a) => !shouldFilter || _match(merge(a), filter));

      // Get actual page
      final page = aggregates.toPage(
        offset: offset,
        limit: limit,
      );

      return Response.ok(
        toDataPaged(
          aggregates.length,
          offset,
          limit,
          page.map(shouldMerge ? merge : toAggregateData),
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return serverError(e, stackTrace);
    }
  }

  static const keys = [
    'org',
    'div',
    'dep',
    'uuid',
    'data',
    'type',
    'fname',
    'lname',
    'email',
    'phone',
    'status',
    'person',
  ];

  bool _match(Map<String, dynamic> a, String filter) {
    final patterns = filter.toLowerCase().split(' ');
    final searchable = _toSearchable(a, keys).toLowerCase();
    return patterns.any(searchable.contains);
  }

  String _toSearchable(dynamic data, [List<String> keys = const []]) {
    if (data is List) {
      return data.map((value) => _toSearchable(value, keys)).join(' ');
    } else if (data is Map) {
      return data.keys
          .where((key) => keys.isEmpty || keys.contains(key))
          .map((key) => _toSearchable(data[key], keys))
          .join(' ');
    }
    return "$data";
  }

  bool _shouldMerge(List<String> expand) {
    if (expand.any((element) => element.toLowerCase() == 'person')) {
      return true;
    }
    if (expand.isNotEmpty) {
      throw "Invalid query parameter 'expand' values: $expand, expected any of: {person}";
    }
    return false;
  }

  /// Merge [Affiliation] with [Person]
  Map<String, dynamic> merge(Affiliation aggregate) {
    final entry = toAggregateData(aggregate);
    final affiliation = entry.elementAt<Map<String, dynamic>>('data');
    final puuid = affiliation.elementAt<String>('person/uuid');
    entry.update('data', (value) => _mergePerson(puuid, affiliation));
    return entry;
  }

  Map<String, dynamic> _mergePerson(String puuid, Map<String, dynamic> affiliation) {
    if (puuid != null) {
      final person = persons.get(puuid, createNew: false);
      if (person != null) {
        return Map.from(affiliation)..addAll({'person': person.data});
      }
    }
    return affiliation;
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') List<String> expand = const [],
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      return Response.ok(
        _shouldMerge(expand) ? merge(aggregate) : toAggregateData(aggregate),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return serverError(e, stackTrace);
    }
  }

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) {
    return super.create(data);
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, data);
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, data: data);
  }

  @override
  AffiliationCommand onCreate(Map<String, dynamic> data) => CreateAffiliation(data);

  @override
  AffiliationCommand onUpdate(Map<String, dynamic> data) => UpdateAffiliation(data);

  @override
  AffiliationCommand onDelete(Map<String, dynamic> data) => DeleteAffiliation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  /// Affiliation - Aggregate root
  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => APISchemaObject.object({
        "uuid": context.schema['UUID']..description = "Unique Affiliation id",
        "person": documentAggregateRef(
          context,
          defaultType: 'Person',
          description: "Person reference for PII lookup",
        ),
        "org": documentAggregateRef(
          context,
          readOnly: false,
          defaultType: 'Organisation',
          description: "Organisation which personnel is affiliated with",
        ),
        "div": documentAggregateRef(
          context,
          readOnly: false,
          defaultType: 'Division',
          description: "Division which personnel is affiliated with",
        ),
        "dep": documentAggregateRef(
          context,
          readOnly: false,
          description: "Department which personnel is affiliated with",
          defaultType: 'Department',
        ),
        "type": documentAffiliationType(),
        "status": documentAffiliationStandbyStatus(),
        "active": APISchemaObject.boolean()..description = "Affiliation status flag"
      })
        ..description = "Affiliation information"
        ..required = ['person']
        ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;

  @override
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {
        "AffiliationType": documentAffiliationType(),
        "AffiliationStandbyStatus": documentAffiliationType(),
      };

  APISchemaObject documentAffiliationType() => APISchemaObject.string()
    ..description = "Affiliation type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "member"
    ..enumerated = [
      'member',
      'employee',
      'external',
      'volunteer',
    ];

  APISchemaObject documentAffiliationStandbyStatus() => APISchemaObject.string()
    ..description = "Personnel standby status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "available"
    ..enumerated = [
      'available',
      'short_notice',
      'unavailable',
    ];
}
