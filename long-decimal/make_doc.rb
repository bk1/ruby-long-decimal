#!/usr/bin/env ruby

$outdir = 'doc/'
puts "Creating documentation in '#$outdir'."
system "rdoc -d -o #$outdir lib/longdecimal.rb"
    # vim: set et sw=4 ts=4:
