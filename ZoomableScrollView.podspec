Pod::Spec.new do |s|
  s.name         = 'ZoomableScrollView'
  s.version      = '1.0.0'
  s.summary      = 'A zoomable and scrollable view'
  s.homepage     = 'https://github.com/tucan9389/ZoomableScrollView'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.source       = { :git => 'https://github.com/tucan9389/ZoomableScrollView.git', :tag => "#{s.version}" }
  s.author       = { 'tucna9389' => 'https://github.com/tucan9389' }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/*.{swift}'
  s.requires_arc = true
end
