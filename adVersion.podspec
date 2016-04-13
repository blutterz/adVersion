Pod::Spec.new do |s|

  s.name         = "adVersion"
  s.version      = "0.0.1"
  s.summary      = "iOS 版本检查更新模块 for 企业开发用户"

  s.homepage     = "https://github.com/blutterz/adVersion"
  
  s.license      = "BSD"
  s.author       = { "blutter" => "blutter@163.com" }
  
  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/blutterz/adVersion.git", :tag => "#{s.version}" }

  s.source_files  = "adVersion/*.{h,m}"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"
  s.frameworks = 'Foundation', 'UIKit'
  s.requires_arc = true
  s.dependency 'Alert','~> 1.0.3'

end
