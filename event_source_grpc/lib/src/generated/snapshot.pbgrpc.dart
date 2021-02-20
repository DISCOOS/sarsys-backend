///
//  Generated code. Do not modify.
//  source: snapshot.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'snapshot.pb.dart' as $2;
import 'file.pb.dart' as $3;
export 'snapshot.pb.dart';

class SnapshotGrpcServiceClient extends $grpc.Client {
  static final _$getMeta =
      $grpc.ClientMethod<$2.GetSnapshotMetaRequest, $2.GetSnapshotMetaResponse>(
          '/org.discoos.es.SnapshotGrpcService/GetMeta',
          ($2.GetSnapshotMetaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.GetSnapshotMetaResponse.fromBuffer(value));
  static final _$configure = $grpc.ClientMethod<$2.ConfigureSnapshotRequest,
          $2.ConfigureSnapshotResponse>(
      '/org.discoos.es.SnapshotGrpcService/Configure',
      ($2.ConfigureSnapshotRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $2.ConfigureSnapshotResponse.fromBuffer(value));
  static final _$save =
      $grpc.ClientMethod<$2.SaveSnapshotRequest, $2.SaveSnapshotResponse>(
          '/org.discoos.es.SnapshotGrpcService/Save',
          ($2.SaveSnapshotRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.SaveSnapshotResponse.fromBuffer(value));
  static final _$download =
      $grpc.ClientMethod<$2.DownloadSnapshotRequest, $3.FileChunk>(
          '/org.discoos.es.SnapshotGrpcService/Download',
          ($2.DownloadSnapshotRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $3.FileChunk.fromBuffer(value));
  static final _$upload =
      $grpc.ClientMethod<$2.SnapshotChunk, $2.UploadSnapshotResponse>(
          '/org.discoos.es.SnapshotGrpcService/Upload',
          ($2.SnapshotChunk value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.UploadSnapshotResponse.fromBuffer(value));

  SnapshotGrpcServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$2.GetSnapshotMetaResponse> getMeta(
      $2.GetSnapshotMetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getMeta, request, options: options);
  }

  $grpc.ResponseFuture<$2.ConfigureSnapshotResponse> configure(
      $2.ConfigureSnapshotRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$configure, request, options: options);
  }

  $grpc.ResponseFuture<$2.SaveSnapshotResponse> save(
      $2.SaveSnapshotRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$save, request, options: options);
  }

  $grpc.ResponseStream<$3.FileChunk> download(
      $2.DownloadSnapshotRequest request,
      {$grpc.CallOptions options}) {
    return $createStreamingCall(
        _$download, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$2.UploadSnapshotResponse> upload(
      $async.Stream<$2.SnapshotChunk> request,
      {$grpc.CallOptions options}) {
    return $createStreamingCall(_$upload, request, options: options).single;
  }
}

abstract class SnapshotGrpcServiceBase extends $grpc.Service {
  $core.String get $name => 'org.discoos.es.SnapshotGrpcService';

  SnapshotGrpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$2.GetSnapshotMetaRequest,
            $2.GetSnapshotMetaResponse>(
        'GetMeta',
        getMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.GetSnapshotMetaRequest.fromBuffer(value),
        ($2.GetSnapshotMetaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.ConfigureSnapshotRequest,
            $2.ConfigureSnapshotResponse>(
        'Configure',
        configure_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.ConfigureSnapshotRequest.fromBuffer(value),
        ($2.ConfigureSnapshotResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$2.SaveSnapshotRequest, $2.SaveSnapshotResponse>(
            'Save',
            save_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.SaveSnapshotRequest.fromBuffer(value),
            ($2.SaveSnapshotResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.DownloadSnapshotRequest, $3.FileChunk>(
        'Download',
        download_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $2.DownloadSnapshotRequest.fromBuffer(value),
        ($3.FileChunk value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.SnapshotChunk, $2.UploadSnapshotResponse>(
        'Upload',
        upload,
        true,
        false,
        ($core.List<$core.int> value) => $2.SnapshotChunk.fromBuffer(value),
        ($2.UploadSnapshotResponse value) => value.writeToBuffer()));
  }

  $async.Future<$2.GetSnapshotMetaResponse> getMeta_Pre($grpc.ServiceCall call,
      $async.Future<$2.GetSnapshotMetaRequest> request) async {
    return getMeta(call, await request);
  }

  $async.Future<$2.ConfigureSnapshotResponse> configure_Pre(
      $grpc.ServiceCall call,
      $async.Future<$2.ConfigureSnapshotRequest> request) async {
    return configure(call, await request);
  }

  $async.Future<$2.SaveSnapshotResponse> save_Pre($grpc.ServiceCall call,
      $async.Future<$2.SaveSnapshotRequest> request) async {
    return save(call, await request);
  }

  $async.Stream<$3.FileChunk> download_Pre($grpc.ServiceCall call,
      $async.Future<$2.DownloadSnapshotRequest> request) async* {
    yield* download(call, await request);
  }

  $async.Future<$2.GetSnapshotMetaResponse> getMeta(
      $grpc.ServiceCall call, $2.GetSnapshotMetaRequest request);
  $async.Future<$2.ConfigureSnapshotResponse> configure(
      $grpc.ServiceCall call, $2.ConfigureSnapshotRequest request);
  $async.Future<$2.SaveSnapshotResponse> save(
      $grpc.ServiceCall call, $2.SaveSnapshotRequest request);
  $async.Stream<$3.FileChunk> download(
      $grpc.ServiceCall call, $2.DownloadSnapshotRequest request);
  $async.Future<$2.UploadSnapshotResponse> upload(
      $grpc.ServiceCall call, $async.Stream<$2.SnapshotChunk> request);
}
