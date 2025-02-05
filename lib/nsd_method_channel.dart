import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'model.dart';
import 'nsd_platform_interface.dart';

/// An implementation of [NsdPlatform] that uses method channels.
class MethodChannelNsd extends NsdPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('lumi_flutter_nsd');

  final _discoverServiceController = StreamController<NsdEvent>.broadcast();

  @override
  Stream<NsdService> get serviceFound => _discoverServiceController.stream
      .where((event) => event.type == NsdEventType.serviceFound)
      .map((event) => NsdService.fromMap(event.data ?? {}));

  @override
  Stream<NsdService> get serviceLost => _discoverServiceController.stream
      .where((event) => event.type == NsdEventType.serviceLost)
      .map((event) => NsdService.fromMap(event.data ?? {}));

  @override
  Stream<void> get discoverServiceStarted => _discoverServiceController.stream
      .where((event) => event.type == NsdEventType.discoverStarted);

  @override
  Stream<void> get discoverServiceStopped => _discoverServiceController.stream
      .where((event) => event.type == NsdEventType.discoverStopped);

  @override
  Stream<void> get discoverServiceFailed => _discoverServiceController.stream
      .where((event) => event.type == NsdEventType.discoveryFailed);

  @override
  Stream<void> get resolveServiceFailed => _discoverServiceController.stream
      .where((event) => event.type == NsdEventType.resolveFailed);

  MethodChannelNsd() {
    methodChannel.setMethodCallHandler((call) {
      if (call.method == 'onServiceFound') {
        final arguments = Map<String, dynamic>.from(call.arguments);
        _discoverServiceController.add(NsdEvent(
          type: NsdEventType.serviceFound,
          data: arguments,
        ));
      }
      if (call.method == 'onServiceLost') {
        final arguments = Map<String, dynamic>.from(call.arguments);
        _discoverServiceController.add(NsdEvent(
          type: NsdEventType.serviceLost,
          data: arguments,
        ));
      }
      if (call.method == 'onDiscoverStarted') {
        _discoverServiceController
            .add(NsdEvent(type: NsdEventType.discoverStarted));
      }
      if (call.method == 'onDiscoverStopped') {
        _discoverServiceController
            .add(NsdEvent(type: NsdEventType.discoverStopped));
      }
      if (call.method == 'onDiscoveryFailed') {
        _discoverServiceController
            .add(NsdEvent(type: NsdEventType.discoveryFailed));
      }
      if (call.method == 'onResolveFailed') {
        _discoverServiceController
            .add(NsdEvent(type: NsdEventType.resolveFailed));
      }
      return Future.value(null);
    });
  }

  @override
  Future<void> discoverServices(String serviceType) async {
    await methodChannel.invokeMethod('discoverServices', serviceType);
  }

  @override
  Future<void> stopDiscovery() async {
    await methodChannel.invokeMethod('stopDiscovery');
  }

  @override
  void setDebug(bool debug) {
    methodChannel.invokeMethod('setDebug', debug);
  }

  @override
  void dispose() {
    _discoverServiceController.close();
  }
}
