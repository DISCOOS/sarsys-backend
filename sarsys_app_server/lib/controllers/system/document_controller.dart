import 'package:sarsys_app_server/app_server.dart';

class DocumentController extends FileController {
  DocumentController() : super("web") {
    addCachePolicy(
      const CachePolicy(preventCaching: true),
      (p) => p.endsWith("client.html"),
    );
  }

  @override
  Map<String, APIOperation> documentOperations(APIDocumentContext context, String route, APIPath path) =>
      super.documentOperations(context, route, path)
        ..map((key, operation) => MapEntry(key, operation..tags = ['System']));
}
