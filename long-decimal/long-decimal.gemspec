# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'long-decimal/version'

Gem::Specification.new do |spec|
  spec.name          = "long-decimal"
  spec.version       = LongDecimalSupport::VERSION
  spec.authors       = ["Karl Brodowsky"]
  spec.email         = ["karl_brodowsky@yahoo.com"]
  spec.summary       = %q{Fixed Point Decimal Numbers}
  spec.description   = %q{Decimal arbitrary precision fixed point numbers in pure Ruby.}
  spec.homepage      = "https://github.com/bk1/ruby-long-decimal"
  spec.license       = "LGPL or Ruby"
  spec.files         = "./Gemfile", "./LICENSE", "./README", "./Rakefile", "./lib/long-decimal-extra.rb", "./lib/long-decimal.rb", "./test/testlongdecimal.rb", "./test/testlongdeclib.rb", "./test/testrandlib.rb", "./test/testrandom.rb", "./test/testrandpower.rb", "./tex/long-decimal.pdf", "./tex/long-decimal.tex", "./long-decimal.gemspec", "./lib/long-decimal/version.rb"
  spec.executables   = 
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
