# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'MuSound_3' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MuSound_3

  target 'MuSound_3Tests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'MuSound_3UITests' do
    inherit! :search_paths
    # Pods for testing
  end
  
  pod 'Firebase/Core'
  pod 'Firebase/Storage'
  pod 'Firebase/Firestore'
  pod 'Firebase/Auth'
  pod 'MessageKit'
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          if target.name == 'MessageKit'
              target.build_configurations.each do |config|
                  config.build_settings['SWIFT_VERSION'] = '4.0'
              end
          end
      end
  end

end

