///
//  Generated code. Do not modify.
//  source: sarsys_tracking_service.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'sarsys_tracking_service.pb.dart' as $0;
export 'sarsys_tracking_service.pb.dart';

class SarSysTrackingServiceClient extends $grpc.Client {
  static final _$start =
      $grpc.ClientMethod<$0.StartTrackingRequest, $0.StartTrackingResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/start',
          ($0.StartTrackingRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.StartTrackingResponse.fromBuffer(value));
  static final _$stop =
      $grpc.ClientMethod<$0.StopTrackingRequest, $0.StopTrackingResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/stop',
          ($0.StopTrackingRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.StopTrackingResponse.fromBuffer(value));
  static final _$addTrackings =
      $grpc.ClientMethod<$0.AddTrackingsRequest, $0.AddTrackingsResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/AddTrackings',
          ($0.AddTrackingsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.AddTrackingsResponse.fromBuffer(value));
  static final _$removeTrackings =
      $grpc.ClientMethod<$0.RemoveTrackingsRequest, $0.RemoveTrackingsResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/RemoveTrackings',
          ($0.RemoveTrackingsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.RemoveTrackingsResponse.fromBuffer(value));
  static final _$getMeta =
      $grpc.ClientMethod<$0.GetMetaRequest, $0.GetMetaResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/GetMeta',
          ($0.GetMetaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.GetMetaResponse.fromBuffer(value));

  SarSysTrackingServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.StartTrackingResponse> start(
      $0.StartTrackingRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$start, request, options: options);
  }

  $grpc.ResponseFuture<$0.StopTrackingResponse> stop(
      $0.StopTrackingRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$stop, request, options: options);
  }

  $grpc.ResponseFuture<$0.AddTrackingsResponse> addTrackings(
      $0.AddTrackingsRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$addTrackings, request, options: options);
  }

  $grpc.ResponseFuture<$0.RemoveTrackingsResponse> removeTrackings(
      $0.RemoveTrackingsRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$removeTrackings, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetMetaResponse> getMeta($0.GetMetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getMeta, request, options: options);
  }
}

abstract class SarSysTrackingServiceBase extends $grpc.Service {
  $core.String get $name => 'app.sarsys.tracking.SarSysTrackingService';

  SarSysTrackingServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.StartTrackingRequest, $0.StartTrackingResponse>(
            'start',
            start_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.StartTrackingRequest.fromBuffer(value),
            ($0.StartTrackingResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StopTrackingRequest, $0.StopTrackingResponse>(
            'stop',
            stop_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.StopTrackingRequest.fromBuffer(value),
            ($0.StopTrackingResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.AddTrackingsRequest, $0.AddTrackingsResponse>(
            'AddTrackings',
            addTrackings_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.AddTrackingsRequest.fromBuffer(value),
            ($0.AddTrackingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveTrackingsRequest,
            $0.RemoveTrackingsResponse>(
        'RemoveTrackings',
        removeTrackings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RemoveTrackingsRequest.fromBuffer(value),
        ($0.RemoveTrackingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetMetaRequest, $0.GetMetaResponse>(
        'GetMeta',
        getMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetMetaRequest.fromBuffer(value),
        ($0.GetMetaResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.StartTrackingResponse> start_Pre($grpc.ServiceCall call,
      $async.Future<$0.StartTrackingRequest> request) async {
    return start(call, await request);
  }

  $async.Future<$0.StopTrackingResponse> stop_Pre($grpc.ServiceCall call,
      $async.Future<$0.StopTrackingRequest> request) async {
    return stop(call, await request);
  }

  $async.Future<$0.AddTrackingsResponse> addTrackings_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.AddTrackingsRequest> request) async {
    return addTrackings(call, await request);
  }

  $async.Future<$0.RemoveTrackingsResponse> removeTrackings_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.RemoveTrackingsRequest> request) async {
    return removeTrackings(call, await request);
  }

  $async.Future<$0.GetMetaResponse> getMeta_Pre(
      $grpc.ServiceCall call, $async.Future<$0.GetMetaRequest> request) async {
    return getMeta(call, await request);
  }

  $async.Future<$0.StartTrackingResponse> start(
      $grpc.ServiceCall call, $0.StartTrackingRequest request);
  $async.Future<$0.StopTrackingResponse> stop(
      $grpc.ServiceCall call, $0.StopTrackingRequest request);
  $async.Future<$0.AddTrackingsResponse> addTrackings(
      $grpc.ServiceCall call, $0.AddTrackingsRequest request);
  $async.Future<$0.RemoveTrackingsResponse> removeTrackings(
      $grpc.ServiceCall call, $0.RemoveTrackingsRequest request);
  $async.Future<$0.GetMetaResponse> getMeta(
      $grpc.ServiceCall call, $0.GetMetaRequest request);
}
