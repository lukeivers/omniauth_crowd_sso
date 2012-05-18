# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth_crowd/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ["Robert Di Marco", "Luke Ivers"]
  gem.email = ["rob@innovationontherun.com", "lukeivers@gmail.com"]
  gem.description = "This is an OmniAuth provider for Atlassian Crowd's REST API.  It allows you to easily integrate your Rack application in with Atlassian Crowd.  Updated by Luke Ivers to use the SSO API instead of the regular user API."
  gem.summary = "An OmniAuth provider for Atlassian Crowd SSO REST API"
  gem.homepage = "http://github.com/lukeivers/omniauth_crowd_sso"

  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name = "omniauth_crowd_sso"
  gem.require_paths = ["lib"]
  gem.version = OmniAuth::Crowd::VERSION

  gem.add_dependency 'omniauth', '~> 1.0'
  gem.add_dependency 'nokogiri', '>= 1.4.4'
  gem.add_development_dependency(%q<rack>, [">= 0"])
  gem.add_development_dependency(%q<rake>, [">= 0"])
  gem.add_development_dependency(%q<rack-test>, [">= 0"])
  gem.add_development_dependency(%q<rspec>, ["~> 2.5.0"])
  gem.add_development_dependency(%q<webmock>, ["~> 1.3.4"])
  gem.add_development_dependency(%q<bundler>, ["~> 1.1.0"])
end
