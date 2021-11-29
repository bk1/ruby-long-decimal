#!/usr/bin/env ruby
# frozen_string_literal: true

#
# library for tests for long-decimal.rb and long-decimal-extra.rb
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2015
#
# TAG:       $TAG v1.00.04$
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdeclib.rb,v 1.42 2011/02/03 00:22:39 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

# require "/long-decimal"

class Integer
  def cube
    self * self * self
  end

  def square
    self * self
  end
end

#
# test class for LongDecimal and LongDecimalQuot
#
module TestLongDecHelper
  include LongDecimalRoundingMode

  @RCS_ID = '-$Id: testlongdeclib.rb,v 1.42 2011/02/03 00:22:39 bk1 Exp $-'

  def mu_pp(obj)
    obj.inspect.chomp
  end

  def build_message(_head, template = nil, *arguments)
    template &&= template.chomp
    template.gsub(/\?/) { mu_pp(arguments.shift) }
  end

  def assert_equal_float(lhs, rhs, delta = 0, msg = '')
    if (lhs - rhs).abs >= delta
      msg2 = "delta=#{delta} #{msg}"
      assert_equal(lhs, rhs, msg2)
    end
  end

  def assert_equal_rbo(lhs, rhs, msg = '', lhsname = 'lhs', rhsname = 'rhs', delta = 0)
    msg2 = "#{lhsname}=#{lhs} (#{lhs.class}) #{rhsname}=#{rhs} (#{rhs.class}) " + msg
    if ((lhs.is_a? Rational) && (rhs.is_a? BigDecimal)) || ((lhs.is_a? BigDecimal) && (rhs.is_a? Rational))
      lhs_ld = lhs.to_ld
      rhs_ld = rhs.to_ld
      assert(lhs_ld == rhs_ld || (lhs_ld - rhs_ld).abs <= delta,
             msg2 + " as ld: #{lhs_ld} #{rhs_ld}")
    elsif delta.positive? && ((lhs.is_a? Float) || (rhs.is_a? Float))
      assert_equal_float(lhs, rhs, delta, msg2 + " d=#{delta}")
    elsif (lhs.is_a? Rational) && (rhs.is_a? Rational)
      assert_equal(lhs.numerator * rhs.denominator, lhs.denominator * rhs.numerator,
                   "#{msg} rational")
    else
      assert_equal(lhs, rhs, "#{msg2} exact")
    end
  end

  def assert_equal_complex(lhs, rhs, msg = '', delta = 0)
    msg2 = "lhs=#{lhs} rhs=#{rhs} " + msg
    assert_equal_rbo(lhs.real, rhs.real, "real: #{lhs.real == rhs.real} " + msg2, 'lhsr', 'rhsr',
                     delta)
    assert_equal_rbo(lhs.imag, rhs.imag, "imag: #{lhs.imag == rhs.imag} " + msg2, 'lhsi', 'rhsi',
                     delta)
  end

  #
  # convenience method for comparing two numbers. true if and only if
  # they express the same value
  #
  def assert_eql(expected, actual, message = '')
    full_message = build_message(message, 'Expected <?> to match <?>', actual, expected)
    assert((expected.eql? actual), full_message)
    #     _wrap_assertion {
    #       full_message = build_message(message, "Expected <?> to match <?>", actual, expected)
    #       assert_block(full_message) {
    #         (expected <=> actual).zero?
    #       }
    #     }
  end

  #
  # convenience method for comparing two numbers. true if and only if
  # they express the same value
  #
  def assert_val_equal(expected, actual, message = '')
    full_message = build_message(message, 'Expected <?> to match <?>', actual, expected)
    assert((expected <=> actual).zero?, full_message)
    #     _wrap_assertion {
    #       full_message = build_message(message, "Expected <?> to match <?>", actual, expected)
    #       assert_block(full_message) {
    #         (expected <=> actual).zero?
    #       }
    #     }
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
  def assert_equal_rounded(expected, actual, message = '')
    lhs = (expected - actual).abs * 2000
    rhs = actual.unit.abs * 1001
    full_message = build_message(message, "Expected <?> to match <?> (lhs=#{lhs} rhs=#{rhs})",
                                 actual, expected)
    assert(lhs < rhs, full_message)

    #     _wrap_assertion {
    #       lhs = (expected - actual).abs()*2000
    #       rhs = actual.unit.abs()*1001
    #       full_message = build_message(message, "Expected <?> to match <?> (lhs=#{lhs} rhs=#{rhs})", actual, expected)
    #       assert_block(full_message) {
    #         #       prec = actual.scale
    #         #       ed   = expected.round_to_scale(prec, ROUND_HALF_FLOOR)
    #         #       eu   = expected.round_to_scale(prec, ROUND_HALF_CEILING)
    #         #       # puts("ed=#{ed} eu=#{eu} e=#{expected} a=#{actual}")
    #         #       ed <= actual && actual <= eu

    #         # (expected - actual).abs < (actual.unit()/2)*(1001/1000)
    #         # (expected - actual).abs()*2000 < actual.unit()*1001
    #         lhs < rhs
    #       }
    #     }
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
  def assert_equal_rounded_with_mode(expected, actual, mode, message = '')
    expected_rounded = expected.round_to_scale(actual.scale, mode)
    lhs = (expected_rounded - actual).abs * 2000
    rhs = actual.unit.abs * 1001
    full_message = build_message(message, "Expected <?> to match <?> (lhs=#{lhs} rhs=#{rhs})",
                                 actual, expected_rounded)
    assert(lhs < rhs, full_message)
  end

  #
  # convenience method for comparing three long-decimal numbers.  yd
  # and yu should form a closed interval containing y.  Length of
  # interval is a unit at most.
  #
  def assert_small_interval(yd, yu, y, message = '')
    yd, yu = yu, yd if yu < yd
    full_message = build_message(message,
                                 'Expected interval [<?>, <?>] to be one unit at most and to contain <?>', yd, yu, y)
    _prec = y.scale
    assert(yd <= y && y <= yu && yu - yd <= y.unit, full_message)
    #     _wrap_assertion {
    #       if (yu < yd) then
    #         yd, yu = yu, yd
    #       end
    #       full_message = build_message(message, "Expected interval [<?>, <?>] to be one unit at most and to contain <?>", yd, yu, y)
    #       assert_block(full_message) {
    #         prec = y.scale
    #         yd <= y && y <= yu && yu - yd <= y.unit
    #       }
    #     }
  end

  #
  # convenience method for comparing Float with LongDecimal
  # using a delta coming from these
  #
  def assert_mixed_equal(expected_f, actual_ld, message = '')
    delta = [actual_ld.unit, expected_f.abs / 1e10].max
    assert_equal_float(expected_f, actual_ld, delta, message)
  end

  #
  # helper method for test_split_merge_words
  #
  def check_split_merge_words(x, l, wl)
    w = LongMath.split_to_words(x, l)
    y = LongMath.merge_from_words(w, l)
    assert_equal(x, y, "#{x} splitted and merged should be equal but is #{y} l=#{l}")
    assert_equal(wl, w.length,
                 "#{x} splitted to l=#{l} should have length #{wl} but has #{w.length}")
    w
  end

  #
  # helper method for test_exp
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_exp_floated(x, prec)
    print '.'
    $stdout.flush

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    # eprec = prec+1
    y = LongMath.exp(x, prec)
    yy = LongMath.exp(x, prec + 10)
    #  assert_equal(yy.round_to_scale(y.scale, ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = exp(x) calculated using regular floating point arithmetic
    z = Math.exp(x.to_f)
    yf = y.to_f
    assert((yf - z).abs <= [y.unit, z.abs / 1e9].max,
           "y=#{yf} and z=#{z} should be almost equal x=#{x} d=#{yf - z}")

    # check by taking log(exp(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if y.positive?
      lprec = prec - 1
      if y < 1
        l10 = (Math.log(y.to_f) / Math.log(10)).round
        lprec += l10
      end
      df = 1
      if lprec.negative?
        df += lprec.abs
        lprec = 0
      end
      z = LongMath.log(y, lprec)
      delta = z.unit * df
      assert((x - z).abs <= delta,
             "x=#{x} and z=#{z} should be almost equal (#{(x - z).abs.inspect} < d=#{delta.inspect} y=#{y} lprec=#{lprec} prec=#{prec})")
    end

    # check by doing calculation with different internal rounding modes.  They should not differ.
    yd = LongMath.exp_internal(x, prec, nil, nil, nil, nil, ROUND_DOWN)
    yu = LongMath.exp_internal(x, prec, nil, nil, nil, nil, ROUND_UP)
    # assert_equal(yd, yu, "the result yd/yu should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    # assert_equal(y,  yu, "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(y -yu).to_f.to_s}")
    assert_small_interval(yd, yu, y,
                          "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd - yu).to_f}")
    y
  end

  #
  # helper method for test_exp_rounding_modes
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_exp_with_rounding_modes(x, prec)
    print '.'
    $stdout.flush

    # make sure x is LongDecimal
    _x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    # eprec = prec+1
    y_rd = LongMath.exp(x, prec, ROUND_DOWN)
    y_rf = LongMath.exp(x, prec, ROUND_FLOOR)
    assert_equal(y_rd, y_rf)
    y_ru = LongMath.exp(x, prec, ROUND_UP)
    y_rc = LongMath.exp(x, prec, ROUND_CEILING)
    assert_equal(y_ru, y_rc)
    y_hu = LongMath.exp(x, prec, ROUND_HALF_UP)
    y_hc = LongMath.exp(x, prec, ROUND_HALF_CEILING)
    y_hd = LongMath.exp(x, prec, ROUND_HALF_DOWN)
    y_hf = LongMath.exp(x, prec, ROUND_HALF_FLOOR)
    assert_equal(y_hu, y_hc)
    assert(y_hu >= y_hd)
    assert(y_hu <= y_hd + y_hd.unit)
    assert_equal(y_hd, y_hf)
    assert(y_rd <= y_hu, "y_rd=#{y_rd} y_hu=#{y_hu}")
    assert(y_hu <= y_ru, "y_hu=#{y_hu} y_ru=#{y_ru}")

    yy_rd = LongMath.exp(x, prec + 10, ROUND_DOWN)
    yy_hu = LongMath.exp(x, prec + 10, ROUND_HALF_UP)
    yy_ru = LongMath.exp(x, prec + 10, ROUND_UP)
    puts
    puts(" y_rd=#{y_rd}")
    puts("yy_rd=#{yy_rd}")
    puts(" y_hu=#{y_hu}")
    puts("yy_hu=#{yy_hu}")
    puts(" y_ru=#{y_ru}")
    puts("yy_ru=#{yy_ru}")
    assert_equal_rounded_with_mode(yy_rd, y_rd, ROUND_DOWN, "x=#{x} y_rd=#{y_rd} yy_rd=#{yy_rd}")
    assert_equal_rounded(yy_hu, y_hu, "x=#{x} y_hu=#{y_hu} yy_hu=#{yy_hu}")
    assert_equal_rounded_with_mode(yy_ru, y_ru, ROUND_UP, "x=#{x} y_ru=#{y_ru} yy_ru=#{yy_ru}")
    nil
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
    assert_equal(0, y.scale, 'scale must be 0')

    # compare y against z = exp(x) calculated using regular floating point arithmetic
    z  = Math.exp(x0.to_f)
    yf = y.to_f
    yi = yf.round
    zi = z.round
    assert((yi - zi).abs / [yf.abs, z.abs, Float::MIN].max < 1e-9,
           "yi=#{yi} and zi=#{zi} should be equal x=#{x} y=#{y} z=#{z}")

    if y > 1
      w = LongMath.log(y, 0)
      assert((w - x).abs < 1, "log(y)=#{w} must be almost x=#{x0}")
    end
  end

  #
  # helper method for test_exp2
  # tests if exp2(x) with precision prec is calculated correctly
  #
  def check_exp2_floated(x, prec)
    print '.'
    $stdout.flush

    # make sure x is LongDecimal
    _x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    # eprec = prec+1
    y = LongMath.exp2(x, prec)
    yy = LongMath.exp2(x, prec + 10)
    #  assert_equal(yy.round_to_scale(y.scale, ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = exp(x) calculated using regular floating point arithmetic
    zf = 2.0**x.to_f
    yf = y.to_f
    assert((yf - zf).abs <= [y.unit, zf.abs / 1e9].max,
           "y=#{yf} and z=#{zf} should be almost equal x=#{x}")

    # check by taking log(exp(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if y.positive?
      lprec = prec - 1
      if y < 1
        l10 = (Math.log(y.to_f) / Math.log(10)).round
        lprec += l10
      end
      df = 1
      if lprec.negative?
        df += lprec.abs
        lprec = 0
      end
      z = LongMath.log2(y, lprec)
      delta = z.unit * df
      assert((x - z).abs <= delta,
             "x=#{x} and z=#{z} should be almost equal (#{(x - z).abs.inspect} < d=#{delta.inspect} y=#{y} lprec=#{lprec} prec=#{prec})")
    end
    y
  end

  #
  # helper method for test_exp10
  # tests if exp10(x) with precision prec is calculated correctly
  #
  def check_exp10_floated(x, prec)
    print '.'
    $stdout.flush

    # make sure x is LongDecimal
    _x0 = x
    x = x.to_ld
    # calculate y = exp(x)
    # eprec = prec+1
    y = LongMath.exp10(x, prec)
    yy = LongMath.exp10(x, prec + 10)
    #  assert_equal(yy.round_to_scale(y.scale, ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    if y.abs < LongMath::MAX_FLOATABLE
      # compare y against z = exp(x) calculated using regular floating point arithmetic
      zf = 10.0**x.to_f
      yf = y.to_f
      assert((yf - zf).abs <= [y.unit, zf.abs / 1e9].max,
             "y=#{yf} and z=#{zf} should be almost equal x=#{x}")
    end

    # check by taking log(exp(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if y.positive?
      lprec = prec - 1
      if y < 1
        l10 = (Math.log(y.to_f) / Math.log(10)).round
        lprec += l10
      end
      df = 1
      if lprec.negative?
        df += lprec.abs
        lprec = 0
      end
      z = LongMath.log10(y, lprec)
      delta = z.unit * df
      assert((x - z).abs <= delta,
             "x=#{x} and z=#{z} should be almost equal (#{(x - z).abs.inspect} < d=#{delta.inspect} y=#{y} lprec=#{lprec} prec=#{prec})")
    end
    y
  end

  #
  # helper method for test_lm_power_xint
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_power_xint(x, y, prec)
    print '.'
    $stdout.flush

    xi = x.to_i
    x  = x.to_ld
    y  = y.to_ld
    z  = LongMath.power(x, y, prec)
    zz = LongMath.power_internal(x, y, prec)
    assert((zz - z).abs <= z.unit,
           "power with and without optimizations z=#{z} zz=#{zz} x=#{x} y=#{y}")
    # compare y against z = exp(x) calculated using regular floating point arithmetic
    zz = xi**y.to_f
    zf = z.to_f
    assert((zf - zz).abs < [z.unit.to_f, zz.abs / 1e9].max,
           "z=#{z} and zz=#{zz} should be almost equal x=#{x} y=#{y} (zf=#{zf})")
  end

  #
  # helper method for test_lm_power_yint
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_power_yint(x, y, prec)
    print '.'
    $stdout.flush

    yi = y.to_i
    x  = x.to_ld
    y  = y.to_ld

    z  = LongMath.power(x, y, prec, ROUND_HALF_UP)
    zz = (x**yi).round_to_scale(prec, ROUND_HALF_UP)
    assert_equal(z, zz, "power with ** or power-method x=#{x} y=#{y} z=#{z} zz=#{zz}")
    zz = LongMath.power_internal(x, y, prec)
    assert((zz - z).abs <= z.unit,
           "power with and without optimizations x=#{x} y=#{y} z=#{z} zz=#{zz}")

    zz = x.to_f**y.to_f
    zf = z.to_f
    # assert((zf - zz).abs / [zf.abs, zz.abs, Float::MIN].max < 1e-9, "z=#{zf.to_s} and zz=#{zz.to_s} should be almost equal x=#{x} y=#{y} z=#{z} zz=#{zz}")
    assert((zf - zz).abs < [z.unit.to_f, zf.abs / 1e9].max,
           "zf=#{zf} and zz=#{zz} should be almost equal x=#{x} y=#{y} z=#{z} zz=#{zz}")
  end

  #
  # helper method for test_lm_power_yint
  # tests if exp(x) with precision prec is calculated correctly
  #
  def check_power_yhalfint(x, y2, prec)
    print '.'
    $stdout.flush

    y2i = y2.to_i
    x = x.to_ld
    y = LongDecimal('0.5') * y2i

    z  = LongMath.power(x, y, prec, ROUND_HALF_UP)
    zz = LongMath.sqrt(x**y2i, prec, ROUND_HALF_UP)
    assert_equal(z, zz, "power with ** or power-method x=#{x} y=#{y} z=#{z} zz=#{zz}")
    zz = LongMath.power_internal(x, y, prec)
    assert((zz - z).abs <= z.unit,
           "power with and without optimizations x=#{x} y=#{y} z=#{z} zz=#{zz}")

    zz = x.to_f**y.to_f
    zf = z.to_f
    # assert((zf - zz).abs / [zf.abs, zz.abs, Float::MIN].max < 1e-9, "z=#{zf.to_s} and zz=#{zz.to_s} should be almost equal x=#{x} y=#{y} z=#{z} zz=#{zz}")
    assert((zf - zz).abs < [z.unit.to_f, zf.abs / 1e9].max,
           "zf=#{zf} and zz=#{zz} should be almost equal x=#{x} y=#{y} z=#{z} zz=#{zz}")
  end

  #
  # helper method for test_log
  # tests if log(x) with precision prec is calculated correctly
  #
  def check_log_floated(x, prec, _divisor = 1e9, _summand = 0)
    print ','
    $stdout.flush

    assert(prec.positive?, 'does not work for prec=0')

    # make sure x is LongDecimal
    x0 = x
    x = x.to_ld
    # calculate y = log(x)
    y = LongMath.log(x, prec)
    yy = LongMath.log(x, prec + 10)
    # assert_equal(yy.round_to_scale(y.scale, ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = log(x) calculated using regular floating
    # point arithmetic
    if x <= LongMath::MAX_FLOATABLE
      xf = x.to_f
      if xf.positive?
        xf = x.to_f
        z  = Math.log(xf)
        zl = z.to_ld(y.scale)
        df = [1e-14, z.abs / 1e10].max
        dl = y.unit
        # delta = [ y.unit, z.abs / divisor + summand ].max
        delta = [df, dl].max
        assert((y - zl).abs <= delta,
               "y=#{y} (#{y.to_f}) and z=#{z} (#{zl}=#{zl.to_f}) should be almost equal (delta=#{delta.inspect} d=#{y - zl}=#{(y - zl).to_f} x=#{x} y=#{y}=#{y.to_f})")
      end
    end

    # check by taking exp(log(y))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if y <= LongMath::MAX_EXP_ABLE
      eprec = prec - 1
      if y > 1
        _ly = 0
        if y > LongMath::MAX_FLOATABLE
          puts("unusual y=#{y} y=#{y}\n")
          _ly = LongMath::MAX_EXP_ABLE
        else
          _ly = Math.log(y.to_f)
        end
        # l10 = (ly * (1.2+2/(prec+1.0)) / Math.log(10)).ceil
        l10 = (y.to_f * (1.2 + (2 / (prec + 1.0))) / Math.log(10)).ceil
        # l10 = (y.to_f / Math.log(10)).ceil
        eprec -= l10
      end
      df = 1
      if eprec.negative?
        df += eprec.abs
        eprec = 0
      end
      z = LongMath.exp(y, eprec)
      u = z.unit
      v = y.unit
      # delta = (u + u.move_point_left(1)) * df
      delta = [v * z, u * df].max
      assert((x - z).abs <= delta,
             "x=#{x} and z=#{z} should be almost equal (#{(x - z).abs} < d=#{delta} y=#{y} eprec=#{eprec} prec=#{prec})")
    end

    # check by doing calculation with different internal rounding modes.  They should not differ.
    # yd = LongMath.log_internal(x, prec, nil, nil, ROUND_DOWN)
    # yu = LongMath.log_internal(x, prec, nil, nil, ROUND_UP)
    yd = LongMath.log_internal(x, prec, nil, nil, ROUND_FLOOR)
    yu = LongMath.log_internal(x, prec, nil, nil, ROUND_CEILING)
    # assert_equal(yd, yu, "the result yd/yu should not depend on the internal rounding mode yd=#{yd} yu=#{yu} y=#{y} p=#{prec} d=#{(yd-yu).to_f.to_s}")
    # assert_equal(y,  yu, "the result y/yu  should not depend on the internal rounding mode yd=#{yd} yu=#{yu} y=#{y} p=#{prec} d=#{(y -yu).to_f.to_s}")
    assert_small_interval(yd, yu, y,
                          "the result y/yu  should not depend on the internal rounding mode x0=#{x0} x=#{x} p=#{prec} d=#{(yd - yu).to_f}")
    y
  end

  #
  # helper method for test_lm_power
  # tests if LongMath::power(x, y, prec) with precision prec is calculated correctly
  #
  def check_power_floated(x, y, prec)
    print '.'
    $stdout.flush

    # make sure x and y are LongDecimal
    _x0 = x
    x = x.to_ld
    _y0 = y
    y = y.to_ld
    # calculate z = x**y
    z = LongMath.power(x, y, prec)
    prec_dp = (2 * prec) + 1
    z_dp = LongMath.power(x, y, prec_dp)
    msg = "x=#{x}\ny=#{y}\nz=#{z}\nz_dp=#{z_dp}\nprec=#{prec}"
    # puts msg
    assert((z - z_dp).abs <= 2 * z.unit, msg)

    corr2 = (x - 1).abs * 1_000_000_000 # 10**9
    if z.abs < LongMath::MAX_FLOATABLE && corr2 > 1
      # compare y against w = x**y calculated using regular floating point arithmetic
      xf = x.to_f
      yf = y.to_f
      wf = xf**yf
      zf = z.to_f
      qf = 1e9
      delta = [z.unit.to_f, zf.abs / qf].max
      # puts "delta=#{delta} z=#{z} zu=#{z.unit} zuf=#{z.unit.to_f} zf=#{zf} |zf/qf|=#{zf.abs/qf}"
      if yf.abs > 1
        l = Math.log(yf.abs)
        delta *= l if l > 1
        # puts "delta=#{delta} l=#{l}"
      end
      corr = corr2 * 0.5
      if corr > 1
        corr_f = [corr.to_f, 5.0].min
        delta *= corr_f
      end
      # puts "delta=#{delta} corr_f=#{corr_f} corr=#{corr}"

      diff = (zf - wf).abs
      msg = "z=#{z}=#{zf} and wf=#{wf} should be almost equal\nx=#{x}=#{xf}\ny=#{y}=#{yf}\ndelta=#{delta}\nl=#{l}\ndiff=#{diff}\nprec=#{prec}\ncorr=#{corr}=#{corr.to_f}\ncorr2=#{corr2}=#{corr2.to_f}\ncorr_f=#{corr_f}"
      # puts msg
      assert_equal_float(zf, wf, delta, msg)
      # puts "OK"
      print '.'
    end

    # check by taking log(z) = y * log(x)
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if z.positive?
      lprec = prec
      if z < 1
        l10 = (Math.log(z.to_f) / Math.log(10)).floor
        lprec += l10
      end
      if x < 1
        l10 = (Math.log(x.to_f) / Math.log(10)).floor
        lprec += l10
      end
      unit = (10**-lprec).to_ld
      lprec = 0 if lprec.negative?
      l10y = 0
      l10y = (Math.log(y.abs.to_f) / Math.log(10)).ceil if y.abs > 1
      lprec_dp = (2 * lprec) + 1
      u = LongMath.log(z, lprec)
      u_dp = LongMath.log(z_dp, lprec_dp)
      v = LongMath.log(x, lprec + l10y)
      v_dp = LongMath.log(x, lprec_dp + l10y)
      yv = (y * v).round_to_scale(lprec, ROUND_HALF_DOWN)
      yv_dp = (y * v_dp).round_to_scale(lprec_dp, ROUND_HALF_DOWN)
      assert((u_dp - yv_dp).abs <= unit,
             "u=log(z,#{lprec})=#{u_dp}=#{u} and yv=y*v=y*log(x,#{lprec + l10y})=#{yv_dp}=#{yv} should be almost equal (unit=#{unit} x=#{x} y=#{y} z=#{z_dp}=#{z} u=#{u_dp}=#{u} v=#{v_dp}=#{v} lprec=#{lprec} prec=#{prec} lprec_dp=#{lprec_dp} prec_dp=#{prec_dp})")
      assert((u - yv).abs <= unit,
             "u=log(z,#{lprec})=#{u} and yv=y*v=y*log(x,#{lprec + l10y})=#{yv} should be almost equal (unit=#{unit} x=#{x} y=#{y} z=#{z} u=#{u} v=#{v} lprec=#{lprec} prec=#{prec})")
    end
  end

  #
  # helper method for test_log10
  # tests if log10(x) with precision prec is calculated correctly
  #
  def check_log10_floated(x, prec)
    print ','
    $stdout.flush

    # make sure x is LongDecimal
    _x0 = x
    x = x.to_ld
    # calculate y = log10(x)
    y = LongMath.log10(x, prec)
    yy = LongMath.log10(x, prec + 10)
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = log10(x) calculated using regular floating
    # point arithmetic
    if x <= LongMath::MAX_FLOATABLE
      xf = x.to_f
      if xf.positive?
        _xf = x.to_f
        z = Math.log(x.to_f) / Math.log(10)
        yf = y.to_f
        _zl = z.to_ld(y.scale)
        df = [1e-13, z.abs / 1e10].max
        dl = y.unit
        delta = [df, dl].max
        assert((yf - z).abs < delta,
               "y=#{yf} and z=#{z} should be almost equal (x=#{x} delta=#{delta}")
      end
    end

    # check by taking 10**(log10(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if y <= LongMath::MAX_EXP_ABLE
      eprec = prec
      if y > 1
        lx = 0
        if x > LongMath::MAX_FLOATABLE
          puts("unusual x=#{x} y=#{y}\n")
          lx = LongMath::MAX_EXP_ABLE
        else
          lx = Math.log(x.to_f)
        end
        l10 = (lx / Math.log(10)).ceil
        eprec = [eprec - l10, 0].max
      end

      z  = LongMath.power(10, y, eprec)
      zz = LongMath.exp10(y, eprec)
      u  = z.unit
      v  = y.unit
      assert((zz - z).abs <= u,
             "zz=#{zz} and z=#{z} should be almost equal (y=#{y} eprec=#{eprec} prec=#{prec})")
      delta = [v * z * LongMath::LOG10 * 1.2, u * 1.1].max
      assert((x - z).abs <= delta,
             "x=#{x} and z=#{z} should be almost equal (y=#{y} eprec=#{eprec} prec=#{prec} delta=#{delta})")
    end

    y
  end

  #
  # helper method for test_log10
  # tests if log10(x) with precision prec is calculated correctly
  #
  def check_log10_exact(x, log10x, prec)
    # make sure x is LongDecimal
    _x0 = x
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
    print ','
    $stdout.flush

    # make sure x is LongDecimal
    _x0 = x
    x = x.to_ld
    # calculate y = log2(x)
    y = LongMath.log2(x, prec)
    yy = LongMath.log2(x, prec + 10)
    # assert_equal(yy.round_to_scale(y.scale, ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
    assert_equal_rounded(yy, y, "x=#{x} y=#{y} yy=#{yy}")

    # compare y against z = log2(x) calculated using regular floating
    # point arithmetic
    if x <= LongMath::MAX_FLOATABLE
      xf = x.to_f
      if xf.positive?
        xf = x.to_f
        z = Math.log(xf) / Math.log(2)
        yf = y.to_f
        _zl = z.to_ld(y.scale)
        df = [1e-13, z.abs / 1e10].max
        dl = y.unit.abs
        delta = [df, dl].max
        assert((yf - z).abs < delta.to_f,
               "y=#{yf} and z=#{z} should be almost equal (x=#{x} delta=#{delta}")
      end
    end

    # check by taking 2**(log2(x))
    # we have to take into account that we might not have enough
    # significant digits, so we have to go down with the precision
    if y <= LongMath::MAX_EXP_ABLE
      eprec = prec
      if y > 1
        lx = 0
        if x > LongMath::MAX_FLOATABLE
          puts("unusual x=#{x} y=#{y}\n")
          lx = LongMath::MAX_EXP_ABLE
        else
          lx = Math.log(x.to_f)
        end
        l10 = (lx / Math.log(10)).ceil
        eprec = [eprec - l10, 0].max
      end

      z  = LongMath.power(2.to_ld, y, eprec)
      zz = LongMath.exp2(y, eprec)
      u = z.unit
      v = y.unit
      assert((zz - z).abs <= u,
             "zz=#{zz} and z=#{z} should be almost equal (y=#{y} eprec=#{eprec} prec=#{prec})")
      delta = [v * z, u].max
      assert((x - z).abs <= delta,
             "x=#{x} and z=#{z} should be almost equal (y=#{y} eprec=#{eprec} prec=#{prec} delta=#{delta})")
    end
    y
  end

  #
  # helper method for test_log2
  # tests if log2(x) with precision prec is calculated correctly
  #
  def check_log2_exact(x, log2x, prec)
    # make sure x is LongDecimal
    _x0 = x
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
    z = y.square
    zz = (y + 1).square
    assert(y >= 0, "sqrt must be >= 0#{s}")
    assert(z <= x && x < zz, "y=#{y}=sqrt(#{x}) and x in [#{z}, #{zz})" + s)
    y
  end

  #
  # helper method of test_int_sqrtw
  #
  def check_sqrtw(x, s)
    y = LongMath.sqrtw(x)
    z = y * y
    zz = (y + 1) * (y + 1)
    assert(y >= 0, "sqrt must be >= 0#{s}")
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
    z2 = (y + 1) * (y + 1)
    assert(y >= 0, "sqrt _with_remaindermust be >= 0#{s}")
    assert_equal(z1, x, "x=#{x} y=#{y} r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    assert(z0 <= x && x < z2,
           "y=#{y}=sqrt(_with_remainder#{x}) and x in [#{z0}, #{z2}) r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    y
  end

  #
  # helper method for test_int_sqrtw_with_remainder
  #
  def check_sqrtw_with_remainder(x, s)
    y, r = LongMath.sqrtw_with_remainder(x)
    z0 = y * y
    z1 = z0 + r
    z2 = (y + 1) * (y + 1)
    assert(y >= 0, "sqrt _with_remaindermust be >= 0#{s}")
    assert_equal(z1, x, "x=#{x} y=#{y} r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    assert(z0 <= x && x < z2,
           "y=#{y}=sqrt(_with_remainder#{x}) and x in [#{z0}, #{z2}) r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    y
  end

  #
  # helper method of test_sqrt
  # su0 and su1 describe how close the sqrt should be to the ideal result in units of the result
  # usually su0=0 or -1 and su1=0 or 1
  #
  def check_sqrt(x, scale, mode, su0, su1, str)
    y = x.sqrt(scale, mode)
    if mode == ROUND_UNNECESSARY
      ALL_ROUNDING_MODES.each do |any_mode|
        next if any_mode == ROUND_UNNECESSARY

        yy = x.sqrt(scale, any_mode)
        assert_equal(y, yy, "any_mode=#{any_mode}")
      end
    end

    if [ROUND_HALF_UP, ROUND_HALF_DOWN, ROUND_HALF_EVEN].include?(mode)
      yy = x.sqrt(scale + 10, mode)
      assert_equal(yy.round_to_scale(y.scale, mode), y, "x=#{x} y=#{y} yy=#{yy}")
    end

    z0 = (y + (su0 * y.unit)).square
    z1 = (y + (su1 * y.unit)).square
    assert(y.sign >= 0, "sqrt must be >= 0#{str}")
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
    assert(y.sign >= 0, "sqrt must be >= 0#{str}")
    assert(z0 <= x && x < z1, "y=#{y}=sqrt(#{x}) and x in [#{z0}, #{z1}) " + str)
    assert((x - z0 - r).zero?,
           "x=y*y+r x=#{x} z0=#{z0} z1=#{z1} y=#{y} r=#{r} total=#{x - z0 - r} " + str)
    r
  end

  #
  # helper method for test_int_cbrtb
  #
  def check_cbrtb(x, s)
    y = LongMath.cbrtb(x)
    z = y.cube
    zz = (y + 1).cube
    assert(y >= 0, "cbrt must be >= 0#{s}")
    assert(z <= x && x < zz, "y=#{y}=cbrt(#{x}) and x in [#{z}, #{zz})" + s)
    y
  end

  #
  # helper method for test_int_cbrtb_with_remainder
  #
  def check_cbrtb_with_remainder(x, s)
    y, r = LongMath.cbrtb_with_remainder(x)
    z0 = y.cube
    # puts "x=#{x} y=#{y} z0=#{z0} r=#{r}"
    z1 = z0 + r
    z2 = (y + 1).cube
    assert(y >= 0, "cbrt _with_remainder must be >= 0#{s}")
    assert_equal(z1, x, "x=#{x} y=#{y} r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    assert(z0 <= x && x < z2,
           "y=#{y}=cbrt(_with_remainder#{x}) and x in [#{z0}, #{z2}) r=#{r} z0=#{z0} z1=#{z1} z2=#{z2}" + s)
    y
  end

  #
  # helper method of test_cbrt
  #
  def check_cbrt(x, scale, mode, su0, su1, str)
    y  = x.cbrt(scale, mode)
    if [ROUND_HALF_UP, ROUND_HALF_DOWN, ROUND_HALF_EVEN].include?(mode)
      yy = x.cbrt(scale + 10, mode)
      assert_equal(yy.round_to_scale(y.scale, mode), y, "x=#{x} y=#{y} yy=#{yy}")
    end
    z0 = (y + (su0 * y.unit)).cube
    z1 = (y + (su1 * y.unit)).cube
    assert(y.sign >= 0, "cbrt must be >= 0#{str}")
    assert(z0 <= x && x <= z1,
           "y=#{y}=cbrt(#{x}) and x in [#{z0}, #{z1}) su0=#{su0} su1=#{su1}" + str)
    y
  end

  #
  # helper method of test_cbrt_with_remainder
  #
  def check_cbrt_with_remainder(x, scale, str)
    y, r = x.cbrt_with_remainder(scale)
    z0 = y.cube
    z1 = y.succ.cube
    assert(y.sign >= 0, "cbrt must be >= 0#{str}")
    assert(z0 <= x && x < z1, "y=#{y}=cbrt(#{x}) and x in [#{z0}, #{z1}) " + str)
    assert((x - z0 - r).zero?,
           "x=y**3+r x=#{x} z0=#{z0} z1=#{z1} y=#{y} r=#{r} total=#{x - z0 - r} " + str)
    r
  end

  def deep_freeze_complex(z)
    z.imag.freeze
    z.real.freeze
    z.freeze
  end
end

# end of file testlongdecimal.rb
