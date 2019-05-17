Pod::Spec.new do |s|
  s.name            = 'PushyRN'
  s.version         = '1.0.8'
  s.summary         = 'The official Pushy SDK for React Native iOS apps.'
  s.description     = 'Pushy is the most reliable push notification gateway, perfect for real-time, mission-critical applications.'
  s.homepage          = 'https://pushy.me/'

  s.author          = { 'Pushy' => 'contact@pushy.me' }
  s.license         = { :type => 'Apache-2.0', :file => 'LICENSE' }

  s.platform        = :ios
  s.source          = { :git => 'https://github.com/pushy-me/pushy-react-native.git', :tag => s.version }
  s.source_files    = '**/*.{h,m,swift}'
  s.requires_arc    = true

  s.dependency 'React'
  s.dependency 'Pushy'
end
