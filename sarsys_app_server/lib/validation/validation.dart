import 'package:aqueduct/aqueduct.dart';
import 'package:json_schema/json_schema.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

class JsonValidation {
  JsonValidation(this.specification, {List<Validator> validators}) : validators = validators ?? [];
  final Map<String, dynamic> specification;
  final Map<String, JsonSchema> validating = {};
  final List<Validator> validators;

  /// Get [JsonValidation] with given [validators]
  JsonValidation copyWith(List<Validator> validators) =>
      JsonValidation(specification, validators: validators)..validating.addAll(validating);

  /// Validate OpenAPI schemas
  JsonSchema schemas() {
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

  void validateBody(String type, dynamic data, {bool isPatch = false, List<Validator> validators = const []}) {
    if (!has("#/components/schemas/$type")) {
      throw SchemaException("Schema $type does not exist");
    }
    final schema = schemas().resolvePath("#/components/schemas/$type");
    // Validate Json Schema
    final errors = schema.validateWithErrors(data)
      ..removeWhere(
        (error) => error.message == 'uuid not supported as format',
      );

    // Validate with custom validators
    errors.addAll(
      List<Validator>.from(validators).fold(
        [],
        (errors, validator) => List.of(errors)
          ..addAll(
            validator(type, data, this, isPatch: isPatch),
          ),
      ),
    );

    if (isPatch) {
      errors.removeWhere((error) => error.message.contains('required prop missing:'));
    }
    if (errors.isNotEmpty) {
      throw toException(type, errors);
    }
  }

  static SchemaException toException(String type, List<ValidationError> errors) => SchemaException(
        "Schema $type has ${errors.length} errors: $errors",
      );
}

abstract class Validator {
  List<ValidationError> call(String type, dynamic data, JsonValidation validation, {bool isPatch});
  bool hasField(Map<String, dynamic> data, String field) {
    final parts = field.split('/');
    if (parts.isNotEmpty) {
      final found = parts.skip(parts.first.isEmpty ? 1 : 0).fold(data, (parent, name) {
        if (parent is Map<String, dynamic>) {
          if (parent.containsKey(name)) {
            return parent[name] is Map<String, dynamic> ? parent[name] : true;
          }
        }
        return false;
      });
      return !(found == false || found == data);
    }
    return data.containsKey(field);
  }

  dynamic getValue(dynamic data, String ref) {
    dynamic found;
    final parts = ref.split('/');
    if (data is Map<String, dynamic>) {
      found = parts.skip(parts.first.isEmpty ? 1 : 0).fold(data, (parent, name) {
        if (parent is Map<String, dynamic>) {
          if (parent.containsKey(name)) {
            return parent[name];
          }
        }
        return (parent ?? {})[name];
      });
    }
    return found;
  }
}

class ReadOnlyValidator extends Validator {
  ReadOnlyValidator(List<String> readOnly) : _readOnly = List.from(readOnly);
  final List<String> _readOnly;

  @override
  List<ValidationError> call(String type, dynamic data, JsonValidation validation, {bool isPatch}) {
    final errors = <_ValidationError>[];
    if (data is Map<String, dynamic>) {
      errors.addAll(
        _readOnly.where((field) => hasField(data, field)).map(
              (field) => _ValidationError(
                "${field.startsWith('/') ? field : '/$field'}",
                "is read only",
                "#/components/schemas/$type",
              ),
            ),
      );
    }
    return errors;
  }
}

class ValueValidator extends Validator {
  ValueValidator({
    this.path,
    this.allowed,
    this.required = true,
  });

  final String path;
  final bool required;
  final List<dynamic> allowed;

  @override
  List<ValidationError> call(String type, dynamic data, JsonValidation validation, {bool isPatch}) {
    final found = getValue(data, path);
    final valueIsMissing = !(required || isPatch) && found == null;
    final valueIsIllegal = found != null && allowed.contains(found);
    return valueIsMissing || valueIsIllegal
        ? []
        : [_ValidationError(path, 'illegal value: $found, accepts: $allowed', path)];
  }
}

class _ValidationError implements ValidationError {
  _ValidationError(this.instancePath, this.message, this.schemaPath);
  @override
  String instancePath;

  @override
  String message;

  @override
  String schemaPath;

  @override
  String toString() => '${instancePath.isEmpty ? '# (root)' : instancePath}: $message';
}
