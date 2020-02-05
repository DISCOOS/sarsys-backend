import 'package:sarsys_app_server/sarsys_app_server.dart';
import 'package:sarsys_app_server/validation/validation.dart';

mixin RequestValidatorMixin {
  List<String> readOnly;
  RequestValidator validator;

  Map<String, dynamic> validate(String type, Map<String, dynamic> data, {bool isPatch = false}) {
    // TODO: Refactor read-only checks into RequestValidator
    final errors = readOnly.where((field) => hasField(data, field)).map(
          (field) => "${field.startsWith('/') ? field : "/$field"}/uuid: is read only",
        );
    if (errors.isNotEmpty) {
      throw SchemaException("Schema $type has ${errors.length} errors: ${errors.join(",")}");
    }
    if (validator != null) {
      validator.validateBody("$type", data, isPatch: isPatch);
    }
    return data;
  }

  bool hasField(Map<String, dynamic> data, String field) {
    final parts = field.split('/');
    if (parts.isNotEmpty) {
      final found = parts.skip(parts.first.isEmpty ? 1 : 0).fold(data, (parent, name) {
        if (parent is Map<String, dynamic>) {
          if (parent.containsKey(name)) {
            return parent[name] is Map<String, dynamic> ? parent[name] : true;
          }
          return false;
        }
        return false;
      });
      return !(found == false || found == data);
    }
    return data.containsKey(field);
  }
}
