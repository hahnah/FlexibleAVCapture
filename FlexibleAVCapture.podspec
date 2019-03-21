#
# Be sure to run `pod lib lint FlexibleAVCapture.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FlexibleAVCapture'
  s.version          = '2.2.0'
  s.summary          = 'Provides a kind of AV capture view controller with flexible camera frame.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'This pod provides a kind of AV capture view controller with flexible camera frame. It includes default capture settings, preview layer, buttons, tap-gesture focusing, pinch-gesture zooming, and so on.'

  s.homepage         = 'https://github.com/hahnah/FlexibleAVCapture'
  s.screenshots      = 'https://raw.githubusercontent.com/hahnah/FlexibleAVCapture/master/screencapture.gif'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hahnah' => 'superhahnah@gmail.com' }
  s.source           = { :git => 'https://github.com/hahnah/FlexibleAVCapture.git', :tag => '2.1.0' }
  s.social_media_url = 'https://twitter.com/superhahnah'

  s.ios.deployment_target = '11.0'
  s.swift_version = '4.2'

  s.source_files = 'FlexibleAVCapture/Classes/**/*'
  
  # s.resource_bundles = {
  #   'FlexibleAVCapture' => ['FlexibleAVCapture/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
