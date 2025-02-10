require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name            = 'PushyRN'
  s.version         = package['version']
  s.summary         = package['description']
  s.homepage        = package['homepage']

  s.author          = package['author']
  s.license         = package['license']

  s.platform       = :ios, "9.0"
  s.source          = { :git => 'https://github.com/pushy/pushy-react-native.git', :tag => s.version }
  s.source_files    = '**/*.{h,c,m,swift}'
  s.requires_arc    = true
  s.swift_version   = '4.2'

  # The "React" pod is required due to the use of RCTBridgeModule & RCTEventEmitter
  # Let's ensure we have version 0.13.0 or greater to avoid a cocoapods issue noted in React Native's release notes:
  # https://github.com/facebook/react-native/releases/tag/v0.13.0
  s.dependency 'React', '>= 0.13.0', '< 1.0.0'

  # Pushy iOS SDK
  s.dependency 'Pushy', '1.0.54'
end
