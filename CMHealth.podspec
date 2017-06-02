Pod::Spec.new do |s|
  s.name              = "CMHealth"
  s.version           = "0.6.0"
  s.summary           = "A HIPAA compliant data storage interface for ResearchKit and CareKit, from CloudMine."
  s.description       = <<-DESC
                        CMHealth is the easiest way to add secure, HIPAA compliant cloud data storage
                        and user management to your ResearchKit or CareKit clinical iOS app.  Built and
                        backed by CloudMine and the CloudMine Connected Health Cloud.
                       DESC

  s.homepage          = "https://github.com/cloudmine/CMHealthSDK-iOS"
  s.license           = 'MIT'
  s.author            = { "CloudMine" => "support@cloudmineinc.com" }
  s.source            = { :git => "https://github.com/cloudmine/CMHealthSDK-iOS.git", :tag => s.version.to_s }

  s.platform          = :ios, '9.0'
  s.requires_arc      = true

  # s.public_header_files = 'Pod/Classes/CMHealth.h' # Pre 1.0 we need to specify exactly which should be public
  s.source_files         = 'Pod/Classes/**/*'

  s.resource_bundles  = {
    'CMHealth' => ['Pod/Assets/*']
  }

  s.dependency 'ResearchKit', '~> 1.3'
  s.dependency 'CareKit', '~> 1.2.0'
  s.dependency 'CloudMine', '~> 1.7'
end
