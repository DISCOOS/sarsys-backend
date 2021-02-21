import 'package:aqueduct/aqueduct.dart';

class DocumentController extends FileController {
  DocumentController() : super('web') {
    addCachePolicy(
      const CachePolicy(preventCaching: true),
      (p) => p.endsWith('client.html'),
    );
  }

  @override
  Logger get logger => Logger('$runtimeType');

  @override
  Map<String, APIOperation> documentOperations(APIDocumentContext context, String route, APIPath path) =>
      super.documentOperations(context, route, path)
        ..map((key, operation) => MapEntry(key, operation..tags = ['System']));
}
