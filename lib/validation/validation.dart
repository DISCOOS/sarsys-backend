import 'package:json_schema/json_schema.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

typedef Validator = List<ValidationError> Function(String type, dynamic data);

class RequestValidator {
  RequestValidator(this.specification, {List<Validator> validators}) : validators = validators ?? [];
  final Map<String, dynamic> specification;
  final Map<String, JsonSchema> validating = {};
  final List<Validator> validators;

  /// Validate OpenAPI schemas
  JsonSchema withSchema() {
    if (!validating.containsKey('schemas')) {
      validating['schemas'] = JsonSchema.createSchema({
        "components": {"schemas": specification["components"]["schemas"]}
      });
    }
    return validating['schemas'];
  }

  bool has(String ref) {
    final parts = ref.split('/');
    if (parts.first != '#') {
      throw SchemaException("$ref is not a json schema reference");
    }
    final data = parts.skip(1).fold(specification, (parent, name) {
      if (parent is Map<String, dynamic>) {
        if (parent.containsKey(name)) {
          return parent[name];
        }
        throw SchemaException("Specification does not contain part $name");
      }
      throw SchemaException("Specification is not a object map");
    });
    return data != null;
  }

  void validateBody(String type, dynamic data, {bool isPatch = false}) {
    if (!has("#/components/schemas/$type")) {
      throw SchemaException("Schema $type does not exist");
    }
    final schema = withSchema().resolvePath("#/components/schemas/$type");
    // Validate Json Schema
    final errors = schema.validateWithErrors(data)
      ..removeWhere(
        (error) => error.message == 'uuid not supported as format',
      );

    // Validate with custom validators
    errors.addAll(
      validators.fold([], (errors, validator) => List.of(errors)..addAll(validator(type, data))),
    );

    if (isPatch) {
      errors.removeWhere((error) => error.message.contains('required prop missing:'));
    }
    if (errors.isNotEmpty) {
      throw SchemaException("Schema $type has ${errors.length} errors: $errors");
    }
  }
}
