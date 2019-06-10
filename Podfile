# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'
target 'SwiftRedux' do

  # Pods for SwiftRedux
  pod 'RxSwift', '~> 4.0'
  pod 'RxBlocking', '~> 4.0'
  pod 'RxAtomic', '~> 4.0', :modular_headers => true
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
    pod 'SafeNest/Main', git: 'https://github.com/protoman92/SafeNest.git'
  end
  
  target 'SwiftRedux-MusicDemo' do
    inherit! :search_paths
  end
end
