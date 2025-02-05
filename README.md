# Flutter Network Service Discovery (NSD)

A Flutter plugin for discovering network services using NSD (Network Service Discovery) on Android and Bonjour on iOS. This plugin enables your app to find services on a local network.

## Features

- Discover services on local networks using mDNS/Bonjour
- Support for both Android and iOS platforms
- Service type filtering
- Automatic service resolution with IP, port, and TXT records
- Debug mode for troubleshooting

## Getting Started

### Add Dependency

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  lumi_flutter_nsd: ^0.0.1
```

### Platform Configuration

#### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

#### iOS

Add the following to your `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Looking for local network devices</string>
<key>NSBonjourServices</key>
<array>
    <string>_http._tcp.</string>
    <string>_airplay._tcp.</string>
    <!-- Add other service types you want to discover -->
</array>
```

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:lumi_flutter_nsd/nsd.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<NsdService> services = [];
  bool isDiscovering = false;

  @override
  void initState() {
    super.initState();
    Nsd.setDebug(true);
    addListener();
  }

  @override
  void dispose() {
    stopDiscovery();
    Nsd.dispose();
    super.dispose();
  }

  void addListener() {
    // Listen for found services
    Nsd.serviceFound.listen((service) {
      setState(() {
        services = [...services, service];
      });
    });

    // Listen for discovery start
    Nsd.discoverServiceStarted.listen((_) {
      setState(() {
        isDiscovering = true;
      });
    });

    // Listen for discovery stop
    Nsd.discoverServiceStopped.listen((_) {
      setState(() {
        isDiscovering = false;
      });
    });

    // Listen for discovery failures
    Nsd.discoverServiceFailed.listen((_) {
      setState(() {
        isDiscovering = false;
      });
    });

    // Listen for lost services
    Nsd.serviceLost.listen((service) {
      setState(() {
        services = services.where((s) => s.name != service.name).toList();
      });
    });
  }

  void startDiscovery() async {
    setState(() {
      services = [];
    });
    await Nsd.discoverServices('_airplay._tcp.');
  }

  void stopDiscovery() async {
    await Nsd.stopDiscovery();
  }
}
```

### Events

The plugin provides several event streams:

| Event | Description |
|-------|-------------|
| `serviceFound` | Emitted when a service is found and resolved |
| `serviceLost` | Emitted when a service is no longer available |
| `discoverServiceStarted` | Emitted when service discovery starts |
| `discoverServiceStopped` | Emitted when service discovery stops |
| `discoverServiceFailed` | Emitted when service discovery fails |
| `resolveServiceFailed` | Emitted when service resolution fails |

### Service Information

The `NsdService` object contains:

```dart
class NsdService {
  final String? ip;        // Service IP address
  final int? port;         // Service port
  final String name;       // Service name
  final String type;       // Service type
  final Map<String, dynamic>? attributes;  // TXT records
}
```

### Common Service Types

- `_http._tcp.` - HTTP services
- `_https._tcp.` - HTTPS services
- `_printer._tcp.` - Printer services
- `_ipp._tcp.` - Internet Printing Protocol
- `_airplay._tcp.` - AirPlay devices

## Error Handling

Enable debug mode to see detailed logs:

```dart
Nsd.setDebug(true);
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see the [LICENSE](LICENSE) file for details.
