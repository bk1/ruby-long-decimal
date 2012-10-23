#!/usr/bin/env ruby

#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/make_doc.rb,v 1.3 2009/04/15 19:29:37 bk1 Exp $
# CVS-Label: $Name: BETA_02_01 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

$outdir = 'doc/'
puts "Creating documentation in '#$outdir'."
system "rdoc -d -o #$outdir lib/long-decimal.rb"
    # vim: set et sw=4 ts=4:
