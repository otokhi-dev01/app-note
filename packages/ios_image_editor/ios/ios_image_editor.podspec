Pod::Spec.new do |s|
  s.name             = 'ios_image_editor'
  s.version          = '1.0.0'
  s.summary          = 'Opens the native iOS markup editor for editing images.'
  s.description      = 'A Flutter plugin that opens the native iOS markup editor for editing images.'
  s.homepage         = 'https://github.com/aruljebaraj/ios_image_editor'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ios_image_editor contributors' => 'opensource@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'ios_image_editor/Sources/ios_image_editor/**/*'
  s.resource_bundles = {
    'ios_image_editor_privacy' => ['ios_image_editor/Sources/ios_image_editor/PrivacyInfo.xcprivacy']
  }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
