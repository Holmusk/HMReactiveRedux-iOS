Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = "9.0"
  s.swift_version = "4.2"
  s.name = "SwiftRedux"
  s.summary = "Rx-enabled Redux implementation for iOS clients."
  s.requires_arc = true
  s.version = "1.0.2"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Hai Pham" => "swiften.svc@gmail.com" }
  s.homepage = "https://github.com/protoman92/SwiftRedux.git"
  s.source = { :git => "https://github.com/protoman92/SwiftRedux.git", :tag => "#{s.version}"}

  s.subspec "Core" do |ss|
    ss.dependency "SwiftFP/Main"
    ss.source_files = "SwiftRedux/*.{h,swift}", "SwiftRedux/Core/*"
  end

  s.subspec "SimpleStore" do |ss|
    ss.dependency "SwiftRedux/Core"
    ss.source_files = "SwiftRedux/SimpleStore/*"
  end

  s.subspec "UI" do |ss|
    ss.dependency "SwiftRedux/Core"
    ss.source_files = "SwiftRedux/{UI,UI+Test}/*"
  end

  s.subspec "Middleware" do |ss|
    ss.dependency "SwiftRedux/Core"
    ss.source_files = "SwiftRedux/Middleware/*"
  end

  s.subspec "Middleware+Router" do |ss|
    ss.dependency "SwiftRedux/Middleware"
    ss.source_files = "SwiftRedux/Middleware+Router/*"
  end

  s.subspec 'Middleware+Saga' do |ss|
    ss.dependency "RxSwift"
    ss.dependency "RxBlocking"
    ss.dependency "SwiftRedux/Middleware"
    ss.source_files = "SwiftRedux/Middleware+Saga/*"
  end
end
