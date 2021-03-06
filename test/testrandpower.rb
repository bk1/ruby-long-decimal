#!/usr/bin/env ruby
# frozen_string_literal: true

#
# testrandpower.rb -- random tests for power-method from long-decimal-extra.rb
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2015
#
# TAG:       $TAG v1.00.04$
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testrandpower.rb,v 1.14 2009/05/09 15:37:00 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

$test_type = nil
if (RUBY_VERSION.match /^1\./) || (RUBY_VERSION.match /^2\.0/)
  require 'test/unit'
  $test_type = :v20
else
  require 'minitest/autorun'
  require 'test/unit/assertions'
  include Test::Unit::Assertions
  $test_type = :v21
end

load 'lib/long-decimal.rb'
load 'lib/long-decimal-extra.rb'

load 'test/testlongdeclib.rb'
load 'test/testrandlib.rb'

LongMath.prec_overflow_handling = :warn_use_max

if $test_type == :v20
  class UnitTest < Test::Unit::TestCase
  end
else
  class UnitTest < MiniTest::Test
  end
end

#
# test class for LongDecimal and LongDecimalQuot
#
class TestRandomPower_class < UnitTest
  include TestLongDecHelper
  include TestRandomHelper
  include LongDecimalRoundingMode

  @RCS_ID = '-$Id: testrandpower.rb,v 1.14 2009/05/09 15:37:00 bk1 Exp $-'

  # for how many seconds should this test run? change to different
  # value on demand
  @@duration = 1_000_000

  #
  # test the calculation of the eyponential function
  #
  def test_random_power
    cnt  = 0
    scnt = 0
    t0   = Time.new
    loop do
      t1 = Time.new
      d  = t1 - t0
      break if d >= @@duration

      xarr, eprec1, lprec1, sprec1, pprec1, xs = random_arr
      yarr, eprec2, lprec2, sprec2, pprec2, ys = random_arr

      prec = (pprec1 + pprec2) >> 1
      xarr.each do |x|
        puts(" t=#{Time.new - t1} x=#{x}: ")
        next if x <= 0
        next if x.abs > LongMath::MAX_FLOATABLE || (1 / x).abs > LongMath::MAX_FLOATABLE

        yarr.each do |y|
          puts("\ncnt=#{cnt} scnt=#{scnt} x=#{x} y=#{y} scx=#{x.scale} scy=#{y.scale} prec=#{prec}")
          next if x > 1 && y > LongMath::MAX_EXP_ABLE * 2
          next if x < 1 && y < -LongMath::MAX_EXP_ABLE * 2
          next if Math.log(1 + x.to_i) * y.to_i > LongMath::MAX_EXP_ABLE
          next if -Math.log(1 + (1 / x).to_i) * y.to_i > LongMath::MAX_EXP_ABLE
          next if (Math.log(x.to_f) * y.to_f).abs > LongMath::MAX_EXP_ABLE * 2

          scnt += 1
          check_power_floated(x, y, prec)
        end
      end
      cnt += 1
    end
    puts("done #{cnt} tests\n")
  end
end

# RUNIT::CUI::TestRunner.run(TestRandomPower_class.suite)

# end of file testrandpower.rb
