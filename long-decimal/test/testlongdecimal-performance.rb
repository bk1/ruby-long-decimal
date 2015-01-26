#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2009
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdecimal-performance.rb,v 1.2 2011/01/16 18:12:51 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require 'test/unit'

# require "runit/testcase"
# require "runit/cui/testrunner"
# require "runit/testsuite"

load "lib/long-decimal.rb"
load "lib/long-decimal-extra.rb"
load "test/testlongdeclib.rb"

LongMath.prec_overflow_handling = :warn_use_max

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimalExtra_class < Test::Unit::TestCase # RUNIT::TestCase
  include TestLongDecHelper

  @RCS_ID='-$Id: testlongdecimal-performance.rb,v 1.2 2011/01/16 18:12:51 bk1 Exp $-'

  MAX_FLOAT_I = (Float::MAX).to_i

  #
  # compare sqrt-methods
  #
  def test_sqrtx
    print "\ntest_sqrtx [#{Time.now}]: "
    n = 100000
    y1 = []
    y2 = []
    y3 = []
    t1 = Time.new
    n.times do |i|
      y1[i] = LongMath.sqrtb(i)
    end
    puts "sqrtb done"
    t2 = Time.new
    n.times do |i|
      y2[i] = LongMath.sqrtw(i)
    end
    puts "sqrtw done"
    t3 = Time.new
    n.times do |i|
      y3[i] = LongMath.sqrtn(i)
    end
    puts "sqrtn done"
    t4 = Time.new
    t4-=t3
    t3-=t2
    t2-=t1
    puts "t2=#{t2} t3=#{t3} t4=#{t4}"
    n.times do |i|
      assert_equal(y1[i], y2[i], "i=#{i}")
      assert_equal(y2[i], y3[i], "i=#{i}")
      assert_equal(y3[i], y1[i], "i=#{i}")
    end
    puts "test_sqrtx done"
  end  

  def fsqrtx2(i)
    1001+i**3+202*i**2+603*i
  end

  #
  # compare sqrt-methods
  #
  def test_sqrtx2
    print "\ntest_sqrtx [#{Time.now}]: "
    n = 100000
    y1 = []
    y2 = []
    y3 = []
    t1 = Time.new
    n.times do |i|
      x = fsqrtx2(i)
      y1[i] = LongMath.sqrtb(x)
    end
    puts "sqrtb done"
    t2 = Time.new
    n.times do |i|
      x = fsqrtx2(i)
      y2[i] = LongMath.sqrtw(x)
    end
    puts "sqrtw done"
    t3 = Time.new
    n.times do |i|
      x = fsqrtx2(i)
      y3[i] = LongMath.sqrtn(x)
    end
    puts "sqrtn done"
    t4 = Time.new
    t4-=t3
    t3-=t2
    t2-=t1
    puts "t2=#{t2} t3=#{t3} t4=#{t4}"
    n.times do |i|
      assert_equal(y1[i], y2[i], "i=#{i}")
      assert_equal(y2[i], y3[i], "i=#{i}")
      assert_equal(y3[i], y1[i], "i=#{i}")
    end
    puts "test_sqrtx done"
  end  

  #
  # test sint_digits10_2 of LongDecimal
  #
  def _test_int_log2
    print "\ntest_int_log2 [#{Time.now}]: "
    $stdout.flush
    n = 10000
    m = 10**200
    t0 = Time.new
    a1 = (1..n).collect do |r|
      x = m*r+7
      LongMath.log2int(x)
    end
    t1 = Time.new
    puts "t=#{t1-t0}"
    $stdout.flush
    a2 = (1..n).collect do |r|
      x = m*r+7
      Math.log(x)/Math.log(2)
    end
    t2 = Time.new
    puts "t=#{t2-t1}"
    $stdout.flush
    a3 = (1..n).collect do |r|
      x = m*r+7
      LongMath.log2(x, 1).to_f
    end
    t3 = Time.new
    puts "t=#{t3-t2}"
    $stdout.flush
    t3 -= t2
    t2 -= t1
    t1 -= t0
    puts "t0=#{t0} t1=#{t1} t2=#{t2} t3=#{t3}"
    n.times do |i|
      unless (a1[i] <= a2[i] && a2[i] <= a1[i] + 0.1)
        r = i+1
        x = m*r+7
        assert_equal(a1[i], a2[i], "i=#{i} x=#{x}")
      end
      assert((a2[i] - a3[i]).abs <= 0.01)
      assert((a3[i] - a1[i]).abs <= 0.1)
    end
    puts Time.new - t0
  end

  #
  # test sint_digits10_2 of LongDecimal
  #
  def _test_sint_digits10_1
    print "\ntest_sint_digits10_1 [#{Time.now}]: "
    t0 = Time.new
    assert_equal(-4, LongDecimal("0.0000").sint_digits10, "0.0000")
    assert_equal(-3, LongDecimal("0.0009").sint_digits10, "0.0009")
    assert_equal(-2, LongDecimal("0.0099").sint_digits10, "0.0099")
    assert_equal(-1, LongDecimal("0.0999").sint_digits10, "0.0999")
    assert_equal(0, LongDecimal("0.9999").sint_digits10, "0.9999")
    assert_equal(1, LongDecimal("1.0000").sint_digits10, "1.0000")
    assert_equal(1, LongDecimal("9.9999").sint_digits10, "9.9999")
    assert_equal(2, LongDecimal("10.0000").sint_digits10, "10.0000")
    assert_equal(2, LongDecimal("99.9999").sint_digits10, "99.9999")
    assert_equal(3, LongDecimal("100.0000").sint_digits10, "100.0000")
    assert_equal(3, LongDecimal("999.9999").sint_digits10, "999.9999")

    assert_equal(-4, LongDecimal("-0.0000").sint_digits10, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").sint_digits10, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").sint_digits10, "-1.0000")
    assert_equal(1, LongDecimal("-9.9999").sint_digits10, "-9.9999")
    assert_equal(2, LongDecimal("-10.0000").sint_digits10, "-10.0000")
    assert_equal(2, LongDecimal("-99.9999").sint_digits10, "-99.9999")
    assert_equal(3, LongDecimal("-100.0000").sint_digits10, "-100.0000")
    assert_equal(3, LongDecimal("-999.9999").sint_digits10, "-999.9999")
    x = 1234.to_ld
    assert_equal(4, x.sint_digits10, "1234")
    assert_equal(4, x.sint_digits10, "1234")
    x = 1234.to_ld(10)
    assert_equal(4, x.sint_digits10, "1234")
    assert_equal(4, x.sint_digits10, "1234")

    x = (10**400).to_ld(10)
    assert_equal(401, (x+1).sint_digits10, "1e400+1")
    assert_equal(401, x.sint_digits10, "1e400")
    assert_equal(400, (x-1).sint_digits10, "1e400-1")
    x = (10**200).to_ld(10)
    assert_equal(201, (x+1).sint_digits10, "1e200+1")
    assert_equal(201, x.sint_digits10, "1e200")
    assert_equal(200, (x-1).sint_digits10, "1e200-1")
    x = (10**100).to_ld(10)
    assert_equal(101, (x+1).sint_digits10, "1e100+1")
    assert_equal(101, x.sint_digits10, "1e100")
    assert_equal(100, (x-1).sint_digits10, "1e100-1")
    puts Time.new - t0
  end

  #
  # test sint_digits10_2 of LongDecimal
  #
  def _test_sint_digits10_2
    print "\ntest_sint_digits10_2 [#{Time.now}]: "
    t0 = Time.new
    assert_equal(-4, LongDecimal("0.0000").sint_digits10_2, "0.0000")
    assert_equal(-3, LongDecimal("0.0009").sint_digits10_2, "0.0009")
    assert_equal(-2, LongDecimal("0.0099").sint_digits10_2, "0.0099")
    assert_equal(-1, LongDecimal("0.0999").sint_digits10_2, "0.0999")
    assert_equal(0, LongDecimal("0.9999").sint_digits10_2, "0.9999")
    assert_equal(1, LongDecimal("1.0000").sint_digits10_2, "1.0000")
    assert_equal(1, LongDecimal("9.9999").sint_digits10_2, "9.9999")
    assert_equal(2, LongDecimal("10.0000").sint_digits10_2, "10.0000")
    assert_equal(2, LongDecimal("99.9999").sint_digits10_2, "99.9999")
    assert_equal(3, LongDecimal("100.0000").sint_digits10_2, "100.0000")
    assert_equal(3, LongDecimal("999.9999").sint_digits10_2, "999.9999")

    assert_equal(-4, LongDecimal("-0.0000").sint_digits10_2, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").sint_digits10_2, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").sint_digits10_2, "-1.0000")
    assert_equal(1, LongDecimal("-9.9999").sint_digits10_2, "-9.9999")
    assert_equal(2, LongDecimal("-10.0000").sint_digits10_2, "-10.0000")
    assert_equal(2, LongDecimal("-99.9999").sint_digits10_2, "-99.9999")
    assert_equal(3, LongDecimal("-100.0000").sint_digits10_2, "-100.0000")
    assert_equal(3, LongDecimal("-999.9999").sint_digits10_2, "-999.9999")
    x = 1234.to_ld
    assert_equal(4, x.sint_digits10_2, "1234")
    assert_equal(4, x.sint_digits10_2, "1234")
    x = 1234.to_ld(10)
    assert_equal(4, x.sint_digits10_2, "1234")
    assert_equal(4, x.sint_digits10_2, "1234")

    x = (10**400).to_ld(10)
    assert_equal(401, (x+1).sint_digits10_2, "1e400+1")
    assert_equal(401, x.sint_digits10_2, "1e400")
    assert_equal(400, (x-1).sint_digits10_2, "1e400-1")
    x = (10**200).to_ld(10)
    assert_equal(201, (x+1).sint_digits10_2, "1e200+1")
    assert_equal(201, x.sint_digits10_2, "1e200")
    assert_equal(200, (x-1).sint_digits10_2, "1e200-1")
    x = (10**100).to_ld(10)
    assert_equal(101, (x+1).sint_digits10_2, "1e100+1")
    assert_equal(101, x.sint_digits10_2, "1e100")
    assert_equal(100, (x-1).sint_digits10_2, "1e100-1")
    puts Time.new - t0
  end

  #
  # test sint_digits10_3 of LongDecimal
  #
  def _test_sint_digits10_3
    print "\ntest_sint_digits10_3 [#{Time.now}]: "
    t0 = Time.new
    assert_equal(-4, LongDecimal("0.0000").sint_digits10_3, "0.0000")
    assert_equal(-3, LongDecimal("0.0009").sint_digits10_3, "0.0009")
    assert_equal(-2, LongDecimal("0.0099").sint_digits10_3, "0.0099")
    assert_equal(-1, LongDecimal("0.0999").sint_digits10_3, "0.0999")
    assert_equal(0, LongDecimal("0.9999").sint_digits10_3, "0.9999")
    assert_equal(1, LongDecimal("1.0000").sint_digits10_3, "1.0000")
    assert_equal(1, LongDecimal("9.9999").sint_digits10_3, "9.9999")
    assert_equal(2, LongDecimal("10.0000").sint_digits10_3, "10.0000")
    assert_equal(2, LongDecimal("99.9999").sint_digits10_3, "99.9999")
    assert_equal(3, LongDecimal("100.0000").sint_digits10_3, "100.0000")
    assert_equal(3, LongDecimal("999.9999").sint_digits10_3, "999.9999")

    assert_equal(-4, LongDecimal("-0.0000").sint_digits10_3, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").sint_digits10_3, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").sint_digits10_3, "-1.0000")
    assert_equal(1, LongDecimal("-9.9999").sint_digits10_3, "-9.9999")
    assert_equal(2, LongDecimal("-10.0000").sint_digits10_3, "-10.0000")
    assert_equal(2, LongDecimal("-99.9999").sint_digits10_3, "-99.9999")
    assert_equal(3, LongDecimal("-100.0000").sint_digits10_3, "-100.0000")
    assert_equal(3, LongDecimal("-999.9999").sint_digits10_3, "-999.9999")
    x = 1234.to_ld
    assert_equal(4, x.sint_digits10_3, "1234")
    assert_equal(4, x.sint_digits10_3, "1234")
    x = 1234.to_ld(10)
    assert_equal(4, x.sint_digits10_3, "1234")
    assert_equal(4, x.sint_digits10_3, "1234")

    x = (10**400).to_ld(10)
    assert_equal(401, (x+1).sint_digits10_3, "1e400+1")
    assert_equal(401, x.sint_digits10_3, "1e400")
    assert_equal(400, (x-1).sint_digits10_3, "1e400-1")
    x = (10**200).to_ld(10)
    assert_equal(201, (x+1).sint_digits10_3, "1e200+1")
    assert_equal(201, x.sint_digits10_3, "1e200")
    assert_equal(200, (x-1).sint_digits10_3, "1e200-1")
    x = (10**100).to_ld(10)
    assert_equal(101, (x+1).sint_digits10_3, "1e100+1")
    assert_equal(101, x.sint_digits10_3, "1e100")
    assert_equal(100, (x-1).sint_digits10_3, "1e100-1")
    puts Time.new - t0
  end

  #
  # test sint_digits10_4 of LongDecimal
  #
  def _test_sint_digits10_4
    print "\ntest_sint_digits10_4 [#{Time.now}] (7 min): "
    t0 = Time.new
    assert_equal(-4, LongDecimal("0.0000").sint_digits10_4, "0.0000")
    assert_equal(-3, LongDecimal("0.0009").sint_digits10_4, "0.0009")
    assert_equal(-2, LongDecimal("0.0099").sint_digits10_4, "0.0099")
    assert_equal(-1, LongDecimal("0.0999").sint_digits10_4, "0.0999")
    assert_equal(0, LongDecimal("0.9999").sint_digits10_4, "0.9999")
    assert_equal(1, LongDecimal("1.0000").sint_digits10_4, "1.0000")
    assert_equal(1, LongDecimal("9.9999").sint_digits10_4, "9.9999")
    assert_equal(2, LongDecimal("10.0000").sint_digits10_4, "10.0000")
    assert_equal(2, LongDecimal("99.9999").sint_digits10_4, "99.9999")
    assert_equal(3, LongDecimal("100.0000").sint_digits10_4, "100.0000")
    assert_equal(3, LongDecimal("999.9999").sint_digits10_4, "999.9999")

    assert_equal(-4, LongDecimal("-0.0000").sint_digits10_4, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").sint_digits10_4, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").sint_digits10_4, "-1.0000")
    assert_equal(1, LongDecimal("-9.9999").sint_digits10_4, "-9.9999")
    assert_equal(2, LongDecimal("-10.0000").sint_digits10_4, "-10.0000")
    assert_equal(2, LongDecimal("-99.9999").sint_digits10_4, "-99.9999")
    assert_equal(3, LongDecimal("-100.0000").sint_digits10_4, "-100.0000")
    assert_equal(3, LongDecimal("-999.9999").sint_digits10_4, "-999.9999")
    x = 1234.to_ld
    assert_equal(4, x.sint_digits10_4, "1234")
    assert_equal(4, x.sint_digits10_4, "1234")
    x = 1234.to_ld(10)
    assert_equal(4, x.sint_digits10_4, "1234")
    assert_equal(4, x.sint_digits10_4, "1234")

    x = (10**400).to_ld(10)
    assert_equal(401, (x+1).sint_digits10_4, "1e400+1")
    assert_equal(401, x.sint_digits10_4, "1e400")
    assert_equal(400, (x-1).sint_digits10_4, "1e400-1")
    x = (10**200).to_ld(10)
    assert_equal(201, (x+1).sint_digits10_4, "1e200+1")
    assert_equal(201, x.sint_digits10_4, "1e200")
    assert_equal(200, (x-1).sint_digits10_4, "1e200-1")
    x = (10**100).to_ld(10)
    assert_equal(101, (x+1).sint_digits10_4, "1e100+1")
    assert_equal(101, x.sint_digits10_4, "1e100")
    assert_equal(100, (x-1).sint_digits10_4, "1e100-1")
    puts Time.new - t0
  end

end

# RUNIT::CUI::TestRunner.run(TestLongDecimalExtra_class.suite)

# end of file testlongdecimal.rb
