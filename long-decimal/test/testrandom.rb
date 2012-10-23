#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testrandom.rb,v 1.2 2006/04/07 22:26:08 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_22 $
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

  @RCS_ID='-$Id: testrandom.rb,v 1.2 2006/04/07 22:26:08 bk1 Exp $-'

  @@duration = 100000

  @@r1 = Crypt::ISAAC.new
  @@r2 = Crypt::ISAAC.new
  @@r3 = Crypt::ISAAC.new
  @@r4 = Crypt::ISAAC.new

  #
  # test the calculation of the exponential function
  #
  def test_random
    cnt = 0
    t0  = Time.new
    while (true) do
      d = Time.new - t0
      break if d >= @@duration
      x0 = @@r1.rand(700)
      x1 = @@r2.rand(1000)
      x2 = @@r2.rand(100)+3
      x3 = @@r3.rand(1000)
      x4 = @@r3.rand(100)+4
      x5 = @@r4.rand(1000)
      x6 = @@r4.rand(100)+5
      x = x0 + LongDecimal(x1, x2) + LongDecimal(x3, x4) + LongDecimal(x5, x6)
      prec = @@r1.rand(120)
      puts("x=#{x} p=#{prec}\n")
      check_exp_floated(x, prec)
      check_exp_floated(-x, prec)
      xx = x.inverse.to_ld(x.scale*2)
      if (xx <= LongMath::MAX_EXP_ABLE)
          check_exp_floated(xx, prec)
          check_exp_floated(-xx, prec)
      end
      if (x > 0)
	check_log_floated(x, prec)
      end
      if (xx > 0)
	check_log_floated(xx, prec)
      end
      sprec = prec+(x.scale>>1)
      check_sqrt_with_remainder(x, sprec, "x=#{x} p=#{sprec}")
      cnt += 1
    end
    puts("done #{cnt} tests\n")
  end

end

RUNIT::CUI::TestRunner.run(TestLongDecimal_class.suite)

# end of file testlongdecimal.rb
