#if canImport(FlutterMacOS)
import FlutterMacOS
import Cocoa
import Foundation
#else
import Flutter
import UIKit
import Network
#endif

public class NsdPlugin: NSObject, FlutterPlugin, NetServiceBrowserDelegate, NetServiceDelegate {
  private var channel: FlutterMethodChannel
  private var netServiceBrowser: NetServiceBrowser!
  private var services = [NetService]()
  var isDebug: Bool = false
  var isDiscovering: Bool = false
  var isResolving: Bool = false

  init(channel: FlutterMethodChannel) {
      self.channel = channel
      self.services.removeAll()
      netServiceBrowser = NetServiceBrowser()
      super.init()
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "lumi_flutter_nsd", binaryMessenger: registrar.messenger())
    let instance = NsdPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setDebug":
      if let debug = call.arguments as? Bool {
        setDebug(debug: debug, result: result)
      }
      break
    case "discoverServices":
      if let serviceType = call.arguments as? String {
        discoverServices(serviceType: serviceType, result: result)
      }
      break
    case "stopDiscovery":
      stopDiscovery(result: result)
      break
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func setDebug(debug: Bool, result: @escaping FlutterResult) {
    isDebug = debug
    result(nil)
  }

  func discoverServices(serviceType: String, result: @escaping FlutterResult) {
    if isDebug {
      print("NsdPlugin: Starting discovery for \(serviceType)")
    }
    
    if isDiscovering {
      stopDiscovery()
    }
    
    let type = serviceType.replacingOccurrences(of: "local.", with: "")
    
    netServiceBrowser.delegate = self
    netServiceBrowser.searchForServices(ofType: type, inDomain: "")
    result("discoverServices")
  }

  func stopDiscovery(result: @escaping FlutterResult) {
    stopDiscovery()
    result(nil)
  }

  private func stopDiscovery() {
    netServiceBrowser.stop()
    services.removeAll()
  }

  private func updateInterface() {
      for service in services {
          if service.port == -1 {
              service.delegate = self
              service.resolve(withTimeout: 10)
          }
      }
  }
  
  // MARK: - NetServiceBrowserDelegate
  public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    if isDebug {
      print("NsdPlugin: Discovery failed: \(errorDict)")
    }
    channel.invokeMethod("onStartDiscoveryFailed", arguments: errorDict)
  }
    
  public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    if isDebug {
      print("NsdPlugin: Found service: \(service.name)")
    }
    
    services.append(service)

    if !moreComing {
      self.updateInterface()
    }
  }
  
  public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    if isDebug {
      print("NsdPlugin: Lost service: \(service.name)")
    }
    
    services.removeAll { $0 == service }
    
    // Notify service lost 
    let serviceInfo: [String: Any] = [
      "name": service.name,
      "type": service.type
    ]
    channel.invokeMethod("onServiceLost", arguments: serviceInfo)
  }
  
  public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    if isDebug {
      print("NsdPlugin: Discovery stopped")
    }

    isDiscovering = false
    channel.invokeMethod("onDiscoverStopped", arguments: nil)
  }
  
  public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
    if isDebug {
      print("NsdPlugin: Discovery will start")
    }
    
    isDiscovering = true
    channel.invokeMethod("onDiscoverStarted", arguments: nil)
  }
  
  // MARK: - NetServiceDelegate
  
  public func netServiceDidResolveAddress(_ service: NetService) {
    if isDebug {
      print("NsdPlugin: Resolved service: \(service.name)")
    }
    
    guard let addresses = service.addresses else { return }
    
    // Get the first IPv4 address
    var hostname: String?
    for address in addresses {
      var addr = sockaddr()
      (address as NSData).getBytes(&addr, length: MemoryLayout<sockaddr>.size)
      
      if addr.sa_family == UInt8(AF_INET) {
        var addr4 = sockaddr_in()
        (address as NSData).getBytes(&addr4, length: MemoryLayout<sockaddr_in>.size)
        var host = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &addr4.sin_addr, &host, socklen_t(INET_ADDRSTRLEN))
        hostname = String(cString: host)
        break
      }
    }
    
    // Convert TXT record to dictionary
    var txtRecordDict: [String: String] = [:]
    if let txtData = service.txtRecordData() {
      let txtRecord = NetService.dictionary(fromTXTRecord: txtData)
      for (key, value) in txtRecord {
        if let stringValue = String(data: value, encoding: .utf8) {
          txtRecordDict[key] = stringValue
        }
      }
    }
    
    let result: [String: Any] = [
      "name": service.name,
      "ip": hostname ?? "",
      "port": service.port,
      "type": service.type,
      "attributes": txtRecordDict
    ]
    
    if isDebug {
      print("NsdPlugin: Service details: \(result)")
    }
    
    channel.invokeMethod("onServiceFound", arguments: result)
  }
  
  public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    if isDebug {
      print("NsdPlugin: Failed to resolve service: \(errorDict)")
    }
    
    // Notify resolution failure
    let errorInfo: [String: Any] = [
      "service": sender.name,
      "error": errorDict
    ]
    channel.invokeMethod("onResolveFailed", arguments: errorInfo)
  }
}
