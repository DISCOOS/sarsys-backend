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
export 'snapshot.pb.dart';

class SnapshotServiceClient extends $grpc.Client {
  static final _$getRepoMeta = $grpc.ClientMethod<$2.GetSnapshotMetaRequest,
          $2.GetSnapshotsMetaResponse>(
      '/org.discoos.es.SnapshotService/GetRepoMeta',
      ($2.GetSnapshotMetaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $2.GetSnapshotsMetaResponse.fromBuffer(value));

  SnapshotServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$2.GetSnapshotsMetaResponse> getRepoMeta(
      $2.GetSnapshotMetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getRepoMeta, request, options: options);
  }
}

abstract class SnapshotServiceBase extends $grpc.Service {
  $core.String get $name => 'org.discoos.es.SnapshotService';

  SnapshotServiceBase() {
    $addMethod($grpc.ServiceMethod<$2.GetSnapshotMetaRequest,
            $2.GetSnapshotsMetaResponse>(
        'GetRepoMeta',
        getRepoMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.GetSnapshotMetaRequest.fromBuffer(value),
        ($2.GetSnapshotsMetaResponse value) => value.writeToBuffer()));
  }

  $async.Future<$2.GetSnapshotsMetaResponse> getRepoMeta_Pre(
      $grpc.ServiceCall call,
      $async.Future<$2.GetSnapshotMetaRequest> request) async {
    return getRepoMeta(call, await request);
  }

  $async.Future<$2.GetSnapshotsMetaResponse> getRepoMeta(
      $grpc.ServiceCall call, $2.GetSnapshotMetaRequest request);
}
