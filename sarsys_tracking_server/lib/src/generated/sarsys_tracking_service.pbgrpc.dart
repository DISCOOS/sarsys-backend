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
  static final _$getMeta = $grpc.ClientMethod<$0.MetaRequest, $0.MetaResponse>(
      '/app.sarsys.tracking.SarSysTrackingService/GetMeta',
      ($0.MetaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.MetaResponse.fromBuffer(value));

  SarSysTrackingServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options,
      $core.Iterable<$grpc.ClientInterceptor> interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.MetaResponse> getMeta($0.MetaRequest request,
      {$grpc.CallOptions options}) {
    return $createUnaryCall(_$getMeta, request, options: options);
  }
}

abstract class SarSysTrackingServiceBase extends $grpc.Service {
  $core.String get $name => 'app.sarsys.tracking.SarSysTrackingService';

  SarSysTrackingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.MetaRequest, $0.MetaResponse>(
        'GetMeta',
        getMeta_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MetaRequest.fromBuffer(value),
        ($0.MetaResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.MetaResponse> getMeta_Pre(
      $grpc.ServiceCall call, $async.Future<$0.MetaRequest> request) async {
    return getMeta(call, await request);
  }

  $async.Future<$0.MetaResponse> getMeta(
      $grpc.ServiceCall call, $0.MetaRequest request);
}
