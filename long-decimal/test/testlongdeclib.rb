#!/usr/bin/env ruby
#
# library for testlongdecimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdeclib.rb,v 1.15 2006/05/01 12:22:12 bk1 Exp $
# CVS-Label: $Name: ALPHA_01_01 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

load "lib/long-decimal.rb"

#
# test class for LongDecimal and LongDecimalQuot
#
module TestLongDecHelper

  @RCS_ID='-$Id: testlongdeclib.rb,v 1.15 2006/05/01 12:22:12 bk1 Exp $-'


  #
  # convenience method for comparing two numbers. true if and only if
  # they express the same value
  #
  def assert_val_equal(expected, actual, message="")
    _wrap_assertion {
      full_message = build_message(message, "Expected <?> to match <?>", actual, expected)
      assert_block(full_message) {
        (expected <=> actual).zero?
      }
    }
  end

  #
  # convenience method for comparing two long-decimal numbers. true if and only if
  # the second can be obtained from the first by rounding with
  # ROUND_HALF_UP or ROUND_HALF_DOWN.  If the digits that the first
  # number has in excess to the second are 5000....., it is sufficient
  # for sucess if either rounding up or rounding down yields the
  # second number.  In all other cases there is no difference between
  # using ROUND_HALF_UP, ROUND_HALF_DOWN or ROUND_HALF_EVEN anyway, so
  # one of these is used.
  #
  def assert_equal_rounded(expected, actual, message="")
    _wrap_assertion {
      lhs = (expected - actual).abs()*2000
      rhs = actual.unit.abs()*1001
      full_message = build_message(message, "Expected <?> to match <?> (lhs=#{lhs} rhs=#{rhs})", actual, expected)
      assert_block(full_message) {
        #       prec = actual.scale
        #       ed   = expected.round_to_scale(prec, LongMath::ROUND_HALF_FLOOR)
        #       eu   = expected.round_to_scale(prec, LongMath::ROUND_HALF_CEILING)
        #       # puts("ed=#{ed} eu=#{eu} e=#{expected} a=#{actual}")
        #       ed <= actual && actual <= eu

        # (expected - actual).abs < (actual.unit()/2)*(1001/1000)
        # (expected - actual).abs()*2000 < actual.unit()*1001
        lhs < rhs
      }
    }
  end

  #
  # convenience method for comparing three long-decimal numbers.  yd
  # and yu should form a closed interval containing y.  Length of
  # interval is a unit at most.
  #
  def assert_small_interval(yd, yu, y, message="")
    _wrap_assertion {
      if (yu < yd) then
        yd, yu = yu, yd
      end
      full_message = build_message(message, "Expected interval [<?>, <?>] to be one unit at most and to contain <?>", yd, yu, y)
      assert_block(full_message) {
        prec = y.scale
        yd <= y && y <= yu && yu - yd <= y.unit
      }
    }
  end

  #
  # convenience method for comparing Float with LongDecimal
  # using a delta coming from these
  #
  def assert_mixed_equal(expected_f, actual_ld, message="")
    delta = [ actual_ld.unit, expected_f.abs / 1e10 ].max
    assert_equal_float(expected_f, actual_ld, delta, message)
  end

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
  # helper method for test_exp
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_exp_floated(x, prec)

    print "."
    $stdout.flush

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    # eprec = prec+1
    y  = LongMath.exp(x, prec)
    yy = LongMath.exp(x, prec+10)
    #  assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = exp(x) calculated using regular floating point arithmetic
    z = Math.exp(x.to_f)
    yf = y.to_f
    assert((yf - z).abs <= [ y.unit, z.abs / 1e9 ].max, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")

    # check by taking log(exp(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y > 0) then
      lprec = prec - 1
      if (y < 1) then
        l10 = (Math.log(y.to_f) / Math.log(10)).round
        lprec += l10
      end
      df = 1
      if (lprec < 0)
        df += lprec.abs
        lprec = 0
      end
      z = LongMath.log(y, lprec)
      delta = z.unit * df
      assert((x - z).abs <= delta, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (#{(x-z).abs.inspect} < d=#{delta.inspect} y=#{y.to_s} lprec=#{lprec} prec=#{prec})")
    end

    # check by doing calculation with different internal rounding modes.  They should not differ.
    yd = LongMath.exp_internal(x, prec, nil, nil, nil, nil, LongDecimal::ROUND_DOWN)
    yu = LongMath.exp_internal(x, prec, nil, nil, nil, nil, LongDecimal::ROUND_UP)
    # assert_equal(yd, yu, "the result yd/yu should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    # assert_equal(y,  yu, "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(y -yu).to_f.to_s}")
    assert_small_interval(yd, yu, y, "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd-yu).to_f.to_s}")
  end

  #
  # helper method for test_exp_int
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_exp_int(x)

    # make sure x is LongDecimal
    x0 = x
    x  = x.to_ld
    y  = LongMath.exp(x, 0)
    assert_equal(y.scale, 0, "scale must be 0")

    # compare y against z = exp(x) calculated using regular floating point arithmetic
    z  = Math.exp(x0.to_f)
    yf = y.to_f
    yi = yf.round
    zi = z.round
    assert((yi-zi).abs / [yf.abs, z.abs, Float::MIN].max < 1e-9, "yi=#{yi} and zi=#{zi} should be equal x=#{x} y=#{y} z=#{z}")

    if (y > 1)
      w = LongMath.log(y, 0)
      assert((w-x).abs < 1, "log(y)=#{w} must be almost x=#{x0}")
    end

  end

  #
  # helper method for test_exp2
  # tests if exp2(x) with precision prec is calculated correctly
  #
  def check_exp2_floated(x, prec)

    print "."
    $stdout.flush

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    # eprec = prec+1
    y  = LongMath.exp2(x, prec)
    yy = LongMath.exp2(x, prec+10)
    #  assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = exp(x) calculated using regular floating point arithmetic
    zf = 2.0 ** (x.to_f)
    yf = y.to_f
    assert((yf - zf).abs <= [ y.unit, zf.abs / 1e9 ].max, "y=#{yf.to_s} and z=#{zf.to_s} should be almost equal x=#{x}")

    # check by taking log(exp(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y > 0) then
      lprec = prec - 1
      if (y < 1) then
        l10 = (Math.log(y.to_f) / Math.log(10)).round
        lprec += l10
      end
      df = 1
      if (lprec < 0)
        df += lprec.abs
        lprec = 0
      end
      z = LongMath.log2(y, lprec)
      delta = z.unit * df
      assert((x - z).abs <= delta, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (#{(x-z).abs.inspect} < d=#{delta.inspect} y=#{y.to_s} lprec=#{lprec} prec=#{prec})")
    end

  end


  #
  # helper method for test_exp10
  # tests if exp10(x) with precision prec is calculated correctly
  #
  def check_exp10_floated(x, prec)

    print "."
    $stdout.flush

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    # eprec = prec+1
    y  = LongMath.exp10(x, prec)
    yy = LongMath.exp10(x, prec+10)
    #  assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    if (y.abs < LongMath::MAX_FLOATABLE) then
      # compare y against z = exp(x) calculated using regular floating point arithmetic
      zf = 10.0 ** (x.to_f)
      yf = y.to_f
      assert((yf - zf).abs <= [ y.unit, zf.abs / 1e9 ].max, "y=#{yf.to_s} and z=#{zf.to_s} should be almost equal x=#{x}")
    end

    # check by taking log(exp(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y > 0) then
      lprec = prec - 1
      if (y < 1) then
        l10 = (Math.log(y.to_f) / Math.log(10)).round
        lprec += l10
      end
      df = 1
      if (lprec < 0)
        df += lprec.abs
        lprec = 0
      end
      z = LongMath.log10(y, lprec)
      delta = z.unit * df
      assert((x - z).abs <= delta, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (#{(x-z).abs.inspect} < d=#{delta.inspect} y=#{y.to_s} lprec=#{lprec} prec=#{prec})")
    end

  end

  #
  # helper method for test_lm_power_xint
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_power_xint(x, y, prec)

    print "."
    $stdout.flush

    xi = x.to_i
    x  = x.to_ld()
    y  = y.to_ld()
    z  = LongMath.power(x, y, prec)
    zz = LongMath.power_internal(x, y, prec)
    assert((zz - z).abs <= z.unit, "power with and without optimizations z=#{z} zz=#{zz} x=#{x} y=#{y}")
    # compare y against z = exp(x) calculated using regular floating point arithmetic
    zz = (xi) ** (y.to_f)
    zf = z.to_f
    assert((zf - zz).abs < [z.unit.to_f, zz.abs / 1e9 ].max, "z=#{z} and zz=#{zz} should be almost equal x=#{x} y=#{y} (zf=#{zf})")
  end

  #
  # helper method for test_lm_power_yint
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_power_yint(x, y, prec)

    print "."
    $stdout.flush

    yi = y.to_i
    x  = x.to_ld
    y  = y.to_ld

    z  = LongMath.power(x, y, prec, LongMath::ROUND_HALF_UP)
    zz = (x ** yi).round_to_scale(prec, LongMath::ROUND_HALF_UP)
    assert_equal(z, zz, "power with ** or power-method x=#{x} y=#{y} z=#{z} zz=#{zz}")
    zz = LongMath.power_internal(x, y, prec)
    assert((zz - z).abs <= z.unit, "power with and without optimizations x=#{x} y=#{y} z=#{z} zz=#{zz}")

    zz = (x.to_f) ** (y.to_f)
    zf = z.to_f
    # assert((zf - zz).abs / [zf.abs, zz.abs, Float::MIN].max < 1e-9, "z=#{zf.to_s} and zz=#{zz.to_s} should be almost equal x=#{x} y=#{y} z=#{z} zz=#{zz}")
    assert((zf - zz).abs < [ z.unit.to_f, zf.abs / 1e9 ].max, "zf=#{zf.to_s} and zz=#{zz.to_s} should be almost equal x=#{x} y=#{y} z=#{z} zz=#{zz}")
  end

  #
  # helper method for test_log
  # tests if log(x) with precision prec is calculated correctly
  #
  def check_log_floated(x, prec, divisor=1e9, summand=0)

    print ","
    $stdout.flush

    assert(prec > 0, "does not work for prec=0")

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = log(x)
    y  = LongMath.log(x, prec)
    yy = LongMath.log(x, prec+10)
    # assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = exp(x) calculated using regular floating
    # point arithmetic
    if (x <= LongMath::MAX_FLOATABLE) then
      xf = x.to_f
      if (xf > 0) then
        xf = x.to_f
        z  = Math.log(xf)
        zl = z.to_ld(y.scale)
        df = [ 1e-14, z.abs / 1e10 ].max
        dl = y.unit
        # delta = [ y.unit, z.abs / divisor + summand ].max
        delta = [ df, dl ].max
        assert((y - zl).abs <= delta, "y=#{y.to_s} (#{y.to_f}) and z=#{z.to_s} (#{zl.to_f}) should be almost equal (d=#{delta.inspect} x=#{x} y=#{y})")
      end
    end

    # check by taking exp(log(y))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (y <= LongMath::MAX_EXP_ABLE) then
      eprec = prec - 1
      if (y > 1) then
        ly = 0
        if (y > LongMath::MAX_FLOATABLE) then
          puts("unusual y=#{y} y=#{y}\n")
          ly = LongMath::MAX_EXP_ABLE
        else
          ly = Math.log(y.to_f)
        end
        # l10 = (ly * (1.2+2/(prec+1.0)) / Math.log(10)).ceil
        l10 = (y.to_f * (1.2+2/(prec+1.0)) / Math.log(10)).ceil
        # l10 = (y.to_f / Math.log(10)).ceil
        eprec -= l10
      end
      df = 1
      if (eprec < 0)
        df += eprec.abs
        eprec = 0
      end
      z = LongMath.exp(y, eprec)
      u = z.unit
      v = y.unit
      # delta = (u + u.move_point_left(1)) * df
      delta = [ v * z, u * df ].max
      # puts("x=#{x.to_s} and z=#{z.to_s} should be almost equal (#{(x-z).abs} < d=#{delta} y=#{y.to_s} eprec=#{eprec} prec=#{prec} u=#{u.inspect} v=#{v.inspect} df=#{df})")
      assert((x - z).abs <= delta, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (#{(x-z).abs} < d=#{delta} y=#{y.to_s} eprec=#{eprec} prec=#{prec})")
    end

    # check by doing calculation with different internal rounding modes.  They should not differ.
    # yd = LongMath.log_internal(x, prec, nil, nil, LongDecimal::ROUND_DOWN)
    # yu = LongMath.log_internal(x, prec, nil, nil, LongDecimal::ROUND_UP)
    yd = LongMath.log_internal(x, prec, nil, nil, LongDecimal::ROUND_FLOOR)
    yu = LongMath.log_internal(x, prec, nil, nil, LongDecimal::ROUND_CEILING)
    # assert_equal(yd, yu, "the result yd/yu should not depend on the internal rounding mode yd=#{yd} yu=#{yu} y=#{y} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    # assert_equal(y,  yu, "the result y/yu  should not depend on the internal rounding mode yd=#{yd} yu=#{yu} y=#{y} p=#{prec} d=#{(y -yu).to_f.to_s}")
    assert_small_interval(yd, yu, y, "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    return y
  end

  #
  # helper method for test_lm_power
  # tests if LongMath::power(x, y, prec) with precision prec is calculated correctly
  #
  def check_power_floated(x, y, prec)

    print "."
    # print("\nstart: check_power_floated: x=#{x} y=#{y} prec=#{prec}")
    # t0 = Time.new
    $stdout.flush

    # make sure x and y are LongDecimal
    x0 = x
    x = x.to_ld
    y0 = y
    y = y.to_ld
    # calculate z = x**y
    z = LongMath.power(x, y, prec)

    if (z.abs < LongMath::MAX_FLOATABLE)
      # compare y against w = x**y calculated using regular floating point arithmetic
      w = (x.to_f) ** (y.to_f)
      zf = z.to_f
      # assert((zf - w).abs / [zf.abs, w.abs, Float::MIN].max < 1e-9, "z=#{zf.to_s} and w=#{w.to_s} should be almost equal x=#{x} y=#{y}")
      assert((zf - w).abs <= [ z.unit, zf.abs / 1e9 ].max, "z=#{zf.to_s} and w=#{w.to_s} should be almost equal x=#{x} y=#{y}")
    end

    # check by taking log(z) = y * log(x)
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if (z > 0) then
      lprec = prec
      if (z < 1) then
        l10 = (Math.log(z.to_f) / Math.log(10)).floor
        lprec += l10
      end
      if (x < 1) then
        l10 = (Math.log(x.to_f) / Math.log(10)).floor
        lprec += l10
      end
      unit = (10**(-lprec)).to_ld
      if (lprec < 0)
        lprec = 0
      end
      l10y = 0
      if (y.abs > 1) then
        l10y = (Math.log(y.abs.to_f) / Math.log(10)).ceil
      end
      u = LongMath.log(z, lprec)
      v = LongMath.log(x, lprec+l10y)
      yv = (y*v).round_to_scale(lprec, LongDecimal::ROUND_HALF_DOWN)
      assert((u - yv).abs <= unit, "u=#{u} and yv=y*v=#{yv} should be almost equal (unit=#{unit} x=#{x.to_s} y=#{y.to_s} z=#{z.to_s} u=#{u.to_s} v=#{v.to_s} lprec=#{lprec} prec=#{prec})")
    end
    # puts("ok check_power_floated: x=#{x} y=#{y} prec=#{prec} t=#{Time.new - t0}\n")

  end

  #
  # helper method for test_log10
  # tests if log10(x) with precision prec is calculated correctly
  #
  def check_log10_floated(x, prec)

    print ","
    $stdout.flush

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = log10(x)
    y  = LongMath.log10(x, prec)
    yy = LongMath.log10(x, prec+10)
    # assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = log10(x) calculated using regular floating
    # point arithmetic
    if (x <= LongMath::MAX_FLOATABLE) then
      xf = x.to_f
      if (xf > 0) then
        xf = x.to_f
        z = Math.log(x.to_f) / Math.log(10)
        yf = y.to_f
        zl = z.to_ld(y.scale)
        df = [ 1e-13, z.abs / 1e10 ].max
        dl = y.unit
        delta = [ df, dl ].max
        # assert((yf - z).abs / [yf.abs, z.abs, Float::MIN].max < 1e-9, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")
        assert((yf - z).abs < delta, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal (x=#{x} delta=#{delta}")
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

      z  = LongMath.power(10, y, eprec)
      zz = LongMath.exp10(y, eprec)
      u  = z.unit
      v  = y.unit
      assert((zz - z).abs <= u, "zz=#{zz.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec})")
      delta = [ v*z*LongMath::LOG10*1.2, u * 1.1 ].max
      assert((x - z).abs <= delta, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec} delta=#{delta})")
      # assert((x - z).abs <= z.unit, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec})")
    end
    
    return y

  end

  #
  # helper method for test_log10
  # tests if log10(x) with precision prec is calculated correctly
  #
  def check_log10_exact(x, log10x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    log10x = log10x.to_ld(prec)
    # calculate y = log10(x)
    y = LongMath.log10(x, prec)
    assert_equal(y, log10x, "log x should match exactly x=#{x} y=#{y} log10x=#{log10x}")
  end

  #
  # helper method for test_log2
  # tests if log2(x) with precision prec is calculated correctly
  #
  def check_log2_floated(x, prec)

    print ","
    $stdout.flush

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = log2(x)
    y  = LongMath.log2(x, prec)
    yy = LongMath.log2(x, prec+10)
    # assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = log2(x) calculated using regular floating
    # point arithmetic
    if (x <= LongMath::MAX_FLOATABLE) then
      xf = x.to_f
      if (xf > 0) then
        xf = x.to_f
        z = Math.log(xf) / Math.log(2)
        yf = y.to_f
        zl = z.to_ld(y.scale)
        df = [ 1e-13, z.abs / 1e10 ].max
        dl = y.unit.abs
        delta = [ df, dl ].max
        # assert((yf - z).abs / [yf.abs, z.abs, Float::MIN].max < 1e-9, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal x=#{x}")
        assert((yf - z).abs < delta.to_f, "y=#{yf.to_s} and z=#{z.to_s} should be almost equal (x=#{x} delta=#{delta}")
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

      z  = LongMath.power(2.to_ld, y, eprec)
      zz = LongMath.exp2(y, eprec)
      u = z.unit
      v = y.unit
      assert((zz - z).abs <= u, "zz=#{zz.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec})")
      delta = [ v*z, u ].max
      assert((x - z).abs <= delta, "x=#{x.to_s} and z=#{z.to_s} should be almost equal (y=#{y.to_s} eprec=#{eprec} prec=#{prec} delta=#{delta})")
    end
    return y

  end

  #
  # helper method for test_log2
  # tests if log2(x) with precision prec is calculated correctly
  #
  def check_log2_exact(x, log2x, prec)

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    log2x = log2x.to_ld(prec)
    # calculate y = log2(x)
    y = LongMath.log2(x, prec)
    assert_equal(y, log2x, "log x should match exactly x=#{x} y=#{y} log2x=#{log2x} prec=#{prec}")
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
  # helper method of test_sqrt
  #
  def check_sqrt(x, scale, mode, su0, su1, str)
    y  = x.sqrt(scale, mode)
    if (mode == LongMath::ROUND_HALF_UP || mode == LongMath::ROUND_HALF_DOWN || mode == LongMath::ROUND_HALF_EVEN)
      yy = x.sqrt(scale+10, mode)
      assert_equal(yy.round_to_scale(y.scale, mode), y, "x=#{x} y=#{y} yy=#{yy}")
    end
    z0 = (y+su0*y.unit).square
    z1 = (y+su1*y.unit).square
    assert(0 <= y.sign, "sqrt must be >= 0" + str)
    assert(z0 <= x && x <= z1, "y=#{y}=sqrt(#{x}) and x in [#{z0}, #{z1}) " + str)
    y
  end

  #
  # helper method of test_sqrt_with_remainder
  #
  def check_sqrt_with_remainder(x, scale, str)
    y, r = x.sqrt_with_remainder(scale)
    z0 = y.square
    z1 = y.succ.square
    assert(0 <= y.sign, "sqrt must be >= 0" + str)
    assert(z0 <= x && x < z1, "y=#{y}=sqrt(#{x}) and x in [#{z0}, #{z1}) " + str)
    assert((x - z0 - r).zero?, "x=y*y+r x=#{x} z0=#{z0} z1=#{z1} y=#{y} r=#{r} total=#{x - z0 - r} " + str)
    r
  end

end

# end of file testlongdecimal.rb
