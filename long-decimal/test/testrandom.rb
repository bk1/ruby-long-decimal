#!/usr/bin/env ruby
#
# testrandom.rb -- runit test for long-decimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testrandom.rb,v 1.10 2006/04/30 20:49:54 bk1 Exp $
# CVS-Label: $Name: ALPHA_01_01 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "runit/testcase"
require "runit/cui/testrunner"
require "runit/testsuite"
require "crypt/ISAAC"

load "test/testlongdeclib.rb"
load "test/testrandlib.rb"

#
# test class for LongDecimal and LongDecimalQuot
#
class TestRandom_class < RUNIT::TestCase
  include TestLongDecHelper
  include TestRandomHelper

  @RCS_ID='-$Id: testrandom.rb,v 1.10 2006/04/30 20:49:54 bk1 Exp $-'

  # for how many seconds should this test run? change to different
  # value on demand
  @@duration = 1000000

  def check_exp_log_rand(arr, eprec, lprec, pprec, sprec, sc, cnt)
    arr.each do |x|
      @scnt += 1
      puts("\ncnt=#{cnt} scnt=#{@scnt} x=#{x} ep=#{eprec} lp=#{lprec} sp=#{sprec} pp=#{pprec}\n")
      if (x.abs <= LongMath::MAX_EXP_ABLE)
	check_exp_floated(x, eprec)
	check_exp2_floated(x, pprec)
	check_exp10_floated(x, pprec)
      end
      if (x > 0)
	check_log_floated(x, lprec)
	check_log2_floated(x, lprec)
	check_log10_floated(x, lprec)
      end
      if (x > 0)
	xr = x.round_to_scale(sc, LongMath::ROUND_HALF_UP)
	check_sqrt_with_remainder(xr, sprec, "x=#{x} p=#{sprec}")
      end
    end
  end

  #
  # test the calculation of the exponential function
  #
  def test_random
    cnt = 0
    @scnt = 0
    t0  = Time.new
    while (true) do
      d = Time.new - t0
      break if d >= @@duration
      arr, eprec, lprec, sprec, pprec, sc = random_arr
      check_exp_log_rand(arr, eprec, lprec, pprec, sprec, sc, cnt)
      cnt += 1
    end
    puts("done #{cnt} tests\n")
  end

end

RUNIT::CUI::TestRunner.run(TestRandom_class.suite)

# end of file testrandom.rb
