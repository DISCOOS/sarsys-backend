import 'package:json_schema/json_schema.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

class RequestValidator {
  RequestValidator(this.specification);
  final Map<String, dynamic> specification;
  final Map<String, JsonSchema> validating = {};

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
        throw SchemaException("Specification $parent does not contain part $name");
      }
      throw SchemaException("Specification $parent is not a object map");
    });
    return data != null;
  }

  void validateBody(String schema, dynamic data) {
    if (!has("#/components/schemas/$schema")) {
      throw SchemaException("Schema $schema does not exist");
    }
    final errors = withSchema().validateWithErrors(data)
      ..removeWhere(
        (error) => error.message == 'uuid not supported as format',
      );
    if (errors.isNotEmpty) {
      throw SchemaException("Schema $schema has ${errors.length} errors: $errors");
    }
  }
}
