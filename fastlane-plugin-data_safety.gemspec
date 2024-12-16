lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/google_data_safety/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-google_data_safety'
  spec.version       = Fastlane::GoogleDataSafety::VERSION
  spec.author        = 'Owen Bean'
  spec.email         = 'owenbean400@gmail.com'

  spec.summary       = 'Google safety data Fastlane plugin for automation.'
  spec.homepage      = "https://github.com/owenbean400/fastlane-plugin-google_data_safety"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'googleauth', '~> 1.8.1'

end
