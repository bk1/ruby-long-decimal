#
# long-decimal-extra.rb -- Arbitrary precision decimals with fixed decimal point
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/lib/long-decimal-extra.rb,v 1.1 2007/08/19 19:23:33 bk1 Exp $
# CVS-Label: $Name: ALPHA_01_03 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#
require "complex"
require "rational"
require "bigdecimal"

# require "long-decimal.rb"

# require "bigdecimal/math"

#
# LongMath provides some helper functions to support LongDecimal and
# LongDecimalQuot, mostly operating on integers.  They are used
# internally here, but possibly they can be used elsewhere as well.
# In addition LongMath provides methods like those in Math, but for
# LongDecimal instead of Float.
#
module LongMath

  #
  # calc the base-2-exponential function of x to the given precision as
  # LongDecimal.  Only supports values of x such that the result still
  # fits into a float (x <= 709).  This limitation is somewhat
  # arbitrary, but it is enforced in order to avoid producing numbers
  # with the exponential function that exceed the memory.
  #
  def LongMath.exp2(x, prec, mode = LongMath.standard_mode) # down?
    LongMath.power(2, x, prec, mode)
  end

  #
  # calc the base-10-exponential function of x to the given precision as
  # LongDecimal.  Only supports values of x such that the result still
  # fits into a float (x <= 709).  This limitation is somewhat
  # arbitrary, but it is enforced in order to avoid producing numbers
  # with the exponential function that exceed the memory.
  #
  def LongMath.exp10(x, prec, mode = LongMath.standard_mode) # down?
    LongMath.power(10, x, prec, mode)
  end

  #
  # calculate the base 10 logarithm of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log10(x, prec, mode = LongMath.standard_mode) # down?

    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    iprec = prec + 6
    unless (x.kind_of? LongDecimal)
      x = x.to_ld(iprec, mode)
    end
    if (x.one?) then
      return LongDecimal.zero!(prec)
    end

    id = x.int_digits10
    xx = x.move_point_left(id)
    lnxx = log_internal(xx, iprec, mode)
    ln10 = log_internal(10, iprec, mode)
    y  = id + (lnxx / ln10).round_to_scale(prec, mode)
    return y
  end

  #
  # calculate the base 2 logarithm of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log2(x, prec, mode = LongMath.standard_mode)

    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    iprec = prec + 6
    unless (x.kind_of? LongDecimal)
      x = x.to_ld(iprec, mode)
    end
    if (x.one?) then
      return LongDecimal.zero!(prec)
    end
    id = x.int_digits2
    xx = (x / (1 << id)).round_to_scale(x.scale+id)
    lnxx = log_internal(xx, iprec, mode)
    ln2  = log_internal(2.to_ld, iprec, mode)
    y    = id + (lnxx / ln2).round_to_scale(prec, mode)
    return y
  end

  private

  #
  # internal helper method for calculating the internal precision for power
  #
  def LongMath.calc_iprec_for_power(x, y, prec)

    logx_f = nil
    if (x.abs <= LongMath::MAX_FLOATABLE)
      x_f    = x.to_f
      logx_f = Math.log(x_f.abs)
    else
      logx_f = LongMath.log(x, 15, LongMath::ROUND_UP)
    end

    y_f = nil
    if (y.abs <= LongMath::MAX_FLOATABLE) then
      y_f = y.to_f
    else
      y_f = y.round_to_scale(15, LongMath::ROUND_UP)
    end

    logx_y_f = logx_f * y_f
    if (logx_y_f.abs > LongMath::MAX_FLOATABLE) then
      raise ArgumentError, "power would be way too big: y*log(x)=#{logx_y_f}";
    end
    logx_y_f = logx_y_f.to_f unless logx_y_f.kind_of? Float

    iprec_x  = calc_iprec_for_exp(logx_y_f.abs.ceil, prec, logx_y_f < 0)
    iprec_y  = iprec_x
    iprec    = iprec_x + 2
    if (logx_f < 0)
      iprec_x -= (logx_f/LOG10).round
    end
    if (y_f.abs < 1)
      logy_f = nil
      if (y_f.kind_of? Float) then
        logy_f = Math.log(y_f.abs)
      else
        logy_f = LongMath.log(y_f.abs, 15, LongMath::ROUND_UP)
        if (logy_f.abs > LongMath::MAX_FLOATABLE) then
          raise ArgumentError, "exponent would be way too big: y=#{y} logy_f=#{logy_f}";
        end
        logy_f = logy_f.to_f
      end
      # puts("x=#{x} y=#{y} x_f=#{x_f} y_f=#{y_f} logx_f=#{logx_f} logy_f=#{logy_f} logx_y_f=#{logx_y_f}\n")
      iprec_y -= (logy_f/LOG10).round
    end
    # puts("x=#{x} y=#{y} x_f=#{x_f} y_f=#{y_f} logx_f=#{logx_f} logy_f=#{logy_f} logx_y_f=#{logx_y_f}\n")
    # puts("\niprec: x=#{x} y=#{y} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y}\n")
    [ iprec, iprec_x, iprec_y, logx_y_f ]

  end

  public

  #
  # calc the power of x with exponent y to the given precision as
  # LongDecimal.  Only supports values of y such that exp(y) still
  # fits into a float (y <= 709)
  #
  def LongMath.power(x, y, prec, mode = LongMath.standard_mode)

    raise TypeError, "x=#{x} must be numeric" unless x.kind_of? Numeric
    raise TypeError, "y=#{y} must be numeric" unless y.kind_of? Numeric
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "y=#{y.inspect} must not be greater #{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE
    # raise TypeError, "y=#{y.inspect} must not be greater #{MAX_EXP_ABLE}" unless y <= MAX_EXP_ABLE
    # raise TypeError, "x=#{x.inspect} must not negative" unless x >= 0 || (y.kind_of? Integer) || (y.kind_of? LongDecimalBase) && y.is_int?
    raise TypeError, "x=#{x.inspect} must not negative" unless x >= 0
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")

    # handle the special cases where base or exponent are 0 or 1 explicitely
    if y.zero? then
      return LongDecimal.one!(prec)
    elsif x.zero? then
      return LongDecimal.zero!(prec)
    elsif y.one? then
      return x.to_ld(prec, mode)
    elsif x.one? then
      return LongDecimal.one!(prec)
    end

    # els
    # could be result with our precision
    # x ** y <= 10**-s/2  <=> y * log(x) <= -s log(10) - log(2)

    iprec, iprec_x, iprec_y, logx_y_f = calc_iprec_for_power(x, y, prec)
    if (x < 1 && y > 0 || x > 1 && y < 0) then
      if (logx_y_f <= - prec * LOG10 - LOG2) then
        return LongDecimal.zero!(prec)
      end
    end
    # puts("x=#{x} y=#{y} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y} prec=#{prec}")

    unless (x.kind_of? LongDecimalBase) || (x.kind_of? Integer)
      x = x.to_ld(iprec_x, mode)
    end
    unless (y.kind_of? LongDecimalBase) || (y.kind_of? Integer)
      y = y.to_ld(iprec_y, mode)
    end

    # try shortcut if exponent is an integer
    if (y.kind_of? LongDecimalBase) && y.is_int? then
      y = y.to_i
    end
    unless (y.kind_of? Integer)
      y2 = y*2
      if (y2.kind_of? LongDecimalBase) && y2.is_int? then
        y2 = y2.to_i
        puts("y2=#{y2}")
      end
      if (y2.kind_of? Integer)
        x = LongMath.sqrt(x, 2*iprec_x, mode)
        y = y2
      end
    end
    if (y.kind_of? Integer)
      unless x.kind_of? LongDecimal
        # x = x.to_ld(prec)
        x = x.to_ld(iprec_x)
      end
      # z = x ** y
      z = LongMath.ipower(x, y, 2*iprec, mode)
      # puts("x=#{x} y=#{y} z=#{z} y int")
      return z.to_ld(prec, mode)
    end

    # it can be assumed that the exponent is not an integer, so it should
    # be converted into LongDecimal
    unless (y.kind_of? LongDecimal)
      # y = y.to_ld(prec, mode)
      y = y.to_ld(iprec_y, mode)
    end

    # if x < 1 && y < 0 then
    # working with x < 1 should be improved, less precision needed
    if x < 1 then
      # since we do not allow x < 0 and we have handled x = 0 already,
      # we can be sure that x is no integer, so it has been converted
      # if necessary to LongDecimalBase
      y = -y
      x = (1/x).round_to_scale(iprec_x*2, mode)
      iprec, iprec_x, iprec_y = calc_iprec_for_power(x, y, prec)
    end

    # exponent is split in two parts, an integer part and a
    # LongDecimal with absolute value <= 0.5
    y0 = y.round_to_scale(0, LongMath.standard_imode).to_i
    # z0 = x**y0
    z0 = LongMath.ipower(x, y0, 2*iprec, mode)
    y1 = y - y0
    prec_extra = 0
    if (y0 > 0)
      prec_extra = (y0*Math.log10(x.to_f).abs).ceil
    end
    # z1 = LongMath.power_internal(x, y1, prec+prec_extra , mode)
    z1 = LongMath.power_internal(x, y1, prec+prec_extra + 4, mode)
    z  = z0 * z1
    # puts("x=#{x} y=#{y} z=#{z} y not int")
    return z.to_ld(prec, mode)
  end

  #
  # internal functionality to calculate the y-th power of x assuming
  # that y is an integer
  # prec is a hint on how much internal precision is needed at most
  # final rounding is left to the caller
  #
  def LongMath.ipower(x, y, prec, mode)

    raise TypeError, "x=#{x} must be numeric" unless x.kind_of? Numeric
    raise TypeError, "y=#{y} must be integer" unless y.kind_of? Integer
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "y=#{y.inspect} must not be greater #{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")

    cnt = 0

    if (y.zero?)
      return 1
    elsif ! (x.kind_of? LongDecimalBase) || x.scale * y.abs <= prec
      return x ** y
    elsif (y < 0)
      l = Math.log10(x.abs.to_f)
      if (l > 0)
        prec += (2*l).ceil
      end
      return 1/LongMath.ipower(x, -y, prec, mode)
    else
      # y > 0
      # puts("ipower y>0 x=#{x} y=#{y} prec=#{prec}")
      z  = x
      while true do

        cnt++
        y -= 1
        if (y.zero?)
          break
        end
        while (y & 0x01) == 0 do

          cnt++
          y = y >> 1
          x = (x*x)
          if (x.kind_of? LongDecimalBase)
            x = x.round_to_scale(prec, mode)
          end
          if (cnt > 1000)
            puts("ipower x=#{x} y=#{y} cnt=#{cnt} z=#{z}")
            cnt = 0
          end

        end
        z = (z*x)
        if (z.kind_of? LongDecimalBase)
          z = z.round_to_scale(prec, mode)
        end

      end
    end
    return z
  end

  #
  # internal functionality of exp.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing exp.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.power_internal(x, y, prec = nil, final_mode = LongMath.standard_mode, iprec = nil, mode = LongMath.standard_imode)

    if (prec.nil?) then
      if (x.kind_of? LongDecimalBase) && (y.kind_of? LongDecimalBase)
        prec = [x.scale, y.scale].max
      elsif (x.kind_of? LongDecimalBase)
        prec = x.scale
      elsif (y.kind_of? LongDecimalBase)
        prec = y.scale
      else
        raise ArgumentError, "precision must be supplied either as precision of x=#{x} or explicitely"
      end
    end
    check_is_prec(prec, "prec")

    if (final_mode.nil?)
      final_mode = LongMath.standard_mode
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    if y.zero? then
      return LongDecimal.one!(prec)
    elsif x.zero? then
      return LongDecimal.zero!(prec)
    end

    if (iprec.nil?) then
      iprec, iprec_x, iprec_y = calc_iprec_for_power(x, y, prec)
    end
    unless (x.kind_of? LongDecimal)
      # x = x.to_ld(iprec, mode)
      x = x.to_ld(iprec_x, mode)
    end
    unless (y.kind_of? LongDecimal)
      # y = y.to_ld(iprec, mode)
      y = y.to_ld(iprec_y, mode)
    end

    # logx = log(x, iprec, mode)
    logx = log(x, iprec + 20, mode)
    logx_y = logx*y
    # xy = exp_internal(logx_y, prec + 1, mode)
    # xy = exp_internal(logx_y, prec + 4, mode)
    xy = exp_internal(logx_y, prec + 3, mode)
    xy.round_to_scale(prec, final_mode)

  end # power_internal

end # LongMath

# end of file long-decimal-extra.rb
