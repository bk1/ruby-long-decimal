#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testrandom.rb,v 1.5 2006/04/10 21:47:02 bk1 Exp $
# CVS-Label: $Name: ALPHA_01_00 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "runit/testcase"
require "runit/cui/testrunner"
require "runit/testsuite"
require "crypt/ISAAC"

load "test/testlongdeclib.rb"

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimal_class < RUNIT::TestCase
  include TestLongDecHelper

  @RCS_ID='-$Id: testrandom.rb,v 1.5 2006/04/10 21:47:02 bk1 Exp $-'

  # for how many seconds should this test run? change to different
  # value on demand
  @@duration = 1000000

  @@r1 = Crypt::ISAAC.new
  @@r2 = Crypt::ISAAC.new
  @@r3 = Crypt::ISAAC.new
  @@r4 = Crypt::ISAAC.new

  def check_exp_log_rand(x, eprec, lprec)
    check_exp_log_half(x, eprec, lprec)
    xx = x.inverse.to_ld(x.scale*2)
    check_exp_log_half(xx, eprec, lprec)
  end

  def check_exp_log_half(x, eprec, lprec)
    if (x <= LongMath::MAX_EXP_ABLE)
      check_exp_floated(x, eprec)
      check_exp_floated(-x, eprec)
    end
    if (x > 0)
      check_log_floated(x, lprec)
      check_log2_floated(x, lprec)
      check_log10_floated(x, lprec)
    end
  end

  #
  # test the calculation of the exponential function
  #
  def test_random
    cnt = 0
    t0  = Time.new
    while (true) do
      d = Time.new - t0
      break if d >= @@duration
      x0 = @@r1.rand(1000)
      x1 = @@r2.rand(1000)
      x2 = @@r2.rand(100)+3
      x3 = @@r3.rand(1000)
      x4 = @@r3.rand(100)+4
      x5 = @@r4.rand(1000)
      x6 = @@r4.rand(100)+5
      xs = LongDecimal(x1, x2) + LongDecimal(x3, x4) + LongDecimal(x5, x6)
      xm = 1 + xs
      x  = x0 + xs
      eprec = @@r1.rand(120)
      lprec = eprec+1
      sprec = eprec+((x.scale+1)>>1)
      puts("cnt=#{cnt} x=#{x} sc=#{x.scale} ep=#{eprec} lp=#{lprec} sp=#{sprec}\n")
      check_exp_log_rand(xs, eprec, lprec)
      check_exp_log_rand(xm, eprec, lprec)
      check_exp_log_rand(x , eprec, lprec)
      check_sqrt_with_remainder(x, sprec, "x=#{x} p=#{sprec}")
      cnt += 1
    end
    puts("done #{cnt} tests\n")
  end

end

RUNIT::CUI::TestRunner.run(TestLongDecimal_class.suite)

# end of file testlongdecimal.rb
