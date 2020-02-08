import 'package:sarsys_app_server/validation/validation.dart';

mixin RequestValidatorMixin {
  List<String> readOnly;
  JsonValidation validator;
  List<ReadOnlyValidator> _validators;

  Map<String, dynamic> validate(String type, Map<String, dynamic> data, {bool isPatch = false}) {
    if (validator != null) {
      _validators ??= [ReadOnlyValidator(readOnly)];
      validator.validateBody("$type", data, isPatch: isPatch, validators: _validators);
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
