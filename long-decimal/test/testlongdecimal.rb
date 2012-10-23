#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdecimal.rb,v 1.15 2006/03/24 17:42:07 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_16 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "runit/testcase"
require "runit/cui/testrunner"
require "runit/testsuite"

load "lib/long-decimal.rb"

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimal_class < RUNIT::TestCase

  @RCS_ID='-$Id: testlongdecimal.rb,v 1.15 2006/03/24 17:42:07 bk1 Exp $-'

  #
  # helper method for test_split_merge_words
  #
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
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_exp_floated(x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    y = LongMath.exp(x, prec)

    # compare y against z = exp(x) calculated using regular floating point arithmetic
    z = Math.exp(x.to_f)
    yf = y.to_f
    assert((yf - z) / [yf.abs, z.abs, Float::MIN].max < 1e-9, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")

    # check by taking log(exp(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y > 0) then
      lprec = prec
      if (y < 1) then
        l10 = (Math.log(y.to_f) / Math.log(10)).round
        lprec += l10
      end
      z = LongMath.log(y, lprec)
      assert((x - z).abs <= z.unit, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} lprec=#{lprec} prec=#{prec})")
    end

    # check by doing calculation with different internal rounding modes.  They should not differ.
    yd = LongMath.exp_internal(x, prec, nil, nil, nil, nil, LongDecimal::ROUND_DOWN)
    yu = LongMath.exp_internal(x, prec, nil, nil, nil, nil, LongDecimal::ROUND_UP)
    assert_equal(yd, yu, "the result yd/yu should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    assert_equal(y,  yu, "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(y -yu).to_f.to_s}")
  end

  #
  # test the calculation of the exponential function
  #
  def test_exp
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
  end

  #
  # helper method for test_log
  # tests if log(x) with precision prec is calculated correctly
  #
  def check_log_floated(x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = log(x)
    y = LongMath.log(x, prec)

    # compare y against z = exp(x) calculated using regular floating
    # point arithmetic
    if (x <= LongMath::MAX_FLOATABLE) then
      xf = x.to_f
      if (xf > 0) then
        z = Math.log(x.to_f)
        yf = y.to_f
        assert((yf - z) / [yf.abs, z.abs, Float::MIN].max < 1e-9, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")
      end
    end

    # check by taking exp(log(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y <= LongMath::MAX_EXP_ABLE) then
      eprec = prec
      if (y > 1) then
        lx = 0
        if (x > LongMath::MAX_FLOATABLE) then
          puts("unusual x=#{x} y=#{y}\n")
          lx = LongMath::MAX_EXP_ABLE
        else
          lx = Math.log(x.to_f)
        end
        l10 = (lx / Math.log(10)).ceil
        eprec = [ eprec - l10, 0 ].max
      end

      z = LongMath.exp(y, eprec)
      assert((x - z).abs <= z.unit, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec})")
    end

    # check by doing calculation with different internal rounding modes.  They should not differ.
    yd = LongMath.log_internal(x, prec, nil, nil, LongDecimal::ROUND_DOWN)
    yu = LongMath.log_internal(x, prec, nil, nil, LongDecimal::ROUND_UP)
    assert_equal(yd, yu, "the result yd/yu should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    assert_equal(y,  yu, "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(y -yu).to_f.to_s}")
  end

  #
  # test the calculation of the logarithm function
  #
  def test_log
    check_log_floated(10**2000, 10)
    check_log_floated(100, 10)
    check_log_floated(1, 10)
    check_log_floated(0.01, 10)
    check_log_floated(1e-10, 10)
    check_log_floated(1e-90, 10)
    check_log_floated(1e-300, 10)
    check_log_floated(LongDecimal(1, 2000), 10)

    check_log_floated(10**2000, 100)
    check_log_floated(100, 100)
    check_log_floated(1, 100)
    check_log_floated(0.01, 100)
    check_log_floated(1e-10, 100)
    check_log_floated(1e-90, 100)
    check_log_floated(1e-300, 100)
    check_log_floated(LongDecimal(1, 2000), 100)
  end

  #
  # helper method for test_lm_power
  # tests if LongMath::power(x, y, prec) with precision prec is calculated correctly
  #
  def check_power_floated(x, y, prec)

    # puts("start: check_power_floated: x=#{x} y=#{y} prec=#{prec}\n")
    # make sure x and y are LongDecimal
    x0 = x
    x = x.to_ld
    y0 = y
    y = y.to_ld
    # calculate z = x**y
    z = LongMath.power(x, y, prec)

    # compare y against w = x**y calculated using regular floating point arithmetic
    w = (x.to_f) ** (y.to_f)
    zf = z.to_f
    assert((zf - w) / [zf.abs, w.abs, Float::MIN].max < 1e-9, "z=#{zf.to_s} and w=#{w.to_s} should be almost equal x=#{x} y=#{y}")

    # check by taking log(z) = y * log(x)
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (z > 0) then
      lprec = prec
      if (z < 1) then
        l10 = (Math.log(z.to_f) / Math.log(10)).round
        lprec += l10
      end
      if (x < 1) then
        l10 = (Math.log(x.to_f) / Math.log(10)).round
        lprec += l10
      end
      l10y = 0
      if (y > 1) then
        l10y = (Math.log(y.to_f) / Math.log(10)).ceil
      end
      u = LongMath.log(z, lprec)
      v = LongMath.log(x, lprec+l10y)
      yv = (y*v).round_to_scale(lprec, LongDecimal::ROUND_HALF_DOWN)
      assert((u - yv).abs <= u.unit, "u=#{u} and y*v=#{yv} should be almost equal (x=#{x.to_s} y=#{y.to_s} z=#{z.to_s} u=#{u.to_s} v=#{v.to_s} lprec=#{lprec} prec=#{prec})")
    end
    # puts("ok check_power_floated: x=#{x} y=#{y} prec=#{prec}\n")

  end

  #
  # test the calculation of the power-function of LongMath
  #
  def test_lm_power
    check_power_floated(1, 1, 10)
    check_power_floated(1, 2, 10)
    check_power_floated(2, 1, 10)
    check_power_floated(2, 2, 10)
    check_power_floated(100, 10, 10)
    check_power_floated(10, 100, 10)
    check_power_floated(10, 100, 100)
  end

  #
  # helper method for test_log10
  # tests if log10(x) with precision prec is calculated correctly
  #
  def check_log10_floated(x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = log10(x)
    y = LongMath.log10(x, prec)

    # compare y against z = log10(x) calculated using regular floating
    # point arithmetic
    if (x <= LongMath::MAX_FLOATABLE) then
      xf = x.to_f
      if (xf > 0) then
        z = Math.log(x.to_f) / Math.log(10)
        yf = y.to_f
        assert((yf - z) / [yf.abs, z.abs, Float::MIN].max < 1e-9, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")
      end
    end

    # check by taking 10**(log10(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y <= LongMath::MAX_EXP_ABLE) then
      eprec = prec
      if (y > 1) then
        lx = 0
        if (x > LongMath::MAX_FLOATABLE) then
          puts("unusual x=#{x} y=#{y}\n")
          lx = LongMath::MAX_EXP_ABLE
        else
          lx = Math.log(x.to_f)
        end
        l10 = (lx / Math.log(10)).ceil
        eprec = [ eprec - l10, 0 ].max
      end

      z = LongMath.power(10.to_ld, y, eprec)
      assert((x - z).abs <= z.unit, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec})")
    end

  end

  #
  # helper method for test_log10
  # tests if log10(x) with precision prec is calculated correctly
  #
  def check_log10_exact(x, log10x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    log10x = log10x.to_ld.round_to_scale(prec)
    # calculate y = log10(x)
    y = LongMath.log10(x, prec)
    assert_equal(y, log10x, "log x should match exactly x=#{x} y=#{y} log10x=#{log10x}")
  end

  #
  # test the calculation of the base-10-logarithm function
  #
  def test_log10
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
  end

  #
  # helper method for test_log2
  # tests if log2(x) with precision prec is calculated correctly
  #
  def check_log2_floated(x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = log2(x)
    y = LongMath.log2(x, prec)

    # compare y against z = log2(x) calculated using regular floating
    # point arithmetic
    if (x <= LongMath::MAX_FLOATABLE) then
      xf = x.to_f
      if (xf > 0) then
        z = Math.log(x.to_f) / Math.log(2)
        yf = y.to_f
        assert((yf - z) / [yf.abs, z.abs, Float::MIN].max < 1e-9, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")
      end
    end

    # check by taking 2**(log2(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y <= LongMath::MAX_EXP_ABLE) then
      eprec = prec
      if (y > 1) then
        lx = 0
        if (x > LongMath::MAX_FLOATABLE) then
          puts("unusual x=#{x} y=#{y}\n")
          lx = LongMath::MAX_EXP_ABLE
        else
          lx = Math.log(x.to_f)
        end
        l10 = (lx / Math.log(10)).ceil
        eprec = [ eprec - l10, 0 ].max
      end

      z = LongMath.power(2.to_ld, y, eprec)
      assert((x - z).abs <= z.unit, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec})")
    end

  end

  #
  # helper method for test_log2
  # tests if log2(x) with precision prec is calculated correctly
  #
  def check_log2_exact(x, log2x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    log2x = log2x.to_ld.round_to_scale(prec)
    # calculate y = log2(x)
    y = LongMath.log2(x, prec)
    assert_equal(y, log2x, "log x should match exactly x=#{x} y=#{y} log2x=#{log2x} prec=#{prec}")
  end

  #
  # test the calculation of the base-10-logarithm function
  #
  def test_log2
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
  end

  #
  # helper method for test_int_sqrtb
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
  def test_int_sqrtb
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
  # helper method of test_int_sqrtw
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
  def test_int_sqrtw
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
  # helper method for test_int_sqrtb_with_remainder
  #
  def check_sqrtb_with_remainder(x, s)
    y, r = LongMath.sqrtb_with_remainder(x)
    z0 = y * y
    z1 = z0 + r
    z2 = (y+1)*(y+1)
    assert(0 <= y, "sqrt _with_remaindermust be >= 0" + s)
    assert_equal(z1, x, "x=#{x} y=#{y} r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    assert(z0 <= x && x < z2, "y=#{y}=sqrt(_with_remainder#{x}) and x in [#{z0}, #{z2}) r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    y
  end

  #
  # test method sqrtb_with_remainder for calculating sqrt _with_remainderof short integers
  #
  def test_int_sqrtb_with_remainder
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
  # helper method for test_int_sqrtw_with_remainder
  #
  def check_sqrtw_with_remainder(x, s)
    y, r = LongMath.sqrtw_with_remainder(x)
    z0 = y * y
    z1 = z0 + r
    z2 = (y+1)*(y+1)
    assert(0 <= y, "sqrt _with_remaindermust be >= 0" + s)
    assert_equal(z1, x, "x=#{x} y=#{y} r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    assert(z0 <= x && x < z2, "y=#{y}=sqrt(_with_remainder#{x}) and x in [#{z0}, #{z2}) r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    y
  end

  #
  # test method sqrtb_with_remainder for calculating sqrt _with_remainderof long integers
  #
  def test_int_sqrtw_with_remainder
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
  def test_ld_multiplicity_of_factor
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
    l = LongDecimal.zero!(224)
    assert_equal(l.to_r, 0, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 1 with given number of digits after the decimal point
  #
  def test_one_init
    l = LongDecimal.one!(224)
    assert_equal(l.to_r, 1, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 2 with given number of digits after the decimal point
  #
  def test_two_init
    l = LongDecimal.two!(224)
    assert_equal(l.to_r, 2, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 10 with given number of digits after the decimal point
  #
  def test_ten_init
    l = LongDecimal.ten!(224)
    assert_equal(l.to_r, 10, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of -1 with given number of digits after the decimal point
  #
  def test_minus_one_init
    l = LongDecimal.minus_one!(224)
    assert_equal(l.to_r, -1, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 10**e with given number of digits after the decimal point
  #
  def test_power_of_ten_init
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
  # test int_digits2 of LongDecimal
  #
  def test_int_digits2
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
    assert_equal(0, LongDecimal("0.0000").int_digits10, "0.0000")
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
  end

  #
  # test rounding of LongDecimal with ROUND_UP
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
  # test conversion to String with extra parameters
  #
  def test_to_s_with_params
    l = LongDecimal(224, 0)
    s = l.to_s(5)
    assert_equal("224.00000", s, "l=#{l.inspect} 5")
    s = l.to_s(5, LongDecimal::ROUND_UNNECESSARY, 16)
    assert_equal("e0.00000", s, "l=#{l.inspect} 5 ROUND_UNNECESSARY 16")

    l = LongDecimal(224, 1)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("22", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("22.40000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(224, 2)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("2", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.24000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(-224, 0)
    s = l.to_s(5)
    assert_equal("-224.00000", s, "l=#{l.inspect} 5")
    s = l.to_s(5, LongDecimal::ROUND_UNNECESSARY, 16)
    assert_equal("-e0.00000", s, "l=#{l.inspect} 5 ROUND_UNNECESSARY 16")

    l = LongDecimal(-224, 1)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("-22", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("-22.40000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("-16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("-16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(-224, 2)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.24000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("-2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("-2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")
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

  #
  # test adjustment of scale which is used as preparation for addition
  # and subtraction
  #
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

  #
  # test adjustment of scale which is used as preparation for division
  #
  def test_anti_equalize_scale
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

  #
  # test subtraction of LongDecimal
  #
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

  #
  # test multiplication of LongDecimal
  #
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

  #
  # test division of LongDecimal
  #
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

  #
  # test power (**) of LongDecimal
  #
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

  #
  # test division with remainder of LongDecimal
  #
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

  #
  # test of &-operator of LongDecimal
  #
  def test_logand
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
    z = LongDecimal(n, 4)
    assert_equal(y, z, "right 4")
    w = y.move_point_left(4)
    ww = y.move_point_right(-4)
    assert_equal(w, ww, "left / right 4")
    assert_equal(x, w, "right 4 left 4")

    y = x.move_point_left(12)
    yy = x.move_point_right(-12)
    assert_equal(y, yy, "left / right 12")
    z = LongDecimal(n * 1000, 0)
    assert_equal(y, z, "left 12")
    w = y.move_point_right(12)
    v = x.round_to_scale(12)
    assert_equal(v, w, "right 12 left 12")
  end

  #
  # helper method of test_sqrt
  #
  def check_sqrt(x, scale, mode, su0, su1, str)
    y = x.sqrt(scale, mode)
    z0 = (y+su0*y.unit).square
    z1 = (y+su1*y.unit).square
    assert(0 <= y.sign, "sqrt must be >= 0" + str)
    assert(z0 <= x && x <= z1, "y=#{y}=sqrt(#{x}) and x in [#{z0}, #{z1})" + str)
    y
  end

  #
  # test sqrt of LongDecimal
  #
  def test_sqrt
    x = LongDecimal.zero!(101)
    y = check_sqrt(x, 120, LongDecimal::ROUND_UNNECESSARY, 0, 0, "zero")
    assert(y.zero?, "sqrt(0)")

    x = LongDecimal.one!(101)
    y = check_sqrt(x, 120, LongDecimal::ROUND_UNNECESSARY, 0, 0, "one")
    assert(y.one?, "sqrt(1)")

    x = LongDecimal.two!(101)
    y0 = check_sqrt(x, 120, LongDecimal::ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, LongDecimal::ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 120, LongDecimal::ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    x = 3.to_ld
    y0 = check_sqrt(x, 120, LongDecimal::ROUND_DOWN, 0, 1, "three")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, LongDecimal::ROUND_HALF_EVEN, -1, 1, "three")
    y2 = check_sqrt(x, 120, LongDecimal::ROUND_UP, -1, 0, "three")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    x  = 4.to_ld.round_to_scale(101)
    y0 = check_sqrt(x, 120, LongDecimal::ROUND_DOWN, 0, 0, "four")
    y1 = check_sqrt(x, 120, LongDecimal::ROUND_HALF_EVEN, 0, 0, "four")
    y2 = check_sqrt(x, 120, LongDecimal::ROUND_UP, 0, 0, "four")
    assert_equal(y0, y1, "y0 y1")
    assert_equal(y1, y2, "y1 y2")
  end

  #
  # helper method of test_sqrt_with_remainder
  #
  def check_sqrt_with_remainder(x, scale, str)
    y, r = x.sqrt_with_remainder(scale)
    z0 = y.square
    z1 = y.succ.square
    assert(0 <= y.sign, "sqrt must be >= 0" + str)
    assert(z0 <= x && x < z1, "y=#{y}=sqrt(#{x}) and x in [#{z0}, #{z1})" + str)
    assert((x - z0 - r).zero?, "x=y*y+r")
    r
  end

  #
  # test sqrt_with_remainder of LongDecimal
  #
  def test_sqrt_with_remainder
    x = LongDecimal.zero!(101)
    r = check_sqrt_with_remainder(x, 120, "zero")
    assert(r.zero?, "rsqrt(0)")

    x = LongDecimal.one!(101)
    r = check_sqrt_with_remainder(x, 120, "one")
    assert(r.zero?, "rsqrt(1)")

    x = LongDecimal.two!(101)
    check_sqrt_with_remainder(x, 120, "two")

    x = 3.to_ld
    check_sqrt_with_remainder(x, 120, "three")

    x  = 4.to_ld.round_to_scale(101)
    r = check_sqrt_with_remainder(x, 120, "four")
    assert(r.zero?, "rsqrt(4)")

    x = 5.to_ld
    check_sqrt_with_remainder(x, 120, "five")
  end

  #
  # test absolute value of LongDecimal
  #
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

  #
  # test moving of decimal point of LongDecimal
  #
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

  #
  # test ufo-operator (<=>) of LongDecimal
  #
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

  #
  # test is_int? of LongDecimal
  #
  def test_is_int
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
    x = LongDecimal(224, 2)
    y = LongDecimal(2240, 3)
    assert((x <=> y) == 0, "diff is zero")
    assert(x != y, "but not equal")
    assert(! (x == y), "but not equal")
    assert_equal(x, x, "x equals x")
    assert_equal(y, y, "y equals y")
  end

  #
  # test construction of LongDecimalQuot from LongDecimal
  #
  def test_ldq_ld_init
    x = LongDecimal(224, 2)
    y = LongDecimal(225, 3)
    z = LongDecimalQuot(x, y)
    zz = LongDecimalQuot(Rational(2240, 225), 2)
    assert_equal(zz, z, "224/225")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_UP
  #
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

  #
  # test rounding of LongDecimalQuot with ROUND_DOWN
  #
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

  #
  # test rounding of LongDecimalQuot with ROUND_CEILING
  #
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

  #
  # test rounding of LongDecimalQuot with ROUND_FLOOR
  #
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

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_UP
  #
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

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_DOWN
  #
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

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_EVEN
  #
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

  #
  # test rounding of LongDecimalQuot with ROUND_UNNECESSARY
  #
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

  #
  # test conversion of LongDecimalQuot to String
  #
  def test_ldq_to_s
    l = LongDecimalQuot(Rational(224, 225), 226)
    assert_equal("224/225[226]", l.to_s, "l=#{l.inspect}")
    l = LongDecimalQuot(Rational(-224, 225), 226)
    assert_equal("-224/225[226]", l.to_s, "l=#{l.inspect}")
  end

  #
  # test conversion of LongDecimalQuot to Rational
  #
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

  #
  # test conversion of LongDecimalQuot to Float
  #
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


  # TODO
  # test_to_i: to_i not tested, goes via to_r anyway
  # def test_to_ld
  # def test_to_bd

  #
  # test negation operator (unary -) of LongDecimalQuot
  #
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

  #
  # test addition operator (binary +) of LongDecimalQuot
  #
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

  #
  # test subtraction operator (binary -) of LongDecimalQuot
  #
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

  #
  # test multiplication operator (*) of LongDecimalQuot
  #
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

  #
  # test division operator (/) of LongDecimalQuot
  #
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

  #
  # test power operator (**) of LongDecimalQuot
  #
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

  #
  # test divmod of LongDecimalQuot for division with remainder
  #
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

  #
  # test absolute value of LongDecimalQuot
  #
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

  #
  # test ufo operator (<=>) of LongDecimalQuot
  #
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

  #
  # test is_int? of LongDecimalQuot
  #
  def test_ldq_is_int
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
    assert(LongDecimalQuot(0, 1000).zero?, "0, 1000")
    assert(LongDecimalQuot(0, 0).zero?, "0, 0")
    assert(! LongDecimalQuot(1, 1000).zero?, "1, 1000")
    assert(! LongDecimalQuot(1, 0).zero?, "1, 0")
  end

  #
  # test one? of LongDecimalQuot
  #
  def test_ldq_one
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
