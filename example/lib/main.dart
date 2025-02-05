import 'package:flutter/material.dart';
import 'package:lumi_flutter_nsd/nsd.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    super.dispose();
    stopDiscovery();
    Nsd.dispose();
  }

  void addListener() {
    Nsd.serviceFound.listen((data) {
      setState(() {
        services = [...services, data];
      });
    });

    Nsd.discoverServiceStarted.listen((_) {
      setState(() {
        isDiscovering = true;
      });
    });

    Nsd.discoverServiceStopped.listen((_) {
      setState(() {
        isDiscovering = false;
      });
    });

    Nsd.discoverServiceFailed.listen((_) {
      setState(() {
        isDiscovering = false;
      });
    });

    Nsd.serviceLost.listen((service) {
      setState(() {
        services = services.where((s) => s.name != service.name).toList();
      });
    });
  }

  void startDiscovery() async {
    setState(() {
      isDiscovering = true;
      services = [];
    });
    await Nsd.discoverServices();
  }

  void stopDiscovery() async {
    await Nsd.stopDiscovery();
    setState(() {
      isDiscovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("MyApp::build:---------> $services");
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Discovery MDNS'),
          actions: [
            IconButton(
              onPressed: isDiscovering ? stopDiscovery : startDiscovery,
              icon: isDiscovering
                  ? const Icon(Icons.stop)
                  : const Icon(Icons.search),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ListTile(
              title: Text(service.name),
              subtitle: Text('${service.ip}:${service.port}'),
              // subtitle: Text(service.attributes?.toString() ?? ''),
              // backgroundColor: Colors.blue,
            );
          },
        ),
      ),
    );
  }
}
