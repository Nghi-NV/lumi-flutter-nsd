package com.lumi.nsd

import android.content.Context

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.ConcurrentLinkedQueue

class NsdPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private lateinit var nsdManager: NsdManager
  private val serviceQueue: ConcurrentLinkedQueue<NsdServiceInfo> = ConcurrentLinkedQueue()
  private var isDiscovery: Boolean = false
  private var isResolving: Boolean = false
  private var isDebug: Boolean = false

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "lumi_flutter_nsd")
    context = flutterPluginBinding.applicationContext
    nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "discoverServices" -> discoverServices(call.arguments.toString(), result)
      "stopDiscovery" -> stopDiscovery()
      "setDebug" -> setDebug(call.arguments as Boolean)
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  fun getRecordValue(value: ByteArray): String {
    return String(value, Charsets.UTF_8)
  }

  private fun setDebug(debug: Boolean) {
    isDebug = debug
  }

  private var discoveryListener: NsdManager.DiscoveryListener? = null

  private fun processQueue() {
    if (isResolving || serviceQueue.isEmpty()) return

    val serviceInfo = serviceQueue.poll() ?: return
    isResolving = true

    val resolveListener = object : NsdManager.ResolveListener {
      override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
        if (isDebug) {
          Log.e("NsdPlugin", "onResolveFailed: $errorCode")
        }
        isResolving = false
        processQueue()

        Handler(Looper.getMainLooper()).post {
          channel.invokeMethod("onResolveFailed", mapOf(
            "type" to serviceInfo.serviceType,
            "errorCode" to errorCode
          ))
        }
      }

      override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
        if (isDebug) {
          Log.d("NsdPlugin", "onServiceResolved: ${serviceInfo.serviceName}")
        }
        val host = serviceInfo.host.hostAddress
        val port = serviceInfo.port
        val txtRecord = serviceInfo.attributes
        val txtRecordMap = mapOf(*txtRecord.entries.map {
          it.key to getRecordValue(it.value)
        }.toTypedArray())

        val result = mapOf(
          "ip" to host,
          "port" to port,
          "name" to serviceInfo.serviceName,
          "type" to serviceInfo.serviceType,
          "attributes" to txtRecordMap
        )
        if (isDebug) {
          Log.d("NsdPlugin", "onServiceFound: $result")
        }
        Handler(Looper.getMainLooper()).post {
          channel.invokeMethod("onServiceFound", result)
        }

        isResolving = false
        processQueue()
      }
    }
    nsdManager.resolveService(serviceInfo, resolveListener)
  }

  private fun discoverServices(serviceType: String, result: Result) {
    try {
      if (isDebug) {
        Log.d("NsdPlugin", "serviceType: $serviceType")
      }

      discoveryListener = object : NsdManager.DiscoveryListener {
        override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
          if (isDebug) {
            Log.e("NsdPlugin", "onStartDiscoveryFailed: $errorCode")
          }
          nsdManager.stopServiceDiscovery(this)
          isDiscovery = false

          Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onStartDiscoveryFailed", mapOf(
              "type" to serviceType,
              "errorCode" to errorCode
            ))
          }
        }

        override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
          if (isDebug) {
            Log.e("NsdPlugin", "onStopDiscoveryFailed: $errorCode")
          }
        }

        override fun onDiscoveryStarted(serviceType: String) {
          if (isDebug) {
            Log.d("NsdPlugin", "onDiscoveryStarted")
          }

          Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onDiscoverStarted", null)
          }
        }

        override fun onDiscoveryStopped(serviceType: String) {
          if (isDebug) {
            Log.d("NsdPlugin", "onDiscoveryStopped")
          }
          isDiscovery = false

          Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onDiscoverStopped", null)
          }
        }

        override fun onServiceFound(serviceInfo: NsdServiceInfo) {
          val serviceName = serviceInfo.serviceName
          if (isDebug) {
            Log.d("NsdPlugin", "onServiceFound: $serviceName")
          }

          serviceQueue.add(serviceInfo)
          processQueue()
        }

        override fun onServiceLost(serviceInfo: NsdServiceInfo) {
          if (isDebug) {
            Log.d("NsdPlugin", "onServiceLost: ${serviceInfo.serviceName}")
          }

          Handler(Looper.getMainLooper()).post {
            val result = mapOf(
              "name" to serviceInfo.serviceName,
              "type" to serviceInfo.serviceType
            )
            channel.invokeMethod("onServiceLost", result)
          }
        }
      }

      nsdManager.discoverServices(
        serviceType,
        NsdManager.PROTOCOL_DNS_SD,
        discoveryListener
      )
      result.success("discoverServices")
    } catch (e: Exception) {
      result.error("NSD_ERROR", e.message, null)
    }
  }

  private fun stopDiscovery() {
    try {
      discoveryListener?.let {
        nsdManager.stopServiceDiscovery(it)
        discoveryListener = null
      }
    } catch (e: Exception) {
      if (isDebug) {
        Log.e("NsdPlugin", "Error stopping discovery: ${e.message}")
      }
    }
  }
}

