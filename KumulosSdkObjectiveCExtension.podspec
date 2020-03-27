
Pod::Spec.new do |s|
  s.name = "KumulosSdkObjectiveCExtension"
  s.version = "4.2.0"
  s.license = "MIT"
  s.summary = "Official Objective-C SDK for integrating Kumulos services with your mobile apps"
  s.homepage = "https://github.com/Kumulos/KumulosSdkObjectiveC"
  s.authors = { "Kumulos Ltd" => "support@kumulos.com" }
  s.source = { :git => "https://github.com/Kumulos/KumulosSdkObjectiveC.git", :tag => "#{s.version}" }

  s.ios.deployment_target = "10.0"

  s.source_files = "Sources/KumulosSDKExtension/**/*.{h,m}"
  s.exclude_files = "Carthage"
  s.module_name = "KumulosSDKExtension"
  s.header_dir = "KumulosSDKExtension"

  s.ios.public_header_files = [
    'Sources/KumulosSDKExtension/KumulosSDKExtension.h',
    'Sources/KumulosSDKExtension/KumulosNotificationService.h',
  ]

end
