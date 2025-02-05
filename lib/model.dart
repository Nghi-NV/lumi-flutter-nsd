enum NsdEventType {
  serviceFound,
  serviceLost,
  discoverStarted,
  discoverStopped,
  discoveryFailed,
  resolveFailed,
}

class NsdEvent {
  final NsdEventType type;
  final Map<String, dynamic>? data;

  NsdEvent({required this.type, this.data});
}

class NsdService {
  final String? ip;
  final int? port;
  final String name;
  final String type;
  final Map<String, dynamic>? attributes;

  NsdService({
    this.ip,
    this.port,
    required this.name,
    required this.type,
    this.attributes,
  });

  factory NsdService.fromMap(Map<String, dynamic> map) {
    return NsdService(
      ip: map['ip'],
      port: map['port'],
      name: map['name'],
      type: map['type'],
      attributes: map['attributes'] != null
          ? Map<String, dynamic>.from(map['attributes'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'port': port,
      'name': name,
      'type': type,
      'attributes': attributes,
    };
  }

  @override
  String toString() {
    return 'NsdService{ip: $ip, port: $port, name: $name, type: $type, attributes: $attributes}';
  }
}
