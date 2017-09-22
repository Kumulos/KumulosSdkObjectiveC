
Pod::Spec.new do |s|
  s.name = "KumulosSdkObjectiveC"
  s.version = "1.3.2"
  s.license = "MIT"
  s.summary = "Official Objective-C SDK for integrating Kumulos services with your mobile apps"
  s.homepage = "https://github.com/Kumulos/KumulosSdkObjectiveC"
  s.authors = { "Kumulos Ltd" => "support@kumulos.com" }
  s.source = { :git => "https://github.com/Kumulos/KumulosSdkObjectiveC.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.12"

  s.source_files = "Sources"
  s.exclude_files = "Carthage"
  s.module_name = "KumulosSDK"

  s.osx.exclude_files = 'Sources/*Push*'

  s.ios.public_header_files = [
      'Sources/KumulosSDK.h',
      'Sources/Kumulos.h',
      'Sources/KSAPIOperation.h',
      'Sources/KSAPIResponse.h',
      'Sources/Kumulos+Push.h',
      'Sources/KumulosPushSubscriptionManager.h'
  ]

  s.osx.public_header_files = [
      'Sources/KumulosSDK.h',
      'Sources/Kumulos.h',
      'Sources/KSAPIOperation.h',
      'Sources/KSAPIResponse.h'
  ]

  s.framework = "AFNetworking"

  s.dependency "AFNetworking", "~> 3.1.0"
end
