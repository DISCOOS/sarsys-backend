///
//  Generated code. Do not modify.
//  source: tracking_service.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'tracking_service.pb.dart' as $2;
export 'tracking_service.pb.dart';

class SarSysTrackingServiceClient extends $grpc.Client {
  static final _$getMeta =
      $grpc.ClientMethod<$2.GetTrackingMetaRequest, $2.GetTrackingMetaResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/GetMeta',
          ($2.GetTrackingMetaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.GetTrackingMetaResponse.fromBuffer(value));
  static final _$start =
      $grpc.ClientMethod<$2.StartTrackingRequest, $2.StartTrackingResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/start',
          ($2.StartTrackingRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.StartTrackingResponse.fromBuffer(value));
  static final _$stop =
      $grpc.ClientMethod<$2.StopTrackingRequest, $2.StopTrackingResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/stop',
          ($2.StopTrackingRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.StopTrackingResponse.fromBuffer(value));
  static final _$addTrackings =
      $grpc.ClientMethod<$2.AddTrackingsRequest, $2.AddTrackingsResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/AddTrackings',
          ($2.AddTrackingsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.AddTrackingsResponse.fromBuffer(value));
  static final _$removeTrackings =
      $grpc.ClientMethod<$2.RemoveTrackingsRequest, $2.RemoveTrackingsResponse>(
          '/app.sarsys.tracking.SarSysTrackingService/RemoveTrackings',
          ($2.RemoveTrackingsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.RemoveTrackingsResponse.fromBuffer(value));

  SarSysTrackingServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$2.GetTrackingMetaResponse> getMeta(
      $2.GetTrackingMetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getMeta, request, options: options);
  }

  $grpc.ResponseFuture<$2.StartTrackingResponse> start(
      $2.StartTrackingRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$start, request, options: options);
  }

  $grpc.ResponseFuture<$2.StopTrackingResponse> stop(
      $2.StopTrackingRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$stop, request, options: options);
  }

  $grpc.ResponseFuture<$2.AddTrackingsResponse> addTrackings(
      $2.AddTrackingsRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$addTrackings, request, options: options);
  }

  $grpc.ResponseFuture<$2.RemoveTrackingsResponse> removeTrackings(
      $2.RemoveTrackingsRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$removeTrackings, request, options: options);
  }
}

abstract class SarSysTrackingServiceBase extends $grpc.Service {
  $core.String get $name => 'app.sarsys.tracking.SarSysTrackingService';

  SarSysTrackingServiceBase() {
    $addMethod($grpc.ServiceMethod<$2.GetTrackingMetaRequest,
            $2.GetTrackingMetaResponse>(
        'GetMeta',
        getMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.GetTrackingMetaRequest.fromBuffer(value),
        ($2.GetTrackingMetaResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$2.StartTrackingRequest, $2.StartTrackingResponse>(
            'start',
            start_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.StartTrackingRequest.fromBuffer(value),
            ($2.StartTrackingResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$2.StopTrackingRequest, $2.StopTrackingResponse>(
            'stop',
            stop_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.StopTrackingRequest.fromBuffer(value),
            ($2.StopTrackingResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$2.AddTrackingsRequest, $2.AddTrackingsResponse>(
            'AddTrackings',
            addTrackings_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.AddTrackingsRequest.fromBuffer(value),
            ($2.AddTrackingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.RemoveTrackingsRequest,
            $2.RemoveTrackingsResponse>(
        'RemoveTrackings',
        removeTrackings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.RemoveTrackingsRequest.fromBuffer(value),
        ($2.RemoveTrackingsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$2.GetTrackingMetaResponse> getMeta_Pre($grpc.ServiceCall call,
      $async.Future<$2.GetTrackingMetaRequest> request) async {
    return getMeta(call, await request);
  }

  $async.Future<$2.StartTrackingResponse> start_Pre($grpc.ServiceCall call,
      $async.Future<$2.StartTrackingRequest> request) async {
    return start(call, await request);
  }

  $async.Future<$2.StopTrackingResponse> stop_Pre($grpc.ServiceCall call,
      $async.Future<$2.StopTrackingRequest> request) async {
    return stop(call, await request);
  }

  $async.Future<$2.AddTrackingsResponse> addTrackings_Pre(
      $grpc.ServiceCall call,
      $async.Future<$2.AddTrackingsRequest> request) async {
    return addTrackings(call, await request);
  }

  $async.Future<$2.RemoveTrackingsResponse> removeTrackings_Pre(
      $grpc.ServiceCall call,
      $async.Future<$2.RemoveTrackingsRequest> request) async {
    return removeTrackings(call, await request);
  }

  $async.Future<$2.GetTrackingMetaResponse> getMeta(
      $grpc.ServiceCall call, $2.GetTrackingMetaRequest request);
  $async.Future<$2.StartTrackingResponse> start(
      $grpc.ServiceCall call, $2.StartTrackingRequest request);
  $async.Future<$2.StopTrackingResponse> stop(
      $grpc.ServiceCall call, $2.StopTrackingRequest request);
  $async.Future<$2.AddTrackingsResponse> addTrackings(
      $grpc.ServiceCall call, $2.AddTrackingsRequest request);
  $async.Future<$2.RemoveTrackingsResponse> removeTrackings(
      $grpc.ServiceCall call, $2.RemoveTrackingsRequest request);
}
