#!/usr/bin/env ruby

#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/install.rb,v 1.3 2009/04/15 19:29:37 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require 'rbconfig'
require 'fileutils'
include FileUtils::Verbose

include Config

file = 'lib/long-decimal.rb'
dest = CONFIG["sitelibdir"]
install(file, dest)
    # vim: set et sw=4 ts=4:
