# Installation

[CMHealth](https://cocoapods.org/pods/CMHealth) may be installed through [CocoaPods](http://cocoapods.org) version 1.0.0 or later.
To install it, simply add the following lines to your Podfile:

```ruby
platform :ios, '9.0'

target 'MyHealthApp' do
  use_frameworks!
  
pod 'CMHealth', :git => 'git@github.com:cloudmine/CMHealthSDK-iOS.git'
pod 'CareKit', :git => 'git@github.com:cloudmine/CareKit.git', :branch => 'cm-patched'

end
```
Once intalled, the SDK must be imported and configured in your `AppDelegate` class. See the section on
[Configuration](#configuration) for more information.

*Note: CMHealth depends on the `master` branch of Apple's CareKit. When Apple publishes CareKit 1.2 to CocoaPods, the requirement to install from GitHub will be removed. For any questions, please contact [support@cloudmineinc.com](mailto:support@cloudmineinc.com).*