#!/usr/bin/env ruby

#
# version.rb -- extract version information from files
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/version.rb,v 1.3 2006/02/25 20:05:53 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_06 $
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
  if name =~ /PRE_ALPHA_(\d+)_(\d+)/ then
    str = sprintf("0.%02d.%02d", $1, $2)
  else
    str = version
  end

  # print "file=#{file}\nstr=#{str}\nversion=#{version}\nname=#{name}\n";
  print str,"\n"
end

# end of file version.rb
