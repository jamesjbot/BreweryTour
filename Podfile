# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

target 'BreweryTour' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    pod 'Bond', '6.3'
    pod 'SwiftyBeaver', '1.4.0'
    pod 'Alamofire'
#, '~> 4.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
	target.build_configurations.each do |config|
         config.build_settings['SWIFT_VERSION'] = '3.2'
	end
    end
end
   
