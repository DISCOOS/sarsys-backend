///
//  Generated code. Do not modify.
//  source: aggregate.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'aggregate.pb.dart' as $0;
export 'aggregate.pb.dart';

class AggregateServiceClient extends $grpc.Client {
  static final _$getMeta = $grpc.ClientMethod<$0.GetAggregateMetaRequest,
          $0.GetAggregateMetaResponse>(
      '/org.discoos.es.AggregateService/GetMeta',
      ($0.GetAggregateMetaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.GetAggregateMetaResponse.fromBuffer(value));
  static final _$replaceData = $grpc.ClientMethod<
          $0.ReplaceAggregateDataRequest, $0.ReplaceAggregateDataResponse>(
      '/org.discoos.es.AggregateService/ReplaceData',
      ($0.ReplaceAggregateDataRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.ReplaceAggregateDataResponse.fromBuffer(value));

  AggregateServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.GetAggregateMetaResponse> getMeta(
      $0.GetAggregateMetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getMeta, request, options: options);
  }

  $grpc.ResponseFuture<$0.ReplaceAggregateDataResponse> replaceData(
      $0.ReplaceAggregateDataRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$replaceData, request, options: options);
  }
}

abstract class AggregateServiceBase extends $grpc.Service {
  $core.String get $name => 'org.discoos.es.AggregateService';

  AggregateServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetAggregateMetaRequest,
            $0.GetAggregateMetaResponse>(
        'GetMeta',
        getMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAggregateMetaRequest.fromBuffer(value),
        ($0.GetAggregateMetaResponse value) => value.writeToBuffer()));
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

  $async.Future<$0.ReplaceAggregateDataResponse> replaceData_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.ReplaceAggregateDataRequest> request) async {
    return replaceData(call, await request);
  }

  $async.Future<$0.GetAggregateMetaResponse> getMeta(
      $grpc.ServiceCall call, $0.GetAggregateMetaRequest request);
  $async.Future<$0.ReplaceAggregateDataResponse> replaceData(
      $grpc.ServiceCall call, $0.ReplaceAggregateDataRequest request);
}
