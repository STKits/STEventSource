
Pod::Spec.new do |s|
  s.name             = 'STEventSource'
  s.version          = '0.1.4'
  s.summary          = 'Server Sent Events'
  s.description      = <<-DESC
  Swift Server Sent Events
                       DESC

  s.homepage         = 'https://github.com/STKits/STEventSource'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cnjsyyb' => 'cnjsyyb@163.com' }
  s.source           = { :git => 'https://github.com/STKits/STEventSource.git', :tag => s.version.to_s }

  s.swift_versions = ['5.0']
  
  s.ios.deployment_target = '13.0'

  s.source_files = 'STEventSource/Classes/*.swift'
  
  s.resource_bundles = {
    'STEventSource_Privacy' => ['STEventSource/Classes/PrivacyInfo.xcprivacy']
  }
  
end
