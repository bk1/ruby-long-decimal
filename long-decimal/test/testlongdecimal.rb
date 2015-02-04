#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2015
#
# TAG:       $TAG v1.00.03$
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

$test_type = nil
if ((RUBY_VERSION.match /^1\./) || (RUBY_VERSION.match /^2\.0/)) then
  require 'test/unit'
  $test_type = :v20
else
  require 'minitest/autorun'
  require 'test/unit/assertions'
  include Test::Unit::Assertions
  $test_type = :v21
end

# require "runit/testcase"
# require "runit/cui/testrunner"
# require "runit/testsuite"

load "lib/long-decimal.rb"
load "test/testlongdeclib.rb"

LongMath.prec_overflow_handling = :warn_use_max

if ($test_type == :v20)
  class UnitTest < Test::Unit::TestCase
  end
else
  class UnitTest < MiniTest::Test
  end
end

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimal_class < UnitTest # RUNIT::TestCase
  include TestLongDecHelper
  include LongDecimalRoundingMode

  #
  # test split_to_words and merge_from_words
  #
  def test_split_merge_words
    print "\ntest_split_merge_words [#{Time.now}]: "
    check_split_merge_words(0, 1, 1)
    check_split_merge_words(0, 10, 1)
    check_split_merge_words(0, 100, 1)
    check_split_merge_words(0, 1000, 1)
    check_split_merge_words(-1, 1, 1)
    check_split_merge_words(-1, 10, 1)
    check_split_merge_words(-1, 100, 1)
    check_split_merge_words(-1, 1000, 1)
    check_split_merge_words(1, 1, 1)
    check_split_merge_words(1, 10, 1)
    check_split_merge_words(1, 100, 1)
    check_split_merge_words(1, 1000, 1)
    check_split_merge_words(10, 1, 4)
    check_split_merge_words(10, 10, 1)
    check_split_merge_words(10, 100, 1)
    check_split_merge_words(10, 1000, 1)
    x = 10**12 # 10**12 = 1000**4 < 2**40
    check_split_merge_words(x, 1, 40)
    check_split_merge_words(x, 10, 4)
    check_split_merge_words(x, 100, 1)
    check_split_merge_words(x, 1000, 1)
    x = 2**40
    check_split_merge_words(x, 1, 41)
    check_split_merge_words(x, 10, 5)
    check_split_merge_words(x, 100, 1)
    check_split_merge_words(x, 1000, 1)
  end

  #
  # test the calculation of the exponential function
  #
  def test_exp
    print "\ntest_exp [#{Time.now}] (60 sec): "
    $stdout.flush
    xx = LongMath.log(10.to_ld, 10)*100
    check_exp_floated(700, 10)
    check_exp_floated(100, 10)
    check_exp_floated(1, 10)
    check_exp_floated(0.01, 10)
    check_exp_floated(1e-10, 10)
    check_exp_floated(1e-90, 10)
    check_exp_floated(0, 10)
    check_exp_floated(-1, 10)
    check_exp_floated(-100, 10)
    check_exp_floated(-700, 10)
    check_exp_floated(xx, 10)
    check_exp_floated(-xx, 10)

    check_exp_floated(700, 100)
    check_exp_floated(100, 100)
    check_exp_floated(1, 100)
    check_exp_floated(0.01, 100)
    check_exp_floated(1e-10, 100)
    check_exp_floated(1e-90, 100)
    check_exp_floated(0, 100)
    check_exp_floated(-1, 100)
    check_exp_floated(-100, 100)
    check_exp_floated(-700, 100)
    check_exp_floated(xx, 100)
    check_exp_floated(-xx, 100)

    # random tests that have failed previously
    check_exp_floated(LongDecimal("0.0000000000000000000000000050000000000000000000000000000000000000000000000000000000000000017066"), 25)
    check_exp_floated(LongDecimal("0.00000000000000000000000000000000000000000000000000000000000000570000000004000000000000050"), 86)
    check_exp_floated(LongDecimal("-51.0000000000000000000000000000000000000000000000000000000000000000000002300000000434000994"), 22)
    check_exp_floated(LongDecimal("0.0000000000000000000000816000000000000000000000000000066500000949"), 55)
    check_exp_floated(LongDecimal("0.0000000000000000000000000000000000000000000012100000000000000000565000000000000000000000000593"), 94)
    check_exp_floated(LongDecimal("0.49999999987500000004166666665104166667291666666406250000111607142808314732164558531736266121036184952198542695369806246270654055688438826256113701277472962860048170064139001013692959178218223"), 9)
    check_exp_floated(LongDecimal("0.000000000000000000000000000000000000000000000000695000000000000000000000000000042500000000000000552"), 50)
  end

  #
  # test the calculation of the exponential function where result is
  # near zero
  #
  def test_exp_near_zero
    print "\ntest_exp_near_zero [#{Time.now}]: "

    x = LongDecimal(1, 100)
    y = LongMath.log(x, 100)
    z = check_exp_floated(y, 100)
    assert_equal(x, z, "must be equal")
    z = check_exp_floated(y, 99)
    assert(z.zero?, "must be zero")
    z = check_exp_floated(y * 100, 99)
    assert(z.zero?, "must be zero")

  end

  #
  # test the calculation of the exponential function with precision 0
  #
  def test_exp_int
    print "\ntest_exp_int [#{Time.now}]: "

    xx = LongMath.log(10, 10)*100
    pi = LongMath.pi(10)
    sq = LongMath.sqrt(5, 20)

    check_exp_int(0)

    check_exp_int(700.1)
    check_exp_int(700)
    check_exp_int(100.01)
    check_exp_int(100)
    check_exp_int(1.001)
    check_exp_int(1)
    check_exp_int(0.01)
    check_exp_int(1e-10)
    check_exp_int(1e-90)
    check_exp_int(xx)
    check_exp_int(pi)
    check_exp_int(sq)

    check_exp_int(-700.1)
    check_exp_int(-700)
    check_exp_int(-100.01)
    check_exp_int(-100)
    check_exp_int(-1.001)
    check_exp_int(-1)
    check_exp_int(-0.01)
    check_exp_int(-1e-10)
    check_exp_int(-1e-90)
    check_exp_int(-xx)
    check_exp_int(-pi)
    check_exp_int(-sq)

  end

  #
  # test LongMath.exp with non-LongDecimal arguments
  #
  def test_non_ld_exp
    print "\ntest_non_ld_exp [#{Time.now}]: "
    xi = 77
    yi = LongMath.exp(xi, 30)
    zi = LongMath.log(yi, 30)
    assert(zi.is_int?, "zi")
    assert_equal(xi, zi.to_i, "zi")

    xf = 77.0
    yf = LongMath.exp(xf, 30)
    zf = LongMath.log(yf, 30)
    assert(zf.is_int?, "zf")
    assert_equal(xf, zf.to_f, "zf")
    assert_equal(yi, yf, "i-f")

    xr = Rational(224, 225)
    yr = LongMath.exp(xr, 30)
    zr = LongMath.log(yr, 30)
    assert((zr-xr).abs <= zr.unit, "zr-xr")
  end

  #
  # test exp2 of LongMath
  #
  def test_exp2
    print "\ntest_exp2 [#{Time.now}]: "
    10.times do |i|
      n = (i*i+i)/2
      x = LongDecimal(n, 3*i)+LongMath.pi(20)
      check_exp2_floated(x, n)

      y  = LongMath.exp2(x, n)
      yy = LongMath.exp2(x, n + 5)
      assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
      z  = LongMath.power(2, x, n)
      assert_equal(z, y, "exp2 x=#{x} y=#{y} z=#{z} i=#{i} n=#{n}")
    end

    # random tests that have failed previously
    check_exp2_floated(LongDecimal("-0.00147492625237084606064197462823289474038138852346725504592707365251736299180323394082648207114993022483949313246714392730651107673327728615912046468517225938833913598854936005"), 20)

  end

  #
  # test the calculation of the exponential function where result is
  # near zero
  #
  def test_exp2_near_zero
    print "\ntest_exp2_near_zero [#{Time.now}]: "

    x = LongDecimal(1, 100)
    y = LongMath.log2(x, 100)
    z = check_exp2_floated(y, 100)
    assert_equal(x, z, "must be equal")
    z = check_exp2_floated(y, 99)
    assert(z.zero?, "must be zero")
    z = check_exp2_floated(y * 100, 99)
    assert(z.zero?, "must be zero")

  end

  #
  # test exp10 of LongMath
  #
  def test_exp10
    print "\ntest_exp10 [#{Time.now}]: "
    10.times do |i|
      n  = (i*i+i)/2
      x  = LongDecimal(n, 3*i)+LongMath.pi(20)
      check_exp10_floated(x, n)

      y  = LongMath.exp10(x, n)
      yy = LongMath.exp10(x, n + 5)
      assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
      z  = LongMath.power(10, x, n)
      assert_equal(z, y, "exp10 x=#{x} y=#{y} z=#{z} i=#{i} n=#{n}")
    end
  end

  #
  # test the calculation of the exponential function where result is
  # near zero
  #
  def test_exp10_near_zero
    print "\ntest_exp10_near_zero [#{Time.now}]: "

    x = LongDecimal(1, 100)
    y = LongMath.log10(x, 100)
    z = check_exp10_floated(y, 100)
    assert_equal(x, z, "must be equal")
    z = check_exp10_floated(y, 99)
    assert(z.zero?, "must be zero")
    z = check_exp10_floated(y * 100, 99)
    assert(z.zero?, "must be zero")

  end

  #
  # test LongMath.log with non-LongDecimal arguments
  #
  def test_non_ld_log
    print "\ntest_non_ld_log [#{Time.now}]: "
    xi = 77
    yi = LongMath.log(xi, 35)
    zi = LongMath.exp(yi, 30)
    assert(zi.is_int?, "zi=#{zi}")
    assert_equal(xi, zi.to_i, "zi")

    xf = 77.0
    yf = LongMath.log(xf, 35)
    zf = LongMath.exp(yf, 30)
    assert(zf.is_int?, "zf=#{zf}")
    assert_equal(xf, zf.to_f, "zf")
    assert_equal(yi, yf, "i-f")

    xr = Rational(224, 225)
    yr = LongMath.log(xr, 35)
    zr = LongMath.exp(yr, 30)
    assert((zr-xr).abs <= zr.unit, "zr-xr zr=#{zr}")
  end

  #
  # test the calculation of the logarithm function
  #
  def test_log
    print "\ntest_log [#{Time.now}] (120 sec): "
    $stdout.flush

    check_log_floated(10**2000, 10)
    check_log_floated(100, 10)
    check_log_floated(1, 10)
    check_log_floated(0.01, 10)
    check_log_floated(1e-10, 10)
    check_log_floated(1e-90, 10)
    check_log_floated(1e-300, 10)
    check_log_floated(LongDecimal(1, 2000), 10)

    check_log_floated(2, 50)
    check_log_floated(1.01, 50)
    check_log_floated(1+1e-10, 50, 1e7)
    check_log_floated(1.to_ld(90).succ, 100, 1e9, 1e-90)
    check_log_floated(1.to_ld(300).succ, 400, 1e9,1e-300)

    check_log_floated(2, 50)
    check_log_floated(0.99, 50)
    check_log_floated(1-1e-10, 50, 1e7)
    check_log_floated(1.to_ld(90).pred, 100, 1e9, 1e-90)
    check_log_floated(1.to_ld(300).pred, 400, 1e9, 1e-300)

    check_log_floated(10**2000, 100)
    check_log_floated(100, 100)
    check_log_floated(1, 100)
    check_log_floated(0.01, 100)
    check_log_floated(1e-10, 100)
    check_log_floated(1e-90, 100)
    check_log_floated(1e-300, 100)
    check_log_floated(LongDecimal(1, 2000), 100)

    # random tests that have failed
    check_log_floated(LongDecimal("666.000000000000000000000000000000000091600000000531000000000000000000000000000000000000000000831"), 1)
    check_log_floated(LongDecimal("333.000000000000000000000000919000000000000000000000000000000000001240000000000198"), 91)
    check_log_floated(LongDecimal("695.000000000000000000000000000000000000016169000000000000000572"), 10)
    check_log_floated(LongDecimal("553.00000000526000000000000000000000000000000000000000000000000298000000000000000079"), 1)
    check_log_floated(LongDecimal("0.999999991970000064480899482218377157786431422974955673511105941705818652715281320853860023218224705269648462237420298445354478282732556754661276455617"), 38)
    check_log_floated(LongDecimal("473.00000000000000000000000000000000003200056000000000000000000000000000000000000000000664"), 1)
    check_log_floated(LongDecimal("0.0000000000000000000000000000000000081600000000000000000000000000000000007510000886"), 101)
    check_log_floated(LongDecimal("0.99999999999999999999999571850000000000000000001833124224999999999999992151478630572500000000033603444243589176249999856126853469423130083125615992876877728537781582"), 37)
    check_log_floated(LongDecimal("0.99999999999999999999999999999999999999999999999999999999999999999999999999091999999999999999999409997650000000000000000000000000000000000000000000008244640000000000000010714442676000000000003481027730055225"), 102)
    check_log_floated(LongDecimal("0.99999999999999999999999999999999999999999999999999999999999999999999993359999909094250000000000000000000000000000000000000000000000000000000440896012072283682638553830625"), 84)
    check_log_floated(LongDecimal("1.0000000000000000000000000000000000000000009604500000000000000000000000730"), 46)

  end

  #
  # test the calculation of the base-x-logarithm of sqrt(x)
  #
  def test_log_of_sqrt
    print "\ntest_log_of_sqrt [#{Time.now}]: "
    # n = 125
    n = 30
    m = 5
    xe  = LongMath.sqrt(LongMath.exp(1, 2*n), n)

    (2*m).times do |i|
      check_log_floated(xe, n+m-i)
    end

    ye  = check_log_floated(xe, n)
    assert((ye*2).one?, "xe=#{xe} ye=#{ye}")

  end


  #
  # test LongMath.power for bases that can be expressed as integer
  #
  def test_lm_power_xint
    print "\ntest_lm_power_xint [#{Time.now}]: "

    xx = LongMath.log(3, 40)
    pi = LongMath.pi(40)
    sq = LongMath.sqrt(5, 40)

    check_power_xint(2, 700.01, 10)
    check_power_xint(2, 100.001, 10)
    check_power_xint(2, 1.000000001, 10)
    check_power_xint(2, 0.01, 10)
    check_power_xint(2, 1e-10, 10)
    check_power_xint(2, 1e-90, 10)
    check_power_xint(2, 0, 10)
    check_power_xint(2, -1.000000001, 10)
    check_power_xint(2, -100.001, 10)
    check_power_xint(2, -700.01, 10)
    check_power_xint(2, xx, 10)
    check_power_xint(2, pi, 10)
    check_power_xint(2, sq, 10)

    check_power_xint(10, 308.01, 10)
    check_power_xint(10, 100.001, 10)
    check_power_xint(10, 1.000000001, 10)
    check_power_xint(10, 0.01, 10)
    check_power_xint(10, 1e-10, 10)
    check_power_xint(10, 1e-90, 10)
    check_power_xint(10, 0, 10)
    check_power_xint(10, -1.000000001, 10)
    check_power_xint(10, -100.001, 10)
    check_power_xint(10, -308.01, 10)
    check_power_xint(10, xx, 10)
    check_power_xint(10, pi, 10)
    check_power_xint(10, sq, 10)

    check_power_xint(2, 700.01, 100)
    check_power_xint(2, 100.001, 100)
    check_power_xint(2, 1.000000001, 100)
    check_power_xint(2, 0.01, 100)
    check_power_xint(2, 1e-10, 100)
    check_power_xint(2, 1e-90, 100)
    check_power_xint(2, 0, 100)
    check_power_xint(2, -1.000000001, 100)
    check_power_xint(2, -100.001, 100)
    check_power_xint(2, -700.01, 100)
    check_power_xint(2, xx, 100)
    check_power_xint(2, pi, 100)
    check_power_xint(2, sq, 100)

    check_power_xint(10, 308.01, 100)
    check_power_xint(10, 100.001, 100)
    check_power_xint(10, 1.000000001, 100)
    check_power_xint(10, 0.01, 100)
    check_power_xint(10, 1e-10, 100)
    check_power_xint(10, 1e-90, 100)
    check_power_xint(10, 0, 100)
    check_power_xint(10, -1.000000001, 100)
    check_power_xint(10, -100.001, 100)
    check_power_xint(10, -308.01, 100)
    check_power_xint(10, xx, 100)
    check_power_xint(10, pi, 100)
    check_power_xint(10, sq, 100)

    check_power_xint(2, 700.01, 40)
    check_power_xint(2, 100.001, 40)
    check_power_xint(2, 1.000000001, 40)
    check_power_xint(2, 0.01, 40)
    check_power_xint(2, 1e-10, 40)
    check_power_xint(2, 1e-90, 40)
    check_power_xint(2, 0, 40)
    check_power_xint(2, -1.000000001, 40)
    check_power_xint(2, -100.001, 40)
    check_power_xint(2, -700.01, 40)
    check_power_xint(2, xx, 40)
    check_power_xint(2, pi, 40)
    check_power_xint(2, sq, 40)

    check_power_xint(10, 308.01, 40)
    check_power_xint(10, 100.001, 40)
    check_power_xint(10, 1.000000001, 40)
    check_power_xint(10, 0.01, 40)
    check_power_xint(10, 1e-10, 40)
    check_power_xint(10, 1e-90, 40)
    check_power_xint(10, 0, 40)
    check_power_xint(10, -1.000000001, 40)
    check_power_xint(10, -100.001, 40)
    check_power_xint(10, -308.01, 40)
    check_power_xint(10, xx, 40)
    check_power_xint(10, pi, 40)
    check_power_xint(10, sq, 40)

  end

  #
  # test LongMath.power for bases that can be expressed as integer
  #
  def test_lm_power_yint
    print "\ntest_lm_power_yint [#{Time.now}] (2 min): "

    xx = LongMath.log(3, 40)
    pi = LongMath.pi(40)
    sq = LongMath.sqrt(5, 40)

    check_power_yint(xx, 400, 10)
    check_power_yint(xx, 100, 10)
    check_power_yint(xx, 1, 10)
    check_power_yint(xx, 0, 10)
    check_power_yint(xx, -1, 10)
    check_power_yint(xx, -100, 10)
    check_power_yint(xx, -400, 10)

    check_power_yint(pi, 400, 10)
    check_power_yint(pi, 100, 10)
    check_power_yint(pi, 1, 10)
    check_power_yint(pi, 0, 10)
    check_power_yint(pi, -1, 10)
    check_power_yint(pi, -100, 10)
    check_power_yint(pi, -400, 10)

    check_power_yint(sq, 400, 10)
    check_power_yint(sq, 100, 10)
    check_power_yint(sq, 1, 10)
    check_power_yint(sq, 0, 10)
    check_power_yint(sq, -1, 10)
    check_power_yint(sq, -100, 10)
    check_power_yint(sq, -400, 10)

    check_power_yint(xx, 400, 100)
    check_power_yint(xx, 100, 100)
    check_power_yint(xx, 1, 100)
    check_power_yint(xx, 0, 100)
    check_power_yint(xx, -1, 100)
    check_power_yint(xx, -100, 100)
    check_power_yint(xx, -400, 100)

    check_power_yint(pi, 400, 100)
    check_power_yint(pi, 100, 100)
    check_power_yint(pi, 1, 100)
    check_power_yint(pi, 0, 100)
    check_power_yint(pi, -1, 100)
    check_power_yint(pi, -100, 100)
    check_power_yint(pi, -400, 100)

    check_power_yint(sq, 400, 100)
    check_power_yint(sq, 100, 100)
    check_power_yint(sq, 1, 100)
    check_power_yint(sq, 0, 100)
    check_power_yint(sq, -1, 100)
    check_power_yint(sq, -100, 100)
    check_power_yint(sq, -400, 100)

    check_power_yint(xx, 400, 40)
    check_power_yint(xx, 100, 40)
    check_power_yint(xx, 1, 40)
    check_power_yint(xx, 0, 40)
    check_power_yint(xx, -1, 40)
    check_power_yint(xx, -100, 40)
    check_power_yint(xx, -400, 40)

    check_power_yint(pi, 400, 40)
    check_power_yint(pi, 100, 40)
    check_power_yint(pi, 1, 40)
    check_power_yint(pi, 0, 40)
    check_power_yint(pi, -1, 40)
    check_power_yint(pi, -100, 40)
    check_power_yint(pi, -400, 40)

    check_power_yint(sq, 400, 40)
    check_power_yint(sq, 100, 40)
    check_power_yint(sq, 1, 40)
    check_power_yint(sq, 0, 40)
    check_power_yint(sq, -1, 40)
    check_power_yint(sq, -100, 40)
    check_power_yint(sq, -400, 40)

  end

  #
  # test LongMath.power for bases that can be expressed as integer
  #
  def test_lm_power_yhalfint
    print "\ntest_lm_power_yhalfint [#{Time.now}] (10 min): "

    xx = LongMath.log(3, 40)
    pi = LongMath.pi(40)
    sq = LongMath.sqrt(5, 40)

    check_power_yhalfint(xx, 801, 10)
    check_power_yhalfint(xx, 799, 10)
    check_power_yhalfint(xx, 201, 10)
    check_power_yhalfint(xx, 3, 10)
    check_power_yhalfint(xx, 1, 10)
    check_power_yhalfint(xx, -1, 10)
    check_power_yhalfint(xx, -201, 10)
    check_power_yhalfint(xx, -799, 10)
    check_power_yhalfint(xx, -801, 10)

    check_power_yhalfint(pi, 801, 10)
    check_power_yhalfint(pi, 799, 10)
    check_power_yhalfint(pi, 201, 10)
    check_power_yhalfint(pi, 3, 10)
    check_power_yhalfint(pi, 1, 10)
    check_power_yhalfint(pi, -1, 10)
    check_power_yhalfint(pi, -201, 10)
    check_power_yhalfint(pi, -799, 10)
    check_power_yhalfint(pi, -801, 10)

    check_power_yhalfint(sq, 801, 10)
    check_power_yhalfint(sq, 799, 10)
    check_power_yhalfint(sq, 201, 10)
    check_power_yhalfint(sq, 3, 10)
    check_power_yhalfint(sq, 1, 10)
    check_power_yhalfint(sq, -1, 10)
    check_power_yhalfint(sq, -201, 10)
    check_power_yhalfint(sq, -799, 10)
    check_power_yhalfint(sq, -801, 10)

    check_power_yhalfint(xx, 801, 40)
    check_power_yhalfint(xx, 799, 40)
    check_power_yhalfint(xx, 201, 40)
    check_power_yhalfint(xx, 3, 40)
    check_power_yhalfint(xx, 1, 40)
    check_power_yhalfint(xx, -1, 40)
    check_power_yhalfint(xx, -201, 40)
    check_power_yhalfint(xx, -799, 40)
    check_power_yhalfint(xx, -801, 40)

    check_power_yhalfint(pi, 801, 40)
    check_power_yhalfint(pi, 799, 40)
    check_power_yhalfint(pi, 201, 40)
    check_power_yhalfint(pi, 3, 40)
    check_power_yhalfint(pi, 1, 40)
    check_power_yhalfint(pi, -1, 40)
    check_power_yhalfint(pi, -201, 40)
    check_power_yhalfint(pi, -799, 40)
    check_power_yhalfint(pi, -801, 40)

    check_power_yhalfint(sq, 801, 40)
    check_power_yhalfint(sq, 799, 40)
    check_power_yhalfint(sq, 201, 40)
    check_power_yhalfint(sq, 3, 40)
    check_power_yhalfint(sq, 1, 40)
    check_power_yhalfint(sq, -1, 40)
    check_power_yhalfint(sq, -201, 40)
    check_power_yhalfint(sq, -799, 40)
    check_power_yhalfint(sq, -801, 40)

  end

  #
  # test the calculation of the base-10-logarithm function
  #
  def test_log10
    print "\ntest_log10 [#{Time.now}]: "
    check_log10_floated(10**2000, 30)
    check_log10_floated(100, 30)
    check_log10_floated(1, 30)
    check_log10_floated(0.01, 30)
    check_log10_floated(1e-10, 30)
    check_log10_floated(1e-90, 30)
    check_log10_floated(1e-300, 30)
    check_log10_floated(LongDecimal(1, 2000), 30)

    check_log10_exact(10**2000, 2000, 30)
    check_log10_exact(10**0, 0, 30)
    check_log10_exact(10**1, 1, 30)
    check_log10_exact(10**10, 10, 30)

    # random tests that have failed
    check_log10_floated(LongDecimal("587.00000000000000000095700000000000000000000000000000000000000000000000000000000000000000000001206"), 21)
    check_log10_floated(LongDecimal("543.0000002480000900000000000000000000000000000000000000000000000000000000000000000000847"), 2)
    check_log10_floated(LongDecimal("180.0000000000000000003570000000000000000000000000000000000000000000000577000000000000000000000000000637"), 2)
    check_log10_floated(LongDecimal("0.0000000000000000000000000000000000000000180000000063000000000000000000000000000000000025"), 74)
    check_log10_floated(LongDecimal("0.0000000000000000000000000006200000000000000000000000000000000000000000000000007940000015"), 74)
    check_log10_floated(LongDecimal("0.00000000000000000000000000000000000000000032900000000000000000000233000000000000000000000000000000254"), 10)
    check_log10_floated(LongDecimal("0.00000000000000000000000233000000094800000000000000000000000000000000000000000000000000000000000000682"), 100)
    check_log10_floated(LongDecimal("0.000000000000000000000000000000000000097000000041500000000000000000784"), 97)
    check_log10_floated(LongDecimal("185.000025300000000000000006320000000000000000000000000000737"), 27)
    check_log10_floated(LongDecimal("0.00000000000000000000000000000302000000000000000000000000000000000000000000000000000000060673"), 100)
    check_log10_floated(LongDecimal("442.000000000000045300000000000000000000000000000000000000000000000000000000000000000000000721000000000752"), 97)
    check_log10_floated(LongDecimal("0.001030927835051546391752577284408545010096715910298651428936221023301883588097777204212461151695109779555577162172"), 62)

  end

  #
  # test the calculation of the base-10-logarithm function
  #
  def test_log2
    print "\ntest_log2 [#{Time.now}]: "
    check_log2_floated(10**2000, 30)
    check_log2_floated(2**2000, 30)
    check_log2_floated(100, 30)
    check_log2_floated(1, 30)
    check_log2_floated(0.01, 30)
    check_log2_floated(1e-10, 30)
    check_log2_floated(1e-90, 30)
    check_log2_floated(1e-300, 30)
    check_log2_floated(LongDecimal(1, 2000), 30)

    check_log2_exact(2**2000, 2000, 30)
    check_log2_exact(2**0, 0, 30)
    check_log2_exact(2**1, 1, 30)
    check_log2_exact(2**10, 10, 30)

    # random tests that have failed
    check_log2_floated(LongDecimal("341.00000739000000000000000000000000000000000000000000000000000000000000171"), 3)
    check_log2_floated(LongDecimal("504.00000000000000000000000000000000000000000000000000000000000000000000000000000000000327400000000000828"), 1)
    check_log2_floated(LongDecimal("0.0033222591362126245847176079734219269102990032888157967351353737817463383406363175903135730345286354858609181999523961456225622835123748782987926188031081"), 48)
    check_log2_floated(LongDecimal("0.000802000000000000000000197000000000000000000000302"), 84)
    check_log2_floated(LongDecimal("0.00000000000000000000000000000000000000000000000000000000000000000000000452000000000069480"), 3)
    check_log2_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000930000000000000000000000000983000000000000300"), 61)
    check_log2_floated(LongDecimal("0.000000000000000000000000000000000000000000000000000000000086000133000000000000000000000000947"), 106)
    check_log2_floated(LongDecimal("0.00000000000000000000000000000276000000000000000000000000000000000008560000000000000000000000000000161"), 81)

  end

  #
  # test the calculation of the base-x-logarithm of sqrt(x)
  #
  def test_log_2_10_of_sqrt
    print "\ntest_log_2_10_of_sqrt [#{Time.now}]: "
    # n = 125
    n = 30
    m = 5
    x2  = LongMath.sqrt(2, n)
    x10 = LongMath.sqrt(10, n)

    (2*m).times do |i|
      check_log2_floated(x2, n+m-i)
      check_log10_floated(x10, n+m-i)
    end

    y2  = check_log2_floated(x2, n)
    assert((y2*2).one?, "xe=#{x2} ye=#{y2}")
    y10 = check_log10_floated(x10, n)
    assert((y10*2).one?, "xe=#{x10} ye=#{y10}")

  end

  #
  # test LongMath.power with non-LongDecimal arguments
  #
  def test_non_ld_power
    print "\ntest_non_ld_power [#{Time.now}]: "
    xi = 77
    yi = 88
    zi = LongMath.power(xi, yi, 35)
    wi = (LongMath.log(zi, 40) / LongMath.log(xi, 40)).round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert(wi.is_int?, "wi=#{wi} not int (zi=#{zi})")
    assert_equal(yi, wi.to_i, "zi=#{zi} wi=#{wi}")
    zj = LongMath.power_internal(xi, yi, 35)
    assert_equal(zi, zj, "internal power should yield the same result zi=#{zi} zj=#{zj}")

    xf = 77.0
    yf = 88.0
    zf = LongMath.power(xf, yf, 35)
    wf = (LongMath.log(zf, 40) / LongMath.log(xf, 40)).round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert(wf.is_int?, "wf=#{wf} not int (zf=#{zf} wi=#{wi} zi=#{zi}")
    assert_equal(yf, wf.to_i, "yf=#{yf} wf=#{yf}")

    xr = Rational(224, 225)
    yr = Rational(168, 169)
    zr = LongMath.power(xr, yr, 35)
    wr = (LongMath.log(zr, 40) / LongMath.log(xr, 40)).round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert((yr-wr).abs <= wr.unit, "wr-yr")
  end

  #
  # test the calculation of the power-function of LongMath
  #
  def test_lm_power
    print "\ntest_lm_power [#{Time.now}]: "
    check_power_floated(1.001, 1.001, 10)
    check_power_floated(1.001, 2.001, 10)
    check_power_floated(2.001, 1.001, 10)
    check_power_floated(2.001, 2.001, 10)
    check_power_floated(100.001, 10.001, 10)
    check_power_floated(10.001, 100.001, 10)
    check_power_floated(10.001, 100.001, 100)
    check_power_floated(1e-20, 1.01, 19)
    check_power_floated(1.01, 1e-20, 19)
    check_power_floated(1e-20, 1.01, 20)
    check_power_floated(1.01, 1e-20, 20)
    check_power_floated(1e-20, 1.01, 21)
    check_power_floated(1.01, 1e-20, 21)

    check_power_floated(1.001, -1.001, 10)
    check_power_floated(1.001, -2.001, 10)
    check_power_floated(2.001, -1.001, 10)
    check_power_floated(2.001, -2.001, 10)
    check_power_floated(100.001, -10.001, 10)
    check_power_floated(10.001, -100.001, 10)
    check_power_floated(1e-20, -1.01, 19)
    check_power_floated(1.01, -1e-20, 19)
    check_power_floated(1e-20, -1.01, 20)
    check_power_floated(1.01, -1e-20, 20)
    check_power_floated(1e-20, -1.01, 21)
    check_power_floated(1.01, -1e-20, 21)

  end


  #
  # test calculation of pi
  #
  def test_pi
    print "\ntest_pi [#{Time.now}]: "
    s  = "3.14159265358979323846264338327950288419716939937510"
    s +=   "58209749445923078164062862089986280348253421170679"
    s +=   "82148086513282306647093844609550582231725359408128"
    s +=   "48111745028410270193852110555964462294895493038196"
    s +=   "44288109756659334461284756482337867831652712019091"
    s +=   "45648566923460348610454326648213393607260249141273"
    s +=   "72458700660631558817488152092096282925409171536436"
    s +=   "78925903600113305305488204665213841469519415116094"
    s +=   "33057270365759591953092186117381932611793105118548"
    s +=   "07446237996274956735188575272489122793818301194912"
    s +=   "98336733624406566430860213949463952247371907021798"
    s +=   "60943702770539217176293176752384674818467669405132"
    s +=   "00056812714526356082778577134275778960917363717872"
    s +=   "14684409012249534301465495853710507922796892589235"
    s +=   "42019956112129021960864034418159813629774771309960"
    s +=   "51870721134999999837297804995105973173281609631859"
    s +=   "50244594553469083026425223082533446850352619311881"
    s +=   "71010003137838752886587533208381420617177669147303"
    s +=   "59825349042875546873115956286388235378759375195778"
    s +=   "18577805321712268066130019278766111959092164201989"
    s +=   "38095257201065485863278865936153381827968230301952"
    s +=   "03530185296899577362259941389124972177528347913151"
    s +=   "55748572424541506959508295331168617278558890750983"
    s +=   "81754637464939319255060400927701671139009848824012"
    s +=   "85836160356370766010471018194295559619894676783744"
    s +=   "94482553797747268471040475346462080466842590694912"
    s +=   "93313677028989152104752162056966024058038150193511"
    s +=   "25338243003558764024749647326391419927260426992279"
    s +=   "67823547816360093417216412199245863150302861829745"
    s +=   "55706749838505494588586926995690927210797509302955"
    s +=   "32116534498720275596023648066549911988183479775356"
    s +=   "63698074265425278625518184175746728909777727938000"
    s +=   "81647060016145249192173217214772350141441973568548"
    s +=   "16136115735255213347574184946843852332390739414333"
    s +=   "45477624168625189835694855620992192221842725502542"
    s +=   "56887671790494601653466804988627232791786085784383"
    s +=   "82796797668145410095388378636095068006422512520511"
    s +=   "73929848960841284886269456042419652850222106611863"
    s +=   "06744278622039194945047123713786960956364371917287"
    s +=   "46776465757396241389086583264599581339047802759010"

    l = LongDecimal(s)
    pi = LongMath.pi 200
    assert_equal(l.round_to_scale(200, ROUND_HALF_EVEN), pi, "200 digits")
    pi = LongMath.pi 201
    assert_equal(l.round_to_scale(201, ROUND_HALF_EVEN), pi, "201 digits")
    pi = LongMath.pi 199
    assert_equal(l.round_to_scale(199, ROUND_HALF_EVEN), pi, "199 digits")
    pi = LongMath.pi 201
    assert_equal(l.round_to_scale(201, ROUND_HALF_EVEN), pi, "201 digits")
    pi = LongMath.pi 1000
    assert_equal(l.round_to_scale(1000, ROUND_HALF_EVEN), pi, "1000 digits")
  end

  #
  # test method sqrtb for calculating sqrt of short integers
  #
  def test_int_sqrtb
    print "\ntest_int_sqrtb [#{Time.now}] (120 sec): "
    $stdout.flush
    assert_equal(Complex(0,1), LongMath.sqrtb(-1), "sqrt(-1)=i")
    1024.times do |x|
      check_sqrtb(x, " loop x=#{x}")
    end
    512.times do |i|
      x1 = i*i
      y = check_sqrtb(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtb(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtb(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtb(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtb(x1-1, " 2**i-1 i=#{i}")
        check_sqrtb(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtb(x1, " 3*2**i i=#{i}")
      check_sqrtb(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtb(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method sqrtb for calculating sqrt of long integers
  #
  def test_int_sqrtw
    print "\ntest_int_sqrtw [#{Time.now}] (90 sec): "
    $stdout.flush
    assert_equal(Complex(0,1), LongMath.sqrtw(-1), "sqrt(-1)=i")
    1024.times do |x|
      check_sqrtw(x, " loop x=#{x}")
    end
    1024.times do |i|
      x1 = i*i
      y = check_sqrtw(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtw(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtw(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtw(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtw(x1-1, " 2**i-1 i=#{i}")
        check_sqrtw(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtw(x1, " 3*2**i i=#{i}")
      check_sqrtw(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtw(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method sqrtb_with_remainder for calculating sqrt _with_remainderof short integers
  #
  def test_int_sqrtb_with_remainder
    print "\ntest_int_sqrtb_with_remainder [#{Time.now}]: "
    10.times do |x|
      check_sqrtb_with_remainder(x, " loop x=#{x}")
    end
    100.times do |i|
      x = 10*i + 10
      check_sqrtb_with_remainder(x, " loop x=#{x}")
    end
    50.times do |j|
      i = 10 * j
      x1 = i * i
      y = check_sqrtb_with_remainder(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtb_with_remainder(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtb_with_remainder(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtb_with_remainder(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtb_with_remainder(x1-1, " 2**i-1 i=#{i}")
        check_sqrtb_with_remainder(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtb_with_remainder(x1, " 3*2**i i=#{i}")
      check_sqrtb_with_remainder(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtb_with_remainder(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method sqrtb_with_remainder for calculating sqrt _with_remainderof long integers
  #
  def test_int_sqrtw_with_remainder
    print "\ntest_int_sqrtw_with_remainder [#{Time.now}]: "
    10.times do |x|
      check_sqrtw_with_remainder(x, " loop x=#{x}")
    end
    100.times do |j|
      x = 10 * j + 10
      check_sqrtw_with_remainder(x, " loop x=#{x}")
    end
    100.times do |j|
      i = 10*j
      x1 = i*i
      y = check_sqrtw_with_remainder(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtw_with_remainder(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtw_with_remainder(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtw_with_remainder(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtw_with_remainder(x1-1, " 2**i-1 i=#{i}")
        check_sqrtw_with_remainder(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtw_with_remainder(x1, " 3*2**i i=#{i}")
      check_sqrtw_with_remainder(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtw_with_remainder(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method cbrtb for calculating cbrt of short integers
  #
  def test_int_cbrtb
    print "\ntest_int_cbrtb [#{Time.now}] (120 sec): "
    $stdout.flush
    assert_equal(-1, LongMath.cbrtb(-1), "cbrt(-1)=i")
    4096.times do |x|
      check_cbrtb(x, " loop x=#{x}")
    end
    512.times do |i|
      x1 = i*i*i
      y = check_cbrtb(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_cbrtb(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_cbrtb(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_cbrtb(x1, " 2**i i=#{i}")
      if (i % 3 == 0)
        assert_equal(1 << (i / 3), y, "2^(i/3) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_cbrtb(x1-1, " 2**i-1 i=#{i}")
        check_cbrtb(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_cbrtb(x1, " 3*2**i i=#{i}")
      check_cbrtb(x1-1, " 3*2**i-1 i=#{i}")
      check_cbrtb(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method cbrtb_with_remainder for calculating cbrt _with_remainderof short integers
  #
  def test_int_cbrtb_with_remainder
    print "\ntest_int_cbrtb_with_remainder [#{Time.now}]: "
    10.times do |x|
      check_cbrtb_with_remainder(x, " loop x=#{x}")
    end
    100.times do |i|
      x = 10 * i + 10
      check_cbrtb_with_remainder(x, " loop x=#{x}")
    end
    50.times do |j|
      i = 10 * j
      x1 = i * i * i
      y = check_cbrtb_with_remainder(x1, " i**3 i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_cbrtb_with_remainder(x2, " i**3+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_cbrtb_with_remainder(x0, " i**3-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_cbrtb_with_remainder(x1, " 2**i i=#{i}")
      if (i % 3 == 0)
        assert_equal(1 << (i/3), y, "2^(i/3) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_cbrtb_with_remainder(x1-1, " 2**i-1 i=#{i}")
        check_cbrtb_with_remainder(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_cbrtb_with_remainder(x1, " 3*2**i i=#{i}")
      check_cbrtb_with_remainder(x1-1, " 3*2**i-1 i=#{i}")
      check_cbrtb_with_remainder(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test gcd_with_high_power
  #
  def test_gcd_with_high_power
    print "\ntest_gcd_with_high_power [#{Time.now}]: "
    n = 224
    assert_equal(32, LongMath.gcd_with_high_power(n, 2), "2-part of 224 is 32")
    assert_equal(7, LongMath.gcd_with_high_power(n, 7), "7-part of 224 is 7")
    assert_equal(1, LongMath.gcd_with_high_power(n, 3), "3-part of 224 is 1")
  end

  #
  # test multiplicity_of_factor for integers
  #
  def test_multiplicity_of_factor
    print "\ntest_multiplicity_of_factor [#{Time.now}]: "
    n = 224
    assert_equal(5, LongMath.multiplicity_of_factor(n, 2), "ny_2(224) is 5")
    assert_equal(1, LongMath.multiplicity_of_factor(n, 7), "ny_7(224) is 1")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 3), "ny_3(224) is 0")
  end

  #
  # test division of Complex, which is overriden in long-decimal.rb
  # due to bug 1454/1455 (redmine.ruby-lang.org) mixing of BigDecimal with Rational won't work.
  #
  def test_complex_div
    print "\ntest_complex_div [#{Time.now}]: "
    twenties = [ 20, 20.0, BigDecimal("20.0"), Rational(20, 1), LongDecimal("20.0"), LongDecimalQuot(20, 1) ]
    fifteens = [ 15, 15.0, BigDecimal("15.0"), Rational(15, 1), LongDecimal("15.0"), LongDecimalQuot(15, 1) ]
    threes   = [ 3, 3.0, BigDecimal("3.0"), Rational(3, 1), LongDecimal("3.0"), LongDecimalQuot(3, 1) ]
    fours    = [ 4, 4.0, BigDecimal("4.0"), Rational(4, 1), LongDecimal("4.0"), LongDecimalQuot(4, 1) ]
    zr = Complex(Rational(24, 5),-Rational(7, 5))
    zb = Complex(BigDecimal("4.8"),-BigDecimal("1.4"))
    zf = Complex(4.8,-1.4)
    zl = Complex(LongDecimal("4.8"),-LongDecimal("1.4"))
    tw_c = 0
    twenties.each do |xr|
      tw_c += 1
      fi_c = 0
      fifteens.each do |xi|
        fi_c += 1
        x = Complex(xr, xi)
        th_c = 0
        threes.each do |yr|
          th_c += 1
          fo_c = 0
          fours.each do |yi|
            fo_c += 1
            has_rational   = (xr.kind_of? Rational) || (xi.kind_of? Rational) || (yr.kind_of? Rational) || (yi.kind_of? Rational)
            has_bigdecimal = (xr.kind_of? BigDecimal) || (xi.kind_of? BigDecimal) || (yr.kind_of? BigDecimal) || (yi.kind_of? BigDecimal)
            if (has_rational && has_bigdecimal)
              # these won't go together well
              next
            end
            y = Complex(yr, yi)
            z = x/y
            msg = "x=#{x} y=#{y} z=#{z} xr=#{xr.inspect} (#{tw_c}) xi=#{xi.inspect} (#{fi_c}) yr=#{yr.inspect} (#{th_c}) yi=#{yi.inspect} (#{fo_c})"
            # puts msg
            if (xr.kind_of? Integer) && (xi.kind_of? Integer) && (yr.kind_of? Integer) && (yi.kind_of? Integer) # && ! LongDecimal::RUNNING_AT_LEAST_19
              # ruby 1.9 creates rational result even from integers, ruby 1.8 uses integers as results.
              zc = (x.cdiv y)
              assert_equal_complex(zc, z, "all int zc=#{zc} " + msg)
              next
            end
            unless has_bigdecimal
              assert_equal_complex(zr, z, msg, 1e-15)
            end
            unless has_rational
              assert_equal_complex(zb, z, msg, 1e-15)
            end
            assert_equal_complex(zf, z, msg, 1e-15)
            assert_equal_complex(zl, z, msg, 1e-15)
            unless (xr.kind_of? LongDecimalBase) || (xi.kind_of? LongDecimalBase) || (yr.kind_of? LongDecimalBase) || (yi.kind_of? LongDecimalBase)
              zc = x.cdiv(y)
              assert_equal_complex(z, zc, msg, 1.0e-15)
            end
          end
        end
      end
    end
  end

  #
  # test division of Complex, which is overriden in long-decimal.rb
  # due to bug 1454/1455 (redmine.ruby-lang.org) mixing of BigDecimal with Complex won't work.
  #
  def test_complex_by_real_div
    print "\ntest_complex_by_real_div [#{Time.now}]: "
    twenties = [ 20, 20.0, BigDecimal("20.0"), Rational(20, 1), LongDecimal("20.0"), LongDecimalQuot(20, 1) ]
    fifteens = [ 15, 15.0, BigDecimal("15.0"), Rational(15, 1), LongDecimal("15.0"), LongDecimalQuot(15, 1) ]
    fives    = [ 5, 5.0, Rational(5, 1), LongDecimal("5.0"), LongDecimalQuot(5, 1) ]
    zr = Complex(Rational(4,1),Rational(3,1))
    zb = Complex(BigDecimal("4.0"),BigDecimal("3.0"))
    zf = Complex(4.0,3.0)
    zl = Complex(LongDecimal("4.0"),LongDecimal("3.0"))
    twenties.each do |xr|
      fifteens.each do |xi|
        x = Complex(xr, xi)
        fives.each do |y|
          has_rational   = (xr.kind_of? Rational) || (xi.kind_of? Rational) || (y.kind_of? Rational)
          has_bigdecimal = (xr.kind_of? BigDecimal) || (xi.kind_of? BigDecimal) || (y.kind_of? BigDecimal)
          if (has_rational && has_bigdecimal)
            # these won't go together well
            next
          end
          z = x / y
          msg = "x=#{x} y=#{y} z=#{z} xr=#{xr.inspect} xi=#{xi.inspect} y=#{y.inspect}"
          if (xr.kind_of? Integer) && (xi.kind_of? Integer) && (y.kind_of? Integer)
            assert_equal_complex((x.cdiv y), z, "all int")
            next
          end
          unless has_bigdecimal
            assert_equal_complex(zr, z, msg)
          end
          unless has_rational
            assert_equal_complex(zb, z, msg)
          end
          assert_equal_complex(zf, z, msg)
          assert_equal_complex(zl, z, msg)
          unless (xr.kind_of? LongDecimalBase) || (xi.kind_of? LongDecimalBase) || (y.kind_of? LongDecimalBase)
            zc = x.cdiv(y)
            assert_equal_complex(z, zc, msg)
          end
        end
      end
    end
  end

  #
  # test division of Complex, which is overriden in long-decimal.rb
  # due to bug 1454/1455 (redmine.ruby-lang.org) mixing of BigDecimal with Rational or Complex won't work.
  #
  def test_real_by_complex_div
    print "\ntest_real_by_complex_div [#{Time.now}]: "
    twenties = [ 20, 20.0, Rational(20, 1), LongDecimal("20.0"), LongDecimalQuot(20, 1) ]
    threes   = [ 3, 3.0, BigDecimal("3.0"), Rational(3, 1), LongDecimal("3.0"), LongDecimalQuot(3, 1) ]
    fours    = [ 4, 4.0, BigDecimal("4.0"), Rational(4, 1), LongDecimal("4.0"), LongDecimalQuot(4, 1) ]
    zr = Complex(Rational(24,10),Rational(-32,10))
    deep_freeze_complex(zr)
    zb = Complex(BigDecimal("2.4"),BigDecimal("-3.2"))
    deep_freeze_complex(zb)
    zf = Complex(2.4,-3.2)
    deep_freeze_complex(zf)
    zl = Complex(LongDecimal("2.4"),LongDecimal("-3.2"))
    deep_freeze_complex(zl)
    zi = nil
    if ($test_type == :v20)
      zi = Complex(2, -4)
      deep_freeze_complex(zi)
    else
      zi = zr
    end
    twenties.each do |x|
      threes.each do |yr|
        fours.each do |yi|
          has_rational   = (x.kind_of? Rational) || (yr.kind_of? Rational) || (yi.kind_of? Rational)
          has_bigdecimal = (x.kind_of? BigDecimal) || (yr.kind_of? BigDecimal) || (yi.kind_of? BigDecimal)
          if (has_rational && has_bigdecimal)
            # these won't go together well
            next
          end
          y = Complex(yr, yi)
          # puts "x=#{x} y=#{y}"
          z = x/y
          # puts "x=#{x} y=#{y} z=#{z}"
          msg = "x=#{x} y=#{y} z=#{z} -- zr=#{zr} zb=#{zb} zf=#{zf} zl=#{zl} zi=#{zi} -- yr=#{yr.inspect} yi=#{yi.inspect} x=#{x.inspect}"
          if (x.kind_of? Integer) && (yr.kind_of? Integer) && (yi.kind_of? Integer) && LongDecimal::RUNNING_AT_LEAST_19
            has_rational # quotients of ints within Complex are Rational in 1.9
          end
          if (x.kind_of? Integer) && (yr.kind_of? Integer) && (yi.kind_of? Integer) && ! LongDecimal::RUNNING_AT_LEAST_19
            assert_equal_complex(zi, z, msg)
            next
          end
          # unless has_bigdecimal
            assert_equal_complex(zr, z, msg)
          # end
          # unless has_rational
            assert_equal_complex(zb, z, msg)
          # end
          assert_equal_complex(zf, z, msg)
          assert_equal_complex(zl, z, msg)
        end
      end
    end
  end

  #
  # test division of Complex, which is overriden in long-decimal.rb
  # due to bug 1454/1455 (redmine.ruby-lang.org) mixing of BigDecimal with Rational or Complex won't work.
  #
  def test_real_by_complex_div_single_case
    print "\ntest_real_by_complex_div [#{Time.now}]: "
    zr = Complex(Rational(24,10),Rational(-32,10))
    zb = Complex(BigDecimal("2.4"),BigDecimal("-3.2"))
    zf = Complex(2.4,-3.2)
    zl = Complex(LongDecimal("2.4"),LongDecimal("-3.2"))
    zi = nil
    if ($test_type == :v20)
      zi = Complex(2, -4)
    else
      zi = zr
    end
    x = 20.0
    yr = 3
    yi = 4.0
    has_rational   = false
    has_bigdecimal = false
    y = Complex(yr, yi)
    z = x/y
    msg = "x=#{x} y=#{y} z=#{z} -- zr=#{zr} zb=#{zb} zf=#{zf} zl=#{zl} zi=#{zi} -- yr=#{yr.inspect} yi=#{yi.inspect} x=#{x.inspect}"
    assert_equal_complex(zr, z, msg)
    assert_equal_complex(zb, z, msg)
    assert_equal_complex(zf, z, msg)
    assert_equal_complex(zl, z, msg)
  end

  #
  # test multiplicity_of_factor for rationals
  #
  def test_rat_multiplicity_of_factor
    print "\ntest_rat_multiplicity_of_factor [#{Time.now}]: "
    n = Rational(224, 225)
    assert_equal(5, LongMath.multiplicity_of_factor(n, 2), "ny_2(n) is 5")
    assert_equal(1, LongMath.multiplicity_of_factor(n, 7), "ny_7(n) is 1")
    assert_equal(-2, LongMath.multiplicity_of_factor(n, 3), "ny_3(n) is -2")
    assert_equal(-2, LongMath.multiplicity_of_factor(n, 5), "ny_5(n) is -2")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 11), "ny_11(n) is 0")
  end

  #
  # test multiplicity_of_factor for rationals with numerator and
  # denominator exceeding Float
  #
  def test_rat_long_multiplicity_of_factor
    print "\ntest_rat_long_multiplicity_of_factor [#{Time.now}]: "
    n = Rational(224*(10**600+1), 225*(5**800))
    assert_equal(5, LongMath.multiplicity_of_factor(n, 2), "ny_2(n) is 5")
    assert_equal(1, LongMath.multiplicity_of_factor(n, 7), "ny_7(n) is 1")
    assert_equal(-2, LongMath.multiplicity_of_factor(n, 3), "ny_3(n) is -2")
    assert_equal(-802, LongMath.multiplicity_of_factor(n, 5), "ny_5(n) is -2")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 11), "ny_11(n) is 0")
  end

  #
  # test multiplicity_of_factor for LongDecimal
  #
  def test_ld_multiplicity_of_factor
    print "\ntest_ld_multiplicity_of_factor [#{Time.now}]: "
    # 0.729
    n = LongDecimal(729, 3)
    assert_equal(-3, LongMath.multiplicity_of_factor(n, 2), "ny_2(n) is -3")
    assert_equal(6, LongMath.multiplicity_of_factor(n, 3), "ny_3(n) is 6")
    assert_equal(-3, LongMath.multiplicity_of_factor(n, 5), "ny_5(n) is -3")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 7), "ny_7(n) is 0")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 11), "ny_11(n) is 0")
  end

  #
  # test creation of 0 with given number of digits after the decimal point
  #
  def test_zero_init
    print "\ntest_zero_init [#{Time.now}]: "
    l = LongDecimal.zero!(224)
    assert_equal(l.to_r, 0, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 1 with given number of digits after the decimal point
  #
  def test_one_init
    print "\ntest_one_init [#{Time.now}]: "
    l = LongDecimal.one!(224)
    assert_equal(l.to_r, 1, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 2 with given number of digits after the decimal point
  #
  def test_two_init
    print "\ntest_two_init [#{Time.now}]: "
    l = LongDecimal.two!(224)
    assert_equal(l.to_r, 2, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 10 with given number of digits after the decimal point
  #
  def test_ten_init
    print "\ntest_ten_init [#{Time.now}]: "
    l = LongDecimal.ten!(224)
    assert_equal(l.to_r, 10, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of -1 with given number of digits after the decimal point
  #
  def test_minus_one_init
    print "\ntest_minus_one_init [#{Time.now}]: "
    l = LongDecimal.minus_one!(224)
    assert_equal(l.to_r, -1, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 10**e with given number of digits after the decimal point
  #
  def test_power_of_ten_init
    print "\ntest_power_of_ten_init [#{Time.now}]: "
    20.times do |e|
      l = LongDecimal.power_of_ten!(e, 224)
      assert_equal(l.to_r, 10**e, "to_r e=#{e}")
      assert_equal(l.scale, 224, "scale")
    end
  end

  #
  # test construction of LongDecimal from Integer
  #
  def test_int_init
    print "\ntest_int_init [#{Time.now}]: "
    i = 224
    l = LongDecimal(i)
    assert_equal(i, l.to_i, "no loss of information for integers allowed")
    assert_equal(l, i.to_ld(0), "to_ld")
    i = -333
    l = LongDecimal(i)
    assert_equal(i, l.to_i, "no loss of information for integers allowed")
    assert_equal(l, i.to_ld(0), "to_ld")
    i = 1000000000000000000000000000000000000000000000000
    l = LongDecimal(i)
    assert_equal(i, l.to_i, "no loss of information for integers allowed")
    assert_equal(l, i.to_ld(0), "to_ld")
    i = 19
    l = LongDecimal(i, 1)
    assert_equal(1, l.to_i, "loss of information 1.9->1")
    assert_equal(LongDecimal(190, 1), i.to_ld(1))
  end

  #
  # test construction from Rational
  #
  def test_rat_init
    print "\ntest_rat_init [#{Time.now}]: "
    r = Rational(227, 100)
    l = LongDecimal(r)
    assert_equal(r, l.to_r, "no loss of information for rationals with denominator power of 10 allowed l=#{l.inspect}")
    assert_equal(l, r.to_ld, "to_ld")
    l = LongDecimal(r, 3)
    assert_equal(r, l.to_r * 1000, "scaling for rationals")
    assert_equal(l, (r/1000).to_ld(5), "to_ld")
    r = Rational(224, 225)
    l = LongDecimal(r)
    assert((r - l.to_r).to_f.abs < 0.01, "difference of #{r.inspect} and #{l.inspect} must be less 0.01 but is #{(r - l.to_r).to_f.abs}")
    assert_equal(l, r.to_ld, "to_ld")
  end

  #
  # test construction from Float
  #
  def test_float_init
    print "\ntest_float_init [#{Time.now}]: "
    s = "5.32"
    l = LongDecimal(s)
    assert_equal(s, l.to_s, "l=#{l.inspect}")
    assert_equal(l, s.to_f.to_ld, "to_ld")
    f = 2.24
    l = LongDecimal(f)
    assert_equal(f.to_s, l.to_s, "l=#{l.inspect} f=#{f.inspect}")
    assert_equal(l, f.to_ld, "to_ld")
    f = 2.71E-4
    l = LongDecimal(f)
    assert_equal("0.000271", l.to_s, "l=#{l.inspect} f=#{f.inspect}")
    assert_equal(l, f.to_ld, "to_ld")
    f = 224.225
    l = LongDecimal(f, 4)
    assert_equal("0.0224225", l.to_s, "l=#{l.inspect} f=#{f.inspect}")
    assert_equal(l, (f/10000).to_ld(7), "to_ld l=#{l} f=#{f}")
  end

  #
  # test construction from BigDecimal
  #
  def test_bd_init
    print "\ntest_bd_init [#{Time.now}]: "
    b = BigDecimal("5.32")
    l = LongDecimal(b)
    assert_equal(b, l.to_bd, "l=#{l.inspect}")
    assert_equal(l, b.to_ld, "to_ld")
    b = BigDecimal("2.24")
    l = LongDecimal(b)
    assert((b.to_f - l.to_f).abs < 1e-9, "l=#{l.inspect} b=#{b.inspect}")
    assert_equal(l, b.to_ld, "to_ld")
    b = BigDecimal("2.71E-4")
    l = LongDecimal(b)
    assert_equal("0.000271", l.to_s, "l=#{l.inspect} b=#{b.inspect}")
    assert_equal(l, b.to_ld, "to_ld")
    b = BigDecimal("224.225")
    l = LongDecimal(b, 4)
    assert_equal("0.0224225", l.to_s, "l=#{l.inspect} b=#{b.inspect}")
    assert_equal(l, (b/10000).to_ld(7), "to_ld")
  end

  #
  # test int_digits2 of LongDecimal
  #
  def test_int_digits2
    print "\ntest_int_digits2 [#{Time.now}]: "
    assert_equal(0, LongDecimal("0.0000").int_digits2, "0.0000")
    assert_equal(0, LongDecimal("0.9999").int_digits2, "0.9999")
    assert_equal(1, LongDecimal("1.0000").int_digits2, "1.0000")
    assert_equal(1, LongDecimal("1.9999").int_digits2, "1.9999")
    assert_equal(2, LongDecimal("2.0000").int_digits2, "2.0000")
    assert_equal(2, LongDecimal("3.9999").int_digits2, "3.9999")
    assert_equal(3, LongDecimal("4.0000").int_digits2, "4.0000")
    assert_equal(3, LongDecimal("7.9999").int_digits2, "7.9999")
    assert_equal(4, LongDecimal("8.0000").int_digits2, "8.0000")
    assert_equal(4, LongDecimal("15.9999").int_digits2, "15.9999")

    assert_equal(0, LongDecimal("-0.0000").int_digits2, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").int_digits2, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").int_digits2, "-1.0000")
    assert_equal(1, LongDecimal("-1.9999").int_digits2, "-1.9999")
    assert_equal(2, LongDecimal("-2.0000").int_digits2, "-2.0000")
    assert_equal(2, LongDecimal("-3.9999").int_digits2, "-3.9999")
    assert_equal(3, LongDecimal("-4.0000").int_digits2, "-4.0000")
    assert_equal(3, LongDecimal("-7.9999").int_digits2, "-7.9999")
  end

  #
  # test int_digits10 of LongDecimal
  #
  def test_int_digits10
    print "\ntest_int_digits10 [#{Time.now}]: "
    assert_equal(0, LongDecimal("0.0000").int_digits10, "0.0000")
    assert_equal(0, LongDecimal("0.0009").int_digits10, "0.0009")
    assert_equal(0, LongDecimal("0.0099").int_digits10, "0.0099")
    assert_equal(0, LongDecimal("0.0999").int_digits10, "0.0999")
    assert_equal(0, LongDecimal("0.9999").int_digits10, "0.9999")
    assert_equal(1, LongDecimal("1.0000").int_digits10, "1.0000")
    assert_equal(1, LongDecimal("9.9999").int_digits10, "9.9999")
    assert_equal(2, LongDecimal("10.0000").int_digits10, "10.0000")
    assert_equal(2, LongDecimal("99.9999").int_digits10, "99.9999")
    assert_equal(3, LongDecimal("100.0000").int_digits10, "100.0000")
    assert_equal(3, LongDecimal("999.9999").int_digits10, "999.9999")

    assert_equal(0, LongDecimal("-0.0000").int_digits10, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").int_digits10, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").int_digits10, "-1.0000")
    assert_equal(1, LongDecimal("-9.9999").int_digits10, "-9.9999")
    assert_equal(2, LongDecimal("-10.0000").int_digits10, "-10.0000")
    assert_equal(2, LongDecimal("-99.9999").int_digits10, "-99.9999")
    assert_equal(3, LongDecimal("-100.0000").int_digits10, "-100.0000")
    assert_equal(3, LongDecimal("-999.9999").int_digits10, "-999.9999")
    x = 1234.to_ld
    assert_equal(4, x.int_digits10, "1234")
    assert_equal(4, x.int_digits10, "1234")
    x = 1234.to_ld(10)
    assert_equal(4, x.int_digits10, "1234")
    assert_equal(4, x.int_digits10, "1234")
  end

  #
  # test sint_digits10 of LongDecimal
  #
  def test_sint_digits10
    print "\ntest_sint_digits10 [#{Time.now}]: "
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
  end

  #
  # test int_digits10 of LongMath
  #
  def test_lm_int_digits10
    print "\ntest_lm_int_digits10 [#{Time.now}]: "
    assert_equal(0, LongMath.int_digits10(0), "0")
    assert_equal(1, LongMath.int_digits10(1), "1")
    assert_equal(1, LongMath.int_digits10(9), "9")
    assert_equal(2, LongMath.int_digits10(10), "10")
    assert_equal(2, LongMath.int_digits10(11), "11")
    assert_equal(2, LongMath.int_digits10(98), "98")
    assert_equal(2, LongMath.int_digits10(99), "99")
    assert_equal(3, LongMath.int_digits10(100), "100")
    assert_equal(3, LongMath.int_digits10(999), "999")
    assert_equal(4, LongMath.int_digits10(1000), "1000")
    assert_equal(4, LongMath.int_digits10(9999), "9999")
  end

  #
  # test LongMath.multiplicity_of_10(n)
  #
  def test_lm_multiplicity_of_10
    print "\ntest_lm_multiplicity_of_10 [#{Time.now}]: "
    assert_equal(0, LongMath.multiplicity_of_10(-999), "-999")
    assert_equal(0, LongMath.multiplicity_of_10(-1), "-1")
    assert_equal(0, LongMath.multiplicity_of_10(-5), "-5")
    assert_equal(0, LongMath.multiplicity_of_10(1), "1")
    assert_equal(0, LongMath.multiplicity_of_10(2), "2")
    assert_equal(0, LongMath.multiplicity_of_10(8), "8")
    assert_equal(0, LongMath.multiplicity_of_10(1024), "1024")
    assert_equal(0, LongMath.multiplicity_of_10(5), "5")
    assert_equal(0, LongMath.multiplicity_of_10(625), "625")
    assert_equal(1, LongMath.multiplicity_of_10(-1230), "-1230")
    10.times do |i|
      n = i*i+i+1
      while (n % 10) == 0 do
        n /= 10
      end
      10.times do |j|
        m = j*j
        x = n * 10**m
        assert_equal(m, LongMath.multiplicity_of_10(x), "x=#{x} i=#{i} j=#{j} n=#{n} m=#{m}")
      end
    end
  end

  #
  # test round_trailing_zeros of LongDecimal
  #
  def test_round_trailing_zeros
    print "\ntest_round_trailing_zeros [#{Time.now}]: "
    x = LongDecimal.one!(100)
    y = x.round_trailing_zeros
    z = LongDecimal.one!(0)
    assert_equal(y, z, "1 w/o trailing")
    x = LongDecimal(22400, 5)
    y = x.round_trailing_zeros
    z = LongDecimal(224, 3)
    assert_equal(y, z, "2.24 w/o trailing")
    x = LongDecimal(123456, 3)
    y = x.round_trailing_zeros
    assert_equal(y, x, "1234.56 w/o trailing")
  end

  #
  # test rounding of LongDecimal with ROUND_UP
  #
  def test_round_to_scale_up
    print "\ntest_round_to_scale_up [#{Time.now}]: "
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_UP)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_DOWN
  #
  def test_round_to_scale_down
    print "\ntest_round_to_scale_down [#{Time.now}]: "
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_DOWN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_CEILING
  #
  def test_round_to_scale_ceiling
    print "\ntest_round_to_scale_ceiling [#{Time.now}]: "
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_CEILING)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_FLOOR
  #
  def test_round_to_scale_floor
    print "\ntest_round_to_scale_floor [#{Time.now}]: "
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_FLOOR)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_UP
  #
  def test_round_to_scale_half_up
    print "\ntest_round_to_scale_half_up [#{Time.now}]: "
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_HALF_UP)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_DOWN
  #
  def test_round_to_scale_half_down
    print "\ntest_round_to_scale_half_down [#{Time.now}]: "
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_HALF_DOWN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_CEILING
  #
  def test_round_to_scale_half_ceiling
    print "\ntest_round_to_scale_half_ceiling [#{Time.now}]: "
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_HALF_CEILING)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_FLOOR
  #
  def test_round_to_scale_half_floor
    print "\ntest_round_to_scale_half_floor [#{Time.now}]: "
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_HALF_FLOOR)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_EVEN
  #
  def test_round_to_scale_half_even
    print "\ntest_round_to_scale_half_even [#{Time.now}]: "
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.35")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("2.4", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.35")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("-2.4", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_HALF_EVEN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_ODD
  #
  def test_round_to_scale_half_odd
    print "\ntest_round_to_scale_half_odd [#{Time.now}]: "
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.35")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.35")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_HALF_ODD)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_GEOMETRIC_*
  #
  def test_round_to_scale_geometric_common
    print "\ntest_round_to_scale_geometric_common [#{Time.now}]: "
    ALL_ROUNDING_MODES.each do |rounding_mode|
      if (rounding_mode.major == MAJOR_GEOMETRIC)
        l = LongDecimal("0.00")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.00", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327641")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327641", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327642")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327642", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327641")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327641", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327642")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-1.414213562373095048801688724209698078569671875376948073176679737990732478462107038850387534327642", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        l = LongDecimal("2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.24")
        r = l.round_to_scale(4, rounding_mode)
        assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding with ROUND_HARMONIC_*
  #
  def test_round_to_scale_harmonic_common
    print "\ntest_round_to_scale_harmonic_common [#{Time.now}]: "
    ALL_ROUNDING_MODES.each do |rounding_mode|
      if (rounding_mode.major == MAJOR_HARMONIC)
        l = LongDecimal("0.00")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.00", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        # harmonic mean of 1 and 2 is 4/3
        l = LongDecimal("1.33333333333333333333333333333333333333333333")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect} rounding_mode=#{rounding_mode}")
        assert_equal("1.33333333333333333333333333333333333333333333", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("1.33333333333333333333333333333333333333333334")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("1.33333333333333333333333333333333333333333334", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-1.33333333333333333333333333333333333333333333")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-1.33333333333333333333333333333333333333333333", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-1.33333333333333333333333333333333333333333334")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-1.33333333333333333333333333333333333333333334", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        l = LongDecimal("2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.24")
        r = l.round_to_scale(4, rounding_mode)
        assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding with ROUND_HARMONIC_UP
  #
  def test_round_to_scale_harmonic_up
    print "\ntest_round_to_scale_harmonic_up [#{Time.now}]: "
    l = LongDecimal("2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.41")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.41", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("-3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.47999")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.47999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48001")
    r = l.round_to_scale(0, ROUND_HARMONIC_UP)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HARMONIC_DOWN
  #
  def test_round_to_scale_harmonic_down
    print "\ntest_round_to_scale_harmonic_down [#{Time.now}]: "
    l = LongDecimal("2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.41")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.41", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.47999")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.47999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48001")
    r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HARMONIC_CEILING
  #
  def test_round_to_scale_harmonic_ceiling
    print "\ntest_round_to_scale_harmonic_ceiling [#{Time.now}]: "
    l = LongDecimal("2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.41")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.41", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.47999")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.47999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48001")
    r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HARMONIC_FLOOR
  #
  def test_round_to_scale_harmonic_floor
    print "\ntest_round_to_scale_harmonic_floor [#{Time.now}]: "
    l = LongDecimal("2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.41")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.41", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("-3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.47999")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.47999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48001")
    r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HARMONIC_EVEN
  #
  def test_round_to_scale_harmonic_even
    print "\ntest_round_to_scale_harmonic_even [#{Time.now}]: "
    l = LongDecimal("2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.41")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.41", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.47999")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.47999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48001")
    r = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HARMONIC_ODD
  #
  def test_round_to_scale_harmonic_odd
    print "\ntest_round_to_scale_harmonic_odd [#{Time.now}]: "
    l = LongDecimal("2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.41")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.41", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.39")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("-2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.39", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.40")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("-3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.40", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.47999")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("12", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.47999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("12.48001")
    r = l.round_to_scale(0, ROUND_HARMONIC_ODD)
    assert_equal("13", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("12.48001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_QUADRATIC_*
  #
  def test_round_to_scale_quadratic_common
    print "\ntest_round_to_scale_quadratic_common [#{Time.now}]: "
    ALL_ROUNDING_MODES.each do |rounding_mode|
      if (rounding_mode.major == MAJOR_QUADRATIC)
        l = LongDecimal("0.00")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.00", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        # sqrt(2) is the quadratic mean of 0 and 2: 0.7071067811865475244008443621048490392848359376884740365883398689953662392310535194251937671638207864
        l = LongDecimal("0.7071067811")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect} rounding_mode=#{rounding_mode}")
        assert_equal("0.7071067811", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.7071067812")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.7071067812", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.7071067811")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.7071067811", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.7071067812")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.7071067812", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        l = LongDecimal("1.5811388300")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("1.5811388300", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("1.5811388301")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("1.5811388301", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        l = LongDecimal("2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.24")
        r = l.round_to_scale(4, rounding_mode)
        assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding with ROUND_CUBIC_*
  #
  def test_round_to_scale_cubic_common
    print "\ntest_round_to_scale_cubic_common [#{Time.now}]: "
    ALL_ROUNDING_MODES.each do |rounding_mode|
      if (rounding_mode.major == MAJOR_CUBIC)
        l = LongDecimal("0.00")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.00", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.01")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.01", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.000001")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.000001", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.099999")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.099999", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        l = LongDecimal("0.7937005259")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.7937005259", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("0.7937005260")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("0.7937005260", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.7937005259")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.7937005259", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-0.7937005260")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("-1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-0.7937005260", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        l = LongDecimal("1.6509636244")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("1.6509636244", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("1.6509636245")
        r = l.round_to_scale(0, rounding_mode)
        assert_equal("2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("1.6509636245", l.to_s, "l=#{l.inspect} r=#{r.inspect}")

        l = LongDecimal("2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.20")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.21")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.25")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("-2.29")
        r = l.round_to_scale(1, rounding_mode)
        assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
        assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
        l = LongDecimal("2.24")
        r = l.round_to_scale(4, rounding_mode)
        assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding with ROUND_UNNECESSARY
  #
  def test_round_to_scale_unnecessary
    print "\ntest_round_to_scale_unnecessary [#{Time.now}]: "
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, ROUND_UNNECESSARY)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.2400")
    r = l.round_to_scale(2, ROUND_UNNECESSARY)
    assert_equal("2.24", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    begin
      l = LongDecimal("2.24")
      r = l.round_to_scale(1, ROUND_UNNECESSARY)
      assert_fail("should not have succeeded l=#{l.inspect} r=#{r.inspect}")
    rescue ArgumentError
      # ignored
    end
  end

  #
  # test rounding of int to remainder set
  #
  def test_int_round_to_one_allowed_remainder
    print "\ntest_int_round_to_one_allowed_remainder [#{Time.now}] (20sec): "
    $stdout.flush
    2.upto 20 do |modulus|
      0.upto modulus-1 do |r|
        print "."
        n = 3*modulus
        (-n).upto n do |i|
          text = "i=#{i} n=#{n} m=#{modulus} r=#{r}"
          $stdout.flush

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_UP, ZERO_ROUND_TO_PLUS)
          assert(i_rounded.abs >= i.abs, "i_r=#{i_rounded} " + text)
          if (i == 0) then
            assert(i_rounded >= 0, "i_r=#{i_rounded} " + text)
          end

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_DOWN, ZERO_ROUND_TO_PLUS)
          if (i > 0)
            assert(i_rounded <= i, "i_r=#{i_rounded} " + text)
          elsif (i < 0)
            assert(i_rounded >= i, "i_r=#{i_rounded} " + text)
          elsif (i == 0) then
            assert(i_rounded >= 0, "i_r=#{i_rounded} " + text)
          else
            raise("i=#{i} i_r=#{i_rounded}")
          end

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_CEILING, ZERO_ROUND_TO_PLUS)
          assert(i_rounded >= i, "i_r=#{i_rounded} " + text)

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_FLOOR, ZERO_ROUND_TO_PLUS)
          assert(i_rounded <= i, "i_r=#{i_rounded} " + text)

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_HALF_UP, ZERO_ROUND_TO_PLUS)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded.abs < i.abs || i_rounded.sgn == - i.sgn)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_HALF_DOWN, ZERO_ROUND_TO_PLUS)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded.abs > i.abs && i_rounded.sgn == i.sgn)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_HALF_CEILING, ZERO_ROUND_TO_PLUS)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded < i)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          i_rounded = check_round_to_one_remainder(i, r, modulus, ROUND_HALF_FLOOR, ZERO_ROUND_TO_PLUS)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded > i && i != 0)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          ALL_ROUNDING_MODES.each do |rounding_mode|
            unless (rounding_mode.major == MAJOR_GEOMETRIC \
                    || rounding_mode.major == MAJOR_HARMONIC \
                    || rounding_mode.major == MAJOR_QUADRATIC \
                    || rounding_mode.major == MAJOR_CUBIC)
              next;
            end
            if (rounding_mode.minor == MINOR_EVEN || rounding_mode.minor == MINOR_ODD)
              next
            end
            i_rounded = check_round_to_one_remainder(i, r, modulus, rounding_mode, ZERO_ROUND_TO_PLUS)
          end
        end
      end
    end
  end

  #
  # test rounding of int to remainder set
  #
  def test_zero_round_to_zero_as_allowed_remainder
    print "\ntest_zero_round_to_zero_as_allowed_remainder [#{Time.now}]: "

    2.upto 20 do |modulus|
      text = "m=#{modulus}"
      ALL_ROUNDING_MODES.each do |rounding_mode|
        if (rounding_mode.minor == MINOR_EVEN || rounding_mode.minor == MINOR_ODD)
          next
        end
        if (rounding_mode.major == MAJOR_UNNECESSARY)
          next
        end
        ALL_ZERO_MODES.each do |zero_mode|
          zero_rounded = 0.round_to_allowed_remainders([0], modulus, rounding_mode, zero_mode)
          assert_equal(0, zero_rounded)
        end
      end
    end
  end

  #
  # test rounding of int to remainder set
  #
  def test_zero_round_to_one_allowed_remainder
    print "\ntest_zero_round_to_one_allowed_remainder [#{Time.now}]: "
    2.upto 20 do |modulus|
      0.upto modulus-1 do |r|
        text = "m=#{modulus} r=#{r}"

        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_UP, ZERO_ROUND_TO_PLUS)
        assert(zero_r >= 0, "0_r=#{zero_r} " + text)
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_UP, ZERO_ROUND_TO_MINUS)
        assert(zero_r <= 0, "0_r=#{zero_r} " + text)
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_UP, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        dd = 2*zero_r.abs
        assert(dd <= modulus, "0_r=#{zero_r} " + text)
        if (zero_r < 0)
          assert(dd < modulus, "0_r=#{zero_r} " + text)
        end
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_UP, ZERO_ROUND_TO_CLOSEST_PREFER_MINUS)
        dd = 2*zero_r.abs
        assert(dd <= modulus, "0_r=#{zero_r} " + text)
        if (zero_r > 0)
          assert(dd < modulus, "0_r=#{zero_r} " + text)
        end

        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_DOWN, ZERO_ROUND_TO_PLUS)
        assert(zero_r >= 0, "0_r=#{zero_r} " + text)
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_DOWN, ZERO_ROUND_TO_MINUS)
        assert(zero_r <= 0, "0_r=#{zero_r} " + text)
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_DOWN, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        dd = 2*zero_r.abs
        assert(dd <= modulus, "0_r=#{zero_r} " + text)
        if (zero_r < 0)
          assert(dd < modulus, "0_r=#{zero_r} " + text)
        end
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_DOWN, ZERO_ROUND_TO_CLOSEST_PREFER_MINUS)
        dd = 2*zero_r.abs
        assert(dd <= modulus, "0_r=#{zero_r} " + text)
        if (zero_r > 0)
          assert(dd < modulus, "0_r=#{zero_r} " + text)
        end

        # ceiling always rounds toward positive infinity, so 0 does not need any special handling and zero_rounding_mode is ignored
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_CEILING, ZERO_ROUND_UNNECESSARY)
        assert(zero_r >= 0, "0_r=#{zero_r} " + text)

        # ceiling always rounds toward negative infinity, so 0 does not need any special handling and zero_rounding_mode is ignored
        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_FLOOR, ZERO_ROUND_UNNECESSARY)
        assert(zero_r <= 0, "0_r=#{zero_r} " + text)

        ALL_ROUNDING_MODES.each do |rounding_mode|
          unless (rounding_mode.minor == MINOR_UP || rounding_mode.minor == MINOR_DOWN)
            next
          end
          unless (rounding_mode.major == MAJOR_HALF \
                  || rounding_mode.major == MAJOR_HARMONIC \
                  || rounding_mode.major == MAJOR_GEOMETRIC \
                  || rounding_mode.major == MAJOR_QUADRATIC \
                  || rounding_mode.major == MAJOR_CUBIC)
            next
          end
          [ZERO_ROUND_TO_PLUS,ZERO_ROUND_TO_CLOSEST_PREFER_PLUS].each do |zero_rounding_mode|
            zero_r = check_round_to_one_remainder(0, r, modulus, rounding_mode, zero_rounding_mode)
            if (rounding_mode.major == MAJOR_HALF)
              dd = 2*zero_r.abs
              text2 = text + " dd=#{dd} rm=#{rounding_mode} zm=#{zero_rounding_mode}"
              assert(dd <= modulus, "0_r=#{zero_r} " + text2)
              if (zero_r < 0)
                assert(dd < modulus, "0_r=#{zero_r} " + text2)
              end
            end
          end
          [ZERO_ROUND_TO_MINUS,ZERO_ROUND_TO_CLOSEST_PREFER_MINUS].each do |zero_rounding_mode|
            zero_r = check_round_to_one_remainder(0, r, modulus, rounding_mode, ZERO_ROUND_TO_MINUS)
            if (rounding_mode.major == MAJOR_HALF)
              dd = 2*zero_r.abs
              text2 = text + " dd=#{dd} rm=#{rounding_mode}"
              assert(dd <= modulus, "0_r=#{zero_r} " + text2)
              if (zero_r > 0)
                assert(dd < modulus, "0_r=#{zero_r} " + text2)
              end
            end
          end
        end

        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_HALF_CEILING, ZERO_ROUND_UNNECESSARY)
        dd = 2*zero_r.abs
        assert(dd <= modulus, "0_r=#{zero_r} " + text)
        if (zero_r < 0)
          assert(dd < modulus, "0_r=#{zero_r} " + text)
        end

        zero_r = check_round_to_one_remainder(0, r, modulus, ROUND_HALF_FLOOR, ZERO_ROUND_UNNECESSARY)
        dd = 2*zero_r.abs
        assert(dd <= modulus, "0_r=#{zero_r} " + text)
        if (zero_r > 0)
          assert(dd < modulus, "0_r=#{zero_r} " + text)
        end
      end
    end
  end

  def check_round_to_one_remainder(i, r, modulus, rounding_mode, zero_rounding_mode)

    remainders = [ r ]
    i_rounded = i.round_to_allowed_remainders(remainders, modulus, rounding_mode, zero_rounding_mode)
    text = "i_r=#{i_rounded} i=#{i} m=#{modulus} r=#{r} mode=#{rounding_mode} zm=#{zero_rounding_mode}"

    # if i is not zero or zero_rounding_mode is ZERO_ROUND_UNNECESSARY, using another zero_rounding_mode should not influence the result:
    if (i != 0 || zero_rounding_mode == ZERO_ROUND_UNNECESSARY)
      ALL_ZERO_MODES.each do |zm|
        assert_equal(i_rounded, i.round_to_allowed_remainders(remainders, modulus, rounding_mode, zm), "i=#{i} i_r=#{i_rounded} m=#{modulus} zm=#{zm} r=#{r}")
      end
    end

    # make sure that the result is congruent r modulo the modulus and within less than modulus away from i:
    assert(! (i_rounded.nil?), text)
    assert_equal(0, (i_rounded - r) % modulus, text)
    assert(i - modulus < i_rounded)
    assert(i_rounded < i + modulus)
    i_rounded
  end

  #
  # test rounding of int to remainder set
  #
  def test_int_round_to_allowed_remainders
    print "\ntest_int_round_to_allowed_remainders [#{Time.now}] (15 sec): "
    $stdout.flush
    # 2.upto 8 do |modulus|
    2.upto 7 do |modulus|
      xx = (1<< modulus) - 1
      xx.times do |x|
        remainders = make_set(x + 1, modulus)
        min_remainder = remainders.min
        max_remainder = remainders.max
        max_neg_remainder = max_remainder - modulus
        closest_remainder_prefer_plus = nil
        closest_remainder_prefer_minus = nil
        minus_remainder = if (min_remainder == 0)
                            min_remainder
                          else
                            max_neg_remainder
                          end
        if (-max_neg_remainder > min_remainder)
          closest_remainder_prefer_minus = min_remainder
          closest_remainder_prefer_plus = min_remainder
        elsif (-max_neg_remainder < min_remainder)
          closest_remainder_prefer_minus = max_neg_remainder
          closest_remainder_prefer_plus = max_neg_remainder
        else
          closest_remainder_prefer_minus = max_neg_remainder
          closest_remainder_prefer_plus = min_remainder
        end

        text0 = "m=#{modulus} x=#{x} s=#{remainders.inspect}"
        # puts text0
        print "."
        $stdout.flush
        n = 3*modulus
        (-n).upto n do |i|
          text = "i=#{i} n=#{n} " + text0
          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_UP, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          assert(i_rounded.abs >= i.abs, "i_r=#{i_rounded} " + text)
          if (i == 0) then
            assert(i_rounded >= 0, "i_r=#{i_rounded} " + text)
            assert_equal(min_remainder, i_rounded)
            # assert_equal(above.length, 0, "i_r=#{i_rounded} " + text)
          elsif (i > 0) then
            # rounded away from 0, so for positive i to value >= i
            # assert_equal(above.length, 0, text)
            assert(i_rounded >= i, "i_r=#{i_rounded} " + text)
            assert(i_rounded >= min_remainder)
          else
            # i < 0
            # rounded away from 0, so for negative i to value <= i
            assert_equal(below.length, 0, text)
            assert(i_rounded <= i, "i_r=#{i_rounded} " + text)
            assert(i_rounded <= max_neg_remainder)
          end

          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_DOWN, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          if (i > 0)
            assert(i_rounded <= i, "i_r=#{i_rounded} " + text)
            assert(i_rounded >= max_neg_remainder, "i_r=#{i_rounded} " + text)
            # assert_equal(below.length, 0, "i_r=#{i_rounded} " + text)
          elsif (i < 0)
            assert(i_rounded >= i, "i_r=#{i_rounded} " + text)
            assert(i_rounded <= min_remainder, "i_r=#{i_rounded} " + text)
            # assert_equal(above.length, 0, "i_r=#{i_rounded} " + text)
          elsif (i == 0) then
            assert(i_rounded >= 0, "i_r=#{i_rounded} " + text)
            assert_equal(min_remainder, i_rounded, "i_r=#{i_rounded} " + text)
            # assert_equal(above.length, 0, "i_r=#{i_rounded} " + text)
          else
            raise("i=#{i} i_r=#{i_rounded}")
          end

          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_CEILING, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          assert(i_rounded >= i, "i_r=#{i_rounded} " + text)
          # assert_equal(above.length, 0, "i_r=#{i_rounded} " + text)

          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_FLOOR, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          assert(i_rounded <= i, "i_r=#{i_rounded} " + text)
          # assert_equal(below.length, 0, "i_r=#{i_rounded} " + text)

          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_HALF_UP, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded.abs < i.abs || i_rounded.sgn == - i.sgn)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_HALF_DOWN, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded.abs > i.abs && i_rounded.sgn == i.sgn)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_HALF_CEILING, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded < i)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, ROUND_HALF_FLOOR, ZERO_ROUND_TO_PLUS)
          assert(above.empty?)
          assert(below.empty?)
          dd = 2*(i_rounded - i).abs
          assert(dd <= modulus, "i_r=#{i_rounded} " + text)
          if (i_rounded > i && i != 0)
            assert(dd < modulus, "i_r=#{i_rounded} " + text)
          end

          ALL_ROUNDING_MODES.each do |rounding_mode|
            unless (rounding_mode.major == MAJOR_GEOMETRIC \
                    || rounding_mode.major == MAJOR_HARMONIC \
                    || rounding_mode.major == MAJOR_QUADRATIC \
                    || rounding_mode.major == MAJOR_CUBIC)
              next;
            end
            if (rounding_mode.minor == MINOR_EVEN || rounding_mode.minor == MINOR_ODD)
              next
            end
            i_rounded, set, above, below = check_round_to_remainders(i, remainders, modulus, rounding_mode, ZERO_ROUND_TO_PLUS)
            if (rounding_mode.major != MAJOR_CUBIC)
              if (i < 0)
                assert(i_rounded <= 0, "i_r=#{i_rounded} " + text)
              end
              if (i > 0)
                assert(i_rounded >= 0, "i_r=#{i_rounded} " + text)
              end
            end
          end
        end
      end
    end
  end

  #
  # test rounding of 0 to remainder set
  #
  def test_zero_round_to_allowed_remainders
    print "\ntest_zero_round_to_allowed_remainders [#{Time.now}]: "
    $stdout.flush

    2.upto 7 do |modulus|
      xx = (1<< modulus) - 1
      xx.times do |x|
        remainders = make_set(x + 1, modulus)

        min_remainder = remainders.min
        max_remainder = remainders.max
        max_neg_remainder = max_remainder - modulus
        closest_remainder_prefer_plus = nil
        closest_remainder_prefer_minus = nil
        minus_remainder = if (min_remainder == 0)
                            min_remainder
                          else
                            max_neg_remainder
                          end
        if (-max_neg_remainder > min_remainder)
          closest_remainder_prefer_minus = min_remainder
          closest_remainder_prefer_plus = min_remainder
        elsif (-max_neg_remainder < min_remainder)
          closest_remainder_prefer_minus = max_neg_remainder
          closest_remainder_prefer_plus = max_neg_remainder
        else
          closest_remainder_prefer_minus = max_neg_remainder
          closest_remainder_prefer_plus = min_remainder
        end

        text = "m=#{modulus} x=#{x} s=#{remainders.inspect}"
        # puts text
        print "."
        $stdout.flush

        # ROUND_UP and ROUND_DOWN have the same effect for 0
        zero_r1, set1, above1, below1 = check_round_to_remainders(0, remainders, modulus, ROUND_UP, ZERO_ROUND_TO_PLUS)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_DOWN, ZERO_ROUND_TO_PLUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        assert(zero_r1 >= 0, "0_r=#{zero_r1} " + text)
        assert_equal(min_remainder, zero_r1, "0_r=#{zero_r1} " + text)

        zero_r1, set1, above1, below1 = check_round_to_remainders(0, remainders, modulus, ROUND_UP, ZERO_ROUND_TO_MINUS)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_DOWN, ZERO_ROUND_TO_MINUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        assert(zero_r1 <= 0, "0_r=#{zero_r1} " + text)
        assert_equal(minus_remainder, zero_r1, "0_r=#{zero_r1} " + text)

        zero_r1, set1, above1, below1 = check_round_to_remainders(0, remainders, modulus, ROUND_UP, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_DOWN, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        assert_equal(closest_remainder_prefer_plus, zero_r1, text)
        dd = 2*zero_r1.abs
        assert(dd <= modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
        if (zero_r1 < 0)
          assert(dd < modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
        end
        #if (below1.length > 0)
        #  assert(below1.max.abs >= zero_r1.abs, text)
        #end
        #if (above1.length > 0)
        #  assert(above1.min.abs >= zero_r1.abs, text)
        #end

        zero_r1, set1, above1, below1 = check_round_to_remainders(0, remainders, modulus, ROUND_UP, ZERO_ROUND_TO_CLOSEST_PREFER_MINUS)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_DOWN, ZERO_ROUND_TO_CLOSEST_PREFER_MINUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        assert_equal(closest_remainder_prefer_minus, zero_r1, text)
        # assert_equal(above1, above2, text)
        # assert_equal(below1, below2, text)
        dd = 2*zero_r1.abs
        assert(dd <= modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
        if (zero_r1 > 0)
          assert(dd < modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
        end
        #if (below1.length > 0)
        #  assert(below1.max.abs >= zero_r1.abs, text)
        #end
        #assert_equal(above1.length, 0, text)

        zero_rounded, set0, above0, below0 = check_round_to_remainders(0, remainders, modulus, ROUND_CEILING, ZERO_ROUND_UNNECESSARY)
        assert(above0.empty?)
        assert(below0.empty?)
        assert(zero_rounded >= 0, "0_r=#{zero_rounded} " + text)
        assert_equal(min_remainder, zero_rounded, text)
        # assert_equal(above0.length, 0, text)

        zero_rounded, set0, above0, below0 = check_round_to_remainders(0, remainders, modulus, ROUND_FLOOR, ZERO_ROUND_UNNECESSARY)
        assert(above0.empty?)
        assert(below0.empty?)
        assert(zero_rounded <= 0, "0_r=#{zero_rounded} " + text)
        assert_equal(minus_remainder, zero_rounded, text)
        # assert_equal(below0.length, 0, text)

        zero_r1, set1, above1, below1 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_UP, ZERO_ROUND_TO_PLUS)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_DOWN, ZERO_ROUND_TO_PLUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        if (zero_r1 < 0)
          assert_equal(max_neg_remainder, zero_r1)
        else
          assert_equal(min_remainder, zero_r1)
        end
        # assert_equal(above1, above2, text)
        # assert_equal(below1, below2, text)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_UP, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        if (zero_r1 < 0)
          assert_equal(max_neg_remainder, zero_r1)
        else
          assert_equal(min_remainder, zero_r1)
        end
        #assert_equal(above1, above2, text)
        #assert_equal(below1, below2, text)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_DOWN, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        # assert_equal(above1, above2, text)
        # assert_equal(below1, below2, text)
        dd = 2*zero_r1.abs
        assert(dd <= modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
        if (zero_r1 < 0)
          assert(dd < modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
          assert_equal(max_neg_remainder, zero_r1)
        else
          assert_equal(min_remainder, zero_r1)
        end
        # assert_equal(below1.length, 0, text)
        # assert_equal(above1.length, 0, text)

        zero_r1, set1, above1, below1 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_UP, ZERO_ROUND_TO_MINUS)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_DOWN, ZERO_ROUND_TO_MINUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        if (zero_r1 < 0)
          assert_equal(max_neg_remainder, zero_r1)
        else
          assert_equal(min_remainder, zero_r1)
        end
        # assert_equal(above1, above2, text)
        # assert_equal(below1, below2, text)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_UP, ZERO_ROUND_TO_CLOSEST_PREFER_MINUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        # assert_equal(above1, above2, text)
        # assert_equal(below1, below2, text)
        zero_r2, set2, above2, below2 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_DOWN, ZERO_ROUND_TO_CLOSEST_PREFER_MINUS)
        assert(above1.empty?)
        assert(below1.empty?)
        assert(above2.empty?)
        assert(below2.empty?)
        assert_equal(zero_r1, zero_r2, text)
        # assert_equal(above1, above2, text)
        # assert_equal(below1, below2, text)
        dd = 2*zero_r1.abs
        assert(dd <= modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
        if (zero_r1 > 0)
          assert(dd < modulus, "0_r=#{zero_r1} dd=#{dd} " + text)
          assert_equal(min_remainder, zero_r1)
        else
          assert_equal(minus_remainder, zero_r1)
        end
        # assert_equal(below1.length, 0, text)
        # assert_equal(above1.length, 0, text)

        zero_rounded, set0, above0, below0 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_CEILING, ZERO_ROUND_UNNECESSARY)
        assert(above0.empty?)
        assert(below0.empty?)
        dd = 2*zero_rounded.abs
        assert(dd <= modulus, "0_r=#{zero_rounded} dd=#{dd} " + text)
        if (zero_rounded < 0)
          assert_equal(max_neg_remainder, zero_rounded)
          assert(dd < modulus, "0_r=#{zero_rounded} dd=#{dd} " + text)
        else
          assert_equal(min_remainder, zero_rounded)
        end
        # assert_equal(below0.length, 0, text)
        # assert_equal(above0.length, 0, text)

        zero_rounded, set0, above0, below0 = check_round_to_remainders(0, remainders, modulus, ROUND_HALF_FLOOR, ZERO_ROUND_UNNECESSARY)
        assert(above0.empty?)
        assert(below0.empty?)
        dd = 2*zero_rounded.abs
        assert(dd <= modulus, "0_r=#{zero_rounded} " + text)
        if (zero_rounded > 0)
          assert_equal(min_remainder, zero_r1)
          assert(dd < modulus, "0_r=#{zero_rounded} " + text)
        else
          assert_equal(minus_remainder, zero_r1)
        end
        # assert_equal(below0.length, 0, text)
        # assert_equal(above0.length, 0, text)

        ALL_ROUNDING_MODES.each do |rounding_mode|
          unless (rounding_mode.major == MAJOR_GEOMETRIC \
                  || rounding_mode.major == MAJOR_HARMONIC \
                  || rounding_mode.major == MAJOR_QUADRATIC \
                  || rounding_mode.major == MAJOR_CUBIC)
            next;
          end
          if (rounding_mode.minor == MINOR_EVEN || rounding_mode.minor == MINOR_ODD)
            next
          end

          if (rounding_mode == ROUND_CUBIC_CEILING)
            i_rounded, set, above, below = check_round_to_remainders(0, remainders, modulus, rounding_mode, ZERO_ROUND_UNNECESSARY)
            if (min_remainder+max_neg_remainder > 0)
              assert_equal(minus_remainder, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            else
              assert_equal(min_remainder, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            end
          elsif (rounding_mode == ROUND_CUBIC_FLOOR)
            i_rounded, set, above, below = check_round_to_remainders(0, remainders, modulus, rounding_mode, ZERO_ROUND_UNNECESSARY)
            if (min_remainder+max_neg_remainder < 0)
              assert_equal(min_remainder, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            else
              assert_equal(minus_remainder, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            end
          elsif ((rounding_mode == ROUND_CUBIC_DOWN || rounding_mode == ROUND_CUBIC_UP) && min_remainder+max_neg_remainder != 0)
            assert_equal(closest_remainder_prefer_minus, closest_remainder_prefer_plus)
            i_rounded = 0.round_to_allowed_remainders(remainders, modulus, rounding_mode, ZERO_ROUND_UNNECESSARY)
            assert_equal(closest_remainder_prefer_plus, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            i_rounded, set, above, below = check_round_to_remainders(0, remainders, modulus, rounding_mode, ZERO_ROUND_UNNECESSARY)
            assert_equal(closest_remainder_prefer_plus, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
          else
            i_rounded, set, above, below = check_round_to_remainders(0, remainders, modulus, rounding_mode, ZERO_ROUND_TO_PLUS)
            assert_equal(min_remainder, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            i_rounded, set, above, below = check_round_to_remainders(0, remainders, modulus, rounding_mode, ZERO_ROUND_TO_MINUS)
            assert_equal(minus_remainder, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            i_rounded, set, above, below = check_round_to_remainders(0, remainders, modulus, rounding_mode, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
            assert_equal(closest_remainder_prefer_plus, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
            i_rounded, set, above, below = check_round_to_remainders(0, remainders, modulus, rounding_mode, ZERO_ROUND_TO_CLOSEST_PREFER_MINUS)
            assert_equal(closest_remainder_prefer_minus, i_rounded, text+" i_rounded=#{i_rounded} rounding_mode=#{rounding_mode}")
          end
        end

      end
    end
  end

  def make_set(x, m)
    s = []
    b = 1
    m.times do |i|
      if (b & x) == b
        s = s.push(i)
      end
      b = 2*b
    end
    s
  end

  def check_round_to_remainders(i, remainders, modulus, rounding_mode, zero_rounding_mode)

    # do the rounding
    i_rounded = i.round_to_allowed_remainders(remainders.clone, modulus, rounding_mode, zero_rounding_mode)

    # make sure that the zero_rounding_mode does not matter if i is not zero or if ZERO_ROUND_UNNECESSARY is provided
    if (i != 0 || zero_rounding_mode == ZERO_ROUND_UNNECESSARY)
      ALL_ZERO_MODES.each do |zm|
        assert_equal(i_rounded, i.round_to_allowed_remainders(remainders.clone, modulus, rounding_mode, zm), "i=#{i} i_r=#{i_rounded} m=#{modulus} zm=#{zm}")
      end
    end

    # make sure there is exactly one remainder matching
    one_remainder = remainders.select do |r|
      (i_rounded - r) % modulus == 0
    end
    assert_equal(1, one_remainder.length, "i_r=#{i_rounded} i=#{i} m=#{modulus} r=#{remainders} or=#{one_remainder.to_s} rm=#{rounding_mode} zm=#{zero_rounding_mode}")

    # make sure that i_rounded is less than modulus away from i
    assert(i - modulus < i_rounded)
    assert(i_rounded < i + modulus)

    # run the test with each single remainder:
    set = remainders.map do |r|
      if (zero_rounding_mode == ZERO_ROUND_UNNECESSARY)
        check_round_to_one_remainder(i, r, modulus, rounding_mode, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
      else
        check_round_to_one_remainder(i, r, modulus, rounding_mode, zero_rounding_mode)
      end
    end

    # find members which are closer than i_rounded above and below from the results of rounding to a single remainder
    closer_above = []
    closer_below = []
    found = false
    set.each do |i_r|
      if (i_r == i_rounded)
        found = true
      else
        assert(i != i_r, "i=#{i} i_r=#{i_r} i_rounded=#{i_rounded}")
        closer = ((i_r - i).abs < (i_rounded -i).abs)
        if (i < i_r)
          assert(i_rounded < i_r)
          if closer
            closer_above.push(i_r)
            # raise ArgumentError, "i=#{i} ir=#{i_r} i_rounded=#{i_rounded} remainders=#{remainders.inspect} m=#{modulus} rm=#{rounding_mode} zm=#{zero_rounding_mode} closer_above"
          end
        else
          # i_r < i
          assert(i_r < i_rounded)
          if closer
            closer_below.push(i_r)
            # raise ArgumentError, "i=#{i} ir=#{i_r} i_rounded=#{i_rounded} remainders=#{remainders.inspect} m=#{modulus} rm=#{rounding_mode} zm=#{zero_rounding_mode} closer_below"
          end
        end
      end
    end
    # assert(closer_below.empty?)
    # assert(closer_above.empty?)
    return i_rounded, set, closer_above, closer_below

  end # check_round_to_remainders

  # any subset of 0..m-1 with rounding of 0
  #
  # ROUND_UNNECESSARY/ROUND_HALF_EVEN

  def test_minor_major_rounding_modes
    print "\ntest_minor_major_rounding_modes [#{Time.now}]: "
    $stdout.flush
    [[  ROUND_CEILING, MAJOR_CEILING, MINOR_UNUSED ],
     [  ROUND_UNNECESSARY, MAJOR_UNNECESSARY, MINOR_UNUSED ],
     [  ROUND_UP, MAJOR_UP, MINOR_UNUSED ],
     [  ROUND_DOWN, MAJOR_DOWN, MINOR_UNUSED ],
     [  ROUND_FLOOR, MAJOR_FLOOR, MINOR_UNUSED ],
     [  ROUND_CUBIC_CEILING, MAJOR_CUBIC, MINOR_CEILING ],
     [  ROUND_CUBIC_DOWN, MAJOR_CUBIC, MINOR_DOWN ],
     [  ROUND_CUBIC_EVEN, MAJOR_CUBIC, MINOR_EVEN ],
     [  ROUND_CUBIC_ODD, MAJOR_CUBIC, MINOR_ODD ],
     [  ROUND_CUBIC_FLOOR, MAJOR_CUBIC, MINOR_FLOOR ],
     [  ROUND_CUBIC_UP, MAJOR_CUBIC, MINOR_UP ],
     [  ROUND_GEOMETRIC_CEILING, MAJOR_GEOMETRIC, MINOR_CEILING ],
     [  ROUND_GEOMETRIC_DOWN, MAJOR_GEOMETRIC, MINOR_DOWN ],
     [  ROUND_GEOMETRIC_EVEN, MAJOR_GEOMETRIC, MINOR_EVEN ],
     [  ROUND_GEOMETRIC_ODD, MAJOR_GEOMETRIC, MINOR_ODD ],
     [  ROUND_GEOMETRIC_FLOOR, MAJOR_GEOMETRIC, MINOR_FLOOR ],
     [  ROUND_GEOMETRIC_UP, MAJOR_GEOMETRIC, MINOR_UP ],
     [  ROUND_HALF_CEILING, MAJOR_HALF, MINOR_CEILING ],
     [  ROUND_HALF_DOWN, MAJOR_HALF, MINOR_DOWN ],
     [  ROUND_HALF_EVEN, MAJOR_HALF, MINOR_EVEN ],
     [  ROUND_HALF_ODD, MAJOR_HALF, MINOR_ODD ],
     [  ROUND_HALF_FLOOR, MAJOR_HALF, MINOR_FLOOR ],
     [  ROUND_HALF_UP, MAJOR_HALF, MINOR_UP ],
     [  ROUND_HARMONIC_CEILING, MAJOR_HARMONIC, MINOR_CEILING ],
     [  ROUND_HARMONIC_DOWN, MAJOR_HARMONIC, MINOR_DOWN ],
     [  ROUND_HARMONIC_EVEN, MAJOR_HARMONIC, MINOR_EVEN ],
     [  ROUND_HARMONIC_ODD, MAJOR_HARMONIC, MINOR_ODD ],
     [  ROUND_HARMONIC_FLOOR, MAJOR_HARMONIC, MINOR_FLOOR ],
     [  ROUND_HARMONIC_UP, MAJOR_HARMONIC, MINOR_UP ],
     [  ROUND_QUADRATIC_CEILING, MAJOR_QUADRATIC, MINOR_CEILING ],
     [  ROUND_QUADRATIC_DOWN, MAJOR_QUADRATIC, MINOR_DOWN ],
     [  ROUND_QUADRATIC_EVEN, MAJOR_QUADRATIC, MINOR_EVEN ],
     [  ROUND_QUADRATIC_ODD, MAJOR_QUADRATIC, MINOR_ODD ],
     [  ROUND_QUADRATIC_FLOOR, MAJOR_QUADRATIC, MINOR_FLOOR ],
     [  ROUND_QUADRATIC_UP, MAJOR_QUADRATIC, MINOR_UP ]].each do |triple|
      mode = triple[0]
      major = triple[1]
      minor = triple[2]
      found = MODE_LOOKUP[[major, minor]]
      assert_equal(mode, found)
      assert_same(mode, found)
      assert_equal(major, mode.major)
      assert_equal(major, found.major)
      assert_equal(minor, mode.minor)
      assert_equal(minor, found.minor)
    end
  end

  # test remainder rounding half with exact boundary
  #
  def test_int_round_half_int_param_to_two_allowed_remainders
    print "\ntest_int_round_half_to_two_allowed_remainders [#{Time.now}]: "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 3], [1, 5], [2, 4], [2, 6], [3, 5], [3, 7]], true, MAJOR_HALF) do |x, y|
      LongMath.arithmetic_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding half with exact boundary
  #
  def test_int_round_half_non_int_param_to_two_allowed_remainders
    print "\ntest_int_round_half_to_two_allowed_remainders [#{Time.now}] (long): "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 2], [1, 4], [1, 6], [2, 3], [2, 5], [2, 7], [3, 4], [3, 6], [3, 8], [4, 5], [4, 7]], false, MAJOR_HALF) do |x, y|
      LongMath.arithmetic_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding geometric with exact boundary
  #
  def test_int_round_geometric_int_param_to_two_allowed_remainders
    print "\ntest_int_round_geometric_to_two_allowed_remainders [#{Time.now}]: "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 4], [1, 9], [2, 8]], true, MAJOR_GEOMETRIC) do |x, y|
      LongMath.geometric_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding geometric with exact boundary
  #
  def test_int_round_geometric_non_int_param_to_two_allowed_remainders
    print "\ntest_int_round_geometric_to_two_allowed_remainders [#{Time.now}] (long): "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 2], [1, 3], [1, 5], [1, 6], [1, 7], [1, 8], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7]], false, MAJOR_GEOMETRIC) do |x, y|
      LongMath.geometric_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding harmonic with exact boundary
  #
  def test_int_round_harmonic_int_param_to_two_allowed_remainders
    print "\ntest_int_round_harmonic_to_two_allowed_remainders [#{Time.now}]: "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[2, 6], [3, 6]], true, MAJOR_HARMONIC) do |x, y|
      LongMath.harmonic_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding harmonic with exact boundary
  #
  def test_int_round_harmonic_non_int_param_to_two_allowed_remainders
    print "\ntest_int_round_harmonic_to_two_allowed_remainders [#{Time.now}] (long): "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [1, 8], [2, 3], [2, 4], [2, 5], [2, 7]], false, MAJOR_HARMONIC) do |x, y|
      LongMath.harmonic_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding quadratic with exact boundary
  #
  def test_int_round_quadratic_int_param_to_two_allowed_remainders
    print "\ntest_int_round_quadratic_to_two_allowed_remainders [#{Time.now}]: "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 7]], true, MAJOR_QUADRATIC) do |x, y|
      LongMath.quadratic_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding quadratic with exact boundary
  #
  def test_int_round_quadratic_non_int_param_to_two_allowed_remainders
    print "\ntest_int_round_quadratic_to_two_allowed_remainders [#{Time.now}] (long): "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 8], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7], [3, 4], [3, 5], [3, 6], [3, 7]], false, MAJOR_QUADRATIC) do |x, y|
      LongMath.quadratic_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # test remainder rounding cubic with exact boundary
  #
  def test_int_round_cubic_non_int_param_to_two_allowed_remainders
    print "\ntest_int_round_cubic_non_int_param_to_two_allowed_remainders [#{Time.now}]: "
    $stdout.flush
    check_int_round_major_to_two_allowed_remainders([[1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [1, 8], [2, 3], [2, 4], [2, 5], [2, 7]], false, MAJOR_CUBIC) do |x, y|
      LongMath.cubic_mean(0, ROUND_FLOOR, x, y).to_i
    end
  end

  # TODO: round to zero, away from zero to negative, away from zero to positive, across zero to negative, across zero to positive

  # test remainder rounding geometric
  #
  def check_int_round_major_to_two_allowed_remainders(remainder_sets, boundary_exact_integral, major_mode, &block)

    if RUBY_VERSION.match /^1\.8/
      puts "Warning: this test is not supported for Ruby #{RUBY_VERSION}"
      return
    end

    mode_up = MODE_LOOKUP[[major_mode, MINOR_UP]]
    mode_down = MODE_LOOKUP[[major_mode, MINOR_DOWN]]
    mode_floor = MODE_LOOKUP[[major_mode, MINOR_FLOOR]]
    mode_ceiling = MODE_LOOKUP[[major_mode, MINOR_CEILING]]

    20.upto 25 do |modulus|
      remainder_sets.each do |remainders|
        # puts text
        print "."
        $stdout.flush

        lower_remainder = remainders[0]
        upper_remainder = remainders[1]

        text = "m=#{modulus} x=#{0} s=#{remainders.inspect}"

        zero_rounded = 0.round_to_allowed_remainders(remainders, modulus, mode_up, ZERO_ROUND_TO_PLUS)
        assert_equal(lower_remainder, zero_rounded, text + " zero_rounded=#{zero_rounded}")
        zero_rounded = 0.round_to_allowed_remainders(remainders, modulus, mode_down, ZERO_ROUND_TO_PLUS)
        assert_equal(lower_remainder, zero_rounded, text + " zero_rounded=#{zero_rounded}")
        zero_rounded = 0.round_to_allowed_remainders(remainders, modulus, mode_up, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        assert_equal(lower_remainder, zero_rounded, text + " zero_rounded=#{zero_rounded}")
        zero_rounded = 0.round_to_allowed_remainders(remainders, modulus, mode_down, ZERO_ROUND_TO_CLOSEST_PREFER_PLUS)
        assert_equal(lower_remainder, zero_rounded, text + " zero_rounded=#{zero_rounded}")
        zero_rounded = 0.round_to_allowed_remainders(remainders, modulus, mode_ceiling, ZERO_ROUND_TO_PLUS)
        assert_equal(lower_remainder, zero_rounded, text)

        # zero_r1 = 0.round_to_allowed_remainders(remainders, modulus, mode_up, ZERO_ROUND_TO_MINUS)
        # zero_r2 = 0.round_to_allowed_remainders(remainders, modulus, mode_down, ZERO_ROUND_TO_MINUS)
        # assert_equal(zero_r1, zero_r2, text + " zero_r1=#{zero_r1} zero_r2=#{zero_r2}")
        # assert_equal(upper_remainder - modulus, zero_r1, text + " zero_r1=#{zero_r1} zero_r2=#{zero_r2}")

        # zero_r0 = 0.round_to_allowed_remainders(remainders, modulus, mode_floor, ZERO_ROUND_TO_MINUS)
        # assert_equal(upper_remainder - modulus, zero_r0, "zero_r0=#{zero_r0} < 0 " + text)

        param = block.yield(lower_remainder, upper_remainder)
        boundary_lower = nil
        boundary_upper = nil
        if (boundary_exact_integral)
          boundary_lower = param - 1
        else
          boundary_lower = param
        end
        boundary_upper = param +1

        1.upto boundary_lower do |x|
          ALL_ROUNDING_MODES.each do |rm|
            if (rm.major == major_mode && rm.minor != MINOR_EVEN && rm.minor != MINOR_ODD)
              text = "m=#{modulus} x=#{x} rm=#{rm} s=#{remainders.inspect} param=#{param}"
              one_r0 = x.round_to_allowed_remainders(remainders, modulus, rm, ZERO_ROUND_UNNECESSARY)
              assert_equal(lower_remainder, one_r0, text)
            end
          end
        end
        if (boundary_exact_integral)
          ALL_ROUNDING_MODES.each do |rm|
            if (rm.major == major_mode && rm.minor != MINOR_EVEN && rm.minor != MINOR_ODD)
              text = "m=#{modulus} x=#{param} rm=#{rm} s=#{remainders.inspect}"
              x_r0 = param.round_to_allowed_remainders(remainders, modulus, rm, ZERO_ROUND_UNNECESSARY)
              assert(remainders.member?(x_r0), "x_r0=#{x_r0} " + text)
            end
          end
        end
        boundary_upper.upto upper_remainder do |x|
          ALL_ROUNDING_MODES.each do |rm|
            if (rm.major == major_mode && rm.minor != MINOR_EVEN && rm.minor != MINOR_ODD)
              text = "m=#{modulus} x=#{x} rm=#{rm} s=#{remainders.inspect}"
              other_r0 = x.round_to_allowed_remainders(remainders, modulus, rm, ZERO_ROUND_UNNECESSARY)
              assert_equal(upper_remainder, other_r0, text)
            end
          end
        end
      end
    end
  end

  #
  # test conversion to String
  #
  def test_to_s
    print "\ntest_to_s [#{Time.now}]: "
    l = LongDecimal(224, 0)
    assert_equal("224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert_equal("22.4", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert_equal("2.24", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert_equal("0.224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert_equal("0.0224", l.to_s, "l=#{l.inspect}")

    l = LongDecimal(-224, 0)
    assert_equal("-224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 1)
    assert_equal("-22.4", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 2)
    assert_equal("-2.24", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 3)
    assert_equal("-0.224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 4)
    assert_equal("-0.0224", l.to_s, "l=#{l.inspect}")
  end

  #
  # test conversion to String with extra parameters
  #
  def test_to_s_with_params
    print "\ntest_to_s_with_params [#{Time.now}]: "
    l = LongDecimal(224, 0)
    s = l.to_s(5)
    assert_equal("224.00000", s, "l=#{l.inspect} 5")
    s = l.to_s(5, ROUND_UNNECESSARY, 16)
    assert_equal("e0.00000", s, "l=#{l.inspect} 5 ROUND_UNNECESSARY 16")

    l = LongDecimal(224, 1)
    s = l.to_s(0, ROUND_HALF_UP)
    assert_equal("22", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP)
    assert_equal("22.40000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP, 16)
    assert_equal("16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_DOWN, 16)
    assert_equal("16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(224, 2)
    s = l.to_s(0, ROUND_HALF_UP)
    assert_equal("2", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP)
    assert_equal("2.24000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP, 16)
    assert_equal("2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_DOWN, 16)
    assert_equal("2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(-224, 0)
    s = l.to_s(5)
    assert_equal("-224.00000", s, "l=#{l.inspect} 5")
    s = l.to_s(5, ROUND_UNNECESSARY, 16)
    assert_equal("-e0.00000", s, "l=#{l.inspect} 5 ROUND_UNNECESSARY 16")

    l = LongDecimal(-224, 1)
    s = l.to_s(0, ROUND_HALF_UP)
    assert_equal("-22", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP)
    assert_equal("-22.40000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP, 16)
    assert_equal("-16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_DOWN, 16)
    assert_equal("-16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(-224, 2)
    s = l.to_s(0, ROUND_HALF_UP)
    assert_equal("-2", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP)
    assert_equal("-2.24000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_UP, 16)
    assert_equal("-2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, ROUND_HALF_DOWN, 16)
    assert_equal("-2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")
  end

  #
  # test conversion to Rational
  #
  def test_to_r
    print "\ntest_to_r [#{Time.now}]: "
    l = LongDecimal(224, 0)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
  end

  #test_to_f

  #
  # test to_ld of Numeric
  #
  def test_to_ld
    print "\ntest_to_ld [#{Time.now}]: "
    x = LongDecimal(123, 100)
    y = x.to_ld(20, ROUND_UP)
    z = LongDecimal(1, 20)
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(y, z, "x=#{x} y=#{y}")
    y = x.to_ld(20, ROUND_HALF_UP)
    z = LongDecimal(0, 20)
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(y, z, "x=#{x} y=#{y}")

    x = 224
    y = x.to_ld(20)
    z = LongDecimal(224*10**20, 20)
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(y, z, "x=#{x} y=#{y}")
  end

  #
  # test conversion to BigDecimal
  #
  def test_to_bd
    print "\ntest_to_bd [#{Time.now}]: "
    l = LongDecimal(224, 0)
    assert((l.to_bd - 224).abs < 224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert((l.to_bd - 22.4).abs < 22.4 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert((l.to_bd - 2.24).abs < 2.24 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert((l.to_bd - 0.224).abs < 0.224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert((l.to_bd - 0.0224).abs < 0.0224 * 0.000001, "l=#{l.inspect}")
  end

  #
  # test conversion to Integer
  #
  def test_to_i
    print "\ntest_to_i [#{Time.now}]: "
    l = LongDecimal(224, 0)
    assert_equal(224, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert_equal(22, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert_equal(2, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert_equal(0, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert_equal(0, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(229, 1)
    assert_equal(22, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(-229, 1)
    assert_equal(-23, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(-221, 1)
    assert_equal(-23, l.to_i, "l=#{l.inspect}")
  end

  #
  # test adjustment of scale which is used as preparation for addition
  # and subtraction
  #
  def test_equalize_scale
    print "\ntest_equalize_scale [#{Time.now}]: "
    x = LongDecimal(1, 0)
    y = LongDecimal(10, 1)
    assert_equal(0, (x - y).sgn, "difference must be 0")
    assert(! (x.eql? y), "x and y have the same value, but are not equal")
    assert_equal(x, y)
    u, v = x.equalize_scale(y)
    assert_equal(u, v, "u and v must be equal")
    assert_equal(y, v, "y and v must be equal")
    assert_equal(1, u.scale, "scale must be 1")
    y = LongDecimal(200, 2)
    v, u = y.equalize_scale(x)
    assert_equal(2, u.scale, "scale must be 2")
    assert_equal(2, v.scale, "scale must be 2")
    assert_equal(100, u.int_val, "int_val must be 100")
    assert_equal(200, v.int_val, "int_val must be 200")
  end

  #
  # test adjustment of scale which is used as preparation for division
  #
  def test_anti_equalize_scale
    print "\ntest_anti_equalize_scale [#{Time.now}]: "
    x = LongDecimal(20, 3)
    y = LongDecimal(10, 1)
    u, v = x.anti_equalize_scale(y)
    assert_equal(0, u.scale, "scale must be 0")
    assert_equal(0, v.scale, "scale must be 0")
    assert_equal(20, u.int_val, "int_val must be 20")
    assert_equal(1000, v.int_val, "int_val must be 1000")
  end

  #
  # test unary minus operation (negation)
  #
  def test_negation
    print "\ntest_negation [#{Time.now}]: "
    x = LongDecimal(0, 5)
    assert_equal(-x, x, "x and -x are equal for negative x=#{x.inspect}")
    x = LongDecimal(224, 2)
    y = -x
    assert_equal(-1, y.sgn, "sign of y must be -1 y=#{y.inspect}")
    assert_equal(2, y.scale, "scale of y must be 2 y=#{y.inspect}")
    assert_equal(-224, y.int_val, "int_val of y must be -224 y=#{y.inspect}")
  end

  #
  # test addition of LongDecimal
  #
  def test_add
    print "\ntest_add [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x + y
    zz = LongDecimal(254, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x + y
    zz = LongDecimal(724, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x + y
    zz = LongDecimal(724, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x + y
    zz = LongDecimalQuot(Rational(293, 75), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x + y
    zz = LongDecimalQuot(Rational(293, 75), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test add_complexition of LongDecimal
  #
  def test_add_complex
    print "\ntest_add_complex [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = Complex(5, 3)
    z = x + y
    # if (LongDecimalBase::RUNNING_AT_LEAST_19)
    zz = Complex(LongDecimal(724, 2), 3)
    # else
    # zz = Complex(7.24, 3)
    # end
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    msg = "z=#{z.inspect} zz=#{zz.inspect} x=#{x.inspect} y=#{y.inspect}"
    assert_equal(zz, z, msg)
    z = y + x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, msg);
  end

  #
  # test subtraction of LongDecimal
  #
  def test_sub
    print "\ntest_sub [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x - y
    zz = LongDecimal(194, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimal(-194, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x - y
    zz = LongDecimal(-276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimal(276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x - y
    zz = LongDecimal(-276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimal(276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x - y
    zz = LongDecimalQuot(Rational(43, 75), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(-43, 75), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x - y
    zz = LongDecimalQuot(Rational(43, 75), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(-43, 75), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test sub_complextraction of LongDecimal
  #
  def test_sub_complex
    print "\ntest_sub_complex [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = Complex(5, 3)
    z = x - y
    #if (LongDecimalBase::RUNNING_AT_LEAST_19)
    zz = Complex(LongDecimal(-276, 2), -3)
    #else
    # zz = Complex(-2.76, -3)
    #end
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = Complex(LongDecimal(276, 2), 3)
    # zz = Complex(2.76, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test multiplication of fixnum, which is buggy in JRuby and has been fixed here.
  #
  def test_int_mul
    print "\ntest_int_mul [#{Time.now}] (90 sec): "
    $stdout.flush
    65.times do |i|
      x0 = (1 << i)-1
      3.times do |k|
        x = x0+k
        65.times do |j|
          y0 = (1 << j)-1
          3.times do |l|
            y = y0+l
            z = x*y
            if (x == 0 || y == 0)
              assert_equal(0, z)
              next
            end
            assert_equal(0, z%x)
            assert_equal(0, z%y)
            assert_equal(y, z/x)
            assert_equal(x, z/y)
          end
        end
      end
    end
  end

  #
  # test multiplication which uses internally multiplication of fixnum, which is buggy in JRuby and has been fixed here.
  #
  def test_mul2
    print "\ntest_mul2 [#{Time.now}]: "
    $stdout.flush

    map = {}
    [0, 1, 2, 3, 4, 5, 7, 9, 11, 13, 17, 21, 25, 29, 31, 33, 34, 35].each do |i|
      next if i > 5 && (i & 0x1) == 0
      ii = i + 32
      x0 = (1 << ii) - 1
      3.times do |k|
        x1 = x0 + k
        4.times do |s|
          x = LongDecimal(x1, s)
          map[x] = x1
        end
      end
    end
    map.each do |x, x1|
      # puts "x=#{x} x1=#{x1}"
      print ":"
      $stdout.flush
      map.each do |y, y1|
        z = x*y
        z1 = x1*y1
        zz = LongDecimal(z1, x.scale + y.scale)
        assert_equal(zz, z)
        if (x.zero? || y.zero?)
          assert(z.zero?)
          next
        end
        assert_equal(y, (z/x).round_to_scale(y.scale))
        assert_equal(x, (z/y).round_to_scale(x.scale))
      end
    end
  end

  #
  # test multiplication of LongDecimal
  #
  def test_mul
    print "\ntest_mul [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x * y
    zz = LongDecimal(224*3, 3)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x * y
    zz = LongDecimal(224*5, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x * y
    zz = LongDecimal(112000, 4)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 300), 4)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 300), 5)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test mul_complextiplication of LongDecimal
  #
  def test_mul_complex
    print "\ntest_mul_complex [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = Complex(5, 3)
    z = x * y
    # zz = Complex(11.20, 6.72)
    zz = Complex(LongDecimal(1120, 2), LongDecimal(672, 2))
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal_complex(zz, z, "z=#{z.inspect}", 1e-9)
    z = y * x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal_complex(zz, z, "z=#{z.inspect}", 1e-9)
  end

  #
  # test division of LongDecimal
  #
  def test_div
    print "\ntest_div [#{Time.now}]: "
    x = LongDecimal(224, 2) # 2.24 dx=1 sx=2

    y = LongDecimal(3, 1)   # 0.3  dy=0 sy=1
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -3 -> use 0
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(30, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                                   # x= 2.24     dx=1 sx=2
    y = LongDecimal(30000000, 8)   # 0.30000000  dy=0 sy=8
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(30, 224), 1)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                            # x= 2.24 dx=1  sx=2
    y = LongDecimal(3, 4)   # 0.0003  dy=-4 sy=4
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -8 -> use 0
    zz = LongDecimalQuot(Rational(22400, 3), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 2
    zz = LongDecimalQuot(Rational(3, 22400), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                             # x= 2.24 dx=1 sx=2
    y = LongDecimal(3333, 2) # 33.33   dy=2 sy=2
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(224, 3333), 1)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(3333, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                              # x= 2.24 dx=1 sx=2
    y = LongDecimal(33333, 2) # 333.33  dy=3 sy=2
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 2
    zz = LongDecimalQuot(Rational(224, 33333), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -2 -> use 0
    zz = LongDecimalQuot(Rational(33333, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                              # x= 2.24 dx=1 sx=2
    y = LongDecimal(33333, 3) # 33.333  dy=2 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(2240, 33333), 1)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(33333, 2240), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                             # x= 2.24 dx=1 sx=2
    y = LongDecimal(3333, 3) # 3.333   dy=1 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(2240, 3333), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(3333, 2240), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                                  # x= 2.24    dx=1 sx=2
    y = LongDecimal(123456789, 3) # 123456.789 dy=6 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 5
    zz = LongDecimalQuot(Rational(2240, 123456789), 5)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -5 -> use 0
    zz = LongDecimalQuot(Rational(123456789, 2240), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

           # x= 2.24 dx=1 sx=2
    y = 5  #    5    dy=1 sy=0
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -2 -> use 0
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -2 -> use 0
    zz = LongDecimalQuot(Rational(500, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

              # x= 2.24 dx=1 sx=2
    y = 5.001 #         dy=1 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(500, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x / y
    # y is has no scale, use scale of x
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # y is has no scale, use scale of x
    zz = LongDecimalQuot(Rational(500, 224*3), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x / y
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(500, 224*3), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test div_complexision of LongDecimal
  #
  def test_div_complex
    print "\ntest_div_complex [#{Time.now}]: "
    x = LongDecimal(224, 2) # 2.24 dx=1 sx=2

    y = Complex(5, 3)
    z = x / y
    zz = 2.24 / Complex(5, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y / x
    zz = Complex(5 / 2.24, 3 / 2.24)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test division of LongDecimal with Rational as result
  #
  def test_rdiv
    print "\ntest_rdiv [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x.rdiv(y)
    zz = Rational(224, 30)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(30, 224)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(30000000, 8)
    z = x.rdiv(y)
    zz = Rational(224, 30)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(30, 224)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3, 4)
    z = x.rdiv(y)
    zz = Rational(22400, 3)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(3, 22400)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3333, 2)
    z = x.rdiv(y)
    zz = Rational(224, 3333)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(3333, 224)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(33333, 2)
    z = x.rdiv(y)
    zz = Rational(224, 33333)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(33333, 224)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(33333, 3)
    z = x.rdiv(y)
    zz = Rational(2240, 33333)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(33333, 2240)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3333, 3)
    z = x.rdiv(y)
    zz = Rational(2240, 3333)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(3333, 2240)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(123456789, 3)
    z = x.rdiv(y)
    zz = Rational(2240, 123456789)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.rdiv(x)
    zz = Rational(123456789, 2240)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x.rdiv(y)
    zz = Rational(224, 500)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x.rdiv(y)
    zz = Rational(224, 500)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x.rdiv(y)
    zz = Rational(224*3, 500)
    assert_kind_of(Rational, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

  end

  #
  # test division of LongDecimal
  #
  def test_divide
    print "\ntest_divide [#{Time.now}]: "
    x = LongDecimal(224, 2) # 2.24 dx=1 sx=2

    y = LongDecimal(3, 1)   # 0.3  dy=0 sy=1
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -3 -> use 0
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224, 30).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224, 30).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(30, 224).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(30, 224).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                                   # x= 2.24     dx=1 sx=2
    y = LongDecimal(30000000, 8)   # 0.30000000  dy=0 sy=8
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -1 -> use 0
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224, 30).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224, 30).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 1
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(30, 224).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(30, 224).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                            # x= 2.24 dx=1  sx=2
    y = LongDecimal(3, 4)   # 0.0003  dy=-4 sy=4
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -8 -> use 0
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(22400, 3).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(22400, 3).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 2
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(3, 22400).to_ld(2, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(3, 22400).to_ld(2, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                             # x= 2.24 dx=1 sx=2
    y = LongDecimal(3333, 2) # 33.33   dy=2 sy=2
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 1
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224, 3333).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224, 3333).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(3333, 224).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(3333, 224).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                              # x= 2.24 dx=1 sx=2
    y = LongDecimal(33333, 2) # 333.33  dy=3 sy=2
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 2
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224, 33333).to_ld(2, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224, 33333).to_ld(2, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -2 -> use 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(33333, 224).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(33333, 224).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                              # x= 2.24 dx=1 sx=2
    y = LongDecimal(33333, 3) # 33.333  dy=2 sy=3
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 1
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(2240, 33333).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(2240, 33333).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(33333, 2240).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(33333, 2240).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                             # x= 2.24 dx=1 sx=2
    y = LongDecimal(3333, 3) # 3.333   dy=1 sy=3
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 0
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(2240, 3333).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(2240, 3333).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(3333, 2240).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(3333, 2240).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                                  # x= 2.24    dx=1 sx=2
    y = LongDecimal(123456789, 3) # 123456.789 dy=6 sy=3
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 5
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(2240, 123456789).to_ld(5, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(2240, 123456789).to_ld(5, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -5 -> use 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(123456789, 2240).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(123456789, 2240).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                 # x= 2.24 dx=1 sx=2
    y = 5.to_ld  #    5    dy=1 sy=0
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -2 -> use 0
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224, 500).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224, 500).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -2 -> use 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(500, 224).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(500, 224).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                    # x= 2.24 dx=1 sx=2
    y = 5.001.to_ld #         dy=1 sy=3
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 0
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224, 500).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224, 500).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 0
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(500, 224).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(500, 224).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3).to_ld
    # y is has no scale, use scale of x
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224*3, 500).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224*3, 500).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # y is has no scale, use scale of x
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(500, 224*3).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(500, 224*3).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3).to_ld
    z = x.divide(y, ROUND_DOWN)
    zz = Rational(224*3, 500).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide(y, ROUND_UP)
    zz = Rational(224*3, 500).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_DOWN)
    zz = Rational(500, 224*3).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide(x, ROUND_UP)
    zz = Rational(500, 224*3).to_ld(0, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test division of LongDecimal
  #
  def test_divide_complex
    print "\ntest_divide_complex [#{Time.now}]: "
    x = LongDecimal(224, 2) # 2.24 dx=1 sx=2

    y = Complex(5, 3)
    # puts("x=#{x.inspect} y=#{y.inspect}")
    z = x.divide(y, ROUND_DOWN)
    zz = 2.24 / Complex(5, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

  end # test_divide

  #
  # test division of LongDecimal
  #
  def test_divide_s
    print "\ntest_divide_s [#{Time.now}]: "
    x = LongDecimal(224, 2) # 2.24

    y = LongDecimal(3, 1)   # 0.3
    z = x.divide_s(y, 1, ROUND_DOWN)
    zz = Rational(224, 30).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 1, ROUND_UP)
    zz = Rational(224, 30).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_DOWN)
    zz = Rational(30, 224).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_UP)
    zz = Rational(30, 224).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(30000000, 8)   # 0.30000000
    z = x.divide_s(y, 1, ROUND_DOWN)
    zz = Rational(224, 30).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 1, ROUND_UP)
    zz = Rational(224, 30).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 2, ROUND_DOWN)
    zz = Rational(30, 224).to_ld(2, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 20, ROUND_UP)
    zz = Rational(30, 224).to_ld(20, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3, 4)   # 0.0003
    z = x.divide_s(y, 2, ROUND_DOWN)
    zz = Rational(22400, 3).to_ld(2, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 2, ROUND_UP)
    zz = Rational(22400, 3).to_ld(2, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 3, ROUND_DOWN)
    zz = Rational(3, 22400).to_ld(3, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 2, ROUND_UP)
    zz = Rational(3, 22400).to_ld(2, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3333, 2) # 33.33
    z = x.divide_s(y, 4, ROUND_DOWN)
    zz = Rational(224, 3333).to_ld(4, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 30, ROUND_UP)
    zz = Rational(224, 3333).to_ld(30, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 4, ROUND_DOWN)
    zz = Rational(3333, 224).to_ld(4, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_UP)
    zz = Rational(3333, 224).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(33333, 2) # 333.33
    z = x.divide_s(y, 3, ROUND_DOWN)
    zz = Rational(224, 33333).to_ld(3, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 3, ROUND_UP)
    zz = Rational(224, 33333).to_ld(3, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 33, ROUND_DOWN)
    zz = Rational(33333, 224).to_ld(33, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 4, ROUND_UP)
    zz = Rational(33333, 224).to_ld(4, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(33333, 3) # 33.333
    z = x.divide_s(y, 2, ROUND_DOWN)
    zz = Rational(2240, 33333).to_ld(2, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 2, ROUND_UP)
    zz = Rational(2240, 33333).to_ld(2, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 2, ROUND_DOWN)
    zz = Rational(33333, 2240).to_ld(2, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_UP)
    zz = Rational(33333, 2240).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3333, 3) # 3.333
    z = x.divide_s(y, 1, ROUND_DOWN)
    zz = Rational(2240, 3333).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 1, ROUND_UP)
    zz = Rational(2240, 3333).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_DOWN)
    zz = Rational(3333, 2240).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_UP)
    zz = Rational(3333, 2240).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(123456789, 3) # 123456.789
    z = x.divide_s(y, 3, ROUND_DOWN)
    zz = Rational(2240, 123456789).to_ld(3, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 7, ROUND_UP)
    zz = Rational(2240, 123456789).to_ld(7, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 0, ROUND_DOWN)
    zz = Rational(123456789, 2240).to_ld(0, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 9, ROUND_UP)
    zz = Rational(123456789, 2240).to_ld(9, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.to_ld  #    5
    z = x.divide_s(y, 1, ROUND_DOWN)
    zz = Rational(224, 500).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 1, ROUND_UP)
    zz = Rational(224, 500).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_DOWN)
    zz = Rational(500, 224).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_UP)
    zz = Rational(500, 224).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001.to_ld  # 5.001
    z = x.divide_s(y, 1, ROUND_DOWN)
    zz = Rational(224, 500).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 1, ROUND_UP)
    zz = Rational(224, 500).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_DOWN)
    zz = Rational(500, 224).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_UP)
    zz = Rational(500, 224).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3).to_ld(3) # 1.667
    z = x.divide_s(y, 4, ROUND_DOWN)
    zz = Rational(2240, 1667).to_ld(4, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "x=#{x} y=#{y} z=#{z} z=#{z.inspect}")
    z = x.divide_s(y, 1, ROUND_UP)
    zz = Rational(2240, 1667).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # y is has no scale, use scale of x
    z = y.divide_s(x, 1, ROUND_DOWN)
    zz = Rational(1667, 2240).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 1, ROUND_UP)
    zz = Rational(1667, 2240).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3).to_ld
    z = x.divide_s(y, 1, ROUND_DOWN)
    zz = Rational(2240, 1667).to_ld(1, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = x.divide_s(y, 1, ROUND_UP)
    zz = Rational(2240, 1667).to_ld(1, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 2, ROUND_DOWN)
    zz = Rational(1667, 2240).to_ld(2, ROUND_DOWN)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y.divide_s(x, 224, ROUND_UP)
    zz = Rational(1667, 2240).to_ld(224, ROUND_UP)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test division of LongDecimal
  #
  def test_divide_s_complex
    print "\ntest_divide_s_complex [#{Time.now}]: "
    x = LongDecimal(224, 2) # 2.24

    y = Complex(5, 3)
    z = x.divide_s(y, 2, ROUND_DOWN)
    zz = 2.24 / Complex(5, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

  end # test_divide_s

  #
  # test square of LongDecimal
  #
  def test_square
    print "\ntest_square [#{Time.now}]: "
    10.times do |i|
      n = (i*i+i)/2
      x = LongDecimal(n, i)
      y = x.square
      z = LongDecimal(n*n, 2*i)
      assert_equal(y, z, "square i=#{i}")
    end
  end

  #
  # test cube of LongDecimal
  #
  def test_cube
    print "\ntest_cube [#{Time.now}]: "
    10.times do |i|
      n = (i*i+i)/2
      x = LongDecimal(n, i)
      y = x.cube
      z = LongDecimal(n*n*n, 3*i)
      assert_equal(y, z, "cube i=#{i}")
    end
  end

  #
  # test reciprocal of LongDecimal
  #
  def test_reciprocal
    print "\ntest_reciprocal [#{Time.now}]: "
    10.times do |i|
      k = 2*i+1
      n = (k*k+k)/2
      x = LongDecimal(n, i)
      y = x.reciprocal
      z = LongDecimalQuot(Rational(10**i, n), [i+2*(Math.log10(n)-i).floor, 0].max)
      assert_equal(z, y, "reciprocal x=#{x} y=#{y} z=#{z} i=#{i} k=#{k} n=#{n}")
    end
  end

  #
  # test power (**) of LongDecimal
  #
  def test_pow
    print "\ntest_pow [#{Time.now}]: "

    x = LongDecimal(224, 2)

    y = 0.5
    z = x ** y
    zz = Math.sqrt(2.24)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = 0
    z = x ** y
    zz = LongDecimal(1, 0)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be 1")

    y = 1
    z = x ** y
    zz = x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = 2
    z = x ** y
    zz = LongDecimal(224**2, 4)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = LongDecimal(2, 0)
    z = x ** y
    zz = LongDecimal(224**2, 4)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = -1
    z = x ** y
    zz = LongDecimalQuot(Rational(100, 224), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = -2
    z = x ** y
    zz = LongDecimalQuot(Rational(10000, 224**2), 4)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = LongDecimal(5, 1)
    z = x ** y
    zz = Math.sqrt(2.24)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = LongDecimal(5, 1)
    z = 9 ** y
    zz = 3.0
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test division with remainder of LongDecimal
  #
  def test_divmod
    print "\ntest_divmod [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(30, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimal(30000000, 8)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(30, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimal(3330000000, 8)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 3330), 1)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(3330, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5.001
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224), 3)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Rational(5, 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224*3), 2)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 500), 6)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224*3), 3)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Complex(5, 3)
    begin
      q, r = x.divmod y
      assert_fail "should have created TypeError"
    rescue TypeError
      # ignored, expected
    end
  end

  #
  # test dec, dec!, inc and inc! of LongDecimal
  #
  def test_inc_dec
    print "\ntest_inc_dec [#{Time.now}]: "

    x0 = LongDecimal(224, 1)
    x  = LongDecimal(224, 1)
    y  = x.inc
    z  = LongDecimal(234, 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.inc!
    assert_equal(z, x, "z, x")

    x0 = LongDecimal(224, 1)
    x  = LongDecimal(224, 1)
    y  = x.dec
    z  = LongDecimal(214, 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.dec!
    assert_equal(z, x, "z, x")
  end

  #
  # test pred and succ of LongDecimal
  #
  def test_pred_succ
    print "\ntest_pred_succ [#{Time.now}]: "
    x0 = LongDecimal(2245, 2)
    x  = LongDecimal(2245, 2)
    ys = x.succ
    assert_equal(x, x0, "x")
    yp = x.pred
    assert_equal(x, x0, "x")
    zs = LongDecimal(2246, 2)
    zp = LongDecimal(2244, 2)
    assert_equal(zs, ys, "succ")
    assert_equal(zp, yp, "pred")
    y  = LongDecimal(2254, 2)
    n  = (x..y).to_a.size
    assert_equal(10, n, "size")
  end

  #
  # test of &-operator of LongDecimal
  #
  def test_logand
    print "\ntest_logand [#{Time.now}]: "
    x = LongDecimal(224, 2) # 0x0e0 / 100

    y = LongDecimal(3, 1)   # 0x01e / 100
    z = x & y
    zz = LongDecimal(0, 2)  # 0x000 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y & x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(32, 1)  # 0x140 / 100
    z = x & y
    zz = LongDecimal(64, 2) # 0x040 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y & x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5                    # 0x1f4 / 100
    z = x & y
    zz = LongDecimal(224, 2) # 0x0e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y & x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 1                    # 0x064 / 100
    z = x & y
    zz = LongDecimal(96, 2)  # 0x060 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y & x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 256                  # 0x06400 / 100
    z = x & y
    zz = LongDecimal(0, 2)  # 0x000 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y & x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test of |-operator of LongDecimal
  #
  def test_logior
    print "\ntest_logior [#{Time.now}]: "
    x = LongDecimal(224, 2) # 0x0e0 / 100

    y = LongDecimal(3, 1)   # 0x01e / 100
    z = x | y
    zz = LongDecimal(254, 2)  # 0x0fe / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y | x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(32, 1)  # 0x140 / 100
    z = x | y
    zz = LongDecimal(480, 2) # 0x1e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y | x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5                    # 0x1f4 / 100
    z = x | y
    zz = LongDecimal(500, 2) # 0x1f4 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y | x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 1                    # 0x064 / 100
    z = x | y
    zz = LongDecimal(228, 2)  # 0x0e4 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y | x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 256                  # 0x06400 / 100
    z = x | y
    zz = LongDecimal(25824, 2)   # 0x064e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y | x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test of ^-operator of LongDecimal
  #
  def test_logxor
    print "\ntest_logxor [#{Time.now}]: "
    x = LongDecimal(224, 2) # 0x0e0 / 100

    y = LongDecimal(3, 1)   # 0x01e / 100
    z = x ^ y
    zz = LongDecimal(254, 2)  # 0x0fe / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y ^ x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(32, 1)  # 0x140 / 100
    z = x ^ y
    zz = LongDecimal(416, 2) # 0x1a0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y ^ x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5                    # 0x1f4 / 100
    z = x ^ y
    zz = LongDecimal(276, 2) # 0x114 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y ^ x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 1                    # 0x064 / 100
    z = x ^ y
    zz = LongDecimal(132, 2)  # 0x084 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y ^ x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 256                  # 0x06400 / 100
    z = x ^ y
    zz = LongDecimal(25824, 2)   # 0x064e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y ^ x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test of ^-operator of LongDecimal
  #
  def test_lognot
    print "\ntest_lognot [#{Time.now}]: "
    x = LongDecimal(224, 2) # 0x0e0 / 100
    y = ~x
    z = LongDecimal(-225, 2)
    assert_kind_of(LongDecimal, y, "y=#{y.inspect}")
    assert_equal(z, y, "y=#{y.inspect}")
    x = LongDecimal(0, 2) # 0x00 / 100
    y = ~x
    z = LongDecimal(-1, 2)
    assert_kind_of(LongDecimal, y, "y=#{y.inspect}")
    assert_equal(z, y, "y=#{y.inspect}")
  end

  #
  # test << and >> of LongDecimal
  #
  def test_shift
    print "\ntest_shift [#{Time.now}]: "
    n = 12345678901234567890
    x = LongDecimal(n, 9)
    y = x << 5
    yy = LongDecimal(n * 32, 9)
    z = y >> 5
    assert_equal(yy, y, "shift left")
    assert_equal(x, z, "shift left then right")

    y = x >> 5
    yy = LongDecimal(n >> 5, 9)
    z = y << 5
    zz = LongDecimal((n >> 5) << 5, 9)
    assert_equal(yy, y, "shift right")
    assert_equal(zz, z, "shift right then left")
  end

  #
  # test [] access to digits
  #
  def test_bin_digit
    print "\ntest_bin_digit [#{Time.now}]: "
    n = 12345678901234567890
    x = LongDecimal(n, 9)
    100.times do |i|
      assert_equal(n[i], x[i], "i=#{i}")
    end
    n = -12345678901234567890
    x = LongDecimal(n, 9)
    100.times do |i|
      assert_equal(n[i], x[i], "i=#{i}")
    end
  end

  #
  # test move_point_left and move_point_right
  #
  def test_move_point
    print "\ntest_move_point [#{Time.now}]: "
    n = 12345678901234567890
    x = LongDecimal(n, 9)

    y = x.move_point_left(4)
    yy = x.move_point_right(-4)
    assert_equal(y, yy, "left / right 4")
    z = LongDecimal(n, 13)
    assert_equal(y, z, "left 4")
    w = y.move_point_right(4)
    assert_equal(x, w, "left 4 right 4")

    y = x.move_point_left(12)
    yy = x.move_point_right(-12)
    assert_equal(y, yy, "left / right 12")
    z = LongDecimal(n, 21)
    assert_equal(y, z, "left 12")
    w = y.move_point_right(12)
    assert_equal(x, w, "left 12 right 12")

    y = x.move_point_right(4)
    z = LongDecimal(n, 5)
    assert_equal(y, z, "right 4")
    w = y.move_point_left(4)
    ww = y.move_point_right(-4)
    assert_equal(w, ww, "left / right 4")
    assert_equal(x, w, "right 4 left 4")

    y = x.move_point_right(12)
    yy = x.move_point_left(-12)
    assert_equal(y, yy, "left / right 12")
    z = LongDecimal(n * 1000, 0)
    assert_equal(y, z, "left 12")
    w = y.move_point_left(12)
    v = x.round_to_scale(12)
    assert_equal(v, w, "right 12 left 12")

    y = x.move_point_left(12)
    yy = x.move_point_right(-12)
    assert_equal(y, yy, "left / right 12")
    z = LongDecimal(n, 21)
    assert_equal(y, z, "left 12")
    w = y.move_point_right(12)
    assert_equal(x, w, "right 12 left 12")
  end

  #
  # test moving of decimal point of LongDecimal
  #
  def test_move_point2
    print "\ntest_move_point2 [#{Time.now}]: "
    x = LongDecimal(224, 2)

    y = x.move_point_left(0)
    assert_equal(x, y, "point not moved")
    y = x.move_point_right(0)
    assert_equal(x, y, "point not moved")

    z = LongDecimal(224, 3)
    y = x.move_point_left(1)
    assert_equal(z, y, "0.224")
    y = x.move_point_right(-1)
    assert_equal(z, y, "0.224")

    z = LongDecimal(224, 1)
    y = x.move_point_left(-1)
    assert_equal(z, y, "22.4")
    y = x.move_point_right(1)
    assert_equal(z, y, "22.4")

    z = LongDecimal(224, 5)
    y = x.move_point_left(3)
    assert_equal(z, y, "0.00224")
    y = x.move_point_right(-3)
    assert_equal(z, y, "0.00224")

    z = LongDecimal(2240, 0)
    y = x.move_point_left(-3)
    assert_equal(z, y, "2240")
    y = x.move_point_right(3)
    assert_equal(z, y, "2240")
  end

  #
  # test sqrt of LongDecimal
  #
  def test_sqrt
    print "\ntest_sqrt [#{Time.now}]: "

    # sqrt of 0 is always 0 without need to round
    x = LongDecimal.zero!(101)
    y = check_sqrt(x, 120, ROUND_UNNECESSARY, 0, 0, "zero")
    assert(y.zero?, "sqrt(0)")

    # sqrt of 1 is always 1 without need to round
    x = LongDecimal.one!(101)
    y = check_sqrt(x, 120, ROUND_UNNECESSARY, 0, 0, "one")
    assert(y.one?, "sqrt(1)")

    # sqrt of 2 always gets rounded somehow
    x = LongDecimal.two!(101)
    x.freeze
    y0 = check_sqrt(x, 120, ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 120, ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.square")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 140, ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 140, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 140, ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.square")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 160, ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 160, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 160, ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.square")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 120, ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 120, ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.square")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 100, ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 100, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 100, ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.square")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    # sqrt of 3 always gets rounded somehow
    x = 3.to_ld
    y0 = check_sqrt(x, 120, ROUND_DOWN, 0, 1, "three")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, ROUND_HALF_EVEN, -1, 1, "three")
    y2 = check_sqrt(x, 120, ROUND_UP, -1, 0, "three")
    assert(y2.pred.square < x, "y2.pred.square")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    # sqrt of 4 always gets rounded somehow
    x  = 4.to_ld(101)
    y0 = check_sqrt(x, 120, ROUND_DOWN, 0, 0, "four")
    y1 = check_sqrt(x, 120, ROUND_HALF_EVEN, 0, 0, "four")
    y2 = check_sqrt(x, 120, ROUND_UP, 0, 0, "four")
    assert_equal(y0, y1, "y0 y1")
    assert_equal(y1, y2, "y1 y2")
  end

  #
  # test sqrt_with_remainder of LongDecimal
  #
  def test_sqrt_with_remainder
    print "\ntest_sqrt_with_remainder [#{Time.now}]: "
    x = LongDecimal.zero!(101)
    r = check_sqrt_with_remainder(x, 120, "zero")
    assert(r.zero?, "rsqrt(0)")

    x = LongDecimal.one!(101)
    r = check_sqrt_with_remainder(x, 120, "one")
    assert(r.zero?, "rsqrt(1)")

    x = LongDecimal.two!(101)
    check_sqrt_with_remainder(x, 120, "two")
    check_sqrt_with_remainder(x, 140, "two")
    check_sqrt_with_remainder(x, 160, "two")
    check_sqrt_with_remainder(x, 100, "two")

    x = 3.to_ld
    check_sqrt_with_remainder(x, 120, "three")
    check_sqrt_with_remainder(x, 140, "three")
    check_sqrt_with_remainder(x, 160, "three")
    check_sqrt_with_remainder(x, 100, "three")

    x  = 4.to_ld.round_to_scale(101)
    r = check_sqrt_with_remainder(x, 120, "four")
    assert(r.zero?, "rsqrt(4)")

    x = 5.to_ld
    check_sqrt_with_remainder(x, 120, "five")
  end

  # test sqare roots that come to lie exactly on the geometric mean of the two rounding candidates
  def test_sqrt_on_geometric_boundary
    print "\ntest_sqrt_on_geometric_boundary [#{Time.now}]: "
    1.upto(100) do |int_val|
      100.times do |scale|
        y_lower = LongDecimal(int_val, scale)
        y_upper = y_lower.succ
        x = y_lower * y_upper
        msg = "x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} "
        # puts msg
        [ ROUND_GEOMETRIC_UP, ROUND_GEOMETRIC_CEILING ].each do |mode|
          y = LongMath.sqrt(x, scale, mode)
          assert_equal(y_upper, y, msg + "y=#{y} mode=#{mode}")
        end
        [ ROUND_GEOMETRIC_DOWN, ROUND_GEOMETRIC_FLOOR ].each do |mode|
          y = LongMath.sqrt(x, scale, mode)
          assert_equal(y_lower, y, msg + "y=#{y} mode=#{mode}")
        end
        y = LongMath.sqrt(x, scale, ROUND_GEOMETRIC_EVEN)
        assert(y == y_lower || y == y_upper, msg + "y=#{y} mode=#{ROUND_GEOMETRIC_EVEN}")
        assert(y[0] == 0, msg + "y=#{y} mode=#{ROUND_GEOMETRIC_EVEN}")
        y = LongMath.sqrt(x, scale, ROUND_GEOMETRIC_ODD)
        assert(y == y_lower || y == y_upper, msg + "y=#{y} mode=#{ROUND_GEOMETRIC_ODD}")
        assert(y[0] == 1, msg + "y=#{y} mode=#{ROUND_GEOMETRIC_ODD}")
      end
    end
  end

  # test sqare roots that come to lie exactly on the geometric mean of the two rounding candidates
  def test_sqrt_zero_on_geometric_boundary
    print "\ntest_sqrt_on_geometric_boundary [#{Time.now}]: "
    100.times do |scale|
      y_lower = LongDecimal(0, scale)
      y_upper = y_lower.succ
      x = y_lower * y_upper
      msg = "x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} "
      ALL_MINOR.each do |minor|
        if (minor == MINOR_UNUSED)
          next
        end
        mode = MODE_LOOKUP[[MAJOR_GEOMETRIC, minor]]
        y = LongMath.sqrt(x, scale, mode)
        assert_equal(0, y, msg + "y=#{y} mode=#{mode}")
      end
    end
  end

  # test sqare roots that come to lie exactly on the quadratic mean of the two rounding candidates
  def test_sqrt_on_quadratic_boundary
    print "\ntest_sqrt_on_quadratic_boundary [#{Time.now}]: "
    100.times do |int_val|
      100.times do |scale|
        y_lower = LongDecimal(int_val, scale)
        y_upper = y_lower.succ
        x = LongMath.arithmetic_mean(2*scale + 2, ROUND_HALF_EVEN, y_lower * y_lower, y_upper * y_upper)
        msg = "x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} "
        # puts msg
        [ ROUND_QUADRATIC_UP, ROUND_QUADRATIC_CEILING ].each do |mode|
          y = LongMath.sqrt(x, scale, mode)
          assert_equal(y_upper, y, msg + "y=#{y} mode=#{mode}")
        end
        [ ROUND_QUADRATIC_DOWN, ROUND_QUADRATIC_FLOOR ].each do |mode|
          y = LongMath.sqrt(x, scale, mode)
          assert_equal(y, y_lower, msg + "y=#{y} mode=#{mode}")
        end
        y = LongMath.sqrt(x, scale, ROUND_QUADRATIC_EVEN)
        assert(y == y_lower || y == y_upper, msg + "y=#{y} mode=#{ROUND_QUADRATIC_EVEN}")
        assert(y[0] == 0, msg + "y=#{y} mode=#{ROUND_QUADRATIC_EVEN}")
        y = LongMath.sqrt(x, scale, ROUND_QUADRATIC_ODD)
        assert(y == y_lower || y == y_upper, msg + "y=#{y} mode=#{ROUND_QUADRATIC_ODD}")
        assert(y[0] == 1, msg + "y=#{y} mode=#{ROUND_QUADRATIC_ODD}")
      end
    end
  end

  #
  # test LongMath.sqrt with non-LongDecimal arguments
  #
  def test_non_ld_sqrt
    print "\ntest_non_ld_sqrt [#{Time.now}]: "
    xi = 77
    yi = LongMath.sqrt(xi, 31, ROUND_HALF_EVEN)
    zi = yi.square.round_to_scale(30, ROUND_HALF_EVEN)
    assert(zi.is_int?, "zi=#{zi.to_s}")
    assert_equal(xi, zi.to_i, "zi")

    xf = 77.0
    yf = LongMath.sqrt(xf, 31, ROUND_HALF_EVEN)
    zf = yf.square.round_to_scale(30, ROUND_HALF_EVEN)
    assert(zf.is_int?, "zf")
    assert_equal(xf, zf.to_f, "zf")
    assert_equal(yi, yf, "i-f")

    xr = Rational(224, 227)
    yr = LongMath.sqrt(xr, 31, ROUND_HALF_EVEN)
    zr = yr.square.round_to_scale(30, ROUND_HALF_EVEN)
    assert((zr-xr).abs <= zr.unit, "zr-xr")
  end

  #
  # test cbrt of LongDecimal
  #
  def test_cbrt
    print "\ntest_cbrt [#{Time.now}]: "
    x = LongDecimal.zero!(101)
    y = check_cbrt(x, 120, ROUND_UNNECESSARY, 0, 0, "zero")
    assert(y.zero?, "cbrt(0)")

    x = LongDecimal.one!(101)
    y = check_cbrt(x, 120, ROUND_UNNECESSARY, 0, 0, "one")
    assert(y.one?, "cbrt(1)")

    x = LongDecimal.two!(101)
    y0 = check_cbrt(x, 120, ROUND_DOWN, 0, 1, "two")
    assert(y0.cube < x, "y0**3")
    assert(y0.succ.cube > x, "(y0.succ).cube")
    y1 = check_cbrt(x, 120, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_cbrt(x, 120, ROUND_UP, -1, 0, "two")
    assert(y2.pred.cube < x, "y2.pred.cube")
    assert(y2.cube > x, "y2**3")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_cbrt(x, 140, ROUND_DOWN, 0, 1, "two")
    assert(y0.cube < x, "y0**3")
    assert(y0.succ.cube > x, "(y0.succ).cube")
    y1 = check_cbrt(x, 140, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_cbrt(x, 140, ROUND_UP, -1, 0, "two")
    assert(y2.pred.cube < x, "y2.pred.cube")
    assert(y2.cube > x, "y2**3")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_cbrt(x, 160, ROUND_DOWN, 0, 1, "two")
    assert(y0.cube < x, "y0**3")
    assert(y0.succ.cube > x, "(y0.succ).cube")
    y1 = check_cbrt(x, 160, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_cbrt(x, 160, ROUND_UP, -1, 0, "two")
    assert(y2.pred.cube < x, "y2.pred.cube")
    assert(y2.cube > x, "y2**3")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_cbrt(x, 120, ROUND_DOWN, 0, 1, "two")
    assert(y0.cube < x, "y0**3")
    assert(y0.succ.cube > x, "(y0.succ).cube")
    y1 = check_cbrt(x, 120, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_cbrt(x, 120, ROUND_UP, -1, 0, "two")
    assert(y2.pred.cube < x, "y2.pred.cube")
    assert(y2.cube > x, "y2**3")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_cbrt(x, 100, ROUND_DOWN, 0, 1, "two")
    assert(y0.cube < x, "y0**3")
    assert(y0.succ.cube > x, "(y0.succ).cube")
    y1 = check_cbrt(x, 100, ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_cbrt(x, 100, ROUND_UP, -1, 0, "two")
    assert(y2.pred.cube < x, "y2.pred.cube")
    assert(y2.cube > x, "y2**3")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    x = 3.to_ld
    y0 = check_cbrt(x, 120, ROUND_DOWN, 0, 1, "three")
    assert(y0.cube < x, "y0**3")
    assert(y0.succ.cube > x, "(y0.succ).cube")
    y1 = check_cbrt(x, 120, ROUND_HALF_EVEN, -1, 1, "three")
    y2 = check_cbrt(x, 120, ROUND_UP, -1, 0, "three")
    assert(y2.pred.cube < x, "y2.pred.cube")
    assert(y2.cube > x, "y2**3")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    x  = 8.to_ld(101)
    y0 = check_cbrt(x, 120, ROUND_DOWN, 0, 0, "eight")
    y1 = check_cbrt(x, 120, ROUND_HALF_EVEN, 0, 0, "eight")
    y2 = check_cbrt(x, 120, ROUND_UP, 0, 0, "eight")
    assert_equal(y0, y1, "y0 y1")
    assert_equal(y1, y2, "y1 y2")
  end

  #
  # test cbrt_with_remainder of LongDecimal
  #
  def test_cbrt_with_remainder
    print "\ntest_cbrt_with_remainder [#{Time.now}]: "
    x = LongDecimal.zero!(101)
    r = check_cbrt_with_remainder(x, 120, "zero")
    assert(r.zero?, "rcbrt(0)")

    x = LongDecimal.one!(101)
    r = check_cbrt_with_remainder(x, 120, "one")
    assert(r.zero?, "rcbrt(1)")

    x = LongDecimal.two!(101)
    check_cbrt_with_remainder(x, 120, "two")
    check_cbrt_with_remainder(x, 140, "two")
    check_cbrt_with_remainder(x, 160, "two")
    check_cbrt_with_remainder(x, 100, "two")

    x = 3.to_ld
    check_cbrt_with_remainder(x, 120, "three")
    check_cbrt_with_remainder(x, 140, "three")
    check_cbrt_with_remainder(x, 160, "three")
    check_cbrt_with_remainder(x, 100, "three")

    x  = 8.to_ld.round_to_scale(101)
    r = check_cbrt_with_remainder(x, 120, "four")
    assert(r.zero?, "rcbrt(8)")

    x = 5.to_ld
    check_cbrt_with_remainder(x, 120, "five")
  end

  # test sqare roots that come to lie exactly on the cubic mean of the two rounding candidates
  def test_cbrt_on_cubic_boundary
    print "\ntest_cbrt_on_cubic_boundary [#{Time.now}]: "
    100.times do |int_val|
      100.times do |scale|
        y_lower = LongDecimal(int_val, scale)
        y_upper = y_lower.succ
        x = LongMath.arithmetic_mean(3*scale + 2, ROUND_HALF_EVEN, y_lower.cube(), y_upper.cube())
        msg = "x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} "
        # puts msg
        [ ROUND_CUBIC_UP, ROUND_CUBIC_CEILING ].each do |mode|
          y = LongMath.cbrt(x, scale, mode)
          assert_equal(y_upper, y, msg + "y=#{y} mode=#{mode}")
        end
        [ ROUND_CUBIC_DOWN, ROUND_CUBIC_FLOOR ].each do |mode|
          y = LongMath.cbrt(x, scale, mode)
          assert_equal(y, y_lower, msg + "y=#{y} mode=#{mode}")
        end
        y = LongMath.cbrt(x, scale, ROUND_CUBIC_EVEN)
        assert(y == y_lower || y == y_upper, msg + "y=#{y} mode=#{ROUND_CUBIC_EVEN}")
        assert(y[0] == 0, msg + "y=#{y} mode=#{ROUND_CUBIC_EVEN}")
        y = LongMath.cbrt(x, scale, ROUND_CUBIC_ODD)
        assert(y == y_lower || y == y_upper, msg + "y=#{y} mode=#{ROUND_CUBIC_ODD}")
        assert(y[0] == 1, msg + "y=#{y} mode=#{ROUND_CUBIC_ODD}")
      end
    end
  end

  #
  # test LongMath.cbrt with non-LongDecimal arguments
  #
  def test_non_ld_cbrt
    print "\ntest_non_ld_cbrt [#{Time.now}]: "
    xi = 77
    yi = LongMath.cbrt(xi, 32, ROUND_HALF_EVEN)
    zi = yi.cube.round_to_scale(30, ROUND_HALF_EVEN)
    assert(zi.is_int?, "zi=#{zi.to_s}")
    assert_equal(xi, zi.to_i, "zi")

    xf = 77.0
    yf = LongMath.cbrt(xf, 32, ROUND_HALF_EVEN)
    zf = yf.cube.round_to_scale(30, ROUND_HALF_EVEN)
    assert(zf.is_int?, "zf")
    assert_equal(xf, zf.to_f, "zf")
    assert_equal(yi, yf, "i-f")

    xr = Rational(224, 227)
    yr = LongMath.cbrt(xr, 32, ROUND_HALF_EVEN)
    zr = yr.cube.round_to_scale(30, ROUND_HALF_EVEN)
    assert((zr-xr).abs <= zr.unit, "zr-xr")
  end

  #
  # test absolute value of LongDecimal
  #
  def test_abs
    print "\ntest_abs [#{Time.now}]: "
    x = LongDecimal(-224, 2)
    y = x.abs
    assert_equal(-x, y, "abs of negative")
    x = LongDecimal(224, 2)
    y = x.abs
    assert_equal(x, y, "abs of positive")
    x = LongDecimal(0, 2)
    y = x.abs
    assert_equal(x, y, "abs of zero")
  end

  #
  # test ufo-operator (<=>) of LongDecimal
  #
  def test_ufo
    print "\ntest_ufo [#{Time.now}]: "
    x = LongDecimal(224, 2)

    z = x <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")
    y = LongDecimal(2240, 3)
    z = y <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3, 1)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

  end

  #
  # test is_int? of LongDecimal
  #
  def test_is_int
    print "\ntest_is_int [#{Time.now}]: "
    assert(LongDecimal(1, 0).is_int?, "1, 0")
    assert(LongDecimal(90, 1).is_int?, "90, 1")
    assert(LongDecimal(200, 2).is_int?, "200, 2")
    assert(LongDecimal(1000000, 6).is_int?, "1000000, 6")

    assert(! LongDecimal(1, 1).is_int?, "1, 1")
    assert(! LongDecimal(99, 2).is_int?, "99, 2")
    assert(! LongDecimal(200, 3).is_int?, "200, 3")
    assert(! LongDecimal(1000001, 6).is_int?, "1000001, 6")
    assert(! LongDecimal(1000000, 7).is_int?, "1000000, 7")
  end

  #
  # test zero? of LongDecimal
  #
  def test_zero
    print "\ntest_zero [#{Time.now}]: "
    assert(LongDecimal(0, 1000).zero?, "0, 1000")
    assert(LongDecimal(0, 0).zero?, "0, 0")
    assert(LongDecimal.zero!(100).zero?, "0, 100")
    assert(! LongDecimal(1, 1000).zero?, "1, 1000")
    assert(! LongDecimal(1, 0).zero?, "1, 0")
    assert(! LongDecimal.one!(100).zero?, "1, 0")
  end

  #
  # test one? of LongDecimal
  #
  def test_one
    print "\ntest_one [#{Time.now}]: "
    assert(LongDecimal(10**1000, 1000).one?, "1, 1000")
    assert(LongDecimal(1, 0).one?, "1, 0")
    assert(LongDecimal.one!(100).one?, "1, 100")
    assert(! LongDecimal(0, 1000).one?, "0, 1000")
    assert(! LongDecimal(2, 1000).one?, "2, 1000")
    assert(! LongDecimal(0, 0).one?, "0, 0")
    assert(! LongDecimal.zero!(100).one?, "0, 0")
    assert(! LongDecimal.two!(100).one?, "2, 0")
  end

  #
  # test sign-method of LongDecimal
  #
  def test_sgn
    print "\ntest_sgn [#{Time.now}]: "
    x = LongDecimal(0, 5)
    s = x.sgn
    assert_equal(0, s, "must be 0")
    x = LongDecimal(4, 5)
    s = x.sgn
    assert_equal(1, s, "must be 1")
    x = LongDecimal(-3, 5)
    s = x.sgn
    assert_equal(-1, s, "must be -1")
  end

  #
  # test equality-comparison (==) of LongDecimal
  #
  def test_equal
    print "\ntest_equal [#{Time.now}]: "
    x = LongDecimal(224, 2)
    y = LongDecimal(2240, 3)
    assert((x <=> y) == 0, "diff is zero")
    assert_equal(x, y, "equal")
    assert(x == y, "equal ==")
    assert(x === y, "equal ===")
    assert(! (x.eql? y), "not eql?")
    assert((y <=> x) == 0, "diff is yero")
    assert_equal(y, x, "equal")
    assert(y == x, "equal ==")
    assert(y === x, "equal ===")
    assert(! (y.eql? x), "not eql?")
    assert_equal(x, x, "x equals x")
    assert_equal(y, y, "y equals y")
  end

  #
  # test value-equality-comparison (===) of LongDecimal
  #
  def test_val_equal
    print "\ntest_val_equal [#{Time.now}]: "
    x = LongDecimal(224, 2)
    y = LongDecimal(2240, 3)
    assert(x === y, "value equal")
    assert(y === x, "value equal")
    assert(x == y, "but not equal")
    assert(y == x, "but not equal")
    assert_val_equal(x, y)
    assert_val_equal(y, x)
    assert_val_equal(x, x)
    assert_val_equal(y, y)
    assert(! (x.eql? y), "not eql?")
    assert(! (y.eql? x), "not eql?")
    assert(x === x, "x equals x")
    assert(y === y, "y equals y")
    x = 1.to_ld(100)
    y = 1
    assert(x === y, "value equal")
    assert(x == y, "but not equal")
    assert(x === x, "x equals x")
    assert(y === y, "y equals y")
    assert(! (x.eql? y), "not eql?")
    assert(! (y.eql? x), "not eql?")
    x = LongDecimal(123456, 3)
    y = Rational(123456, 1000)
    assert(x === y, "value equal")
    assert(x == y, "but not equal")
    assert(x === x, "x equals x")
    assert(y === y, "y equals y")
    assert(! (x.eql? y), "not eql? x=#{x.inspect} y=#{y.inspect}")
    assert(! (y.eql? x), "not eql? x=#{x.inspect} y=#{y.inspect}")
  end

  #
  # test unit() of LongDecimal
  #
  def test_unit
    print "\ntest_unit [#{Time.now}]: "
    10.times do |i|
      x = LongDecimal.zero!(i)
      u = x.unit
      v = LongDecimal(1, i)
      assert_equal(u, v, "unit i=#{i}")
      n = i*i
      x = i.to_ld(n)
      u = x.unit
      v = LongDecimal(1, n)
      assert_equal(u, v, "unit i=#{i}")
      n = i*i+i
      x = (-i).to_ld(n)
      u = x.unit
      v = LongDecimal(1, n)
      assert_equal(u, v, "unit i=#{i}")
    end
  end

  #
  # test sunit() of LongDecimal
  #
  def test_sunit
    print "\ntest_sunit [#{Time.now}]: "
    10.times do |i|
      x = LongDecimal.zero!(i)
      u = x.sunit
      v = LongDecimal(0, i)
      assert_equal(u, v, "unit i=#{i}")
      n = i*i
      k = 2*i+1
      x = k.to_ld(n)
      u = x.sunit
      v = LongDecimal(1, n)
      assert_equal(u, v, "unit i=#{i}")
      n = i*i+i
      k = -2*i-1
      x = k.to_ld(n)
      u = x.sunit
      v = LongDecimal(-1, n)
      assert_equal(u, v, "unit i=#{i}")
    end
  end

  #
  # test denominator of LongDecimal
  #
  def test_denominator
    print "\ntest_denominator [#{Time.now}]: "
    x = LongDecimal("-2.20")
    assert_equal(100, x.denominator, "-2.20")
    x = LongDecimal("2.20")
    assert_equal(100, x.denominator, "2.20")
    x = LongDecimal("2.2400")
    assert_equal(10000, x.denominator, "2.2400")
    x = LongDecimal(-1, 2)
    assert_equal(100, x.denominator, "-1 2")
    x = LongDecimal(-221, 1)
    assert_equal(10, x.denominator, "-221 1")
    x = LongDecimal(-224, 0)
    assert_equal(1, x.denominator, "-224 0")
    x = LongDecimal(-3, 5)
    assert_equal(100000, x.denominator, "-3 5")
    x = LongDecimal(0, 20)
    assert_equal(10**20, x.denominator, "0 20")
    x = LongDecimal(30000000, 8)
    assert_equal(10**8, x.denominator, "30000000 8")
    x = LongDecimal(3330000000, 8)
    assert_equal(10**8, x.denominator, "3330000000 8")

  end

  #
  # test construction of LongDecimalQuot from LongDecimal
  #
  def test_ldq_ld_init
    print "\ntest_ldq_ld_init [#{Time.now}]: "
    x = LongDecimal(224, 2) # 2.24  dx=1 sx=2
    y = LongDecimal(225, 3) # 0.225 dy=0 sy=3
    z = LongDecimalQuot(x, y)
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(2240, 225), 0)
    assert_equal(zz, z, "2240/225")

    z = LongDecimalQuot(y, x)
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(225, 2240), 1)
    assert_equal(zz, z, "225/2240")
  end

  #
  # test sint_digits10 of LongDecimalQuot
  #
  def test_ldq_sint_digits10
    print "\ntest_ldq_sint_digits10 [#{Time.now}]: "
    assert_equal(nil, LongDecimalQuot(LongDecimal("0.0000"), 1.to_ld).sint_digits10, "0.0000")
    assert_equal(-3, LongDecimalQuot(LongDecimal("0.0009"), 1.to_ld).sint_digits10, "0.0009")
    assert_equal(-2, LongDecimalQuot(LongDecimal("0.0099"), 1.to_ld).sint_digits10, "0.0099")
    assert_equal(-1, LongDecimalQuot(LongDecimal("0.0999"), 1.to_ld).sint_digits10, "0.0999")
    assert_equal(0, LongDecimalQuot(LongDecimal("0.9999"), 1.to_ld).sint_digits10, "0.9999")
    assert_equal(1, LongDecimalQuot(LongDecimal("1.0000"), 1.to_ld).sint_digits10, "1.0000")
    assert_equal(1, LongDecimalQuot(LongDecimal("9.9999"), 1.to_ld).sint_digits10, "9.9999")
    assert_equal(2, LongDecimalQuot(LongDecimal("10.0000"), 1.to_ld).sint_digits10, "10.0000")
    assert_equal(2, LongDecimalQuot(LongDecimal("99.9999"), 1.to_ld).sint_digits10, "99.9999")
    assert_equal(3, LongDecimalQuot(LongDecimal("100.0000"), 1.to_ld).sint_digits10, "100.0000")
    assert_equal(3, LongDecimalQuot(LongDecimal("999.9999"), 1.to_ld).sint_digits10, "999.9999")

    assert_equal(nil, LongDecimalQuot(LongDecimal("-0.0000"), 1.to_ld).sint_digits10, "-0.0000")
    assert_equal(0, LongDecimalQuot(LongDecimal("-0.9999"), 1.to_ld).sint_digits10, "-0.9999")
    assert_equal(1, LongDecimalQuot(LongDecimal("-1.0000"), 1.to_ld).sint_digits10, "-1.0000")
    assert_equal(1, LongDecimalQuot(LongDecimal("-9.9999"), 1.to_ld).sint_digits10, "-9.9999")
    assert_equal(2, LongDecimalQuot(LongDecimal("-10.0000"), 1.to_ld).sint_digits10, "-10.0000")
    assert_equal(2, LongDecimalQuot(LongDecimal("-99.9999"), 1.to_ld).sint_digits10, "-99.9999")
    assert_equal(3, LongDecimalQuot(LongDecimal("-100.0000"), 1.to_ld).sint_digits10, "-100.0000")
    assert_equal(3, LongDecimalQuot(LongDecimal("-999.9999"), 1.to_ld).sint_digits10, "-999.9999")
    x = LongDecimalQuot(1234.to_ld, 1.to_ld)
    assert_equal(4, x.sint_digits10, "1234")
    assert_equal(4, x.sint_digits10, "1234")
    x = LongDecimalQuot(1234.to_ld(10), 1.to_ld)
    assert_equal(4, x.sint_digits10, "1234")
    assert_equal(4, x.sint_digits10, "1234")

    10.times do |i|
      f = 1
      g = 1
      n = (i*i+i)/2
      f, g = g, f+g
      x = LongDecimal(Rational((n+1)*f, (n+2)*g), 3*i)
      y = 1/x
      assert_equal(x.to_r.to_ld.sint_digits10(), x.sint_digits10(), "x=#{x} f=#{f} g=#{g} i=#{i} n=#{n}")
      assert_equal(y.to_r.to_ld.sint_digits10(), y.sint_digits10(), "y=#{y} f=#{f} g=#{g} i=#{i} n=#{n}")
    end
  end

  #
  # test rounding of LongDecimalQuot with ROUND_UP
  #
  def test_ldq_round_to_scale_up
    print "\ntest_ldq_round_to_scale_up [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    # 1.0
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_UP)
    assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_DOWN
  #
  def test_ldq_round_to_scale_down
    print "\ntest_ldq_round_to_scale_down [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    # 0.9
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("-0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_CEILING
  #
  def test_ldq_round_to_scale_ceiling
    print "\ntest_ldq_round_to_scale_ceiling [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("-0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_CEILING)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_FLOOR
  #
  def test_ldq_round_to_scale_floor
    print "\ntest_ldq_round_to_scale_floor [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_FLOOR)
    assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_UP
  #
  def test_ldq_round_to_scale_half_up
    print "\ntest_ldq_round_to_scale_half_up [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_HALF_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_HALF_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("56.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_UP)
    assert_equal("-56.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_DOWN
  #
  def test_ldq_round_to_scale_half_down
    print "\ntest_ldq_round_to_scale_half_down [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_HALF_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_HALF_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_DOWN)
    assert_equal("-56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_CEILING
  #
  def test_ldq_round_to_scale_half_ceiling
    print "\ntest_ldq_round_to_scale_half_ceiling [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_HALF_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_HALF_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("56.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_CEILING)
    assert_equal("-56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_FLOOR
  #
  def test_ldq_round_to_scale_half_floor
    print "\ntest_ldq_round_to_scale_half_floor [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_HALF_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_HALF_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_FLOOR)
    assert_equal("-56.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_EVEN
  #
  def test_ldq_round_to_scale_half_even
    print "\ntest_ldq_round_to_scale_half_even [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_HALF_EVEN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_HALF_EVEN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.75
    l = LongDecimalQuot(Rational(227, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_EVEN)
    assert_equal("56.8", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("227/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_ODD
  #
  def test_ldq_round_to_scale_half_odd
    print "\ntest_ldq_round_to_scale_half_odd [#{Time.now}]: "

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, ROUND_HALF_ODD)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, ROUND_HALF_ODD)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("56.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.75
    l = LongDecimalQuot(Rational(227, 4), 0)
    r = l.round_to_scale(1, ROUND_HALF_ODD)
    assert_equal("56.7", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("227/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_GEOMETRIC_*
  #
  def test_round_to_scale_geometric_common_ldq
    print "\ntest_round_to_scale_geometric_common [#{Time.now}]: "
    ALL_ROUNDING_MODES.each do |rounding_mode|
      unless (rounding_mode.major == MAJOR_GEOMETRIC)
        next
      end

      # close to sqrt(2), but > sqrt(2)
      l = LongDecimalQuot(Rational(175568277047523, 124145519261542), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(2, r, "l=#{l.inspect} r=#{r.inspect}")
      assert_kind_of(LongDecimal, r, "must be LongDecimal")

      # close to sqrt(2), but < sqrt(2)
      l = LongDecimalQuot(Rational(72722761475561,51422757785981), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")
      assert_kind_of(LongDecimal, r, "must be LongDecimal")

      # close to sqrt(6), but > sqrt(6)
      l = LongDecimalQuot(Rational(4122760103977442405, 1683109764441408998), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(3, r, "l=#{l.inspect} r=#{r.inspect}")
      assert_kind_of(LongDecimal, r, "must be LongDecimal")
      
      # close to sqrt(6), but < sqrt(6)
      l = LongDecimalQuot(Rational(1853138378693569178, 756540575094624409), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(2, r, "l=#{l.inspect} r=#{r.inspect}")
      assert_kind_of(LongDecimal, r, "must be LongDecimal")
      
    end
  end
  def test_ldq_round_to_scale_harmonic_common
    print "\ntest_ldq_round_to_scale_harmonic_common [#{Time.now}]: "

    delta = Rational(3, 5463458053)
    arr = [ Rational(112, 15), Rational(12, 5), Rational(144, 17), Rational(180, 19), Rational(24, 7), Rational(4, 3), Rational(40, 9), Rational(60, 11), Rational(84, 13) ]    

    ALL_ROUNDING_MODES.each do |rounding_mode|
      unless (rounding_mode.major == MAJOR_HARMONIC)
        next
      end
      # only 0 gets rounded to zero
      l = LongDecimalQuot(Rational(0, 1), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(0, r, "l=#{l.inspect} r=#{r.inspect}")

      l = LongDecimalQuot(Rational(1, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(50, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(99, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(100, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")

      l = LongDecimalQuot(Rational(1, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(50, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(99, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(101, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(1, r, "l=#{l.inspect} r=#{r.inspect}")

      l = LongDecimalQuot(Rational(-1, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(-50, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(-99, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(-100, 100), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")

      l = LongDecimalQuot(Rational(-1, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(-50, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(-99, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")
      l = LongDecimalQuot(Rational(-101, 101), 0)
      r = l.round_to_scale(0, rounding_mode)
      assert_equal(-1, r, "l=#{l.inspect} r=#{r.inspect}")

      arr.each do |rat|
        rat_up = rat + delta
        rat_down = rat - delta
        [ -1, 1].each do |sign|
          l_up = LongDecimalQuot(sign * rat_up, 0)
          r_up            = l_up.round_to_scale(0, rounding_mode)
          r_up_expected   = l_up.round_to_scale(0, ROUND_UP)
          assert_equal(r_up_expected, r_up, "l=#{l_up} r=#{r_up}")

          l_down = LongDecimalQuot(sign * rat_down, 0)
          r_down          = l_down.round_to_scale(0, rounding_mode)
          r_down_expected = l_down.round_to_scale(0, ROUND_DOWN)
          assert_equal(r_down_expected, r_down, "l=#{l_down} r=#{r_down}")
        end
      end
    end
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HARMONIC_UP
  #
  def test_ldq_round_to_scale_harmonic_up
    print "\ntest_ldq_round_to_scale_harmonic_up [#{Time.now}]: "

    arr = [ Rational(0, 1), Rational(112, 15), Rational(12, 5), Rational(144, 17), Rational(180, 19), Rational(24, 7), Rational(4, 3), Rational(40, 9), Rational(60, 11), Rational(84, 13) ]    
    arr.each do |rat|
      [ -1, 1].each do |sign|
        l = LongDecimalQuot(sign * rat, 0)
        r = l.round_to_scale(0, ROUND_HARMONIC_UP)
        re = l.round_to_scale(0, ROUND_UP)
        assert_equal(re, r, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HARMONIC_DOWN
  #
  def test_ldq_round_to_scale_harmonic_down
    print "\ntest_ldq_round_to_scale_harmonic_down [#{Time.now}]: "

    arr = [ Rational(0, 1), Rational(112, 15), Rational(12, 5), Rational(144, 17), Rational(180, 19), Rational(24, 7), Rational(4, 3), Rational(40, 9), Rational(60, 11), Rational(84, 13) ]    
    arr.each do |rat|
      [ -1, 1].each do |sign|
        l = LongDecimalQuot(sign * rat, 0)
        r = l.round_to_scale(0, ROUND_HARMONIC_DOWN)
        re = l.round_to_scale(0, ROUND_DOWN)
        assert_equal(re, r, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HARMONIC_CEILING
  #
  def test_ldq_round_to_scale_harmonic_ceiling
    print "\ntest_ldq_round_to_scale_harmonic_ceiling [#{Time.now}]: "

    arr = [ Rational(0, 1), Rational(112, 15), Rational(12, 5), Rational(144, 17), Rational(180, 19), Rational(24, 7), Rational(4, 3), Rational(40, 9), Rational(60, 11), Rational(84, 13) ]    
    arr.each do |rat|
      [ -1, 1].each do |sign|
        l = LongDecimalQuot(sign * rat, 0)
        r = l.round_to_scale(0, ROUND_HARMONIC_CEILING)
        re = l.round_to_scale(0, ROUND_CEILING)
        assert_equal(re, r, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HARMONIC_FLOOR
  #
  def test_ldq_round_to_scale_harmonic_floor
    print "\ntest_ldq_round_to_scale_harmonic_floor [#{Time.now}]: "

    arr = [ Rational(0, 1), Rational(112, 15), Rational(12, 5), Rational(144, 17), Rational(180, 19), Rational(24, 7), Rational(4, 3), Rational(40, 9), Rational(60, 11), Rational(84, 13) ]    
    arr.each do |rat|
      [ -1, 1].each do |sign|
        l = LongDecimalQuot(sign * rat, 0)
        r = l.round_to_scale(0, ROUND_HARMONIC_FLOOR)
        re = l.round_to_scale(0, ROUND_FLOOR)
        assert_equal(re, r, "l=#{l.inspect} r=#{r.inspect}")
      end
    end
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HARMONIC_EVEN
  #
  def test_ldq_round_to_scale_harmonic_odd_even
    print "\ntest_ldq_round_to_scale_harmonic_even [#{Time.now}]: "

    sorted_arr = [ Rational(0, 1), Rational(112, 15), Rational(12, 5), Rational(144, 17), Rational(180, 19), Rational(24, 7), Rational(4, 3), Rational(40, 9), Rational(60, 11), Rational(84, 13) ].sort
    sorted_arr.each_with_index do |rat, idx|
      [ -1, 1].each do |sign|
        l = LongDecimalQuot(sign * rat, 0)
        r_even = l.round_to_scale(0, ROUND_HARMONIC_EVEN)
        r_odd  = l.round_to_scale(0, ROUND_HARMONIC_ODD)
        r_up   = l.round_to_scale(0, ROUND_UP)
        r_down = l.round_to_scale(0, ROUND_DOWN)
        msg = "l=#{l} r_even=#{r_even} r_odd=#{r_odd} r_up=#{r_up} r_down=#{r_down}"
        if (idx[0] == 1)
          # idx is odd, lower is odd, upper is even
          assert_equal(r_down, r_odd, msg)
          assert_equal(r_up, r_even, msg)
        else
          # idx is even, lower is even, upper is odd
          assert_equal(r_down, r_even, msg)
          assert_equal(r_up, r_odd, msg)
        end
      end
    end
  end

  # TODO: do tests with rational numbers that approach square and cube roots with continuos fractions
  # TODO: do tests for harmonic that are exact matches
  # def test_ldq_round_to_scale_harmonic_common
  # def test_ldq_round_to_scale_harmonic_*
  # def test_ldq_round_to_scale_quadratic_common
  # def test_ldq_round_to_scale_cubic_common
  # mean(0, 1) h ~= 0/1 (0.0) g ~= 0/1 (0.0) q ~= 299713796309065/423859315570607 (1.9679385874457762e-30) c ~= 337341605343292547068/425023789577343100997 (2.546731871064025e-42)
  # mean(1, 2) h ~= 4/3 (0.0) g ~= 1023286908188737/723573111879672 (6.752897635419861e-31) q ~= 23846123348/15081612629 (2.0854303781806646e-21) c ~= 1264485856748642214079/765907763214316254917 (2.341487333471613e-43)
  # mean(2, 3) h ~= 12/5 (0.0) g ~= 40811117693184120001/16661069030161929800 (7.353407803354322e-40) q ~= 25856179418443/10141627953969 (4.7669213433003236e-27) c ~= 130317599353787806/50194606598524623 (1.0194225879933293e-34)
  # mean(3, 4) h ~= 24/7 (0.0) g ~= 37746084314912758705537/10896355970034596022808 (1.2156731255721638e-45) q ~= 2770146928257146/783515871141485 (8.062828940523879e-31) c ~= 65054809624513623527805/18222541364766376259984 (1.4263838803714024e-45)
  # mean(4, 5) h ~= 40/9 (0.0) g ~= 5990827771012465337616001/1339589813747741660217960 (6.230334061151362e-50) q ~= 92403703427267777/20408563968881417 (1.1931105708159184e-33) c ~= 27536350369366267133/6045456623512535631 (1.783613870656984e-39)
  # mean(5, 6) h ~= 60/11 (0.0) g ~= 338393251269110482793304001/61781872342535164104912440 (2.39159284498137e-53) q ~= 1528340730817793536/276738936543513861 (6.501929239683091e-36) c ~= 18445843787390826070206/3326521989432668429605 (4.343570347610687e-44)
  # mean(6, 7) h ~= 84/13 (0.0) g ~= 9672960393029404726599279937/1492570192695070347200265352 (3.4631861064329583e-56) q ~= 15831918095780075543/2428505377152489569 (8.452997822861375e-38) c ~= 43194459093730958049773639/6606439098706068232729732 (6.452945557933787e-51)
  # mean(7, 8) h ~= 112/15 (0.0) g ~= 170501414157423382892554080001/22784209847768795287357709400 (1.2870874242905067e-58) q ~= 117401968953584936678/15618925616670593309 (2.0450537665966083e-39) c ~= 23163390907237800671596/3074846428596721223467 (2.43070947465473e-44)
  # mean(8, 9) h ~= 144/17 (0.0) g ~= 2094232192940929332692027310337/246807630834617549117003218088 (9.673565793967815e-61) q ~= 677554204864960054861/79574705782782444345 (7.882606437575206e-41) c ~= 16494872556711104462640974/1933904552804480955126907 (3.375307469892163e-52)
  # mean(9, 10) h ~= 180/19 (0.0) g ~= 19436609957075163398170578312001/2048798581888835718525995453560 (1.25559685699217e-62) q ~= 3217679993183604208172/338235011608384785077 (4.36447689651277e-42) c ~= 4040882504079593293406169/424184267363823167289599 (5.119042192153957e-48)
  # mean(0, 1) h ~= 0/1 (0.0) g ~= 0/1 (0.0) q ~= 723573111879672/1023286908188737 (-3.37644881770993e-31) c ~= 398671229182667544523/502294273634706089874 (-2.137393750784152e-42)
  # mean(1, 2) h ~= 4/3 (0.0) g ~= 2470433131948081/1746860020068409 (-1.1586140636036394e-31) q ~= 33084728831/20924619775 (-1.0833682629414323e-21) c ~= 7983356873301848162633/4835574058134930397778 (-3.5858556337917903e-44)
  # mean(2, 3) h ~= 12/5 (0.0) g ~= 181588649567339818802/74133255753507979601 (-7.428450391352243e-41) q ~= 31539468564008/12370797358171 (-3.203745054824327e-27) c ~= 437504922685864439/168514364813585683 (-1.628184145355699e-35)
  # mean(3, 4) h ~= 24/7 (0.0) g ~= 243994524585153428390307/70435152225016546773961 (-8.728140345695666e-47) q ~= 3194006243827753/903401389665111 (-6.064870522018085e-31) c ~= 94325334839741823802096/26421525568725160973013 (-6.506001879715734e-46)
  # mean(4, 5) h ~= 40/9 (0.0) g ~= 50755107359004694554823204/11349187026003431978487841 (-3.4720461729514965e-51) q ~= 103239425127933986/22801774535935219 (-9.558027890799877e-34) c ~= 405017207655713031707/88919334908765308046 (-7.665057177567606e-41)
  # mean(5, 6) h ~= 60/11 (0.0) g ~= 3545422426621607337113893205/647302612981786303317866201 (-1.0893430351002485e-54) q ~= 1673583259997467187/303038218016281903 (-5.422355247603378e-36) c ~= 26287533511969072424225/4740691685532407357821 (-1.997577655798479e-44)
  # mean(6, 7) h ~= 84/13 (0.0) g ~= 120725710451369382942006824406/18628381549199826809800872049 (-1.333970913870012e-57) q ~= 17096528857980129916/2622487812977895435 (-7.248730253002441e-38) c ~= 141921637091497334861749467/21706410310615968627949355 (-5.204540995912305e-52)
  # mean(7, 8) h ~= 112/15 (0.0) g ~= 2469425650577016216339910286407/329990883091804949904058045801 (-4.2950690275918784e-60) q ~= 125489370909157465373/16694857568256031111 (-1.7899529166734255e-39) c ~= 78048336057621933825693/10360600844054638832392 (-7.082927802678382e-45)
  # mean(8, 9) h ~= 144/17 (0.0) g ~= 34524006963619898197960450185032/4068693239617869725628053055041 (-2.8476318939995986e-62) q ~= 718581561374612616758/84393124441923679651 (-7.008188830942463e-41) c ~= 13066622360223262042660757775/1531967002796357371560298349 (-1.7195867967307405e-57)
  # mean(9, 10) h ~= 180/19 (0.0) g ~= 359321361983671685250874795628409/37875797194074684864904537394041 (-3.306493658740672e-64) q ~= 3391485110226381595111/356504999893452273759 (-3.928602329403955e-42) c ~= 4295228807568894669728554/450883806460389984994863 (-1.0950226742693802e-49)
  # mean(0, 1) h ~= 0/1 (0.0) g ~= 0/1 (0.0) q ~= 1746860020068409/2470433131948081 (5.793070318018198e-32) c ~= 736012834525960091591/927318063212049190871 (9.512366582172961e-45)
  # mean(1, 2) h ~= 4/3 (0.0) g ~= 5964153172084899/4217293152016490 (1.9878674620197703e-32) q ~= 56930852179/36006232404 (2.439184431065993e-22) c ~= 9247842730050490376712/5601481821349246652695 (1.0603672415656038e-45)
  # mean(2, 3) h ~= 12/5 (0.0) g ~= 403988416827863757605/164927580537177889002 (7.504258799792064e-42) q ~= 57395647982451/22512425312140 (3.869623893616697e-28) c ~= 567822522039652245/218708971412110306 (1.0851074788258209e-35)
  # mean(3, 4) h ~= 24/7 (0.0) g ~= 525735133485219615486151/151766660420067689570730 (6.266522825229495e-48) q ~= 5964153172084899/1686917260806596 (4.969668655049426e-32) c ~= 159380144464255447329901/44644066933491537232997 (1.9717042745476204e-46)
  # mean(4, 5) h ~= 40/9 (0.0) g ~= 107501042489021854447262409/24037963865754605617193642 (1.934905016133173e-52) q ~= 195643128555201763/43210338504816636 (5.914495922637801e-35) c ~= 432553558025079298840/94964791532277843677 (4.177382334519244e-41)
  # mean(5, 6) h ~= 60/11 (0.0) g ~= 7429238104512325157021090411/1356387098306107770740644842 (4.961832239177257e-56) q ~= 3201923990815260723/579777154559795764 (2.6933815925306123e-37) c ~= 44733377299359898494431/8067213674965075787426 (6.171997780816237e-45)
  # mean(6, 7) h ~= 84/13 (0.0) g ~= 251124381295768170610612928749/38749333291094723966802009450 (5.138269629072973e-59) q ~= 32928446953760205459/5050993190130385004 (3.00622840034924e-39) c ~= 468959370368222962635022040/71725670030553974116577797 (1.2184509578403745e-52)
  # mean(7, 8) h ~= 112/15 (0.0) g ~= 5109352715311455815572374652815/682765976031378695095473801002 (1.4332839870569088e-61) q ~= 242891339862742402051/32313783184926624420 (6.370450816719585e-41) c ~= 101211726964859734497289/13435447272651360055859 (1.0101604156774369e-46)
  # mean(8, 9) h ~= 144/17 (0.0) g ~= 71142246120180725728612927680401/8384194110070357000373109328170 (8.382645630818271e-64) q ~= 1396135766239572671619/163967830224706123996 (2.18415623968481e-42) c ~= 3227472217847702435641669811399/378397783595253075256348819110 (5.464464480892508e-60)
  # mean(9, 10) h ~= 180/19 (0.0) g ~= 738079333924418533899920169568819/77800392970038205448335070241642 (8.707333292855206e-66) q ~= 6609165103409985803283/694740011501837058836 (1.0889328306773457e-43) c ~= 188735721229542064091733991/19812187945160592522068708 (2.4422743422735027e-51)


  #
  # test rounding of LongDecimalQuot with ROUND_UNNECESSARY
  #
  def test_ldq_round_to_scale_unnecessary
    print "\ntest_ldq_round_to_scale_unnecessary [#{Time.now}]: "
    l = LongDecimalQuot(Rational(225, 4), 5)
    r = l.round_to_scale(2, ROUND_UNNECESSARY)
    assert_equal("56.25", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    begin
      r = l.round_to_scale(1, ROUND_UNNECESSARY)
      assert_fail("should not have succeeded l=#{l.inspect} r=#{r.inspect}")
    rescue ArgumentError
      # ignored
    end
  end

  #
  # test conversion of LongDecimalQuot to String
  #
  def test_ldq_to_s
    print "\ntest_ldq_to_s [#{Time.now}]: "
    l = LongDecimalQuot(Rational(224, 225), 226)
    assert_equal("224/225[226]", l.to_s, "l=#{l.inspect}")
    l = LongDecimalQuot(Rational(-224, 225), 226)
    assert_equal("-224/225[226]", l.to_s, "l=#{l.inspect}")
  end

  #
  # test conversion of LongDecimalQuot to Rational
  #
  def test_ldq_to_r
    print "\ntest_ldq_to_r [#{Time.now}]: "
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    r = l.to_r
    assert_kind_of(Rational, r, "must be rational")
    assert_equal(rr, r, "must be equal")
    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    r = l.to_r
    assert_kind_of(Rational, r, "must be rational")
    assert_equal(rr, r, "must be equal")
    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    r = l.to_r
    assert_kind_of(Rational, r, "must be rational")
    assert_equal(rr, r, "must be equal")
  end

  #
  # test conversion of LongDecimalQuot to Float
  #
  def test_ldq_to_f
    print "\ntest_ldq_to_f [#{Time.now}]: "
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    f = l.to_f
    ff = rr.to_f
    assert_kind_of(Float, f, "must be float")
    assert_equal(ff, f, "must be equal")
    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    f = l.to_f
    ff = rr.to_f
    assert_kind_of(Float, f, "must be float")
    assert_equal(ff, f, "must be equal")
    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    f = l.to_f
    ff = rr.to_f
    assert_kind_of(Float, f, "must be float")
    assert_equal(ff, f, "must be equal")
  end

  #
  # test conversion to BigDecimal
  #
  def test_ldq_to_bd
    print "\ntest_ldq_to_bd [#{Time.now}]: "
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    b = l.to_bd
    bb = BigDecimal(rr.to_f.to_s)
    assert_kind_of(BigDecimal, b, "must be bd")
    assert((b - bb).abs < 0.000001, "l=#{l.inspect}")

    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    b = l.to_bd
    bb = BigDecimal(rr.to_f.to_s)
    assert_kind_of(BigDecimal, b, "must be bd")
    assert((b - bb).abs < 0.000001, "l=#{l.inspect}")

    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    b = l.to_bd
    bb = BigDecimal(rr.to_f.to_s)
    assert_kind_of(BigDecimal, b, "must be bd")
    assert((b - bb).abs < 0.000001, "l=#{l.inspect}")
  end

  #
  # test to_i of LongDecimalQuot
  #
  def test_ldq_to_i
    print "\ntest_ldq_to_i [#{Time.now}]: "
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    i = l.to_i
    ii = rr.to_i
    assert_kind_of(Integer, i, "must be integer")
    assert_equal(ii, i, "must be equal")
    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    i = l.to_i
    ii = rr.to_i
    assert_kind_of(Integer, i, "must be integer")
    assert_equal(ii, i, "must be equal")
    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    i = l.to_i
    ii = rr.to_i
    assert_kind_of(Integer, i, "must be integer")
    assert_equal(ii, i, "must be equal")
  end

  #
  # test to_ld of LongDecimalQuot
  #
  def test_ldq_to_ld
    print "\ntest_ldq_to_ld [#{Time.now}]: "
    x = LongDecimalQuot(1, 100)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(100, y.scale, "scale is 100")
    assert(y.one?, "must be one")
    x = LongDecimalQuot(Rational(13, 9), 10)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(10, y.scale, "scale is 10")
    assert_equal(LongDecimal("1.4444444444"), y, "1.44...")
    x = LongDecimalQuot(Rational(14, 9), 10)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(10, y.scale, "scale is 10")
    assert_equal(LongDecimal("1.5555555556"), y, "1.55... y=#{y} x=#{x}")
    x = LongDecimalQuot(Rational(7, 20), 1)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(1, y.scale, "scale is 1")
    assert_equal(LongDecimal("0.4"), y, "0.4")
    x = LongDecimalQuot(Rational(7, 2), 1)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(1, y.scale, "scale is 1")
    assert_equal(LongDecimal("3.5"), y, "3.5")
  end

  #
  # test negation operator (unary -) of LongDecimalQuot
  #
  def test_ldq_negation
    print "\ntest_ldq_negation [#{Time.now}]: "
    x = LongDecimalQuot(Rational(0, 2), 3)
    assert_equal(-x, x, "x and -x are equal for negative x=#{x.inspect}")
    x = LongDecimalQuot(Rational(224, 225), 226)
    yy = LongDecimalQuot(Rational(-224, 225), 226)
    y = -x
    assert_equal(-1, y.sgn, "sign of y must be -1 y=#{y.inspect}")
    assert_equal(226, y.scale, "scale of y must be 2 y=#{y.inspect}")
    assert_equal(yy, y, "yy and y must be equal")
  end

  #
  # test addition operator (binary +) of LongDecimalQuot
  #
  def test_ldq_add
    print "\ntest_ldq_add [#{Time.now}]: "
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x + y
    zz = LongDecimalQuot(Rational(583, 450), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x + y
    zz = LongDecimalQuot(Rational(1349, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x + y
    zz = LongDecimalQuot(Rational(53969, 9000), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x + y
    zz = LongDecimalQuot(Rational(599, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x + y
    zz = LongDecimalQuot(Rational(599, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x + y
    zz = Complex(5+224.0/225.0, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test subtraction operator (binary -) of LongDecimalQuot
  #
  def test_ldq_sub
    print "\ntest_ldq_sub [#{Time.now}]: "
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x - y
    zz = LongDecimalQuot(Rational(313, 450), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(-313, 450), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x - y
    zz = LongDecimalQuot(Rational(-901, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(901, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x - y
    zz = LongDecimalQuot(Rational(-36049, 9000), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(36049, 9000), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x - y
    zz = LongDecimalQuot(Rational(-151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x - y
    zz = LongDecimalQuot(Rational(-151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x - y
    zz = Complex(224.0/225.0 -5, -3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
    zz = -zz
    z = y - x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
  end

  #
  # test multiplication operator (*) of LongDecimalQuot
  #
  def test_ldq_mul
    print "\ntest_ldq_mul [#{Time.now}]: "
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x * y
    zz = LongDecimalQuot(Rational(224*3, 2250), 227)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 225), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x * y
    zz = LongDecimalQuot(Rational(46676, 9375), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 225*3), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 225*3), 226+3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x * y
    zz = Complex(224.0/45.0, 224.0/75.0)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
    z = y * x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
  end

  #
  # test division operator (/) of LongDecimalQuot
  #
  def test_ldq_div
    print "\ntest_ldq_div [#{Time.now}]: "
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x / y
    zz = LongDecimalQuot(Rational(2240, 225*3), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    zz = LongDecimalQuot(Rational(225*3, 2240), 1)
    z = y / x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x / y
    zz = LongDecimalQuot(Rational(224, 225*5), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(225*5, 224), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x / y
    zz = LongDecimalQuot(Rational(8960, 45009), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(45009, 8960), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x / y
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(225*5, 224*3), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x / y
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(225*5, 224*3), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x / y
    zz = Complex(112.0/765.0, -112.0/1275.0)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
    z = y / x
    zz = Complex(1125.0/224.0, 675.0/224.0)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
  end

  #
  # test power operator (**) of LongDecimalQuot
  #
  def test_ldq_pow
    print "\ntest_ldq_pow [#{Time.now}]: "

    x = LongDecimalQuot(Rational(224, 225), 226)

    y = 0.5
    z = x ** y
    zz = Math.sqrt(224.0/225.0)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = 0
    z = x ** y
    zz = LongDecimalQuot(Rational(1, 1), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be 1")

    y = 1
    z = x ** y
    zz = x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = 2
    z = x ** y
    zz = LongDecimalQuot(Rational(224**2, 225**2), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = LongDecimal(2, 0)
    z = x ** y
    zz = LongDecimalQuot(Rational(224**2, 225**2), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = -1
    z = x ** y
    zz = LongDecimalQuot(Rational(225, 224), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = -2
    z = x ** y
    zz = LongDecimalQuot(Rational(225**2, 224**2), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = LongDecimal(5, 1)
    z = x ** y
    zz = Math.sqrt(2.24/2.25)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = LongDecimal(5, 1)
    z = 9 ** y
    zz = 3.0
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test divmod of LongDecimalQuot for division with remainder
  #
  def test_ldq_divmod
    print "\ntest_ldq_divmod [#{Time.now}]: "
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*10, 225*3), 226)
    assert_equal(zz, q + r / y, "z=#{(q+r/y).inspect} y=#{y.inspect} q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*3, 224*10), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 225*5), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*5, 224), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5.001
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(8960, 45009), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(45009, 8960), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Rational(5, 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*5, 224*3), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect} x=#{x.inspect} r/x=#{(r/x).inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*5, 224*3), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Complex(5, 3)
    begin
      q, r = x.divmod y
      assert_fail "should have created TypeError"
    rescue TypeError
      # ignored, expected
    end
  end

  #
  # test dec, dec!, inc and inc! of LongDecimalQuot
  #
  def test_ldq_inc_dec
    print "\ntest_ldq_inc_dec [#{Time.now}]: "

    x0 = LongDecimalQuot(Rational(224, 225), 1)
    x  = LongDecimalQuot(Rational(224, 225), 1)
    y  = x.inc
    z  = LongDecimalQuot(Rational(449, 225), 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.inc!
    assert_equal(z, x, "z, x")

    x0 = LongDecimalQuot(Rational(224, 225), 1)
    x  = LongDecimalQuot(Rational(224, 225), 1)
    y  = x.dec
    z  = LongDecimalQuot(Rational(-1, 225), 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.dec!
    assert_equal(z, x, "z, x")
  end

  #
  # test absolute value of LongDecimalQuot
  #
  def test_ldq_abs
    print "\ntest_ldq_abs [#{Time.now}]: "
    x = LongDecimalQuot(Rational(-224, 225), 226)
    y = x.abs
    assert_equal(-x, y, "abs of negative")
    x = LongDecimalQuot(Rational(224, 225), 226)
    y = x.abs
    assert_equal(x, y, "abs of positive")
    x = LongDecimalQuot(Rational(0, 2), 3)
    y = x.abs
    assert_equal(x, y, "abs of zero")
  end

  #
  # test ufo operator (<=>) of LongDecimalQuot
  #
  def test_ldq_ufo
    print "\ntest_ldq_ufo [#{Time.now}]: "
    x = LongDecimalQuot(Rational(224, 225), 226)

    z = x <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")
    y = LongDecimalQuot(Rational(224, 225), 0)
    z = y <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3, 1)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

  end

  #
  # test is_int? of LongDecimalQuot
  #
  def test_ldq_is_int
    print "\ntest_ldq_is_int [#{Time.now}]: "
    assert(! LongDecimalQuot(Rational(1, 2), 0).is_int?, "1, 2")
    assert(! LongDecimalQuot(Rational(90, 91), 1).is_int?, "90, 91")
    assert(! LongDecimalQuot(Rational(200, 3), 2).is_int?, "200, 3")
    assert(! LongDecimalQuot(Rational(3333333, 1000000), 6).is_int?, "3333333, 1000000")

    assert(LongDecimalQuot(1, 1).is_int?, "1, 1")
    assert(LongDecimalQuot(99, 2).is_int?, "99, 2")
    assert(LongDecimalQuot(200, 3).is_int?, "200, 3")
    assert(LongDecimalQuot(1000001, 6).is_int?, "1000001, 6")
    assert(LongDecimalQuot(1000000, 7).is_int?, "1000000, 7")
  end

  #
  # test zero? of LongDecimalQuot
  #
  def test_ldq_zero
    print "\ntest_ldq_zero [#{Time.now}]: "
    assert(LongDecimalQuot(0, 1000).zero?, "0, 1000")
    assert(LongDecimalQuot(0, 0).zero?, "0, 0")
    assert(! LongDecimalQuot(1, 1000).zero?, "1, 1000")
    assert(! LongDecimalQuot(1, 0).zero?, "1, 0")
  end

  #
  # test one? of LongDecimalQuot
  #
  def test_ldq_one
    print "\ntest_ldq_one [#{Time.now}]: "
    assert(LongDecimalQuot(1, 1000).one?, "1, 1000")
    assert(LongDecimalQuot(1, 0).one?, "1, 0")
    assert(! LongDecimalQuot(0, 1000).one?, "0, 1000")
    assert(! LongDecimalQuot(2, 1000).one?, "2, 1000")
    assert(! LongDecimalQuot(0, 0).one?, "0, 0")
  end

  #
  # test sign method of LongDecimalQuot
  #
  def test_ldq_sgn
    print "\ntest_ldq_sgn [#{Time.now}]: "
    x = LongDecimalQuot(Rational(0, 5), 1000)
    s = x.sgn
    assert_equal(0, s, "must be 0")
    x = LongDecimalQuot(Rational(4, 5), 6)
    s = x.sgn
    assert_equal(1, s, "must be 1")
    x = LongDecimalQuot(Rational(-3, 5), 7)
    s = x.sgn
    assert_equal(-1, s, "must be -1")
  end

  #
  # test equality operator (==) of LongDecimalQuot
  #
  def test_ldq_equal
    print "\ntest_ldq_equal [#{Time.now}]: "
    x = LongDecimalQuot(Rational(224, 225), 226)
    y = LongDecimalQuot(Rational(224, 225), 227)
    assert((x <=> y) == 0, "diff is zero")
    assert(x == y, "but not equal")
    assert(x === y, "but not equal")
    assert_equal(x, x, "x equals x")
    assert_equal(y, y, "y equals y")
    assert(! (x.eql? y), "! #{x.inspect} eql? #{y.inspect}")
    assert(! (y.eql? x), "! #{y.inspect} eql? #{x.inspect}")
  end

  def test_means_one_param
    print "\ntest_means_one_param [#{Time.now}]: "
    [ -1, 0, 1, 7, -1.0, 0.0, 1.0, Math::PI, Rational(-1, 1), Rational(0, 1), Rational(1,1), Rational(2,3), LongDecimal(-10000000000, 10), LongDecimal(-1, 10), LongDecimal(0, 10), LongDecimal(10000000000, 10), LongMath.pi(100) ].each do |x|
      # , Complex(-1, -2), Complex(0,0), Complex(Rational(3, 2), LongDecimal(4, 3))
      12.times do |prec|
        ALL_ROUNDING_MODES.each do |rm|
          if (rm == ROUND_UNNECESSARY)
            next
          end
          xx = x.to_ld(prec, rm)
          text = "x=#{x} xx=#{xx} rm=#{rm} prec=#{prec}"
          assert_equal(xx, LongMath.arithmetic_mean(prec, rm, x), text)
          assert_equal(xx, LongMath.geometric_mean(prec, rm, x), text)
          if (x.sgn != 0)
            assert_equal(xx, LongMath.harmonic_mean(prec, rm, x), text)
          end
          assert_equal(xx, LongMath.quadratic_mean(prec, rm, x), text)
          assert_equal(xx, LongMath.cubic_mean(prec, rm, x), text)
        end
      end
    end
  end

  def test_means_two_param
    print "\ntest_means_two_param [#{Time.now}] (20 sec): "
    arr = [ 0, 1, 2, 7, 0.0, 1.0, 2.0, Math::PI, Rational(40, 9), Rational(0, 1), Rational(1,1), Rational(2,3), LongDecimal(3333333333333333, 10), LongDecimal(33, 10), LongDecimal(0, 10), LongDecimal(10000000000, 10), LongMath.pi(100) ]
    arr.each do |x|
      arr.each do |y|
        print "."
        12.times do |prec|
          ALL_ROUNDING_MODES.each do |rm|
            if (rm == ROUND_UNNECESSARY)
              next
            end
            xx = x.to_ld(prec, rm)
            yy = y.to_ld(prec, rm)
            mi = [xx, yy].min
            am = LongMath.arithmetic_mean(prec, rm, x, y)
            gm = LongMath.geometric_mean(prec, rm, x, y)
            if (x.sgn == 0 || y.sgn == 0)
              hm = gm
            else
              hm = LongMath.harmonic_mean(prec, rm, x, y)
            end
            qm = LongMath.quadratic_mean(prec, rm, x, y)
            cm = LongMath.cubic_mean(prec, rm, x, y)
            ma = [xx, yy].max
            text = "mi=#{mi} hm=#{hm} gm=#{gm} am=#{am} qm=#{qm} cm=#{cm} ma=#{ma} prec=#{prec} rm=#{rm} x=#{x} y=#{y}"
            assert(mi <= hm.succ, text)
            assert(hm <= gm.succ, text)
            assert(gm <= am.succ, text)
            assert(am <= qm.succ, text)
            assert(qm <= cm.succ, text)
            assert(cm <= ma.succ, text)
            if (x == y)
              assert_equal(mi, hm, text)
              assert_equal(hm, gm, text)
              assert_equal(gm, am, text)
              assert_equal(am, qm, text)
              assert_equal(qm, cm, text)
              assert_equal(cm, ma, text)
            end
          end
        end
      end
    end
  end

  def test_means_two_param_round_up
    print "\ntest_means_two_param_round_up [#{Time.now}] (20 sec): "
    arr = [ 0, 1, 2, 7, 0.0, 1.0, 2.0, Math::PI, Rational(40, 9), Rational(0, 1), Rational(1,1), Rational(2,3), LongDecimal(3333333333333333, 10), LongDecimal(33, 10), LongDecimal(0, 10), LongDecimal(10000000000, 10), LongMath.pi(100) ]
    x = Math::PI
    y = Math::PI
    print "."
    prec = 0
    rm = ROUND_UP
    xx = x.to_ld(prec, rm)
    yy = y.to_ld(prec, rm)
    mi = [xx, yy].min
    am = LongMath.arithmetic_mean(prec, rm, x, y)
    gm = LongMath.geometric_mean(prec, rm, x, y)
    if (x.sgn == 0 || y.sgn == 0)
      hm = gm
    else
      hm = LongMath.harmonic_mean(prec, rm, x, y)
    end
    qm = LongMath.quadratic_mean(prec, rm, x, y)
    cm = LongMath.cubic_mean(prec, rm, x, y)
    ma = [xx, yy].max

    text = "mi=#{mi} hm=#{hm} gm=#{gm} am=#{am} qm=#{qm} cm=#{cm} ma=#{ma} prec=#{prec} rm=#{rm} x=#{x} y=#{y}"
    assert(mi <= hm.succ, text)
    assert(hm <= gm.succ, text)
    assert(gm <= am.succ, text)
    assert(am <= qm.succ, text)
    assert(qm <= cm.succ, text)
    assert(cm <= ma.succ, text)
    if (x == y)
      assert_equal(mi, hm, text)
      assert_equal(hm, gm, text)
      assert_equal(gm, am, text)
      assert_equal(am, qm, text)
      assert_equal(qm, cm, text)
      assert_equal(cm, ma, text)
    end
  end

  # test the right ordering of the means excluding agm/hgm
  def test_means_three_param
    print "\ntest_means_three_param [#{Time.now}] (4 min): "
    # arr = [ 0, 1, 2, 0.0, 1.0, Math::PI, Rational(40, 9), Rational(0, 1), Rational(1,1), LongDecimal(3333333333333333, 10), LongDecimal(0, 10), LongDecimal(10000000000, 10), LongMath.pi(100) ]
    arr = [ 1, 2, 1.0, Math::PI, Rational(40, 9), Rational(1,1), LongDecimal(3333333333333333, 10), LongMath.pi(100) ]
    arr.each do |x|
      arr.each do |y|
        print ":"
        arr.each do |z|
          print "."
          # 12.times do |prec|
          [0,1,2,5,10,11,12].each do |prec|
            ALL_ROUNDING_MODES.each do |rm|
              if (rm == ROUND_UNNECESSARY)
                next
              end
              xx = x.to_ld(prec, rm)
              yy = y.to_ld(prec, rm)
              zz = z.to_ld(prec, rm)
              mi = [xx, yy, zz].min
              am = LongMath.arithmetic_mean(prec, rm, x, y, z)
              gm = LongMath.geometric_mean(prec, rm, x, y, z)
              if (x.sgn == 0 || y.sgn == 0 || z.sgn == 0)
                hm = gm
              else
                hm = LongMath.harmonic_mean(prec, rm, x, y, z)
              end
              qm = LongMath.quadratic_mean(prec, rm, x, y, z)
              cm = LongMath.cubic_mean(prec, rm, x, y, z)
              ma = [xx, yy, zz].max
              text = "mi=#{mi} hm=#{hm} gm=#{gm} am=#{am} qm=#{qm} cm=#{cm} ma=#{ma} prec=#{prec} rm=#{rm} x=#{x} y=#{y} z=#{z}"
              assert(mi <= hm.succ, text)
              assert(hm <= gm.succ, text)
              assert(gm <= am.succ, text)
              assert(am <= qm.succ, text)
              assert(qm <= cm.succ, text)
              assert(cm <= ma.succ, text)
              if (x == y && y == z)
                assert_equal(mi, hm, text)
                assert_equal(hm, gm, text)
                assert_equal(gm, am, text)
                assert_equal(am, qm, text)
                assert_equal(qm, cm, text)
                assert_equal(cm, ma, text)
              end
            end
          end
        end
      end
    end
  end

  # test the right ordering of the means (including agm/hgm)
  def test_means_three_param_agm_hgm
    print "\ntest_means_three_param_agm_hgm [#{Time.now}] (4 min): "
    # arr = [ 0, 1, 2, 0.0, 1.0, Math::PI, Rational(40, 9), Rational(0, 1), Rational(1,1), LongDecimal(3333333333333333, 10), LongDecimal(0, 10), LongDecimal(10000000000, 10), LongMath.pi(100) ]
    arr = [ 1, 2, 1.0, Math::PI, Rational(40, 9), Rational(1,1), LongDecimal(3333333333333333, 10), LongDecimal(10000000000, 10), LongMath.pi(100) ]
    arr.each do |x|
      x.freeze
      arr.each do |y|
        y.freeze
        print ":"
        arr.each do |z|
          z.freeze
          print "."
          # prec = 0
          # 3.times do |i|
          [0, 31].each_with_index do |prec, i|
            ALL_ROUNDING_MODES.each do |rm|
              if (rm == ROUND_UNNECESSARY)
                next
              end
              xx = x.to_ld(prec, rm)
              yy = y.to_ld(prec, rm)
              zz = z.to_ld(prec, rm)
              mi = [xx, yy, zz].min
              am = LongMath.arithmetic_mean(prec, rm, x, y, z)
              agm = LongMath.arithmetic_geometric_mean(prec, rm, x, y, z)
              gm = LongMath.geometric_mean(prec, rm, x, y, z)
              if (x.sgn == 0 || y.sgn == 0 || z.sgn == 0)
                hm = gm
                hgm = gm
              else
                hm = LongMath.harmonic_mean(prec, rm, x, y, z)
                hgm = LongMath.harmonic_geometric_mean(prec, rm, x, y, z)
              end
              qm = LongMath.quadratic_mean(prec, rm, x, y, z)
              cm = LongMath.cubic_mean(prec, rm, x, y, z)
              ma = [xx, yy, zz].max
              text = "mi=#{mi} hm=#{hm} gm=#{gm} am=#{am} qm=#{qm} cm=#{cm} ma=#{ma} prec=#{prec} rm=#{rm} x=#{x} y=#{y} z=#{z} i=#{i}"
              assert(mi <= hm.succ, text)
              assert(hm <= hgm.succ, text)
              assert(hgm <= gm.succ, text)
              assert(gm <= agm.succ, text)
              assert(agm <= am.succ, text)
              assert(am <= qm.succ, text)
              assert(qm <= cm.succ, text)
              assert(cm <= ma.succ, text)
              if (x == y && y == z)
                assert_equal(mi, hm, text)
                assert_equal(hm, hgm, text)
                assert_equal(hgm, gm, text)
                assert_equal(gm, agm, text)
                assert_equal(agm, am, text)
                assert_equal(am, qm, text)
                assert_equal(qm, cm, text)
                assert_equal(cm, ma, text)
              end
            end
            # prec = (prec << 3) + 11
          end
        end
      end
    end
  end

  def test_arithmetic_means_two_param_known_result
    assert_equal(1, LongMath.arithmetic_mean(0, ROUND_UNNECESSARY, 0, 2))
    assert_equal(0, LongMath.arithmetic_mean(0, ROUND_UNNECESSARY, -1, 1))
    assert_equal(3, LongMath.arithmetic_mean(0, ROUND_UNNECESSARY, 1, 5))
  end

  def test_geometric_means_two_param_known_result
    assert_equal(2, LongMath.geometric_mean(0, ROUND_UNNECESSARY, 1, 4))
    assert_equal(10, LongMath.geometric_mean(0, ROUND_UNNECESSARY, 4, 25))
    assert_equal(-3, LongMath.geometric_mean(0, ROUND_UNNECESSARY, -1, -9))
  end

  def test_harmonic_means_two_param_known_result
    assert_equal(3, LongMath.harmonic_mean(0, ROUND_UNNECESSARY, 2, 6))
    assert_equal(4, LongMath.harmonic_mean(0, ROUND_UNNECESSARY, 3, 6))
    assert_equal(-3, LongMath.harmonic_mean(0, ROUND_UNNECESSARY, -2, -6))
  end

  def test_quadratic_means_two_param_known_result
    assert_equal(5, LongMath.quadratic_mean(0, ROUND_UNNECESSARY, 1, 7))
    assert_equal(10, LongMath.quadratic_mean(0, ROUND_UNNECESSARY, 2, 14))
    assert_equal(15, LongMath.quadratic_mean(0, ROUND_UNNECESSARY, 3, 21))
    assert_equal(13, LongMath.quadratic_mean(0, ROUND_UNNECESSARY, 7, 17))
    assert_equal(-5, LongMath.quadratic_mean(0, ROUND_UNNECESSARY, -1, -7))
  end


  #
  # test mul minverse of RoundingMode
  #
  def test_rm_minverse
    print "\ntest_rm_minverse [#{Time.now}]: "
    assert_equal(ROUND_UP,           ROUND_DOWN.minverse)
    assert_equal(ROUND_DOWN,         ROUND_UP.minverse)
    assert_equal(ROUND_CEILING,      ROUND_FLOOR.minverse)
    assert_equal(ROUND_FLOOR,        ROUND_CEILING.minverse)
    assert_equal(ROUND_HALF_UP,      ROUND_HALF_DOWN.minverse)
    assert_equal(ROUND_HALF_DOWN,    ROUND_HALF_UP.minverse)
    assert_equal(ROUND_HALF_CEILING, ROUND_HALF_FLOOR.minverse)
    assert_equal(ROUND_HALF_FLOOR,   ROUND_HALF_CEILING.minverse)
    assert_equal(ROUND_HALF_EVEN,    ROUND_HALF_EVEN.minverse)
    assert_equal(ROUND_HALF_ODD,     ROUND_HALF_ODD.minverse)
    assert_equal(ROUND_UNNECESSARY,  ROUND_UNNECESSARY.minverse)
  end

  #
  # test ainverse of RoundingMode
  #
  def test_rm_ainverse
    print "\ntest_rm_ainverse [#{Time.now}]: "
    assert_equal(ROUND_UP,           ROUND_UP.ainverse)
    assert_equal(ROUND_DOWN,         ROUND_DOWN.ainverse)
    assert_equal(ROUND_CEILING,      ROUND_FLOOR.ainverse)
    assert_equal(ROUND_FLOOR,        ROUND_CEILING.ainverse)
    assert_equal(ROUND_HALF_UP,      ROUND_HALF_UP.ainverse)
    assert_equal(ROUND_HALF_DOWN,    ROUND_HALF_DOWN.ainverse)
    assert_equal(ROUND_HALF_CEILING, ROUND_HALF_FLOOR.ainverse)
    assert_equal(ROUND_HALF_FLOOR,   ROUND_HALF_CEILING.ainverse)
    assert_equal(ROUND_HALF_EVEN,    ROUND_HALF_EVEN.ainverse)
    assert_equal(ROUND_HALF_ODD,     ROUND_HALF_ODD.ainverse)
    assert_equal(ROUND_UNNECESSARY,  ROUND_UNNECESSARY.ainverse)
  end


  #
  # helper method for test_npower10
  #
  def check_npower10(x, z = nil)
    y = LongMath.npower10(x)
    if (z.nil?) then
      @powers_of_10 ||= []
      z = @powers_of_10[x]
      if (z.nil?)
        z = 10**x
        @powers_of_10[x] = z
      end
    elsif (z & 0xff == 0)
      zz = @powers_of_10[x]
      if (zz.nil?)
        zz = 10**x
        @powers_of_10[x] = zz
      end
      assert_equal(z, zz)
      # puts("exp=" + x.to_s)
      $stdout.flush
    else
      @powers_of_10[x] ||= z
    end
    assert_equal(z, y, "x=#{x}")
  end

  #
  # test LongMath.npower10
  #
  def test_npower10
    print "\ntest_npower10 [#{Time.now}] (240 min): "
    $stdout.flush

    prec = LongMath.prec_limit
    LongMath.prec_limit=LongMath::MAX_PREC

    12.times do |i|
      check_npower10(3**i)
      # puts(3**i)
    end

    12.times do |i|
      check_npower10(3**i)
      # puts(3**i)
    end

    y = 1
    1024.times do |i|
      check_npower10(i, y)
      y *= 10
    end
    y = 1
    y0 = 1
    xs = 4096
    yf = 10**xs
    x0 = 2046
    y0 = 10**x0
    60.times do |i|
      # puts "i=" + i.to_s
      $stdout.flush
      y = y0
      x = x0
      5.times do |j|
        check_npower10(x, y)
        x += 1
        y *= 10
      end
      x0 += xs
      y0 *= yf
    end

    LongMath.prec_limit = prec
  end

  def test_scale_equal
    print "\ntest_scale_equal [#{Time.now}]: "
    x = LongDecimal(3, 9)
    y = LongDecimal(4, 9)
    z = LongDecimal(4, 8)
    assert(x.scale_equal(y), "xy")
    assert(y.scale_equal(x), "yx")
    assert(! x.scale_equal(z), "xz")
    assert(! y.scale_equal(z), "yz")

    x = LongDecimalQuot(Rational(3, 4), 9)
    y = LongDecimalQuot(Rational(4, 3), 9)
    z = LongDecimalQuot(Rational(4, 3), 8)
    assert(x.scale_equal(y), "xy")
    assert(y.scale_equal(x), "yx")
    assert(! x.scale_equal(z), "xz")
    assert(! y.scale_equal(z), "yz")
    assert(! z.scale_equal(x), "zx")
    assert(! z.scale_equal(y), "zy")
  end

  def test_scale_ufo
    print "\ntest_scale_ufo [#{Time.now}]: "
    x = LongDecimal(3, 9)
    y = LongDecimal(4, 9)
    z = LongDecimal(4, 7)
    assert(x.scale_ufo(y) == 0, "xy")
    assert(y.scale_ufo(x) == 0, "yx")
    assert(x.scale_ufo(z) == 1, "xz")
    assert(y.scale_ufo(z) == 1, "yz")
    assert(z.scale_ufo(x) == -1, "zx")
    assert(z.scale_ufo(y) == -1, "zy")

    x = LongDecimalQuot(Rational(3, 4), 9)
    y = LongDecimalQuot(Rational(4, 3), 9)
    z = LongDecimalQuot(Rational(4, 3), 7)
    assert(x.scale_ufo(y) == 0, "xy")
    assert(y.scale_ufo(x) == 0, "yx")
    assert(x.scale_ufo(z) == 1, "xz")
    assert(y.scale_ufo(z) == 1, "yz")
    assert(z.scale_ufo(x) == -1, "zx")
    assert(z.scale_ufo(y) == -1, "zy")
  end

end

# RUNIT::CUI::TestRunner.run(TestLongDecimal_class.suite)

# end of file testlongdecimal.rb
