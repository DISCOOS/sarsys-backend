import 'package:sarsys_core/sarsys_core.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';

abstract class StatusBaseController extends ResourceController with RequestValidatorMixin {
  StatusBaseController(
    this.type,
    this.config,
    this.modules, {
    this.tag,
    this.validation,
    this.readOnly = const [],
    this.validators = const [],
  });

  final String tag;

  final String type;

  final SarSysOpsConfig config;

  final List<String> modules;

  @override
  final List<String> readOnly;

  @override
  final JsonValidation validation;

  @override
  final List<Validator> validators;

  //////////////////////////////////
  // Status Operations
  //////////////////////////////////

  /// Add @Operation.get() to activate
  Future<Response> getAll() async {
    try {
      final statuses = <Map<String, dynamic>>[];
      for (var module in modules) {
        statuses.add(
          await doGetByName(module),
        );
      }
      return Response.ok(
        statuses,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Add @Operation.get('name') to activate
  Future<Response> getByName(@Bind.path('name') String name) async {
    try {
      return Response.ok(
        await doGetByName(name),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Map<String, dynamic>> doGetByName(String name) => throw UnimplementedError(
        'doGetByName not implemented',
      );

  /// Report error to Sentry and
  /// return 500 with message as body
  Response toServerError(Object error, StackTrace stackTrace) => serverError(
        request,
        error,
        stackTrace,
        logger: logger,
      );

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) =>
      tag == null ? super.documentOperationTags(context, operation) : [tag];

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case 'GET':
        summary = operation.pathVariables.isEmpty ? 'Get all ${_toName()}s' : 'Get ${_toName()}';
        break;
    }
    return summary;
  }

  String _toName() => type.toDelimiterCase(' ');

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = {
      '200': context.responses.getObject('200'),
      '401': context.responses.getObject('401'),
      '403': context.responses.getObject('403'),
      '500': context.responses.getObject('500'),
      '503': context.responses.getObject('503'),
      '504': context.responses.getObject('504'),
    };
    switch (operation.method) {
      case 'GET':
        if (operation.pathVariables.isEmpty) {
          responses.addAll({
            '200': APIResponse.schema(
              'Successful response.',
              APISchemaObject.array(
                ofSchema: context.schema[type],
              ),
            )
          });
        } else {
          responses.addAll({
            '200': APIResponse.schema(
              'Successful response',
              context.schema[type],
            ),
          });
        }
        break;
    }
    return responses;
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    documentSchemaObjects(context).forEach((name, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = '$name';
      }
      if (object.description?.isNotEmpty == false) {
        object.description = '$name schema';
      }
      context.schema.register(name, object);
    });
  }

  Map<String, APISchemaObject> documentSchemaObjects(APIDocumentContext context) => {
        type: documentStatusType(context),
      }..addAll(documentObjects(context));

  APISchemaObject documentStatusType(APIDocumentContext context);

  Map<String, APISchemaObject> documentObjects(APIDocumentContext context) => {};
}
