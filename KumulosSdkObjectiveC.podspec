
Pod::Spec.new do |s|
  s.name = "KumulosSdkObjectiveC"
  s.version = "4.2.3"
  s.license = "MIT"
  s.summary = "Official Objective-C SDK for integrating Kumulos services with your mobile apps"
  s.homepage = "https://github.com/Kumulos/KumulosSdkObjectiveC"
  s.authors = { "Kumulos Ltd" => "support@kumulos.com" }
  s.source = { :git => "https://github.com/Kumulos/KumulosSdkObjectiveC.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.12"

  s.source_files = "Sources/**/*.{h,m}", "Sources/Shared/**/*.{h,m}"
  s.exclude_files = "Carthage", "Sources/KumulosSDKExtension"
  s.module_name = "KumulosSDK"
  s.header_dir = "KumulosSDK"
  s.preserve_path = 'upload_dsyms.sh'

  s.prepare_command = 'chmod +x upload_dsyms.sh'

  s.osx.exclude_files = [
      'Sources/*Push*',
      'Sources/*Analytics*',
      'Sources/*Location*',
      'Sources/*InApp*',
      'Sources/KSUserNotificationCenterDelegate.*',
      'Sources/**/*InApp*',
      'Sources/Shared/*Analytics*',
      'Sources/*SessionHelper*'
  ]

  s.ios.public_header_files = [
      'Sources/KumulosSDK.h',
      'Sources/Kumulos.h',
      'Sources/KSAPIOperation.h',
      'Sources/KSAPIResponse.h',
      'Sources/Kumulos+Push.h',
      'Sources/KumulosPushSubscriptionManager.h',
      'Sources/Kumulos+Location.h',
      'Sources/Kumulos+Crash.h',
      'Sources/Kumulos+Analytics.h',
      'Sources/KumulosInApp.h'
  ]

  s.osx.public_header_files = [
      'Sources/KumulosSDK.h',
      'Sources/Kumulos.h',
      'Sources/KSAPIOperation.h',
      'Sources/KSAPIResponse.h',
      'Sources/Kumulos+Crash.h'
  ]

  s.dependency "KumulosKSCrash", "1.15.21-kumulos1"
end
