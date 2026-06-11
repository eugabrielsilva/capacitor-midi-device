require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))
repo_url = package['repository']['url'].sub(/^git\+/, '').sub(/\.git$/, '')

Pod::Spec.new do |s|
  s.name = 'EugabrielsilvaCapacitorMidiDevice'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = repo_url
  s.author = package['author']
  s.source = { :git => "#{repo_url}.git", :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target = '14.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.10'
end
