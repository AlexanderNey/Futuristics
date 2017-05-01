Pod::Spec.new do |s|
  s.name = 'Futuristics'
  s.version = '0.3.0'
  s.license = { :type => "MIT" }
  s.summary = 'Futures for Swift 3'
  s.homepage = 'https://github.com/AlexanderNey/Futuristics'
  s.social_media_url = 'http://twitter.com/Ajax64'
  s.authors = { 'Alexander Ney' => 'alexander.ney@me.com' }
  s.source = { :git => 'https://github.com/AlexanderNey/Futuristics.git', :tag => s.version}
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.source_files = 'Source/*.swift'
end
