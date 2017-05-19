require File.expand_path("../lib/activehistory/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "activehistory"
  s.version     = ActiveHistory::VERSION
  s.authors     = ["Jon Bracy"]
  s.email       = ["jonbracy@gmail.com"]
  s.homepage    = "https://activehistory.com"
  s.summary     = %q{Track changes to ActiveRecord models}
  s.description = <<~DESC
    ActiveHistory tracks and logs changes to your ActiveRecord models and
    relationships for auditing in the future.
  DESC

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Developoment 
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'sdoc'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'sdoc-templates-42floors'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'pg'

  # Runtime
  # s.add_runtime_dependency 'msgpack'
  # s.add_runtime_dependency 'cookie_store'
  s.add_runtime_dependency 'arel', '~> 7.0'
  s.add_runtime_dependency 'activerecord', '~> 5.0'
  s.add_runtime_dependency 'globalid', '~> 0.3.7'
end
