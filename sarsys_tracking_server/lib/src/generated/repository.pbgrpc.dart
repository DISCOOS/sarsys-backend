///
//  Generated code. Do not modify.
//  source: repository.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'repository.pb.dart' as $1;
export 'repository.pb.dart';

class RepositoryServiceClient extends $grpc.Client {
  static final _$getRepoMeta =
      $grpc.ClientMethod<$1.GetRepoMetaRequest, $1.GetRepoMetaResponse>(
          '/org.discoos.es.RepositoryService/GetRepoMeta',
          ($1.GetRepoMetaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $1.GetRepoMetaResponse.fromBuffer(value));

  RepositoryServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$1.GetRepoMetaResponse> getRepoMeta(
      $1.GetRepoMetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getRepoMeta, request, options: options);
  }
}

abstract class RepositoryServiceBase extends $grpc.Service {
  $core.String get $name => 'org.discoos.es.RepositoryService';

  RepositoryServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$1.GetRepoMetaRequest, $1.GetRepoMetaResponse>(
            'GetRepoMeta',
            getRepoMeta_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.GetRepoMetaRequest.fromBuffer(value),
            ($1.GetRepoMetaResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetRepoMetaResponse> getRepoMeta_Pre($grpc.ServiceCall call,
      $async.Future<$1.GetRepoMetaRequest> request) async {
    return getRepoMeta(call, await request);
  }

  $async.Future<$1.GetRepoMetaResponse> getRepoMeta(
      $grpc.ServiceCall call, $1.GetRepoMetaRequest request);
}
