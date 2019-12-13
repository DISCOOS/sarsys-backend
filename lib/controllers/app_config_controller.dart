import 'package:sarsys_app_server/eventstore/core.dart';
import 'package:sarsys_app_server/eventstore/events.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

class AppConfigController extends ResourceController {
  AppConfigController(this.connection);
  final EsConnection connection;

  // GET /app-config/:id
  @Operation.get('id')
  Future<Response> get(@Bind.path('id') String id) async {
    return Response.ok("GET /${request.path.segments.join('/')}");
  }

  // POST /app-config
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> body) async {
    final result = await connection.writeEvents(
      stream: 'app-config',
      events: [
        WriteEvent(type: 'AppConfigCreated', data: body),
      ],
    );
    return result.isOK ? _toLocation(result) : _toFailure(result);
  }

  Response _toFailure(WriteResult result) => Response(result.statusCode, {}, null);

  Response _toLocation(WriteResult result) => Response.created(
        "/${request.path.segments.join('/')}/${result.eventIds.last}",
      );
}
