import 'package:json_path/json_path.dart';

import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/devices/search](http://localhost/api/client.html#/Device) requests
class DeviceSearchController extends AggregateController<DeviceCommand, Device> {
  DeviceSearchController(DeviceRepository repository, JsonValidation validation)
      : super(
          repository,
          validation: validation,
          tag: "Devices",
        );

  @Operation('OPTIONS')
  Future<Response> options() async {
    return Response.noContent(
      headers: {'x-search-options': 'max-radius=100;'},
    );
  }

  static const matchTypes = ['any', 'all'];

  @Operation.get()
  Future<Response> search({
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
    @Bind.query('match') String match = 'any',
    @Bind.query('deleted') bool deleted = false,
    @Bind.query('pattern') List<String> pattern = const [],
  }) async {
    try {
      if (!matchTypes.contains(match)) {
        return Response.badRequest(
          body: "Illegal match type '$match', legal are '${matchTypes.join("','")}'",
        );
      }

      final filter = pattern.fold<Map<String, Predicate>>(
        {},
        (previous, query) => previous
          ..addAll(
            JsonQuery.from(query).customFilter,
          ),
      );
      final results = repository.searchAll(
        pattern,
        filter: filter,
        distinct: true,
        deleted: deleted,
        any: match.toLowerCase() == 'any',
      );
      return okAggregatePaged(
        results.length,
        offset,
        limit,
        results
            .map((match) => match.uuid)
            .toSet()
            .toPage(
              offset: offset,
              limit: limit,
            )
            .map(repository.get),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => context.schema[schemaName];

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

}
