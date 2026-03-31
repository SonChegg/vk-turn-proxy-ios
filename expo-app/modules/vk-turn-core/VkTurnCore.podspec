Pod::Spec.new do |s|
  s.name = "VkTurnCore"
  s.version = "1.0.0"
  s.summary = "Expo wrapper for the VK TURN iOS runtime"
  s.description = "Local Expo module that wraps the gomobile-based VkTurnCore bridge."
  s.license = { :type => "MIT" }
  s.author = { "OpenAI" => "support@openai.com" }
  s.homepage = "https://github.com/SonChegg/vk-turn-proxy-ios"
  s.platforms = { :ios => "15.1" }
  s.swift_version = "5.9"
  s.source = { :git => "https://github.com/SonChegg/vk-turn-proxy-ios.git" }
  s.static_framework = true

  s.dependency "ExpoModulesCore"

  s.source_files = "ios/**/*.{swift,h,m,mm}"
  s.vendored_frameworks = "ios/Frameworks/VkTurnCore.xcframework"
  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES"
  }
end
