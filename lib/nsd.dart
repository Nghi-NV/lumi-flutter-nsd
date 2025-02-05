import 'model.dart';
import 'nsd_platform_interface.dart';

export 'model.dart';

class Nsd {
  static Future<void> discoverServices({String serviceType = '_airplay._tcp'}) {
    return NsdPlatform.instance.discoverServices(serviceType);
  }

  static Future<void> stopDiscovery() {
    return NsdPlatform.instance.stopDiscovery();
  }

  static void setDebug(bool debug) {
    NsdPlatform.instance.setDebug(debug);
  }

  static Stream<NsdService> get serviceFound =>
      NsdPlatform.instance.serviceFound;

  static Stream<void> get discoverServiceStarted =>
      NsdPlatform.instance.discoverServiceStarted;

  static Stream<void> get discoverServiceStopped =>
      NsdPlatform.instance.discoverServiceStopped;

  static Stream<void> get discoverServiceFailed =>
      NsdPlatform.instance.discoverServiceFailed;

  static Stream<void> get resolveServiceFailed =>
      NsdPlatform.instance.resolveServiceFailed;

  static Stream<NsdService> get serviceLost => NsdPlatform.instance.serviceLost;

  static void dispose() {
    NsdPlatform.instance.dispose();
  }
}
