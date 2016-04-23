
Pod::Spec.new do |s|
  s.name          = "Glass"
  s.version       = "0.0.1"
  s.summary       = "iOS Layered Window Manager"
  s.homepage      = "https://github.com/comyarzaheri/Glass"
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = { "Comyar Zaheri" => "" }
  s.ios.deployment_target = "8.0"
  s.source        = { :git => "https://github.com/comyarzaheri/Glass.git", :tag => s.version.to_s }
  s.source_files  = "Glass/*.swift"
  s.requires_arc  = true
  s.module_name	  = "Glass"
end
