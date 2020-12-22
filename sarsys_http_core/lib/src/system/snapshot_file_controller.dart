import 'package:hive/hive.dart';
import 'package:mime/mime.dart';
import 'package:filesize/filesize.dart';
import 'package:sarsys_http_core/sarsys_http_core.dart';
import 'package:stack_trace/stack_trace.dart';

/// A [ResourceController] for [SnapshotModel] operations requests on [Storage]
class SnapshotFileController extends ResourceController {
  SnapshotFileController(
    this.manager, {
    @required this.tag,
    @required this.config,
    @required this.context,
  }) {
    acceptedContentTypes = [
      ContentType.json,
      ContentType('multipart', 'form-data'),
    ];
  }

  final String tag;
  final SarSysConfig config;
  final RepositoryManager manager;
  final Map<String, dynamic> context;
  final List<String> options = const [
    'data',
    'items',
  ];

  String get dataPath => config.data.path ?? context['data_path'];

  String get(String name) => context[name] ?? Platform.environment[name];

  bool contains(String name) => context.containsKey(name) || Platform.environment.containsKey(name);

  bool shouldAccept() {
    if (contains('POD_NAME')) {
      final name = get('POD_NAME');
      final match = request.raw.headers.value('x-if-match-pod');
      return match == null || name == null || match.toLowerCase() == name.toLowerCase();
    }
    return true;
  }

  bool shouldExpand(String expand, String field) {
    final elements = expand?.split(',') ?? <String>[];
    if (elements.any((element) => element.toLowerCase() == field)) {
      return true;
    }
    elements.removeWhere(
      (e) => !options.contains(e),
    );
    return false;
  }

  /// Report error to Sentry and
  /// return 500 with message as body
  Response toServerError(Object error, StackTrace stackTrace) => serverError(
        request,
        error,
        stackTrace,
        logger: logger,
      );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Scope(['roles:admin'])
  @Operation.post('type')
  Future<Response> upload(
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      if (!shouldAccept()) {
        return requestedRangeNotSatisfiable();
      }
      final repository = manager.getFromTypeName(type);
      if (repository == null) {
        return Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      return onUpload(
        repository,
        expand,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @Scope(['roles:admin'])
  @Operation.get('type')
  Future<Response> download(
    @Bind.path('type') String type,
  ) async {
    try {
      if (!shouldAccept()) {
        return requestedRangeNotSatisfiable();
      }
      final repository = manager.getFromTypeName(type);
      if (repository == null) {
        return Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      return onDownload(
        repository,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> onDownload(
    Repository repository,
  ) async {
    final snapshots = repository.store.snapshots;
    if (snapshots == null) {
      return Response.badRequest(
        body: 'Snapshots not activated',
      );
    }

    final old = snapshots.automatic;
    try {
      // Prevent snapshots being saved during download
      snapshots.automatic = false;

      // Streaming the contents from disk
      final file = File(_toHiveFilePath(snapshots, 'hive'));
      return Response.ok(file.openRead())
        ..encodeBody = false
        ..contentType = ContentType('application', 'octet-stream');
    } finally {
      snapshots.automatic = old;
    }
  }

  Future<Response> onUpload(
    Repository repository,
    String expand,
  ) async {
    final snapshots = repository.store.snapshots;
    if (snapshots == null) {
      return Response.badRequest(
        body: 'Snapshots not activated',
      );
    }

    // Prevent snapshots being
    // saved during upload
    final old = snapshots.automatic;
    snapshots.automatic = false;
    repository.store.pause();

    // Take backup of hive files
    final postfix = '${DateTime.now().millisecondsSinceEpoch}';
    final hivePath = _backupFile(snapshots, postfix, 'hive');
    _backupFile(snapshots, postfix, 'lock');

    try {
      // Prepare for receiving data from client
      final boundary = request.raw.headers.contentType.parameters['boundary'];
      final transformer = MimeMultipartTransformer(boundary);
      final bodyBytes = await request.body.decode<List<int>>();

      // Pay special attention to the square brackets in the argument:
      final bodyStream = Stream.fromIterable([bodyBytes]);
      final parts = await transformer.bind(bodyStream).toList();

      // Fetch all parts
      for (var part in parts) {
        final content = await part.toList();

        final name = _toFileName(part);
        final path = '${Directory.systemTemp.path}/$name';
        final file = File(path);

        final length = content.length;
        for (var i = 0; i < length; i++) {
          final item = content[i];
          logger.info('Snapshots uploading... ${(i ~/ length)}% (${filesize(item.length)})');
          await file.writeAsBytes(item);
        }
        final size = file.statSync().size;
        logger.info('Snapshots uploading... 100% (${filesize(size)})');

        // Overwrite snapshots file
        await file.copy(hivePath);
        file.deleteSync();
      }

      // Attempt to reload
      final reloaded = await _reload(repository);

      if (!reloaded) {
        final restored = await _restore(
          repository,
          postfix,
        );
        if (!restored) {
          return serverError(
            request,
            'Unable to restore from backup',
            Trace.current(),
          );
        }
        return Response.badRequest(
          body: 'Was not able to load snapshot data',
        );
      }

      return Response.ok(
        snapshots.toMeta(
          current: repository.number,
          type: repository.aggregateType,
          uuid: repository.snapshot?.uuid,
          data: shouldExpand(expand, 'data'),
          items: shouldExpand(expand, 'items'),
        ),
      );
    } on HiveError catch (error, stackTrace) {
      return serverError(
        request,
        error,
        stackTrace,
      );
    } finally {
      snapshots.automatic = old;
      repository.store.resume();
    }
  }

  Future<bool> _restore(Repository repo, String postfix) {
    _restoreFile(repo.store.snapshots, postfix, 'hive');
    _restoreFile(repo.store.snapshots, postfix, 'lock');
    return _reload(repo);
  }

  Future<bool> _reload(Repository repo) async {
    final path = _toHiveFilePath(repo.store.snapshots, 'hive');
    final size = File(path).statSync().size;
    await repo.store.snapshots.unload();
    await repo.store.snapshots.load();
    await repo.replay();
    // Crash recovery has been
    // performed if file size has
    // changed (Hive changes it)
    return File(path).statSync().size == size;
  }

  String _toHiveFilePath(Storage snapshots, String extension) => '$dataPath/${snapshots.filename}.$extension';

  String _toBackupFilePath(Storage snapshots, String postfix, String extension) =>
      '${Directory.systemTemp.path}/${snapshots.filename}-$postfix.$extension.bck';

  String _backupFile(Storage snapshots, String postfix, String extension) {
    final hivePath = _toHiveFilePath(snapshots, extension);
    final hiveFile = File(hivePath);
    final backupPath = _toBackupFilePath(snapshots, postfix, extension);
    if (hiveFile.existsSync()) {
      hiveFile.copySync(backupPath);
    }
    return hivePath;
  }

  void _restoreFile(Storage snapshots, String postfix, String extension) {
    final hivePath = _toHiveFilePath(snapshots, extension);
    final backupPath = _toBackupFilePath(snapshots, postfix, extension);
    final backupFile = File(backupPath);
    if (backupFile.existsSync()) {
      backupFile.copySync(hivePath);
      backupFile.deleteSync();
    }
  }

  String _toFileName(MimeMultipart part) {
    // TODO: Validate mime content!

    final tokens = part.headers['content-disposition'].split(';');
    String name;
    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i].contains('filename')) {
        name = tokens[i].substring(tokens[i].indexOf('=') + 2, tokens[i].length - 1);
      }
    }
    return name;
  }

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
        summary = 'Download snapshot file data';
        break;
      case 'POST':
        summary = 'Upload snapshot file as multipart/form-data';
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    return '${documentOperationSummary(context, operation)}.';
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case 'GET':
        parameters.add(
          APIParameter.query('expand')
            ..description = 'Expand response with metadata. '
                "Legal values are: '${options.join("', '")}'",
        );
        break;
    }
    return parameters;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
        return APIRequestBody.schema(
          APISchemaObject.file(),
          description: 'Snapshot file data posted as multipart/form-data',
          required: true,
        );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = {
      '200': context.responses.getObject('200'),
      '400': context.responses.getObject('400'),
      '401': context.responses.getObject('401'),
      '403': context.responses.getObject('403'),
      '416': context.responses.getObject('416'),
      '429': context.responses.getObject('429'),
      '500': context.responses.getObject('503'),
      '503': context.responses.getObject('503'),
      '504': context.responses.getObject('504'),
    };
    switch (operation.method) {
      case 'GET':
        responses.addAll({
          '200': APIResponse.schema(
            'Successful response.',
            APISchemaObject.string()
              ..format = 'binary'
              ..description = 'Snapshot file data',
          ),
        });
        break;
      case 'POST':
        responses.addAll({
          '200': APIResponse.schema(
            'Successful response.',
            context.schema['SnapshotMeta'],
          ),
        });
        break;
    }
    return responses;
  }
}
