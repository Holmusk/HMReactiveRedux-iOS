# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
target 'SwiftRedux' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SwiftRedux
  pod 'RxSwift'
  pod 'RxBlocking'
  pod 'SwiftFP/Main', git: 'https://github.com/protoman92/SwiftFP.git'
  
  target 'SwiftReduxTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'RxTest'
    pod 'SafeNest/Main', git: 'https://github.com/protoman92/SafeNest.git'
  end
  
  target 'SwiftRedux-Demo' do
    inherit! :search_paths
    # Pods for demo
    pod 'MRProgress'
    pod 'RxCocoa'
    pod 'SafeNest/Main', git: 'https://github.com/protoman92/SafeNest.git'
  end
end
