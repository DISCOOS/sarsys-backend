import 'package:mime/mime.dart';
import 'package:fixnum/fixnum.dart';
import 'package:filesize/filesize.dart';
import 'package:chunked_stream/chunked_stream.dart';
import 'package:event_source_grpc/event_source_grpc.dart';
import 'package:grpc/grpc.dart' hide Response;
import 'package:grpc/grpc_connection_interface.dart';
import 'package:sarsys_ops_server/sarsys_ops_server.dart';
import 'package:sarsys_ops_server/src/config.dart';
import 'package:sarsys_core/sarsys_core.dart';

import 'component_base_controller.dart';

class SnapshotGrpcFileServiceController extends ComponentBaseController {
  SnapshotGrpcFileServiceController(
    this.k8s,
    this.channels,
    SarSysOpsConfig config,
    Map<String, dynamic> context,
  ) : super(
          'SnapshotFileService',
          config,
          tag: 'Services',
          context: context,
          modules: [
            'sarsys-app-server',
            'sarsys-tracking-server',
          ],
          options: [
            'all',
            'data',
            'items',
            'metrics',
          ],
        ) {
    acceptedContentTypes = [
      ContentType.json,
      ContentType('multipart', 'form-data'),
    ];
  }

  final K8sApi k8s;
  final Map<String, ClientChannel> channels;
  final Map<String, SnapshotGrpcServiceClient> _clients = {};

  @Scope(['roles:admin'])
  @Operation.get('type', 'name')
  Future<Response> downloadByNameAndType(
    @Bind.path('name') String name,
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
    @Bind.query('chunkSize') int chunkSize = 4096,
  }) async {
    try {
      final pod = await _getPod(
        name,
      );
      if (pod?.isNotEmpty != true) {
        return toResponse(
          name: name,
          type: type,
          args: {
            'chunkSize': chunkSize,
            'expand': expand,
          },
          statusCode: HttpStatus.notFound,
          method: 'doGetMetaByNameAndType',
          body: "$target instance '$name' not found",
        );
      }
      return doDownload(
        type,
        pod,
        chunkSize,
        expand,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  List<SnapshotExpandFields> toExpandFields(String expand) {
    return [
      if (shouldExpand(expand, 'all')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ALL,
      if (shouldExpand(expand, 'data')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_DATA,
      if (shouldExpand(expand, 'items')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ITEMS,
      if (shouldExpand(expand, 'metrics')) SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_METRICS,
    ];
  }

  @Scope(['roles:admin'])
  @Operation.post('type')
  Future<Response> uploadByType(
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
    @Bind.query('chunkSize') int chunkSize = 4096,
  }) async {
    try {
      final pods = await k8s.getPodsFromNs(
        k8s.namespace,
        labels: toModuleLabels(),
      );
      return doUploadAll(
        type,
        pods,
        chunkSize,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doUploadAll(
    String type,
    List<Map<String, dynamic>> pods,
    int chunkSize,
    String expand,
  ) async {
    File file;
    final names = <String>[];
    final items = <Map<String, dynamic>>[];

    try {
      // Get file from caller once
      file = await _getFile(type);

      for (var pod in pods) {
        final meta = await _doUpload(
          type,
          file,
          pod,
          chunkSize,
          expand,
        );
        items.add(meta);
        names.add(
          k8s.toPodName(pod),
        );
      }

      return toResponse(
        type: type,
        names: names,
        method: 'doUploadAll',
        body: toJsonItemsMeta(
          items,
        ),
        args: {
          'chunkSize': chunkSize,
          'expand': expand,
        },
        statusCode: toStatusCode(items),
      );
    } on Exception catch (error, stackTrace) {
      logger.severe(
        'Upload failed with $error',
        error,
        stackTrace,
      );
      return toResponse(
        type: type,
        names: names,
        method: 'doUploadAll',
        body: 'Upload failed with $error',
        args: {
          'chunkSize': chunkSize,
          'expand': expand,
        },
        statusCode: HttpStatus.internalServerError,
      );
    } finally {
      file?.deleteSync();
    }
  }

  @Scope(['roles:admin'])
  @Operation.post('type', 'name')
  Future<Response> uploadByNameAndType(
    @Bind.path('name') String name,
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
    @Bind.query('chunkSize') int chunkSize = 4096,
  }) async {
    try {
      final pod = await _getPod(
        name,
      );
      if (pod?.isNotEmpty != true) {
        return toResponse(
          name: name,
          type: type,
          args: {
            'chunkSize': chunkSize,
            'expand': expand,
          },
          statusCode: HttpStatus.notFound,
          method: 'doGetMetaByNameAndType',
          body: "$target instance '$name' not found",
        );
      }
      return doUpload(
        type,
        pod,
        chunkSize,
        expand,
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> doUpload(
    String type,
    Map<String, dynamic> pod,
    int chunkSize,
    String expand,
  ) async {
    File file;
    final name = k8s.toPodName(pod);

    try {
      // Get file from caller once
      file = await _getFile(type);

      final meta = await _doUpload(
        type,
        file,
        pod,
        chunkSize,
        expand,
      );

      return toResponse(
        type: type,
        name: name,
        body: meta,
        method: 'doUpload',
        args: {
          'chunkSize': chunkSize,
          'expand': expand,
        },
        statusCode: toStatusCode([meta]),
      );
    } on Exception catch (error, stackTrace) {
      logger.severe(
        'Upload failed with $error',
        error,
        stackTrace,
      );
      return toResponse(
        type: type,
        name: name,
        method: 'doUpload',
        body: 'Upload failed with $error',
        args: {
          'chunkSize': chunkSize,
          'expand': expand,
        },
        statusCode: HttpStatus.internalServerError,
      );
    } finally {
      file?.deleteSync();
    }
  }

  Future<File> _getFile(String type) async {
    // Prepare for receiving data from client
    final boundary = request.raw.headers.contentType.parameters['boundary'];
    final transformer = MimeMultipartTransformer(boundary);
    final bodyBytes = await request.body.decode<List<int>>();

    // Pay special attention to the square brackets in the argument:
    final bodyStream = Stream.fromIterable([bodyBytes]);
    final parts = await transformer.bind(bodyStream).toList();

    // Prepare file
    final name = '$type-upload-${DateTime.now().millisecondsSinceEpoch}.hive';
    final path = '${Directory.systemTemp.path}/$name';
    final file = File(path);

    // Fetch all parts
    var fetched = 0;
    final length = request.raw.headers.contentLength;
    await for (var content in parts.first) {
      fetched += content.length;
      // ignore: unnecessary_parenthesis
      logger.info('Snapshots uploading... ${(fetched ~/ length)}% (${filesize(fetched)})');
      await file.writeAsBytes(content);
    }
    final size = file.statSync().size;
    logger.info('Snapshots uploading... 100% (${filesize(size)})');
    return file;
  }

  Future<Map<String, dynamic>> _doUpload(
    String type,
    File file,
    Map<String, dynamic> pod,
    int chunkSize,
    String expand,
  ) async {
    final fileSize = file.statSync().size;
    final chunkReader = ChunkedStreamIterator(file.openRead()).substream(chunkSize).map((content) => SnapshotChunk()
      ..type = type
      ..chunk = (FileChunk()
        ..content = content
        ..fileSize = Int64(fileSize)
        ..chunkSize = Int64(chunkSize)));

    final response = await toClient(pod).upload(
      chunkReader,
    );
    return toJsonCommandMeta(
      toProto3JsonInstanceMeta(
        k8s.toPodName(pod),
        response.meta,
      ),
      response.statusCode,
      response.reasonPhrase,
    );
  }

  Future<Response> doDownload(
    String type,
    Map<String, dynamic> pod,
    int chunkSize,
    String expand,
  ) async {
    File file;
    final name = k8s.toPodName(pod);

    final args = {
      'command': 'download',
      'chunkSize': chunkSize,
      'expand': expand,
    };

    try {
      file = await _doDownload(
        type,
        pod,
        chunkSize,
        expand,
      );

      return toResponse(
        name: name,
        type: type,
        args: args,
        method: 'doDownload',
        body: file.openRead(),
        statusCode: HttpStatus.ok,
      )
        ..encodeBody = false
        ..contentType = ContentType(
          'application',
          'octet-stream',
        );
    } on Exception catch (error, stackTrace) {
      logger.severe(
        'Download failed with $error',
        error,
        stackTrace,
      );
      return toResponse(
        type: type,
        name: name,
        method: 'doDownload',
        body: 'Download failed with $error',
        args: {
          'chunkSize': chunkSize,
          'expand': expand,
        },
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  Future<File> _doDownload(
    String type,
    Map<String, dynamic> pod,
    int chunkSize,
    String expand,
  ) async {
    if (pod.isEmpty) {
      throw const InvalidOperation('Pod is empty');
    }
    final response = toClient(pod).download(
      DownloadSnapshotRequest()
        ..type = type
        ..chunkSize = Int64(chunkSize),
    );

    // Prepare
    final name = k8s.toPodName(pod);
    final path = '${Directory.systemTemp.path}/$type-download-${DateTime.now().millisecondsSinceEpoch}.hive';
    final file = File(path);
    var fetched = 0;
    await for (var chunk in response) {
      fetched += chunk.content.length;
      logger.info(
        'Downloading snapshot $type from $name... ${fetched ~/ chunk.fileSize.toInt()}% (${filesize(fetched)})',
      );
      await file.writeAsBytes(chunk.content);
    }
    return file;
  }

  SnapshotGrpcServiceClient toClient(Map<String, dynamic> pod) {
    final uri = k8s.toPodUri(
      pod,
      port: config.tracking.grpcPort,
    );
    final channel = channels.putIfAbsent(
      uri.authority,
      () => ClientChannel(
        uri.host,
        port: uri.port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      ),
    );
    final client = _clients.putIfAbsent(
      uri.authority,
      () => SnapshotGrpcServiceClient(
        channel,
        options: CallOptions(
          timeout: const Duration(
            seconds: 30,
          ),
        ),
      ),
    );
    logger.fine(
      Context.toMethod('toClient', [
        'host: ${channel.host}',
        'port: ${channel.port}',
      ]),
    );
    return client;
  }

  Future<Map<String, dynamic>> _getPod(String name) async {
    return await k8s.getPodInNs(
      k8s.namespace,
      name,
    );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary = super.documentOperationSummary(context, operation);
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
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case 'POST':
        parameters.add(
          APIParameter.query('chunkSize')
            ..description = 'Size of each file chunk in number of bytes (default is 4096 bytes)',
        );
        break;
    }
    return parameters;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    final body = super.documentOperationRequestBody(context, operation);
    switch (operation.method) {
      case 'POST':
        return APIRequestBody.schema(
          APISchemaObject.file(),
          description: 'Snapshot file data posted as multipart/form-data',
          required: true,
        );
        break;
    }
    return body;
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = super.documentOperationResponses(context, operation);
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
    }
    return responses;
  }

  @override
  Map<String, APISchemaObject> documentSchemaObjects(APIDocumentContext context) => {
        '${target}Command': documentCommand(documentCommandParams(context)),
        '${target}CommandResult': documentCommandResult(context),
        '${target}InstanceCommand': documentInstanceCommand(documentInstanceCommandParams(context)),
        '${target}InstanceCommandResult': documentInstanceCommandResult(context),
      };

  @override
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) =>
      documentInstanceCommandParams(context);

  @override
  APISchemaObject documentInstanceMeta(APIDocumentContext context) => documentSnapshotMeta(context);
}
