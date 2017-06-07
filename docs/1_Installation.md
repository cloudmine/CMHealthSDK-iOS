# Installation

[CMHealth](https://cocoapods.org/pods/CMHealth) is available through [CocoaPods](http://cocoapods.org) version 1.0.0 or later.
To install it, simply add the following line to your Podfile:

```ruby
platform :ios, '9.0'

target 'MyHealthApp' do
  use_frameworks!

  pod 'CMHealth'
end
```

**Please Note**: Apple's CareKit framework supports iOS 9.0 and later.
As such, CMHealth also has a minimum deployment target of iOS 9.0.
