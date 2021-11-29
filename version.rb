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

  File.open(file, 'r') do |open_file|
    open_file.each_line do |line|
      case line
      when /\$Header:\s.+,v\s+([0-9.]+)\s*.+\$/
        version = Regexp.last_match(1)
      when /\$Name:\s+(\S+)\s+\$/
        name = Regexp.last_match(1)
      end
    end
  end

  str = case name
        when /(PRE_ALPHA|ALPHA|BETA)_(\d+)_(\d+)/
          format('0.%<second_part>02d.%<third_part>02d',
                 second_part: Regexp.last_match(2).to_i,
                 third_part: Regexp.last_match(3).to_i)
        when /RELEASE_(\d+)_(\d+)_(\d+)/
          format('%<first_part>d.%<second_part>02d.%<third_part>02d',
                 first_part: Regexp.last_match(1).to_i,
                 second_part: Regexp.last_match(2).to_i,
                 third_part: Regexp.last_match(3).to_i)
        else
          version
        end

  puts str
end

# end of file version.rb
