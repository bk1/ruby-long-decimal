#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2009
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdecimal-extra.rb,v 1.29 2011/02/03 00:22:38 bk1 Exp $
# CVS-Label: $Name:  $
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
load "lib/long-decimal-extra.rb"
load "test/testlongdeclib.rb"

if ($test_type == :v20)
  class UnitTest < Test::Unit::TestCase
  end
else
  class UnitTest < MiniTest::Test
  end
end

LongMath.prec_overflow_handling = :warn_use_max

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimalExtra_class < UnitTest # Test::Unit::TestCase # RUNIT::TestCase
  include TestLongDecHelper

  @RCS_ID='-$Id: testlongdecimal-extra.rb,v 1.29 2011/02/03 00:22:38 bk1 Exp $-'

  MAX_FLOAT_I = (Float::MAX).to_i

  #
  # test conversion to Float
  #
  def _test_to_f
    print "\ntest_to_f [#{Time.now}]: "
    l = LongDecimal(224, 0)
    assert((l.to_f - 224).abs < 224 * 0.000001, "l=#{l.inspect}")  # t2
    assert(((-l).to_f + 224).abs < 224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert((l.to_f - 22.4).abs < 22.4 * 0.000001, "l=#{l.inspect}")
    assert(((-l).to_f + 22.4).abs < 22.4 * 0.000001, "l=#{l.inspect}") # t3
    l = LongDecimal(224, 2)
    assert((l.to_f - 2.24).abs < 2.24 * 0.000001, "l=#{l.inspect}")
    assert(((-l).to_f + 2.24).abs < 2.24 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert((l.to_f - 0.224).abs < 0.224 * 0.000001, "l=#{l.inspect}")
    assert(((-l).to_f + 0.224).abs < 0.224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert((l.to_f - 0.0224).abs < 0.0224 * 0.000001, "l=#{l.inspect}")
    assert(((-l).to_f + 0.0224).abs < 0.0224 * 0.000001, "l=#{l.inspect}")

    l = LongDecimal("0." + ("0" * 30) + "1" + ("0" * 500))
    assert((l.to_f - 1e-31).abs < 1e-32, "l=#{l.inspect}=#{l.to_s}=#{l.to_f}=#{l.to_s.to_f}")
    assert(((-l).to_f + 1e-31).abs < 1e-32, "l=#{l.inspect}=#{l.to_s}=#{l.to_f}=#{l.to_s.to_f}")
    l = LongDecimal("0." + ("0" * 200) + "1" + ("0" * 500))
    assert((l.to_f - 1e-201).abs < 1e-202, "l=#{l.inspect}=#{l.to_s}=#{l.to_f}=#{l.to_s.to_f}")
    assert(((-l).to_f + 1e-201).abs < 1e-202, "l=#{l.inspect}=#{l.to_s}=#{l.to_f}=#{l.to_s.to_f}")
    l = LongDecimal("0." + ("0" * 280) + "1" + ("0" * 500))
    assert((l.to_f - 1e-281).abs < 1e-282, "l=#{l.inspect}=#{l.to_s}=#{l.to_f}=#{l.to_s.to_f}")
    assert(((-l).to_f + 1e-281).abs < 1e-282, "l=#{l.inspect}=#{l.to_s}=#{l.to_f}=#{l.to_s.to_f}")

    l = LongDecimal("0.00000000000000000000000000000000000000000000000000002090000000000000000000000000332000042999999999999999934478499999999999999999999979183597303900000000000002280678889571719972270000000870125632696979999999999928587104894304210318436999963636067429710015568287618182130517226303011944557351440293760289098908449297658922618709026683663019359834144789263320")
    delta1 = (l - LongDecimal("0.0000000000000000000000000000000000000000000000000000209"))
    delta2 = delta1.to_f.abs
    assert(delta2 < 1e-60, "l=#{l.inspect}=#{l.to_s} delta1=#{delta1} delta2=#{delta2}")
    assert(((-l).to_f + 0.0000000000000000000000000000000000000000000000000000209).abs < 1e-60, "l=#{l.inspect}")
  end

  #
  # test to_f of Rational (trivial cases)
  #
  def _test_r_to_f_small
    print "\ntest_r_to_f_small [#{Time.now}]: "
    # trivial: 0, 1, -1,...
    r = Rational(0, 1)
    assert_equal(0.0, r.to_f)
    r = Rational(1, 1)
    assert_equal(1.0, r.to_f)
    r = Rational(-1, 1)
    assert_equal(-1.0, r.to_f)
    r = Rational(3, 2)
    assert_equal(1.5, r.to_f)
    r = Rational(-3, 2)
    assert_equal(-1.5, r.to_f)
  end

  #
  # test to_f of Rational (max of to_f_orig)
  #
  def _test_r_to_f_max_float
    print "\ntest_r_to_f_max_float [#{Time.now}]: "
    # still numerator and denominator expressable as Float
    r = Rational(LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE - 1)
    assert_equal(1.0, r.to_f)
    assert_equal(1.0, r.to_f_orig)
    r = Rational(-LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE - 1)
    assert_equal(-1.0, r.to_f)
    assert_equal(-1.0, r.to_f_orig)
    r = Rational(LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE)
    assert_equal(1.0, r.to_f)
    assert_equal(1.0, r.to_f_orig)
    r = Rational(-(LongMath::MAX_FLOATABLE + 1), LongMath::MAX_FLOATABLE)
    assert_equal(-1.0, r.to_f)
    assert_equal(-1.0, r.to_f_orig)
    r = Rational(LongMath::MAX_FLOATABLE, 1)
    assert_equal(Float::MAX, r.to_f)
    assert_equal(Float::MAX, r.to_f_orig)
    r = Rational(-LongMath::MAX_FLOATABLE, 1)
    assert_equal(-Float::MAX, r.to_f)
    assert_equal(-Float::MAX, r.to_f_orig)
    unless RUBY_PLATFORM == 'java'
      # skip this test in JRuby due to bugs in JRuby's Float
      r = Rational(1, LongMath::MAX_FLOATABLE)
      assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
      assert_equal_float(1/Float::MAX, r.to_f_orig, Float::MIN)
      r = Rational(-1 , LongMath::MAX_FLOATABLE)
      assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
      assert_equal_float(-1/Float::MAX, r.to_f_orig, Float::MIN)
    end
  end

  #
  # test to_f of Rational with numerator.abs > Float::MAX
  #
  def _test_r_to_f_big_numerator
    print "\ntest_r_to_f_big_numerator [#{Time.now}]: "
    # numerator beyond Float::MAX
    r = Rational(LongMath::MAX_FLOATABLE + 1, LongMath::MAX_FLOATABLE - 1)
    assert_equal(1.0, r.to_f)
    r = Rational(-LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE - 1)
    assert_equal(-1.0, r.to_f)
    r = Rational(LongMath::MAX_FLOATABLE + 1, 1)
    assert_equal(Float::MAX, r.to_f)
    r = Rational(-LongMath::MAX_FLOATABLE - 1 , 1)
    assert_equal(-Float::MAX, r.to_f)
    r = Rational(2 * LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE)
    assert_equal(2.0, r.to_f)
    r = Rational(-2 * LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE)
    assert_equal(-2.0, r.to_f)
    r = Rational(LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE)
    assert_equal(Float::MAX, r.to_f)
    r = Rational(-LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE)
    assert_equal(-Float::MAX, r.to_f)
  end

  #
  # test to_f of Rational with denominator.abs > Float::MAX
  #
  def _test_r_to_f_big_numerator
    print "\ntest_r_to_f_big_numerator [#{Time.now}]: "

    # denominator beyond Float::MAX
    r = Rational(LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE + 1)
    assert_equal(1.0, r.to_f)
    r = Rational(-LongMath::MAX_FLOATABLE + 1, LongMath::MAX_FLOATABLE + 1)
    assert_equal(-1.0, r.to_f)
    r = Rational(1, LongMath::MAX_FLOATABLE + 1)
    assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
    r = Rational(-1, LongMath::MAX_FLOATABLE - 1)
    assert_equal(-1/Float::MAX, r.to_f, Float::MIN)
    r = Rational(LongMath::MAX_FLOATABLE, 2 * LongMath::MAX_FLOATABLE)
    assert_equal(0.5, r.to_f)
    r = Rational(-LongMath::MAX_FLOATABLE, 2 * LongMath::MAX_FLOATABLE)
    assert_equal(-0.5, r.to_f)
    r = Rational(LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE ** 2)
    assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
    r = Rational(-LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE ** 2)
    assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
  end

  #
  # test to_f of Rational with numerator.abs > Float::MAX and denominator.abs > Float::MAX
  #
  def _test_r_to_f_big_numerator
    print "\ntest_r_to_f_big_numerator [#{Time.now}]: "
    # both beyond Float::MAX
    delta = 1/Float::MAX
    r = Rational(LongMath::MAX_FLOATABLE + 2, LongMath::MAX_FLOATABLE + 1)
    assert_equal(1.0, r.to_f)
    r = Rational(-LongMath::MAX_FLOATABLE - 2, LongMath::MAX_FLOATABLE + 1)
    assert_equal(-1.0, r.to_f)
    unless RUBY_PLATFORM == 'java'
      # skip this test in JRuby due to bugs in JRuby's Float
      r = Rational(LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE ** 3)
      assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
      r = Rational(-LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE ** 3)
      assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
    end
    r = Rational(LongMath::MAX_FLOATABLE ** 3, LongMath::MAX_FLOATABLE ** 2)
    assert_equal(Float::MAX, r.to_f)
    r = Rational(-LongMath::MAX_FLOATABLE ** 3, LongMath::MAX_FLOATABLE ** 2)
    assert_equal(-Float::MAX, r.to_f)
    r = Rational(LongMath::MAX_FLOATABLE + 1, 2 * LongMath::MAX_FLOATABLE)
    assert_equal(0.5, r.to_f)
    r = Rational(-(LongMath::MAX_FLOATABLE + 1), 2 * LongMath::MAX_FLOATABLE)
    assert_equal(-0.5, r.to_f)
    unless RUBY_PLATFORM == 'java'
      # skip this test in JRuby due to bugs in JRuby's Float
      r = Rational(LongMath::MAX_FLOATABLE + 1, LongMath::MAX_FLOATABLE ** 2)
      assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
      r = Rational(-LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE ** 2)
      assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
    end
  end

  #
  # test to_f of Rational with medium sized absolute value
  #
  def _test_r_to_f_medium
    print "\ntest_r_to_f_medium [#{Time.now}]: "

    # use some value < 1 "in the middle"
    f = 1.34078079299426e-126
    n = 134078079299426
    d = 10 ** 140
    u = 10 ** 300
    n2 = n ** 2
    d2 = d ** 2
    u2 = u ** 2
    delta = 10 ** 135
    f2 = 1/f
    delta2 = 1/delta
    r = Rational(n, d)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d, n)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n * d, d2)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d2, n * d)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n2, d * n)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d * n, n2)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n * u, d * u)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d * u, n * u)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n * u2, d * u2)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d * u2, n * u2)
    assert_equal_float(f2, r.to_f, delta2)

    # use some value > 1 "in the middle"
    f = 1.34078079299426e+154
    n = 134078079299426 * 10**154
    d = 10 ** 14
    n2 = n ** 2
    d2 = d ** 2
    delta = 10 ** 135
    f2 = 1/f
    delta2 = 1/delta
    r = Rational(n, d)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d, n)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n * d, d2)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d2, n * d)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n2, d * n)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d * n, n2)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n * u, d * u)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d * u, n * u)
    assert_equal_float(f2, r.to_f, delta2)
    r = Rational(n * u2, d * u2)
    assert_equal_float(f, r.to_f, delta)
    r = Rational(d * u2, n * u2)
    assert_equal_float(f2, r.to_f, delta2)

  end

  #
  # test to_f of Rational (trivial cases)
  #
  def _test_ld_to_f_small
    print "\ntest_ld_to_f_small [#{Time.now}]: "
    # trivial: 0, 1, -1,...
    r = LongDecimal(0, 0)
    assert_equal(0.0, r.to_f)  # t1
    r = LongDecimal(1, 0)
    assert_equal(1.0, r.to_f)
    r = LongDecimal(-1, 0)
    assert_equal(-1.0, r.to_f)
    r = LongDecimal(15, 1)
    assert_equal(1.5, r.to_f)
    r = LongDecimal(-15, 1)
    assert_equal(-1.5, r.to_f) # t3
  end

  #
  # test to_f of LongDecimal
  #
  def _test_ld_to_f_max_float
    print "\ntest_ld_to_f_max_float [#{Time.now}]: "
    y = 1.7976931348623158
    z = 0.1 ** Float::MAX_10_EXP
    # still numerator and denominator expressable as Float
    r = LongDecimal(LongMath::MAX_FLOATABLE, Float::MAX_10_EXP)
    assert_equal_float(y, r.to_f, 1e-13)  # t4
    r = LongDecimal(-LongMath::MAX_FLOATABLE, Float::MAX_10_EXP)
    assert_equal_float(-y, r.to_f, 1e-13) # t3
    r = LongDecimal(LongMath::MAX_FLOATABLE - 1, Float::MAX_10_EXP)
    assert_equal_float(y, r.to_f, 1e-13) # t4
    r = LongDecimal(-(LongMath::MAX_FLOATABLE + 1), Float::MAX_10_EXP)
    assert_equal_float(-y, r.to_f, 1e-13)
    r = LongDecimal(LongMath::MAX_FLOATABLE, 0)
    assert_equal(Float::MAX, r.to_f)
    r = LongDecimal(-LongMath::MAX_FLOATABLE, 0)
    assert_equal(-Float::MAX, r.to_f)
    r = LongDecimal(1, Float::MAX_10_EXP)
    assert_equal_float(z, r.to_f, Float::MIN)
    r = LongDecimal(-1, Float::MAX_10_EXP)
    assert_equal_float(-z, r.to_f, Float::MIN)
  end

  #
  # test to_f of LongDecimal with numerator.abs > Float::MAX
  #
  def _test_ld_to_f_big_numerator
    print "\ntest_ld_to_f_big_numerator [#{Time.now}]: "
    y = 1.7976931348623158
    u = 1.3407807929942596e308
    # numerator beyond Float::MAX
    r = LongDecimal(LongMath::MAX_FLOATABLE + 1, Float::MAX_10_EXP)
    assert_equal(y, r.to_f)
    r = LongDecimal(-LongMath::MAX_FLOATABLE - 1, Float::MAX_10_EXP)
    assert_equal(-y, r.to_f)
    r = LongDecimal(LongMath::MAX_FLOATABLE + 1, 0)
    assert_equal(Float::MAX, r.to_f)
    r = LongDecimal(-LongMath::MAX_FLOATABLE - 1, 0)
    assert_equal(-Float::MAX, r.to_f)
    r = LongDecimal(2 * LongMath::MAX_FLOATABLE, Float::MAX_10_EXP)
    assert_equal(2.0 * y, r.to_f)
    r = LongDecimal(-2 * LongMath::MAX_FLOATABLE, Float::MAX_10_EXP)
    assert_equal(-2.0 * y, r.to_f)
    r = LongDecimal(u ** 2, Float::MAX_10_EXP)
    assert_equal(Float::MAX, r.to_f)
    r = LongDecimal(-u ** 2, LongMath::MAX_FLOATABLE)
    assert_equal(-Float::MAX, r.to_f)
  end

  #
  # test to_f of LongDecimal with denominator.abs > Float::MAX
  #
  def _test_ld_to_f_big_numerator
    print "\ntest_ld_to_f_big_numerator [#{Time.now}]: "
    y = 1.7976931348623158
    z = 0.1 ** Float::MAX_10_EXP + 1

    # denominator beyond Float::MAX
    r = LongDecimal(LongMath::MAX_FLOATABLE - 1, Float::MAX_10_EXP + 1)
    assert_equal(y * 0.1, r.to_f)
    r = LongDecimal(-LongMath::MAX_FLOATABLE + 1, Float::MAX_10_EXP + 1)
    assert_equal(-y * 0.1, r.to_f)
    r = LongDecimal(1, Float::MAX_10_EXP + 1)
    assert_equal_float(z, r.to_f, Float::MIN)
    r = LongDecimal(-1, Float::MAX_10_EXP + 1)
    assert_equal(-z, r.to_f, Float::MIN)
    r = LongDecimal(LongMath::MAX_FLOATABLE, 2 * Float::MAX_10_EXP)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(-LongMath::MAX_FLOATABLE, 2 * Float::MAX_10_EXP)
    assert_equal(-0.0, r.to_f)
  end

  #
  # test to_f of LongDecimal with numerator.abs > Float::MAX and denominator.abs > Float::MAX
  #
  def _test_ld_to_f_big_numerator
    print "\ntest_ld_to_f_big_numerator [#{Time.now}]: "
    y = 1.7976931348623158
    z = 0.1 ** Float::MAX_10_EXP + 1
    u = 1.3407807929942596e308
    v = y**2 * 0.1 ** Float::MAX_10_EXP
    w = 10  ** Float::MAX_10_EXP
    x = 0.1 ** Float::MAX_10_EXP

    # both beyond Float::MAX
    delta = 1/Float::MAX
    r = LongDecimal(LongMath::MAX_FLOATABLE + 2, Float::MAX_10_EXP + 1)
    assert_equal_float(y * 0.1, r.to_f, 1e-15) # t12
    r = LongDecimal(-LongMath::MAX_FLOATABLE - 2, Float::MAX_10_EXP + 1)
    assert_equal_float(-y * 0.1, r.to_f, 1e-15) # t3
    r = LongDecimal(LongMath::MAX_FLOATABLE ** 2, 3 * Float::MAX_10_EXP)
    assert_equal_float(v, r.to_f, Float::MIN) # t6
    r = LongDecimal(-LongMath::MAX_FLOATABLE ** 2, 3 * Float::MAX_10_EXP)
    assert_equal_float(-v, r.to_f, Float::MIN)
    r = LongDecimal(10 * w + 2, Float::MAX_10_EXP + 1)
    assert_equal_float(1.0, r.to_f, 1e-15)
    r = LongDecimal(-10 * w - 2, Float::MAX_10_EXP + 1)
    assert_equal_float(-1.0, r.to_f, 1e-15)
    r = LongDecimal(w ** 2 - 1, 3 * Float::MAX_10_EXP)
    assert_equal_float(x, r.to_f, Float::MIN)
    r = LongDecimal(-w ** 2 - 1, 3 * Float::MAX_10_EXP)
    assert_equal_float(-x, r.to_f, Float::MIN)
    r = LongDecimal(w ** 2, 3 * Float::MAX_10_EXP)
    assert_equal_float(x, r.to_f, Float::MIN)
    r = LongDecimal(-w ** 2, 3 * Float::MAX_10_EXP)
    assert_equal_float(-x, r.to_f, Float::MIN)
    r = LongDecimal(w ** 2 + 1, 3 * Float::MAX_10_EXP)
    assert_equal_float(x, r.to_f, Float::MIN)
    r = LongDecimal(-w ** 2 + 1, 3 * Float::MAX_10_EXP)
    assert_equal_float(-x, r.to_f, Float::MIN)
    r = LongDecimal(w ** 2 - 1, 3 * Float::MAX_10_EXP + 1)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(-w ** 2 - 1, 3 * Float::MAX_10_EXP + 1)
    assert_equal(-0.0, r.to_f)
    r = LongDecimal(w ** 2, 3 * Float::MAX_10_EXP + 1)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(-w ** 2, 3 * Float::MAX_10_EXP + 1)
    assert_equal(-0.0, r.to_f)
    r = LongDecimal(w ** 2 + 1, 3 * Float::MAX_10_EXP + 1)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(-w ** 2 + 1, 3 * Float::MAX_10_EXP + 1)
    assert_equal(-0.0, r.to_f)
    r = LongDecimal(w ** 3 + 1, 2 * Float::MAX_10_EXP)
    assert_equal(w.to_f, r.to_f)
    r = LongDecimal(-w ** 3 + 1, 2 * Float::MAX_10_EXP)
    assert_equal(-w.to_f, r.to_f)
    r = LongDecimal(10 * w + 1, 1 + Float::MAX_10_EXP)
    assert_equal_float(1.0, r.to_f, 1e-15)
    r = LongDecimal(-10 * w - 1, 1 + Float::MAX_10_EXP)
    assert_equal_float(-1.0, r.to_f, 1e-15)
    r = LongDecimal(10 * w + 1, 2 * Float::MAX_10_EXP)
    assert_equal_float(10/Float::MAX, r.to_f, 2*Float::MIN, "d=#{r.to_f-10/Float::MAX}")
    r = LongDecimal(-10 * w + 1, 2 * Float::MAX_10_EXP)
    assert_equal_float(-10/Float::MAX, r.to_f, 2*Float::MIN, "d=#{r.to_f+10/Float::MAX}")
  end

  #
  # test to_f of LongDecimal with medium sized absolute value
  #
  def _test_ld_to_f_medium
    print "\ntest_ld_to_f_medium [#{Time.now}]: "

    # use some value < 1 "in the middle"
    f = 1.34078079299426e-126
    n = 134078079299426
    ds = 140
    d = 10 ** ds
    us = 300
    u = 10 ** us
    n2 = n ** 2
    d2 = d ** 2
    u2 = u ** 2
    delta = 10 ** 135
    fi = 1/f
    ni = 74583407312002050942828544 * 10 ** 100
    deltai = 1/delta

    r = LongDecimal(n, ds)
    assert_equal_float(f, r.to_f, delta)  # t4
    r = LongDecimal(ni, 0)
    assert_equal_float(fi, r.to_f, deltai)
    r = LongDecimal(n * d, 2 * ds)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimal(n * u, ds + us)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimal(ni * u, us)
    assert_equal_float(fi, r.to_f, deltai) # t9
    r = LongDecimal(n * u2, ds + 2*us)
    assert_equal_float(f, r.to_f, delta)

    # use some value > 1 "in the middle"
    f = 1.34078079299426e+154
    n = 134078079299426 * 10**154
    ds = 14
    d = 10 ** ds
    n2 = n ** 2
    d2 = d ** 2
    delta = 1e139
    fi = 1/f
    deltai = 1/delta
    ni = 745834073120020496384
    dis = 175
    di = 10 ** dis

    r = LongDecimal(n, ds)
    assert_equal_float(f, r.to_f, delta, "d=#{f-r.to_f}")
    r = LongDecimal(ni, dis)
    assert_equal_float(fi, r.to_f, deltai)
    r = LongDecimal(n * d, 2 * ds)
    assert_equal_float(f, r.to_f, 3 * delta, "d=#{f - r.to_f}") # t4
    r = LongDecimal(d * ni, ds + dis)
    assert_equal_float(fi, r.to_f, deltai)
    r = LongDecimal(n * u, ds + us)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimal(ni * u, dis + us)
    assert_equal_float(fi, r.to_f, deltai)
    r = LongDecimal(n * u2, ds + 2 * us)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimal(ni * u2, dis + 2*us)
    assert_equal_float(fi, r.to_f, deltai)

  end

  # do some conversions that lead to infinity
  def _test_ld_to_f_infinity
    print "\ntest_ld_to_f_infinity [#{Time.now}]: "
    f1 = LongDecimal(1000000000000001, 15)
    r = LongDecimal(LongMath::MAX_FLOATABLE + 1, 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}") # t13
    # assert_equal(Float::MAX, r.to_f, "r=#{r}=#{r.to_f}")
    r = LongDecimal(-(LongMath::MAX_FLOATABLE + 1), 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    # assert_equal(-Float::MAX, r.to_f, "r=#{r}=#{r.to_f}")
    r = LongDecimal(LongMath::MAX_FLOATABLE * f1, 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(-LongMath::MAX_FLOATABLE * f1, 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(LongMath::MAX_FLOATABLE * 2, 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(-LongMath::MAX_FLOATABLE * 2, 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(LongMath::MAX_FLOATABLE ** 2, 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(-LongMath::MAX_FLOATABLE ** 2, 0)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(LongMath::MAX_FLOATABLE * 10 + 1, 1)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(-LongMath::MAX_FLOATABLE * 10 - 1, 1)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(LongMath::MAX_FLOATABLE ** 2, Float::MAX_10_EXP)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(-LongMath::MAX_FLOATABLE ** 2, Float::MAX_10_EXP)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(LongMath::MAX_FLOATABLE ** 3, 2 * Float::MAX_10_EXP)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
    r = LongDecimal(-LongMath::MAX_FLOATABLE ** 3, 2 * Float::MAX_10_EXP)
    assert(! r.to_f.finite?, "r=#{r}=#{r.to_f}")
  end

  # test t7
  def _test_ld_to_f_zero_t7
    print "\ntest_ld_to_f_zero_t7 [#{Time.now}]: "
    scale = 600
    divisor = 10 ** scale
    val = divisor / (LongMath::INV_MIN_FLOATABLE * 20)
    r = LongDecimal(val - 1, scale)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(-val + 1, scale)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(val, scale)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(-val, scale)
    assert_equal(0.0, r.to_f)
    r = LongDecimal(val + 1, scale)
    assert_equal_float(0.0, r.to_f, Float::MIN) # t7 (JRuby-only)
    r = LongDecimal(-val - 1, scale)
    assert_equal_float(0.0, r.to_f, Float::MIN) # t7 (JRuby-only)
    r = LongDecimal(val + 2, scale)
    assert_equal_float(0.0, r.to_f, Float::MIN) # t7 (JRuby-only)
    r = LongDecimal(-val - 2, scale)
    assert_equal_float(0.0, r.to_f, Float::MIN) # t7 (JRuby-only)
  end

  #
  # test to_f of LongDecimalQuot (trivial cases)
  #
  def _test_ldq_to_f_small
    print "\ntest_ldq_to_f_small [#{Time.now}]: "
    # trivial: 0, 1, -1,...
    r = LongDecimalQuot(Rational(0, 1), 7)
    assert_equal(0.0, r.to_f)
    r = LongDecimalQuot(Rational(1, 1), 7)
    assert_equal(1.0, r.to_f)
    r = LongDecimalQuot(Rational(-1, 1), 7)
    assert_equal(-1.0, r.to_f)
    r = LongDecimalQuot(Rational(3, 2), 7)
    assert_equal(1.5, r.to_f)
    r = LongDecimalQuot(Rational(-3, 2), 7)
    assert_equal(-1.5, r.to_f)
  end

  #
  # test to_f of LongDecimalQuot
  #
  def _test_ldq_to_f_max_float
    print "\ntest_ldq_to_f_max_float [#{Time.now}]: "
    # still numerator and denominator expressable as Float
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE - 1), 7)
    assert_equal(1.0, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE - 1), 7)
    assert_equal(-1.0, r.to_f)
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE), 7)
    assert_equal(1.0, r.to_f)
    r = LongDecimalQuot(Rational(-(LongMath::MAX_FLOATABLE + 1), LongMath::MAX_FLOATABLE), 7)
    assert_equal(-1.0, r.to_f)
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE, 1), 7)
    assert_equal(Float::MAX, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE, 1), 7)
    assert_equal(-Float::MAX, r.to_f)
    unless RUBY_PLATFORM == 'java'
      # skip this test in JRuby due to bugs in JRuby's Float
      r = LongDecimalQuot(Rational(1, LongMath::MAX_FLOATABLE), 7)
      assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
      r = LongDecimalQuot(Rational(-1 , LongMath::MAX_FLOATABLE), 7)
      assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
    end
  end

  #
  # test to_f of LongDecimalQuot with numerator.abs > Float::MAX
  #
  def _test_ldq_to_f_big_numerator
    print "\ntest_ldq_to_f_big_numerator [#{Time.now}]: "
    # numerator beyond Float::MAX
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE + 1, LongMath::MAX_FLOATABLE - 1), 7)
    assert_equal(1.0, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE - 1), 7)
    assert_equal(-1.0, r.to_f)
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE + 1, 1), 7)
    assert_equal(Float::MAX, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE - 1 , 1), 7)
    assert_equal(-Float::MAX, r.to_f)
    r = LongDecimalQuot(Rational(2 * LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE), 7)
    assert_equal(2.0, r.to_f)
    r = LongDecimalQuot(Rational(-2 * LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE), 7)
    assert_equal(-2.0, r.to_f)
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE), 7)
    assert_equal(Float::MAX, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE), 7)
    assert_equal(-Float::MAX, r.to_f)
  end

  #
  # test to_f of LongDecimalQuot with denominator.abs > Float::MAX
  #
  def _test_ldq_to_f_big_numerator
    print "\ntest_ldq_to_f_big_numerator [#{Time.now}]: "

    # denominator beyond Float::MAX
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE + 1), 7)
    assert_equal(1.0, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE + 1, LongMath::MAX_FLOATABLE + 1), 7)
    assert_equal(-1.0, r.to_f)
    r = LongDecimalQuot(Rational(1, LongMath::MAX_FLOATABLE + 1), 7)
    assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
    r = LongDecimalQuot(Rational(-1, LongMath::MAX_FLOATABLE - 1), 7)
    assert_equal(-1/Float::MAX, r.to_f, Float::MIN)
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE, 2 * LongMath::MAX_FLOATABLE), 7)
    assert_equal(0.5, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE, 2 * LongMath::MAX_FLOATABLE), 7)
    assert_equal(-0.5, r.to_f)
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE ** 2), 7)
    assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE, LongMath::MAX_FLOATABLE ** 2), 7)
    assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
  end

  #
  # test to_f of LongDecimalQuot with numerator.abs > Float::MAX and denominator.abs > Float::MAX
  #
  def _test_ldq_to_f_big_numerator
    print "\ntest_ldq_to_f_big_numerator [#{Time.now}]: "
    # both beyond Float::MAX
    delta = 1/Float::MAX
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE + 2, LongMath::MAX_FLOATABLE + 1), 7)
    assert_equal(1.0, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE - 2, LongMath::MAX_FLOATABLE + 1), 7)
    assert_equal(-1.0, r.to_f)
    unless RUBY_PLATFORM == 'java'
      # skip this test in JRuby due to bugs in JRuby's Float
      r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE ** 3), 7)
      assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
      r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE ** 2, LongMath::MAX_FLOATABLE ** 3), 7)
      assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
    end
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE ** 3, LongMath::MAX_FLOATABLE ** 2), 7)
    assert_equal(Float::MAX, r.to_f)
    r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE ** 3, LongMath::MAX_FLOATABLE ** 2), 7)
    assert_equal(-Float::MAX, r.to_f)
    r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE + 1, 2 * LongMath::MAX_FLOATABLE), 7)
    assert_equal(0.5, r.to_f)
    r = LongDecimalQuot(Rational(-(LongMath::MAX_FLOATABLE + 1), 2 * LongMath::MAX_FLOATABLE), 7)
    assert_equal(-0.5, r.to_f)
    unless RUBY_PLATFORM == 'java'
      # skip this test in JRuby due to bugs in JRuby's Float
      r = LongDecimalQuot(Rational(LongMath::MAX_FLOATABLE + 1, LongMath::MAX_FLOATABLE ** 2), 7)
      assert_equal_float(1/Float::MAX, r.to_f, Float::MIN)
      r = LongDecimalQuot(Rational(-LongMath::MAX_FLOATABLE - 1, LongMath::MAX_FLOATABLE ** 2), 7)
      assert_equal_float(-1/Float::MAX, r.to_f, Float::MIN)
    end
  end

  #
  # test to_f of LongDecimalQuot with medium sized absolute value
  #
  def _test_ldq_to_f_medium
    print "\ntest_ldq_to_f_medium [#{Time.now}]: "

    # use some value < 1 "in the middle"
    f = 1.34078079299426e-126
    n = 134078079299426
    d = 10 ** 140
    u = 10 ** 300
    n2 = n ** 2
    d2 = d ** 2
    u2 = u ** 2
    delta = 10 ** 135
    f2 = 1/f
    delta2 = 1/delta
    r = LongDecimalQuot(Rational(n, d), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d, n), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n * d, d2), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d2, n * d), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n2, d * n), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d * n, n2), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n * u, d * u), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d * u, n * u), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n * u2, d * u2), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d * u2, n * u2), 7)
    assert_equal_float(f2, r.to_f, delta2)

    # use some value > 1 "in the middle"
    f = 1.34078079299426e+154
    n = 134078079299426 * 10**154
    d = 10 ** 14
    n2 = n ** 2
    d2 = d ** 2
    delta = 10 ** 135
    f2 = 1/f
    delta2 = 1/delta
    r = LongDecimalQuot(Rational(n, d), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d, n), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n * d, d2), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d2, n * d), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n2, d * n), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d * n, n2), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n * u, d * u), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d * u, n * u), 7)
    assert_equal_float(f2, r.to_f, delta2)
    r = LongDecimalQuot(Rational(n * u2, d * u2), 7)
    assert_equal_float(f, r.to_f, delta)
    r = LongDecimalQuot(Rational(d * u2, n * u2), 7)
    assert_equal_float(f2, r.to_f, delta2)

  end

  #
  # test exp2 of LongMath
  #
  def _test_exp2
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
  def _test_exp2_near_zero
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
  def _test_exp10
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
  def _test_exp10_near_zero
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
  # test LongMath.power for bases that can be expressed as integer
  #
  def _test_lm_power_xint
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
  def _test_lm_power_yint
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
  def _test_lm_power_yhalfint
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
  # test LongMath.power with non-LongDecimal arguments
  #
  def _test_non_ld_power
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
  def _test_lm_power
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

    # random tests that have failed
  end

  def _test_lm_power0a
    print "\ntest_lm_power0a [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000077517987624900000000000000000000000000000000000000000000000000000000000000000000000000000014809051260000000000000000000000000000000000000000000000000000000000000000000000000000000000707281"),
                        LongDecimal("26.627053911388694974442854299008649887946027550330988420533923061901183724914978160564862753777080769340"),
                        29)
    puts "a"
  end

  def _test_lm_power0b
    print "\ntest_lm_power0b [#{Time.now}]: "
    check_power_floated(LongDecimal("1.000000000000000151000000000000000000000000000000000000000000000000000000000000057800000000205"),
                        LongDecimal("-680.0000000000000000000013100000000000000000000000000000000000000165000000000000000000234"),
                        26)
    puts "b"
  end

  def _test_lm_power0c
    print "\ntest_lm_power0c [#{Time.now}]: "
    check_power_floated(LongDecimal("1.0000000000000000000000000000000000000000000068000000000853000000000926"),
                        LongDecimal("-536.000000000086100000000000000000000000000019200000000000000000000000000000000000000000000000166"),
                        49)
    puts "c"
  end

  def _test_lm_power0d
    print "\ntest_lm_power0d [#{Time.now}]: "
    check_power_floated(LongDecimal("1.0000000000000000049000000000002090000000000447"),
                        LongDecimal("-328.00000000000000000000000000000000567000000000000000026600000000000000000000000679"),
                        24)
    puts "d"
  end

  def _test_lm_power0e
    print "\ntest_lm_power0e [#{Time.now}]: "
    check_power_floated(LongDecimal("1.0000000000000000000003580000000000000000000000376238"),
                        LongDecimal("-359.0000000003910721000000000000000000000000000000000000000000000000000000000000000000000000479"),
                        39)
    puts "e"
  end

  def _test_lm_power0f
    print "\ntest_lm_power0f [#{Time.now}]: "
    check_power_floated(LongDecimal("1.000000000000000000000032000000001500000000000000000000439"),
                        LongDecimal("-252.00000000000000025500000000000176907"),
                        39)
    puts "f"
  end

  def _test_lm_power0g
    print "\ntest_lm_power0g [#{Time.now}]: "
    check_power_floated(LongDecimal("1.0000000000000008590000521000000000000621"),
                        LongDecimal("-135.0000000000000000000000000000000000000000000000000000000074400000000000000000000000000321"),
                        50)
    puts "g"
  end

  def _test_lm_power0h
    print "\ntest_lm_power0h [#{Time.now}]: "
    check_power_floated(LongDecimal("1.000000000000000151000000000000000000000000000000000000000000000000000000000000057800000000205"),
                        LongDecimal("-680.0000000000000000000013100000000000000000000000000000000000000165000000000000000000234"),
                        26)
    puts "h"
  end

  def _test_lm_power0i
    print "\ntest_lm_power0i [#{Time.now}]: "
    check_power_floated(LongDecimal("1.02350000000000000000000356000000000000000000000000000000000000000000000000000000000104"),
                        LongDecimal("-971.0000000000000000055400000000000000000000000000000000000000000000000000040900000000000000000000000603"),
                        45)
    puts "i"
  end

  def _test_lm_power0j
    print "\ntest_lm_power0j [#{Time.now}]: "
    check_power_floated(LongDecimal("1.0023800000000000000000000000000000000000000000000000000000000000265000000000000000000000000000000453"),
                        LongDecimal("-277.000000000000000000000000000000000000000000000000000000000000113000000000000000000041400000294"),
                        22)
    puts "j"
  end

  def _test_lm_power0k
    print "\ntest_lm_power0k [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003422250001093950095910422515315300670761"),
                        LongDecimal("-0.99999999999999999999999999999999999999999999999999997909999999999999999999999999667999957000000000000000065521500000000000000000000020816402696099999999999997719321110428280027729999999129874367303020000000000071412895105695789681563000036363932570289984431712381817869482773696988055442648559706239710901091550702341077381290973316336980640165855210736680"),
                        46)
    puts "k"
  end

  def _test_lm_power0l
    print "\ntest_lm_power0l [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000049273899694369"),
                        LongDecimal("-0.99999999999999999999999999999999999999988899963450000000000000000000000000000001847988671170038537499999999999999999999658146648184996349480690906250000000000066400422857493760370353798820585648437488207957808220483456569835670219978619056054192244103752969215743872596800486621906638928959243058783356441503226136251748249991020724187893339868"),
                        40)
    puts "l"
  end

  def _test_lm_power0m
    print "\ntest_lm_power0m [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000003868840000000000000000000328416000000000000000000006969600000000000000000000000000000059338800000000000000000002518560000000000000000000000000000000000000000000000000000000227529"),
                        LongDecimal("-0.999999999999999999999999999999999999999999999999999998264999999999999999999999999999616741000000000000000004515337500000000000000000000001994863094999999999999986943149282831191620999999999993077825060350000000000033980453035745280148525000000024019946927993617107497210600671335038418031107762499920991889855598841096454678838495791189026426859181655270271342"),
                        31)
    puts "m"
  end

  def _test_lm_power0n
    print "\ntest_lm_power0n [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000435600000000000000000000000000000000000000000000000006204000000075240000000000000000000000000000000000000022090000000535800000003249"),
                        LongDecimal("-4.50377349099168904759987513420506734335755704389619751192197520413005925604849718759451665302464588879636922713303481423460050066204079523260315868192642742903330525895063299416"),
                        20)
    puts "n"
  end

  def _test_lm_power0o
    print "\ntest_lm_power0o [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000700720943029391693947940220429504569709269190190365416713568"),
                        LongDecimal("-6.633249580710799698229865473341373367854177091179010213018664944871230"),
                        7)
    puts "o"
  end

  def _test_lm_power0p
    print "\ntest_lm_power0p [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000816700000697"),
                        LongDecimal("-0.58685446009389671361502347417840375586854460093896713614906034406753510106019528753113359342280707917300359276157963863070992095386428055722936293804476401957909668625460628698383384886591034139"),
                        36)
    puts "p"
  end

  def _test_lm_power0q
    print "\ntest_lm_power0q [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000046500000000000015087"),
                        LongDecimal("-1.0000000037300000000000000000000000000000000000000000003924"),
                        3)
    puts "q"
  end

  def _test_lm_power0r
    print "\ntest_lm_power0r [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000002450257484405715360000000000000000097614149083200000000000000000000000972196"),
                        LongDecimal("-1.00000008600000184900000000000000000000000000000000000000012640000543520000000000000000000013300000571900000000000000399424000000000000000000000000000840560000000000000000000000000000442225"),
                        3)
    puts "r"
  end

  def _test_lm_power0s
    print "\ntest_lm_power0s [#{Time.now}]: "
    check_power_floated(LongDecimal("0.00000000000000000000000000000000000000000000000000000000000000000000367236000000000000000093202800000000000000005914074196000000000000000058905400000000000000000000146689"),
                        LongDecimal("-1.000000000008800000000019360000000062800000000276320250000000001100000985960000000000007850000000000000015625"),
                        4)
    puts "s"
  end

  def _test_lm_power0t
    print "\ntest_lm_power0t [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000000000000000000000000000000000002777290000000006513720000000003819240000000000000000000000000000100340800000000117667200000000000000000000000000000000000000000000906304"),
                        LongDecimal("-0.5773502691896257645091447198050641552797247036332110311421498194545129249630222981047763195372146430879281215100223411775138874331819083544781222838698051829302865547075365868655847179043571799566074987574406310154782766513220296853158689786573196010629608653145605201822170964422894732870490642190250948498852022304300879727510280657218553"),
                        23)
    puts "t"
  end

  def _test_lm_power0u
    print "\ntest_lm_power0u [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000000000007350000295000915"),
                        LongDecimal("-1.000002193000861"),
                        2)
    puts "u"
  end

  def _test_lm_power0v
    print "\ntest_lm_power0v [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000086862400000000000000015172960006039360000000662596000527472000104976"),
                        LongDecimal("-0.999999999999999999999999999999999999999999999999999999999997169999999999996784999999999687000000000000000000000000000012013350000000027295350000002672874337500003018885000000146896669625999999845508318999984783776699499965759759873248317316431267825611053489338193758007138415641516991908731376997678345955102618540146326218008264916981179817214058767402196571"),
                        11)
    puts "v"
  end

  def _test_lm_power0w
    print "\ntest_lm_power0w [#{Time.now}]: "
    check_power_floated(LongDecimal("0.00000000000000000000000000624000383000000000000000000000000000000000000000000000358"),
                        LongDecimal("-1.0000004600000000000000000000000000000004210"),
                        3)
    puts "w"
  end

  def _test_lm_power0x
    print "\ntest_lm_power0x [#{Time.now}]: "
    check_power_floated(LongDecimal("0.00000000006236994468492015585972291475115698519825552824875948893004062366348813472156776148562881057978611940708477498267201430163921921918813918304834563518614088250202460271818014152969"),
                        LongDecimal("-21.81742422927144044215775880732087497227530694228658299334049542576403906256739064739549866577137008231569804502022381108724983114382624747999460445291671084230968250529511708947428208082234"),
                        6)
    puts "x"
  end

  def _test_lm_power0y
    print "\ntest_lm_power0y [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000000035600000000928000000000000000450"),
                        LongDecimal("-0.70821529745042492917661444999959874487397062785764977666003279651340417551441776107007487983685090756343178115766012078677210548592741818458068450268168492334992979756923"),
                        13)
    puts "y"
  end

  def _test_lm_power0z
    print "\ntest_lm_power0z [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000025900000000000000000000000000000000000000000022100000000000000000032"),
                        LongDecimal("-0.999943403203378688766215832183174473300891276419706031790088430934495839737458766990116492"),
                        4)
    puts "z"
  end

  def test_lm_power1a
    print "\ntest_lm_power1a [#{Time.now}]: "
    check_power_floated(LongDecimal("0.002658925294303146195800785280451092866235470739838791730450519159432915"),
                        LongDecimal("-87.0000000000000008330000000000000000000000000000000000000000000000000000000000000000000000000092046"),
                        90)
    puts "a"
  end

  def test_lm_power1b
    print "\ntest_lm_power1b [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0014814814814814814812905349794238683127818125285779606767229367555739725854802645575188374989810195213530274617178142875856830586369415448003164084698537116523550097"),
                        LongDecimal("-52.0000000000000000000000000000000000000000683000000000000000000238000000000228"),
                        25)
    puts "b"
  end

  def test_lm_power1c
    print "\ntest_lm_power1c [#{Time.now}]: "
    check_power_floated(LongDecimal("0.00000000000000000000047400000000000000000084700000892"),
                        LongDecimal("-17.000000001310000000000000000000000000000000000000000000000000002800000000000000217"),
                        56)
    puts "c"
  end

  def test_lm_power1d
    print "\ntest_lm_power1d [#{Time.now}]: "
    check_power_floated(LongDecimal("0.00000000000000000000005110000000000000000004800000000000000000000000000000163"),
                        LongDecimal("-37.000000009170000000000000000000000000000000000000000000000000000000000000055800048"),
                        21)
    puts "d"
  end

  # SLOW!!!
  def test_lm_power1e
    print "\ntest_lm_power1e [#{Time.now}] (2 hours): "
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000002450257484405715360000000000000000097614149083200000000000000000000000972196"),
                        LongDecimal("-1.00000008600000184900000000000000000000000000000000000000012640000543520000000000000000000013300000571900000000000000399424000000000000000000000000000840560000000000000000000000000000442225"),
                        3)
    puts "e"
  end

  # SLOW!!!
  def test_lm_power1f
    print "\ntest_lm_power1f [#{Time.now}] (2 hours): "
    check_power_floated(LongDecimal("0.999999999999983820000000000052544300000001372125483999980457478288050051600649560171986452284020178492146835403829341250837967306416835643061512149984415283328897050537606939603101940467080257495289168053434691062993302374332577706782680685214083677104079828206433042861334386773091111658939537092356816922764138900649581031721453211835260155666851398044388924204855221543729490461274063089475188763279119570"),
                        LongDecimal("80321932.89024988628926432624765785135567744505377819122460049392916097399960142838065367057138986526363804"),
                        40)
    puts "f"
  end

  # SLOW!!!
  def test_lm_power1g
    print "\ntest_lm_power1g [#{Time.now}] (3 hours): "
    check_power_floated(LongDecimal("0.999999999999999999999999999999998351999999999999983020000000000002036927999998210041974559999999997978335404004424810825925120045592892314014072707890311225042124730264194167337496376801852022987153782535008598977724682635285958668331865904517437818865287190004735483899633845078360662820274644903126498781970492928578903950"),
                        LongDecimal("24449877750611246943765281173.594132029339853300733454400081300326994697544849684064538112517261374573394648075725881734888526076256999828217542217625441301525934675012853453406806380262764050867999"),
                        5)
    puts "g"
  end

  # FAILURE!!! (needs to be fixed)
  def test_lm_power1h
    #  32) Failure:
    # test_lm_power1h(TestLongDecimalExtra_class) [/home/bk1/ruby/long-decimal/ruby/long-decimal/test/testlongdeclib.rb:537]:
    # u=log(z,7)=0.0000000 and yv=y*v=y*log(x,67)=-0.0000785 should be almost equal (unit=0.0000001 x=0.9999999999999999999999999999999999999999999999999999999999999992419999999999601999999916300000000000000000000000000000000000005745640000000603368000126905040400006662520000700569 y=103626942927112137297398420916877844574257389450065434211636.290893349001885021464207122860891972260613740163376239637940672943781241170230437221414760788160997546494517494155287108299429330120640311594334671250673655216674953919962963363315956632 z=1.0000000 u=0.0000000 v=-0.0000000000000000000000000000000000000000000000000000000000000007580 lprec=7 prec=7)

    print "\ntest_lm_power1h [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999862599981980000014159073713922242243328677707050386499779178242565766291900177208859765599761583988066205590104341111429059119646260524293805643133602429678974677397380813589741657940554009198199034562447106122960905140273768835224006261013069576237942279008951360618433986"),
                        LongDecimal("10266940451745.37987679671457905534956086166404546967839388790271998098584221166751699838745542116653920000125768690393028114699714286512441385099525"),
                        14)
    puts "h"
  end

  def test_lm_power1h_i

    print "\ntest_lm_power1h_i [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999862599981980000014159073713922242243328677707050386499779178242565766291900177208859765599761583988066205590104341111429059119646260524293805643133602429678974677397380813589741657940554009198199034562447106122960905140273768835224006261013069576237942279008951360618433986"),
                        LongDecimal("10266940451745"),
                        14)
    puts "h"
  end

  # FAILURE!!! (needs to be fixed)
  def test_lm_power1i
    #  33) Failure:
    # test_lm_power1i(TestLongDecimalExtra_class) [/home/bk1/ruby/long-decimal/ruby/long-decimal/test/testlongdeclib.rb:537]:
    # u=log(z,13)=-0.0111941165167 and yv=y*v=y*log(x,76)=-0.0111941184373 should be almost equal (unit=0.0000000000001 x=1.000000000000000000000000000000000000000000000000000000000000000040632256971361441675364911547119523862617306023293961145667519711601390076843063624462699881424344873551296525030641685492629965401733250018815534188264352396285608689080041860127898254008134983805964167477328233064049446442345195928792206909976566059881698019 y=-275498317635275642242287018621310530812854589333829844444179465.026486828659378492893391926808279692889516447254926463357381523771105223660032617000227932272791794838690719013665737808233622061943268216888533855404111493288875534126178784830550654618969484969704069638284634725831920698820381864995363361738394367829090059556279914810540013438298547827401014937988931120431027937060054429855616000850263332145848273205542636020219974448846631834726343291615390210989854686573686051987947338952241558404158600234046969306176292822304779868899689391647661253521411090531104030615753856329486732170039585239348687257061864897478622958348189113878179294939392893585430107561210696450698403851795968372396462047808473453132852141249623740994995021422532249082127739 z=0.98886830447251 u=-0.0111941165167 v=0.0000000000000000000000000000000000000000000000000000000000000000406322569714 lprec=13 prec=14)
    print "\ntest_lm_power1i [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999981500000000000000256687499999999996834187500000000036604706930449997823687754750325053502286291757658419972795166437108241085949094447949893401640711985948839881287077716265593625727522425306777978451009970778400655052736724232660803755458234164496101454557290134193942433026948513566480800350007916601440691706219670728270104113540"),
                        LongDecimal("41380294430118397.455148144857963343847598908617723236165122243380531570432704458595232182042029429597565318650987561380534985825811466980798564531839364855305381553585381037046185516421336524897364607404185776449463"),
                        26)
    puts "i"
  end

  def test_lm_power1i_i
    print "\ntest_lm_power1i_i [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999981500000000000000256687499999999996834187500000000036604706930449997823687754750325053502286291757658419972795166437108241085949094447949893401640711985948839881287077716265593625727522425306777978451009970778400655052736724232660803755458234164496101454557290134193942433026948513566480800350007916601440691706219670728270104113540"),
                        LongDecimal("41380294430118397"),
                        26)
    puts "i"
  end

  def test_lm_power1j
    print "\ntest_lm_power1j [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000046500000000000015087"),
                        LongDecimal("-1.0000000037300000000000000000000000000000000000000000003924"),
                        23)
    puts "j"
  end

  def test_lm_power1k
    print "\ntest_lm_power1k [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999955000001687499940937501993359309219142762877860969997307557898777919131305606255214050322693251861572813240921773249050643887299214365089256902862200379712695062301304665207421015981915226866332635406597037254705387928614026219686983926304930980563519261869550253533841712248417739856791299844197817284010721773168197981077997089850680475101280715114294984559298890080189837019"),
                        LongDecimal("1152073732.71889400921658986175115207373271889400921658986175115207373271192582125814946165771199218501136146446091443861623733780713117713266372156187325484891985619348320999757983534072600830"),
                        34)
    puts "k"
  end

  def test_lm_power1l
    print "\ntest_lm_power1l [#{Time.now}]: "
    check_power_floated(LongDecimal("0.9999999999999999790000000000000003307499999999999953571199999534000611652825014678992260416924691741095240984082153184971715719141172674714489939586322093325704050326051366867179642182008596501250357001333611677371975442553576183439891558582498678369021915"),
                        LongDecimal("723078346985052524411124.9942153732241195797916759141992675639370468905781573122561996247342863251769951237981444054472420932945762836317152649920140953979776753551488373967949714070011978110437743347922047335540909708006357292133505068791464115479823527616"),
                        12);
    puts "l"
  end

  def test_lm_power1m
    print "\ntest_lm_power1m [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000496000000000000000000000005130181"),
                        LongDecimal("4.481689070338064822602055460119275819005749868369667078288462665422608992659321754902779723364868999617977618563052671037918163226699981361015453605440282335627715767767332447975568034896269722320687889640"),
                        53)
    puts "m"
  end

  def test_lm_power1n
    print "\ntest_lm_power1n [#{Time.now}]: "
    check_power_floated(LongDecimal("0.99999996920000071147998520954428850500259566957301785488841492770856751549533360159782111532707660143588897363762546661839650329823327036644"),
                        LongDecimal("5136654.9693748423207184796146471922038482162171466427358132415227272949550162107575"),
                        35)
    puts "n"
  end

  def test_lm_power1o
    print "\ntest_lm_power1o [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999999999999999999999999999999999999990849999999999997459999999999999999999999999999514083722500000000046482000000000006451600000000008893033939125002468242034549999999822903580000236058"),
                        LongDecimal("0.0000000000000000000000000000000"),
                        20)
    puts "o"
  end

  def test_lm_power1p
    print "\ntest_lm_power1p [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999999999999999999999999999999999999990849999999999997459999999999999999999999999999514083722500000000046482000000000006451600000000008893033939125002468242034549999999822903580000236058"),
                        LongDecimal("0.0000000000000000000000000000000"),
                        40)
    puts "p"
  end

  def test_lm_power1q
    print "\ntest_lm_power1q [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999999999999999999999999999999999999990849999999999997459999999999999999999999999999514083722500000000046482000000000006451600000000008893033939125002468242034549999999822903580000236058"),
                        LongDecimal("0.0000000000000000000000000000000"),
                        6)
    puts "q"
  end

  def test_lm_power1r
    print "\ntest_lm_power1r [#{Time.now}]: "
    check_power_floated(LongDecimal("0.9999998980000104039989387921082432049591930941623043954449516646149302092771178487340615327073490985245976137220657507850136754851390337493573677445898517902642450071877694654887775650"),
                        LongDecimal("-0.00000010199999479800035373597293919820816141870627986580"),
                        20)
    puts "r"
  end

  def test_lm_power1s
    print "\ntest_lm_power1s [#{Time.now}]: "
    check_power_floated(LongDecimal("0.9999998980000104039989387921082432049591930941623043954449516646149302092771178487340615327073490985245976137220657507850136754851390337493573677445898517902642450071877694654887775650"),
                        LongDecimal("-0.00000010199999479800035373597293919820816141870627986580"),
                        40)
    puts "s"
  end

  def test_lm_power1t
    print "\ntest_lm_power1t [#{Time.now}]: "
    check_power_floated(LongDecimal("0.9999998980000104039989387921082432049591930941623043954449516646149302092771178487340615327073490985245976137220657507850136754851390337493573677445898517902642450071877694654887775650"),
                        LongDecimal("-0.00000010199999479800035373597293919820816141870627986580"),
                        60)
    puts "t"
  end

  # SLOW!!!
  def test_lm_power1u
    print "\ntest_lm_power1u [#{Time.now}] (2 hours): "
    check_power_floated(LongDecimal("0.99999999999999999999999999999999999999999999999999992269999999999999999990289999999999999999450000000000597529000000000000001501166000000000000085972840999953811008406809999999825939805325"),
                        LongDecimal("714285714285714285714285714.2857142367346938756989795918367346938775543790087466096793002963472667638481661974177164821324438268046647105967619250931245847564869975795833510071"),
                        25)
    puts "u"
  end

  # SLOW!!!
  def test_lm_power1v
    print "\ntest_lm_power1v [#{Time.now}] (2 hours): "
    check_power_floated(LongDecimal("0.999999999999999999072867000000000000859575599688999999203059095533538363738068211580703976213177165458547180420859035425970198975506846513796073745523480165"),
                        LongDecimal("34260010678356060340110500.7153234888531563303375970232929042708037751160246890208435860708347495272359620209409070219221760532838693330228630931194027855701638117625325214394917620590686906959334466842413732434252133614001314264745394120941492068918606855981807681794442879762888899961878810388388032398007558964413624601333106812667470835155455035290542870179962369969203293410746331815980"),
                        4)
    puts "v"
  end

  def test_lm_power1w
    print "\ntest_lm_power1w [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999955000001687499940937501993359309219142762877860969997307557898777919131305606255214050322693251861572813240921773249050643887299214365089256902862200379712695062301304665207421015981915226866332635406597037254705387928614026219686983926304930980563519261869550253533841712248417739856791299844197817284010721773168197981077997089850680475101280715114294984559298890080189837019"),
                        LongDecimal("1152073732.71889400921658986175115207373271889400921658986175115207373271192582125814946165771199218501136146446091443861623733780713117713266372156187325484891985619348320999757983534072600830"),
                        34)
    puts "w"
  end

  def test_lm_power1x
    print "\ntest_lm_power1x [#{Time.now}]: "
    check_power_floated(LongDecimal("0.9999999999999999064168934619655513256941764460425414729252240962626457779773851512889793738821624571066326550143425938244580355705073371363498199960410647291522935828683767303102466756569778099219013139392035"),
                        LongDecimal("10940919037196297324861503538918892464840.3800411376419061644237297393478808698419759633900911655114302630926763678029075600021060757487171800272518085362"),
                        31)
    puts "x"
  end

  # SLOW!!!
  def test_lm_power1y
    print "\ntest_lm_power1y [#{Time.now}] (3 hours): "
    check_power_floated(LongDecimal("0.9999999999999999999999999999999999999999999938200000000000000000000000000000000000000000379683968899999999999999999999999999999999997667396464396000000000000000000000000000000014330439460181976721"),
                        LongDecimal("2277904328018223234624145785876970127.80132938289029176166582780311904615875187470778863280340852479308725681566723062546696023632646350474949485203212931524794058129718906431046410107451255702719381563833303042603168923"),
                        29)
    puts "y"
  end

  def test_lm_power1z
    print "\ntest_lm_power1z [#{Time.now}]: "
    check_power_floated(LongDecimal("0.999999999999999999999999999999999999999999921999999999022000000000000000000000000000004562456000114426000000717362999999999999999762787647991075570047888091371999532279324011562240678532015324522910310739147205531819744871729906561958405090975079783409588877137073074435963740549942065227793722398369867644224486056519686420388938836344615901685525200381485995400522678667"),
                        LongDecimal("251896264925304377034350.0456973701263557812685942497288369797184140257647711785792872260304633895246908954737965005622561558677304225230618944035174740629720501757778145343269720425431792498286712042768306433898613430002918272371991628626003640130802094416142868825298695247199911145446388281612176850992412410783824332967890487347362798155764095915034449097990865463350294815436981248914797801550176"),
                        35)
    puts "z"
  end

  def test_lm_power1a
    print "\ntest_lm_power1a [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000046500000000000015087"),
                        LongDecimal("-1.0000000037300000000000000000000000000000000000000000003924"),
                        20)
    puts "a"
  end

  def test_lm_power1b
    print "\ntest_lm_power1b [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000046500000000000015087"),
                        LongDecimal("-1.0000000037300000000000000000000000000000000000000000003924"),
                        40)
    puts "b"
  end

  def test_lm_power1c
    print "\ntest_lm_power1c [#{Time.now}]: "
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000046500000000000015087"),
                        LongDecimal("-1.0000000037300000000000000000000000000000000000000000003924"),
                        60)
    puts "c"
  end

  def test_lm_power1d
    print "\ntest_lm_power1d [#{Time.now}]: "
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000839040721742199946496057135094908790087131086768769514275053742150410299262922831017525963255748365635401006943680692892935684091800542751473902211475954311868825323737772210353295492066820457541121321"),
                        LongDecimal("2.828427124746193491715927143848192103847391807094579920269011137128713363765124971278"),
                        18)
    puts "d"
  end

  def test_lm_power1e
    print "\ntest_lm_power1e [#{Time.now}]: "
    check_power_floated(LongDecimal("0.99999999999999999957080000000000000013815947999999999996046796745599999999068446772992800001009363347018894143517944326551369536327300875532667540019363271336013307136215732697434336575655193825816793693484735543517962560133437707866565666368082465969956371712599637541755027515672768774646443956623736866833"),
                        LongDecimal("1628664495113750809027151521859950785.982561401863566922682596781753765470394912797043370321097687714712745442876309819766690333961107251381272682168155358789120923845170161713855374636824144351065708845142153775687292"),
                        25)
    puts "e"
  end

  def test_lm_power1f
    print "\ntest_lm_power1f [#{Time.now}]: "
    check_power_floated(LongDecimal("0.9999999999999999999996170000000000000000001466889999999999999995988181130000000000002857876622509999999998399356205378770000001997124082800492789998249134043407016130331222803769176235159503"),
                        LongDecimal("10080628902211448045469261303.5133048444625606725923502869474154814472661420686348619932383678206438602596885342965949921926737285"),
                        40)
    puts "f"
  end

  def test_lm_power1g
    print "\ntest_lm_power1g [#{Time.now}]: "
    check_power_floated(LongDecimal("0.99999999999999999999999999999999999999999999999999999567999999999999999999999999993280680000000000000000001866240000000000000000000000058054924799999999999999991938294692612624"),
                        LongDecimal("172711571675280380383067706300721798.164293576729518909754806389655985463898067955382434334508821341973697474920186895196633042535349353452630898625575004836357975433177114954313031033076280846"),
                        29)
    puts "g"
  end

  def test_lm_power1h
    print "\ntest_lm_power1h [#{Time.now}]: "
    check_power_floated(LongDecimal("0.9999999999999999999999999999999999999999999999999999999999999992419999999999601999999916300000000000000000000000000000000000005745640000000603368000126905040400006662520000700569"),
                        LongDecimal("103626942927112137297398420916877844574257389450065434211636.290893349001885021464207122860891972260613740163376239637940672943781241170230437221414760788160997546494517494155287108299429330120640311594334671250673655216674953919962963363315956632"),
                        7)
    puts "h"
  end

  def test_lm_power1i
    print "\ntest_lm_power1i [#{Time.now}]: "
    check_power_floated(LongDecimal("1.000000000000000000000000000000000000000000000000000000000000000040632256971361441675364911547119523862617306023293961145667519711601390076843063624462699881424344873551296525030641685492629965401733250018815534188264352396285608689080041860127898254008134983805964167477328233064049446442345195928792206909976566059881698019"),
                        LongDecimal("-275498317635275642242287018621310530812854589333829844444179465.026486828659378492893391926808279692889516447254926463357381523771105223660032617000227932272791794838690719013665737808233622061943268216888533855404111493288875534126178784830550654618969484969704069638284634725831920698820381864995363361738394367829090059556279914810540013438298547827401014937988931120431027937060054429855616000850263332145848273205542636020219974448846631834726343291615390210989854686573686051987947338952241558404158600234046969306176292822304779868899689391647661253521411090531104030615753856329486732170039585239348687257061864897478622958348189113878179294939392893585430107561210696450698403851795968372396462047808473453132852141249623740994995021422532249082127739"),
                        14)
    puts "i"
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

end

# RUNIT::CUI::TestRunner.run(TestLongDecimalExtra_class.suite)

# end of file testlongdecimal.rb
