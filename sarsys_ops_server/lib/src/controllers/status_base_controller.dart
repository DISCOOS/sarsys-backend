import 'package:sarsys_http_core/sarsys_http_core.dart';
import 'package:sarsys_ops_server/src/config.dart';

abstract class StatusBaseController extends ResourceController with RequestValidatorMixin {
  StatusBaseController(
    this.type,
    this.config, {
    this.tag,
    this.validation,
    this.readOnly = const [],
    this.validators = const [],
  });

  final String tag;

  final String type;

  final SarSysOpsConfig config;

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
      return doGetAll();
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetAll() => throw UnimplementedError(
        'doGetAll not implemented',
      );

  /// Add @Operation.get('name') to activate
  Future<Response> getByName(@Bind.path('name') String name) async {
    try {
      return doGetByName(name);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doGetByName(String name) => throw UnimplementedError(
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
      '401': context.responses.getObject('401'),
      '403': context.responses.getObject('403'),
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
                ofSchema: documentStatusType(context),
              ),
            )
          });
        } else {
          responses.addAll({
            '200': APIResponse.schema(
              'Successful response',
              documentStatusType(context),
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
        'type': documentStatusType(context),
      }
        ..addAll(documentEntities(context))
        ..addAll(documentValues(context));

  APISchemaObject documentStatusType(APIDocumentContext context);

  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {};
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {};
}
