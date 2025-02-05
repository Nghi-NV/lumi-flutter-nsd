#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nsd.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'lumi_flutter_nsd'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for discovering network services using NSD (Network Service Discovery) on Android and Bonjour on iOS'
  s.description      = <<-DESC
A Flutter plugin for discovering network services using NSD (Network Service Discovery) on Android and Bonjour on iOS. This plugin enables your app to find services on a local network.A Flutter plugin for discovering network services using NSD (Network Service Discovery) on Android and Bonjour on iOS. This plugin enables your app to find services on a local network.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lumi' => 'nghinv990@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
