#!/usr/bin/env ruby
# frozen_string_literal: true

#
# version.rb -- extract version information from files
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2015
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/version.rb,v 1.9 2011/01/22 12:34:39 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

ARGV.each do |file|
  name = ''
  version = ''

  File.open(file, 'r') do |openFile|
    openFile.each_line do |line|
      if line =~ /\$[H]eader:\s.+,v\s+([0-9.]+)\s*.+\$/
        version = Regexp.last_match(1)
      elsif line =~ /\$[N]ame:\s+(\S+)\s+\$/
        name = Regexp.last_match(1)
      end
    end
  end

  str = ''
  str = if name =~ /(PRE_ALPHA|ALPHA|BETA)_(\d+)_(\d+)/
          format('0.%02d.%02d', Regexp.last_match(2).to_i, Regexp.last_match(3).to_i)
        elsif name =~ /RELEASE_(\d+)_(\d+)_(\d+)/
          format('%d.%02d.%02d', Regexp.last_match(1).to_i, Regexp.last_match(2).to_i, Regexp.last_match(3).to_i)
        else
          version
        end

  print str, "\n"
end

# end of file version.rb
