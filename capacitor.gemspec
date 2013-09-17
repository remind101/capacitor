# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capacitor/version'

Gem::Specification.new do |spec|
  spec.name          = "capacitor"
  spec.version       = Capacitor::VERSION
  spec.authors       = ["Jesse Montrose"]
  spec.email         = ["jesse@ninth.org"]
  spec.description   = %q{Instead of making ActiveRecord calls to change a counter field, write them to capacitor.  They'll get summarized in a redis hash, with a separate process batch-retrieving and writing to ActiveRecord.  Being single-threaded, the writing process avoids row lock collisions, and absorbs traffic spikes by coalescing changes to the same row into one DB write.}
  spec.summary       = %q{Buffered ActiveRecord counter writes through redis.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_dependency "formatted-metrics", "~> 1.0"
  spec.add_dependency "redis-namespace", "~> 1.0"
  spec.add_dependency "activesupport", "~> 3.2"

  spec.add_development_dependency "activerecord", "~> 3.2"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redis"
  spec.add_development_dependency "rspec"
end
