# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "acts_as_organizable/version"

Gem::Specification.new do |s|
  s.name        = "acts_as_organizable"
  s.version     = ActsAsOrganizable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mike Hansen"]
  s.email       = ["mhansen@pathlightmedia.com"]
  s.summary     = %q{Simpler tagging.}

  s.rubyforge_project = "acts_as_organizable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
