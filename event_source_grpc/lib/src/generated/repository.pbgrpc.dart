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
  static final _$getMeta =
      $grpc.ClientMethod<$1.GetRepoMetaRequest, $1.GetRepoMetaResponse>(
          '/org.discoos.es.RepositoryService/GetMeta',
          ($1.GetRepoMetaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $1.GetRepoMetaResponse.fromBuffer(value));
  static final _$replayEvents = $grpc.ClientMethod<$1.ReplayRepoEventsRequest,
          $1.ReplayRepoEventsResponse>(
      '/org.discoos.es.RepositoryService/ReplayEvents',
      ($1.ReplayRepoEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $1.ReplayRepoEventsResponse.fromBuffer(value));
  static final _$catchupEvents = $grpc.ClientMethod<$1.CatchupRepoEventsRequest,
          $1.CatchupRepoEventsResponse>(
      '/org.discoos.es.RepositoryService/CatchupEvents',
      ($1.CatchupRepoEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $1.CatchupRepoEventsResponse.fromBuffer(value));
  static final _$repair =
      $grpc.ClientMethod<$1.RepairRepoRequest, $1.RepairRepoResponse>(
          '/org.discoos.es.RepositoryService/Repair',
          ($1.RepairRepoRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $1.RepairRepoResponse.fromBuffer(value));
  static final _$rebuild =
      $grpc.ClientMethod<$1.RebuildRepoRequest, $1.RebuildRepoResponse>(
          '/org.discoos.es.RepositoryService/Rebuild',
          ($1.RebuildRepoRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $1.RebuildRepoResponse.fromBuffer(value));

  RepositoryServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$1.GetRepoMetaResponse> getMeta(
      $1.GetRepoMetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getMeta, request, options: options);
  }

  $grpc.ResponseFuture<$1.ReplayRepoEventsResponse> replayEvents(
      $1.ReplayRepoEventsRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$replayEvents, request, options: options);
  }

  $grpc.ResponseFuture<$1.CatchupRepoEventsResponse> catchupEvents(
      $1.CatchupRepoEventsRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$catchupEvents, request, options: options);
  }

  $grpc.ResponseFuture<$1.RepairRepoResponse> repair(
      $1.RepairRepoRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$repair, request, options: options);
  }

  $grpc.ResponseFuture<$1.RebuildRepoResponse> rebuild(
      $1.RebuildRepoRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$rebuild, request, options: options);
  }
}

abstract class RepositoryServiceBase extends $grpc.Service {
  $core.String get $name => 'org.discoos.es.RepositoryService';

  RepositoryServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$1.GetRepoMetaRequest, $1.GetRepoMetaResponse>(
            'GetMeta',
            getMeta_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.GetRepoMetaRequest.fromBuffer(value),
            ($1.GetRepoMetaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ReplayRepoEventsRequest,
            $1.ReplayRepoEventsResponse>(
        'ReplayEvents',
        replayEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.ReplayRepoEventsRequest.fromBuffer(value),
        ($1.ReplayRepoEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.CatchupRepoEventsRequest,
            $1.CatchupRepoEventsResponse>(
        'CatchupEvents',
        catchupEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.CatchupRepoEventsRequest.fromBuffer(value),
        ($1.CatchupRepoEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.RepairRepoRequest, $1.RepairRepoResponse>(
        'Repair',
        repair_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.RepairRepoRequest.fromBuffer(value),
        ($1.RepairRepoResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.RebuildRepoRequest, $1.RebuildRepoResponse>(
            'Rebuild',
            rebuild_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.RebuildRepoRequest.fromBuffer(value),
            ($1.RebuildRepoResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.GetRepoMetaResponse> getMeta_Pre($grpc.ServiceCall call,
      $async.Future<$1.GetRepoMetaRequest> request) async {
    return getMeta(call, await request);
  }

  $async.Future<$1.ReplayRepoEventsResponse> replayEvents_Pre(
      $grpc.ServiceCall call,
      $async.Future<$1.ReplayRepoEventsRequest> request) async {
    return replayEvents(call, await request);
  }

  $async.Future<$1.CatchupRepoEventsResponse> catchupEvents_Pre(
      $grpc.ServiceCall call,
      $async.Future<$1.CatchupRepoEventsRequest> request) async {
    return catchupEvents(call, await request);
  }

  $async.Future<$1.RepairRepoResponse> repair_Pre($grpc.ServiceCall call,
      $async.Future<$1.RepairRepoRequest> request) async {
    return repair(call, await request);
  }

  $async.Future<$1.RebuildRepoResponse> rebuild_Pre($grpc.ServiceCall call,
      $async.Future<$1.RebuildRepoRequest> request) async {
    return rebuild(call, await request);
  }

  $async.Future<$1.GetRepoMetaResponse> getMeta(
      $grpc.ServiceCall call, $1.GetRepoMetaRequest request);
  $async.Future<$1.ReplayRepoEventsResponse> replayEvents(
      $grpc.ServiceCall call, $1.ReplayRepoEventsRequest request);
  $async.Future<$1.CatchupRepoEventsResponse> catchupEvents(
      $grpc.ServiceCall call, $1.CatchupRepoEventsRequest request);
  $async.Future<$1.RepairRepoResponse> repair(
      $grpc.ServiceCall call, $1.RepairRepoRequest request);
  $async.Future<$1.RebuildRepoResponse> rebuild(
      $grpc.ServiceCall call, $1.RebuildRepoRequest request);
}
