import 'package:sarsys_app_server/domain/app_config.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

class AppConfigController extends ResourceController {
  AppConfigController(this.repository);
  final Repository<AppConfig> repository;

  // TODO: Implement pagination
  // TODO: Implement optimistic locking (with rollback and reload of last state)

  // GET /app-config
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
  }) async =>
      Response.ok(repository.getAll().map((aggregate) => aggregate.data)?.toList() ?? []);

  // GET /app-config/:id
  @Operation.get('id')
  Future<Response> getById(@Bind.path('id') String uuid) async {
    if (!repository.contains(uuid)) {
      return Response.notFound();
    }
    final aggregate = repository.get(uuid);
    return Response.ok(aggregate.data);
  }

  // PATCH /app-config/:id
  @Operation('PATCH', 'id')
  Future<Response> patch(@Bind.path('id') String uuid, @Bind.body() Map<String, dynamic> body) async {
    if (!repository.contains(uuid)) {
      return Response.notFound();
    }
    repository.commit(repository.get(uuid).patch(repository.validate(body)));
    await repository.push();
    return Response.noContent();
  }

  // POST /app-config
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> body) async {
    final uuid = body['id'] as String;
    if (repository.contains(uuid)) {
      return Response.conflict();
    }
    repository.commit(repository.get(uuid, data: body));
    await repository.push();
    return Response.noContent();
  }
}
