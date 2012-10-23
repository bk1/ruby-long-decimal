#!/usr/bin/env ruby

#
# version.rb -- extract version information from files
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2009
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/version.rb,v 1.8 2009/04/18 05:51:14 bk1 Exp $
# CVS-Label: $Name: BETA_02_01 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

ARGV.each do |file|
  name = ""
  version = ""

  File.open(file, "r") do |openFile|
    openFile.each_line do |line|
      if line =~ /\$[H]eader:\s.+,v\s+([0-9.]+)\s*.+\$/ then
        version = $1
      elsif line =~ /\$[N]ame:\s+(\S+)\s+\$/ then
        name = $1
      end
    end
  end

  str = ""
  if name =~ /(PRE_ALPHA|ALPHA|BETA)_(\d+)_(\d+)/ then
    str = sprintf("0.%02d.%02d", $2.to_i, $3.to_i)
  else
    str = version
  end

  print str,"\n"
end

# end of file version.rb
