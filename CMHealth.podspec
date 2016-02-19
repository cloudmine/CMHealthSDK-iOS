Pod::Spec.new do |s|
  s.name             = "CMHealth"
  s.version          = "0.1.6"
  s.summary          = "Store and retrieve ResearchKit data to CloudMine with ease"
  s.description      = <<-DESC
                        Store and retrieve ResearchKit data to CloudMine's backend with ease.
                        Build your ResearchKit app just as you always would, and call a simple
                        method to serialize the results and store them securely with CloudMine.
                        Retrieving your data is equally simple.
                       DESC

  s.homepage         = "https://github.com/cloudmine/CMHealthSDK"
  s.license          = 'MIT'
  s.author           = { "CloudMine" => "support@cloudmine.me" }
  s.source           = { :git => "https://github.com/cloudmine/CMHealthSDK.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'CMHealth' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'ResearchKit', '~> 1.3'
  s.dependency 'CloudMine', '~> 1.7'
end
