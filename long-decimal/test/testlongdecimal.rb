#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for longdecimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdecimal.rb,v 1.5 2006/03/04 21:49:00 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_09 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "runit/testcase"
require "runit/cui/testrunner"
require "runit/testsuite"

load "lib/longdecimal.rb"

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimal_class < RUNIT::TestCase

  @RCS_ID='-$Id: testlongdecimal.rb,v 1.5 2006/03/04 21:49:00 bk1 Exp $-'

  def check_split_merge_words(x, l, wl)
    w = LongMath.split_to_words(x, l)
    y = LongMath.merge_from_words(w, l)
    assert_equal(x, y, "#{x} splitted and merged should be equal but is #{y} l=#{l}")
    assert_equal(wl, w.length, "#{x} splitted to l=#{l} should have length #{wl} but has #{w.length}")
    w
  end

  #
  # test split_to_words and merge_from_words
  #
  def test_split_merge_words
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
  # helper method for test_exp
  #
  def check_exp_floated(x, prec)
    x0 = x
    x = x.to_ld
    y = LongMath.exp(x, prec)
    z = Math.exp(x.to_f)
    yf = y.to_f
    assert((yf - z) / [yf.abs, z.abs, Float::MIN].max < 1e-9, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")
    yd = LongMath.exp_internal(x, prec, nil, nil, nil, nil, LongDecimal::ROUND_DOWN)
    yu = LongMath.exp_internal(x, prec, nil, nil, nil, nil, LongDecimal::ROUND_UP)
    #    if (x >= 0)
    assert_equal(yd, yu, "the result yd/yu should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    assert_equal(y,  yu, "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(y -yu).to_f.to_s}")
    #   else
    #      assert((yu - yd).abs <= y.unit, "the difference should not be too much x=#{x} d=#{(yd-yu).to_f.to_s}")
    #      assert((yu - y ).abs <= y.unit, "the difference should not be too much x=#{x} d=#{(y -yu).to_f.to_s}")
    #    end
  end

  #
  # test the calculation of the exponential function
  #
  def test_exp
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
  end

  #
  # helper method for test_sqrtb
  #
  def check_sqrtb(x, s)
    y = LongMath.sqrtb(x)
    z = y * y
    zz = (y+1)*(y+1)
    assert(0 <= y, "sqrt must be >= 0" + s)
    assert(z <= x && x < zz, "y=#{y}=sqrt(#{x}) and x in [#{z}, #{zz})" + s)
    y
  end

  #
  # test method sqrtb for calculating sqrt of short integers
  #
  def test_sqrtb
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
  # helper method of test_sqrtw
  #
  def check_sqrtw(x, s)
    y = LongMath.sqrtw(x)
    z = y * y
    zz = (y+1)*(y+1)
    assert(0 <= y, "sqrt must be >= 0" + s)
    assert(z <= x && x < zz, "y=#{y}=sqrt(#{x}) and x in [#{z}, #{zz})" + s)
    y
  end

  #
  # test method sqrtb for calculating sqrt of long integers
  #
  def test_sqrtw
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
  # test gcd_with_high_power
  #
  def test_gcd_with_high_power
    n = 224
    assert_equal(32, LongMath.gcd_with_high_power(n, 2), "2-part of 224 is 32")
    assert_equal(7, LongMath.gcd_with_high_power(n, 7), "7-part of 224 is 7")
    assert_equal(1, LongMath.gcd_with_high_power(n, 3), "3-part of 224 is 1")
  end

  #
  # test multiplicity_of_factor for integers
  #
  def test_multiplicity_of_factor
    n = 224
    assert_equal(5, LongMath.multiplicity_of_factor(n, 2), "ny_2(224) is 5")
    assert_equal(1, LongMath.multiplicity_of_factor(n, 7), "ny_7(224) is 1")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 3), "ny_3(224) is 0")
  end

  #
  # test multiplicity_of_factor for rationals
  #
  def test_rat_multiplicity_of_factor
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
  def test_rat_multiplicity_of_factor
    # 0.729
    n = LongDecimal(729, 3)
    assert_equal(-3, LongMath.multiplicity_of_factor(n, 2), "ny_2(n) is -3")
    assert_equal(6, LongMath.multiplicity_of_factor(n, 3), "ny_3(n) is 6")
    assert_equal(-3, LongMath.multiplicity_of_factor(n, 5), "ny_5(n) is -3")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 7), "ny_7(n) is 0")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 11), "ny_11(n) is 0")
  end

  #
  # test construction from Integer
  #
  def test_int_init
    l = LongDecimal(224)
    assert_equal(224, l.to_i, "no loss of information for integers allowed")
    l = LongDecimal(-333)
    assert_equal(-333, l.to_i, "no loss of information for integers allowed")
    l = LongDecimal(1000000000000000000000000000000000000000000000000)
    assert_equal(1000000000000000000000000000000000000000000000000, l.to_i, "no loss of information for integers allowed")
    l = LongDecimal(19, 1)
    assert_equal(1, l.to_i, "loss of information 1.9->1")
  end

  #
  # test construction from Rational
  #
  def test_rat_init
    r = Rational(227, 100)
    l = LongDecimal(r)
    assert_equal(r, l.to_r, "no loss of information for rationals with denominator power of 10 allowed l=#{l.inspect}")
    l = LongDecimal(r, 3)
    assert_equal(r, l.to_r * 1000, "scaling for rationals")
    r = Rational(224, 225)
    l = LongDecimal(r)
    assert((r - l.to_r).to_f.abs < 0.01, "difference of #{r.inspect} and #{l.inspect} must be less 0.01 but is #{(r - l.to_r).to_f.abs}")
  end

  #
  # test construction from Float
  #
  def test_float_init
    s = "5.32"
    l = LongDecimal(s)
    assert_equal(s, l.to_s, "l=#{l.inspect}")
    f = 2.24
    l = LongDecimal(f)
    assert_equal(f.to_s, l.to_s, "l=#{l.inspect} f=#{f.inspect}")
    f = 2.71E-4
    l = LongDecimal(f)
    assert_equal("0.000271", l.to_s, "l=#{l.inspect} f=#{f.inspect}")
  end

  #
  # test construction from BigDecimal
  #
  def test_bd_init
    b = BigDecimal("5.32")
    l = LongDecimal(b)
    assert_equal(b, l.to_bd, "l=#{l.inspect}")
    b = BigDecimal("2.24")
    l = LongDecimal(b)
    assert((b.to_f - l.to_f).abs < 1e-9, "l=#{l.inspect} b=#{b.inspect}")
    b = BigDecimal("2.71E-4")
    l = LongDecimal(b)
    assert_equal("0.000271", l.to_s, "l=#{l.inspect} b=#{b.inspect}")
  end

  #
  # test rounding with ROUND_UP
  #
  def test_round_to_scale_up
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_UP)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_DOWN
  #
  def test_round_to_scale_down
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_DOWN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_CEILING
  #
  def test_round_to_scale_ceiling
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_CEILING)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_FLOOR
  #
  def test_round_to_scale_floor
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_FLOOR)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_UP
  #
  def test_round_to_scale_half_up
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_DOWN
  #
  def test_round_to_scale_half_down
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_EVEN
  #
  def test_round_to_scale_half_even
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.35")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.4", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.35")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.4", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_UNNECESSARY
  #
  def test_round_to_scale_unnecessary
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_UNNECESSARY)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.2400")
    r = l.round_to_scale(2, LongDecimal::ROUND_UNNECESSARY)
    assert_equal("2.24", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    begin
      l = LongDecimal("2.24")
      r = l.round_to_scale(1, LongDecimal::ROUND_UNNECESSARY)
      assert_fail("should not have succeeded l=#{l.inspect} r=#{r.inspect}")
    rescue ArgumentError
      # ignored
    end
  end

  #
  # test conversion to String
  #
  def test_to_s
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
  # test conversion to Rational
  #
  def test_to_r
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

  #
  # test conversion to Float
  #
  def test_to_f
    l = LongDecimal(224, 0)
    assert((l.to_f - 224).abs < 224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert((l.to_f - 22.4).abs < 22.4 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert((l.to_f - 2.24).abs < 2.24 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert((l.to_f - 0.224).abs < 0.224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert((l.to_f - 0.0224).abs < 0.0224 * 0.000001, "l=#{l.inspect}")
  end

  #
  # test conversion to BigDecimal
  #
  def test_to_bd
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

  def test_equalize_scale
    x = LongDecimal(1, 0)
    y = LongDecimal(10, 1)
    assert_equal(0, (x - y).sgn, "difference must be 0")
    assert(! (x == y), "x and y have the same value, but are not equal")
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

  def test_anti_equalize_scale
    x = LongDecimal(20, 3)
    y = LongDecimal(10, 1)
    u, v = x.anti_equalize_scale(y)
    assert_equal(0, u.scale, "scale must be 0")
    assert_equal(0, v.scale, "scale must be 0")
    assert_equal(20, u.int_val, "int_val must be 20")
    assert_equal(1000, v.int_val, "int_val must be 1000")
  end

  def test_negation
    x = LongDecimal(0, 5)
    assert_equal(-x, x, "x and -x are equal for negative x=#{x.inspect}")
    x = LongDecimal(224, 2)
    y = -x
    assert_equal(-1, y.sgn, "sign of y must be -1 y=#{y.inspect}")
    assert_equal(2, y.scale, "scale of y must be 2 y=#{y.inspect}")
    assert_equal(-224, y.int_val, "int_val of y must be -224 y=#{y.inspect}")
  end

  def test_add
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

    y = Complex(5, 3)
    z = x + y
    zz = Complex(7.24, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  def test_sub
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

    y = Complex(5, 3)
    z = x - y
    zz = Complex(-2.76, -3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = Complex(2.76, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  def test_mul
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

    y = Complex(5, 3)
    z = x * y
    zz = Complex(11.20, 6.72)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  def test_div
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x / y
    zz = LongDecimalQuot(Rational(224, 30), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(30, 224), 1)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x / y
    zz = LongDecimalQuot(Rational(224, 500), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(500, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x / y
    zz = LongDecimalQuot(Rational(224, 500), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(500, 224), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x / y
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
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

  def test_pow

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

  def test_divmod
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 30), 2)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(30, 224), 2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 500), 2)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224), 2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5.001
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 500), 2)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224), 2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Rational(5, 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224*3), 2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 500), 6)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224*3), 3)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Complex(5, 3)
    begin
      q, r = x.divmod y
      assert_fail "should have created TypeError"
    rescue TypeError
      # ignored, expected
    end
  end

  def test_abs
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

  def test_move_point
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

  def test_ufo
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

  def test_sgn
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

  def test_equal
    x = LongDecimal(224, 2)
    y = LongDecimal(2240, 3)
    assert((x <=> y) == 0, "diff is zero")
    assert(x != y, "but not equal")
    assert(! (x == y), "but not equal")
    assert_equal(x, x, "x equals x")
    assert_equal(y, y, "y equals y")
  end

  def test_ldq_ld_init
    x = LongDecimal(224, 2)
    y = LongDecimal(225, 3)
    z = LongDecimalQuot(x, y)
    zz = LongDecimalQuot(Rational(2240, 225), 2)
    assert_equal(zz, z, "224/225")
  end

  def test_ldq_round_to_scale_up

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    # 1.0
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  def test_ldq_round_to_scale_down

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    # 0.9
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("-0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  def test_ldq_round_to_scale_ceiling

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("-0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  def test_ldq_round_to_scale_floor

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  def test_ldq_round_to_scale_half_up

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("56.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  def test_ldq_round_to_scale_half_down

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  def test_ldq_round_to_scale_half_even

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.75
    l = LongDecimalQuot(Rational(227, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("56.8", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("227/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  def test_ldq_round_to_scale_unnecessary
    l = LongDecimalQuot(Rational(225, 4), 5)
    r = l.round_to_scale(2, LongDecimal::ROUND_UNNECESSARY)
    assert_equal("56.25", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    begin
      r = l.round_to_scale(1, LongDecimal::ROUND_UNNECESSARY)
      assert_fail("should not have succeeded l=#{l.inspect} r=#{r.inspect}")
    rescue ArgumentError
      # ignored
    end
  end

  def test_ldq_to_s
    l = LongDecimalQuot(Rational(224, 225), 226)
    assert_equal("224/225[226]", l.to_s, "l=#{l.inspect}")
    l = LongDecimalQuot(Rational(-224, 225), 226)
    assert_equal("-224/225[226]", l.to_s, "l=#{l.inspect}")
  end

  def test_ldq_to_r
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

  def test_ldq_to_f
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

  # to_i not tested, goes via to_r anyway

  def test_ldq_negation
    x = LongDecimalQuot(Rational(0, 2), 3)
    assert_equal(-x, x, "x and -x are equal for negative x=#{x.inspect}")
    x = LongDecimalQuot(Rational(224, 225), 226)
    yy = LongDecimalQuot(Rational(-224, 225), 226)
    y = -x
    assert_equal(-1, y.sgn, "sign of y must be -1 y=#{y.inspect}")
    assert_equal(226, y.scale, "scale of y must be 2 y=#{y.inspect}")
    assert_equal(yy, y, "yy and y must be equal")
  end

  def test_ldq_add
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

  def test_ldq_sub
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

  def test_ldq_mul
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

  def test_ldq_div
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

  def test_ldq_pow

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

  def test_ldq_divmod
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
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

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

  def test_ldq_abs
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

  def test_ldq_ufo
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

  def test_ldq_sgn
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

  def test_ldq_equal
    x = LongDecimalQuot(Rational(224, 225), 226)
    y = LongDecimalQuot(Rational(224, 225), 227)
    assert((x <=> y) == 0, "diff is zero")
    assert(x != y, "but not equal")
    assert(! (x == y), "but not equal")
    assert_equal(x, x, "x equals x")
    assert_equal(y, y, "y equals y")
  end

end

RUNIT::CUI::TestRunner.run(TestLongDecimal_class.suite)

# end of file testlongdecimal.rb

