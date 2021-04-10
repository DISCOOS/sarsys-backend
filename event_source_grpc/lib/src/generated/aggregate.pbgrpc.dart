///
//  Generated code. Do not modify.
//  source: aggregate.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'aggregate.pb.dart' as $0;
export 'aggregate.pb.dart';

class AggregateGrpcServiceClient extends $grpc.Client {
  static final _$getMeta = $grpc.ClientMethod<$0.GetAggregateMetaRequest,
          $0.GetAggregateMetaResponse>(
      '/org.discoos.es.AggregateGrpcService/GetMeta',
      ($0.GetAggregateMetaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.GetAggregateMetaResponse.fromBuffer(value));
  static final _$searchMeta = $grpc.ClientMethod<$0.SearchAggregateMetaRequest,
          $0.SearchAggregateMetaResponse>(
      '/org.discoos.es.AggregateGrpcService/SearchMeta',
      ($0.SearchAggregateMetaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.SearchAggregateMetaResponse.fromBuffer(value));
  static final _$replayEvents = $grpc.ClientMethod<
          $0.ReplayAggregateEventsRequest, $0.ReplayAggregateEventsResponse>(
      '/org.discoos.es.AggregateGrpcService/ReplayEvents',
      ($0.ReplayAggregateEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.ReplayAggregateEventsResponse.fromBuffer(value));
  static final _$catchupEvents = $grpc.ClientMethod<
          $0.CatchupAggregateEventsRequest, $0.CatchupAggregateEventsResponse>(
      '/org.discoos.es.AggregateGrpcService/CatchupEvents',
      ($0.CatchupAggregateEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.CatchupAggregateEventsResponse.fromBuffer(value));
  static final _$replaceData = $grpc.ClientMethod<
          $0.ReplaceAggregateDataRequest, $0.ReplaceAggregateDataResponse>(
      '/org.discoos.es.AggregateGrpcService/ReplaceData',
      ($0.ReplaceAggregateDataRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.ReplaceAggregateDataResponse.fromBuffer(value));

  AggregateGrpcServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.GetAggregateMetaResponse> getMeta(
      $0.GetAggregateMetaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getMeta, request, options: options);
  }

  $grpc.ResponseFuture<$0.SearchAggregateMetaResponse> searchMeta(
      $0.SearchAggregateMetaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$searchMeta, request, options: options);
  }

  $grpc.ResponseFuture<$0.ReplayAggregateEventsResponse> replayEvents(
      $0.ReplayAggregateEventsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$replayEvents, request, options: options);
  }

  $grpc.ResponseFuture<$0.CatchupAggregateEventsResponse> catchupEvents(
      $0.CatchupAggregateEventsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$catchupEvents, request, options: options);
  }

  $grpc.ResponseFuture<$0.ReplaceAggregateDataResponse> replaceData(
      $0.ReplaceAggregateDataRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$replaceData, request, options: options);
  }
}

abstract class AggregateGrpcServiceBase extends $grpc.Service {
  $core.String get $name => 'org.discoos.es.AggregateGrpcService';

  AggregateGrpcServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetAggregateMetaRequest,
            $0.GetAggregateMetaResponse>(
        'GetMeta',
        getMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAggregateMetaRequest.fromBuffer(value),
        ($0.GetAggregateMetaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SearchAggregateMetaRequest,
            $0.SearchAggregateMetaResponse>(
        'SearchMeta',
        searchMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SearchAggregateMetaRequest.fromBuffer(value),
        ($0.SearchAggregateMetaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReplayAggregateEventsRequest,
            $0.ReplayAggregateEventsResponse>(
        'ReplayEvents',
        replayEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReplayAggregateEventsRequest.fromBuffer(value),
        ($0.ReplayAggregateEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CatchupAggregateEventsRequest,
            $0.CatchupAggregateEventsResponse>(
        'CatchupEvents',
        catchupEvents_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CatchupAggregateEventsRequest.fromBuffer(value),
        ($0.CatchupAggregateEventsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReplaceAggregateDataRequest,
            $0.ReplaceAggregateDataResponse>(
        'ReplaceData',
        replaceData_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReplaceAggregateDataRequest.fromBuffer(value),
        ($0.ReplaceAggregateDataResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetAggregateMetaResponse> getMeta_Pre($grpc.ServiceCall call,
      $async.Future<$0.GetAggregateMetaRequest> request) async {
    return getMeta(call, await request);
  }

  $async.Future<$0.SearchAggregateMetaResponse> searchMeta_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.SearchAggregateMetaRequest> request) async {
    return searchMeta(call, await request);
  }

  $async.Future<$0.ReplayAggregateEventsResponse> replayEvents_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.ReplayAggregateEventsRequest> request) async {
    return replayEvents(call, await request);
  }

  $async.Future<$0.CatchupAggregateEventsResponse> catchupEvents_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.CatchupAggregateEventsRequest> request) async {
    return catchupEvents(call, await request);
  }

  $async.Future<$0.ReplaceAggregateDataResponse> replaceData_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.ReplaceAggregateDataRequest> request) async {
    return replaceData(call, await request);
  }

  $async.Future<$0.GetAggregateMetaResponse> getMeta(
      $grpc.ServiceCall call, $0.GetAggregateMetaRequest request);
  $async.Future<$0.SearchAggregateMetaResponse> searchMeta(
      $grpc.ServiceCall call, $0.SearchAggregateMetaRequest request);
  $async.Future<$0.ReplayAggregateEventsResponse> replayEvents(
      $grpc.ServiceCall call, $0.ReplayAggregateEventsRequest request);
  $async.Future<$0.CatchupAggregateEventsResponse> catchupEvents(
      $grpc.ServiceCall call, $0.CatchupAggregateEventsRequest request);
  $async.Future<$0.ReplaceAggregateDataResponse> replaceData(
      $grpc.ServiceCall call, $0.ReplaceAggregateDataRequest request);
}
