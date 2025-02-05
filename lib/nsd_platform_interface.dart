import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'model.dart';
import 'nsd_method_channel.dart';

abstract class NsdPlatform extends PlatformInterface {
  /// Constructs a NsdPlatform.
  NsdPlatform() : super(token: _token);

  static final Object _token = Object();

  static NsdPlatform _instance = MethodChannelNsd();

  /// The default instance of [NsdPlatform] to use.
  ///
  /// Defaults to [MethodChannelNsd].
  static NsdPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NsdPlatform] when
  /// they register themselves.
  static set instance(NsdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> discoverServices(String serviceType) {
    throw UnimplementedError('discoverServices() has not been implemented.');
  }

  Future<void> stopDiscovery() {
    throw UnimplementedError('stopDiscovery() has not been implemented.');
  }

  void setDebug(bool debug) {
    throw UnimplementedError('setDebug() has not been implemented.');
  }

  Stream<NsdService> get serviceFound;

  Stream<NsdService> get serviceLost;

  Stream<void> get discoverServiceStarted;

  Stream<void> get discoverServiceStopped;

  Stream<void> get discoverServiceFailed;

  Stream<void> get resolveServiceFailed;

  /// Dispose resources
  void dispose();
}
