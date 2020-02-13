# frozen_string_literal: true

#
# Rakefile for long-decimal project
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2015
#
# TAG:       $TAG v1.00.04$
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/Rakefile,v 1.4 2009/04/15 19:29:37 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require 'bundler/gem_tasks'
require 'rubygems'
require 'bundler'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/testlongdecimal.rb'
  test.verbose = true
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION').strip : LongDecimalSupport::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "long-decimal #{version}"
  rdoc.main = 'README'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/*.rb')
end

task default: :test

# end of file Rakefile
