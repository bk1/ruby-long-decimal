#!/usr/bin/env ruby

require 'rbconfig'
require 'fileutils'
include FileUtils::Verbose

include Config

file = 'lib/longdecimal.rb'
dest = CONFIG["sitelibdir"]
install(file, dest)
    # vim: set et sw=4 ts=4:
