#
# long-decimal-extra.rb -- Arbitrary precision decimals with fixed decimal point
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2009
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/lib/long-decimal-extra.rb,v 1.9 2009/04/21 16:56:49 bk1 Exp $
# CVS-Label: $Name: BETA_02_01 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#
require "complex"
require "rational"
require "bigdecimal"

# require "long-decimal.rb"

# require "bigdecimal/math"

class Rational
  alias :to_g :to_f

  FLOAT_MAX_I = Float::MAX.to_i

  def to_f
    numerator   = @numerator
    denominator = @denominator
    sign        = numerator <=> 0
    if (sign.zero?)
      return 0.0
    elsif sign < 0
      numerator = -numerator
    end
    while numerator >= FLOAT_MAX_I || denominator >= FLOAT_MAX_I do
      numerator   >>= 8
      denominator >>= 8
      if (denominator == 0)
        raise ZeroDivisionError, "denominator too close to zero: #{@numerator}/{@denominator}"
      elsif numerator == 0
        return 0.0
      end
    end
    return numerator.to_f / denominator.to_f
  end
end

class LongDecimal

  #
  # convert self into Float
  # this works straitforward by dividing numerator by power of 10 in
  # float-arithmetic, in all cases where numerator and denominator are
  # within the ranges expressable as Floats.  Goes via string
  # representation otherwise.
  #
  def to_g
    # handle overflow: raise exception
    if (self.abs > LongMath::MAX_FLOATABLE) then
      raise ArgumentError, "self=#{self.inspect} cannot be expressed as Float"
    end

    # handle underflow: return 0.0
    if (self.abs < LongMath::MIN_FLOATABLE) then
      puts "-> 0.0"
      return 0.0
    end

    if (self < 0) then
      puts "-> negate"
      return -(-self).to_g
    end

    dividend = numerator
    divisor  = denominator

    if (divisor == 1) then
      puts "-> /1"
      return dividend.to_f
    elsif dividend.abs <= LongMath::MAX_FLOATABLE then
      puts "-> dividend <= MAX_FLOATABLE"
      if (divisor.abs > LongMath::MAX_FLOATABLE) then
        puts "-> divisor > MAX_FLOATABLE"
        qe = scale - Float::MAX_10_EXP
        q  = 10**qe
        puts "-> q=#{q}"
        f = (dividend / q).to_f
        puts "-> f=#{f}"
        d = LongMath::MAX_FLOATABLE10
        puts "-> d=#{d}"
        y = f / d
        puts "-> y=#{y}"
        return y
      else
        puts "-> divisor <= MAX_FLOATABLE"
        f = dividend.to_f
        return f / divisor
      end
    elsif dividend.abs < divisor
      puts "-> < 1"
      # self is between -1 and 1

      # factor = dividend.abs.div(LongMath::MAX_FLOATABLE)
      # digits = factor.to_ld.int_digits10
      # return LongDecimal(dividend.div(10**digits), scale -digits).to_f
      return self.to_s.to_f
    else
      puts "-> >= 1"
      q = dividend.abs / divisor
      if (q.abs > 1000000000000000000000)
        puts "-> > 1000000000000000000000"
        return q.to_f
      else
        puts "-> <= 1000000000000000000000"
        return self.to_s.to_f
      end
    end
  end
end

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


  #
  # calculate the natural logarithm of x as floating point number,
  # even if x cannot reasonably be expressed as Float.
  #
  def LongMath.log_f(x)
    raise TypeError, "x=#{x.inspect} must not be positive" unless x > 0
    unless x.kind_of? LongDecimal
      x = x.to_ld(18, LongDecimalRoundingMode::ROUND_HALF_UP)
    end
    y = 0
    while (x > LongMath::MAX_FLOATABLE)
      y += LOG_1E100
      x  = x.move_point_left(100)
    end
    while (x < LongMath::MIN_FLOATABLE)
      y -= LOG_1E100
      x  = x.move_point_right(100)
    end
    x_f = x.to_f
    y  += Math.log(x_f)
    y
  end

  private

  LOG_1E100 = Math.log(1e100)

  #
  # internal helper method for calculating the internal precision for power
  #
  def LongMath.calc_iprec_for_power(x, y, prec)

    logx_f = LongMath.log_f(x.abs)

    y_f = nil
    if (y.abs <= LongMath::MAX_FLOATABLE) then
      y_f = y.to_f
    else
      y_f = y.round_to_scale(18, LongMath::ROUND_UP)
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
      logy_f = LongMath.log_f(y.abs)
      iprec_y -= (logy_f/LOG10).round
    end
    [ iprec, iprec_x, iprec_y, logx_y_f ]

  end

  public

  #
  # calc the power of x with exponent y to the given precision as
  # LongDecimal.  Only supports values of y such that the result still
  # fits into a float
  #
  def LongMath.power(x, y, prec, mode = LongMath.standard_mode)

    raise TypeError, "x=#{x} must be numeric" unless x.kind_of? Numeric
    raise TypeError, "y=#{y} must be numeric" unless y.kind_of? Numeric
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "y=#{y.inspect} must not be greater #{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE
    raise TypeError, "y=#{y.inspect} must not be negative if base is zero}" if y < 0 && x.zero?
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

    # could be result with our precision
    # x ** y <= 10**-s/2  <=> y * log(x) <= -s log(10) - log(2)

    iprec, iprec_x, iprec_y, logx_y_f = calc_iprec_for_power(x, y, prec)
    # puts "x=#{x} y=#{y} prec=#{prec} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y} logx_y_f=#{logx_y_f}: checking x < 1 && y > 0 || x > 1 && y < 0=#{x < 1 && y > 0 || x > 1 && y < 0}"
    $stdout.flush
    if (x < 1 && y > 0 || x > 1 && y < 0) then
      # puts "checking if zero logx_y_f=#{logx_y_f} <= #{- prec * LOG10 - LOG2}"
      if (logx_y_f <= - prec * LOG10 - LOG2) then
        return LongDecimal.zero!(prec)
      end
    end

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
      end
      if (y2.kind_of? Integer)
        x = LongMath.sqrt(x, 2*iprec_x, mode)
        y = y2
      end
    end
    if (y.kind_of? Integer)
      unless x.kind_of? LongDecimal
        x = x.to_ld(iprec_x)
      end
      z = LongMath.ipower(x, y, 2*iprec, mode)
      return z.to_ld(prec, mode)
    end

    # it can be assumed that the exponent is not an integer, so it should
    # be converted into LongDecimal
    unless (y.kind_of? LongDecimal)
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
      iprec, iprec_x, iprec_y, logx_y_f = calc_iprec_for_power(x, y, prec)
      # puts "x=#{x} y=#{y} prec=#{prec} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y} logx_y_f=#{logx_y_f}: checking x < 1 && y > 0 || x > 1 && y < 0=#{x < 1 && y > 0 || x > 1 && y < 0}"
      $stdout.flush
      if (x < 1 && y > 0 || x > 1 && y < 0) then
        # puts "checking if zero logx_y_f=#{logx_y_f} <= #{- prec * LOG10 - LOG2}"
        if (logx_y_f <= - prec * LOG10 - LOG2) then
          return LongDecimal.zero!(prec)
        end
      end
    end

    # exponent is split in two parts, an integer part and a
    # LongDecimal with absolute value <= 0.5
    y0 = y.round_to_scale(0, LongMath.standard_imode).to_i
    x0 = x
    point_shift = 0
    while x0 > LongMath::MAX_FLOATABLE
      x0 = x0.move_point_left(100)
      point_shift += 100
    end
    z0 = LongMath.ipower(x0, y0, 2*(iprec + point_shift), mode)
    if (point_shift > 0)
      unless z0.kind_of? LongDecimal
        z0 = z0.to_ld(2*(iprec + point_shift))
      end
      z0 = z0.move_point_right(point_shift * y0)
    end
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

    t0 = Time.now
    raise TypeError, "base x=#{x} must be numeric" unless x.kind_of? Numeric
    raise TypeError, "exponent y=#{y} must be integer" unless y.kind_of? Integer
    raise TypeError, "base x=#{x.inspect} must not be greater MAX_FLOATABLE=#{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "exponent y=#{y.inspect} must not be greater MAX_FLOATABLE=#{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")

    if (y.zero?)
      return 1
    elsif ! (x.kind_of? LongDecimalBase) || x.scale * y.abs <= prec
      # puts "x=#{x} y=#{y} using **"
      return x ** y
    elsif (y < 0)
      l = Math.log10(x.abs.to_f)
      if (l > 0)
        prec += (2*l).ceil
      end
      # return (1/LongMath.ipower(x, -y, prec + 2, mode)).round_to_scale(prec, mode)
      xi = 1/x
      # puts "x=#{x} y=#{y} prec=#{prec} using (1/x)**y xi=#{xi}"
      xr = xi.round_to_scale(prec + 6, mode)
      return LongMath.ipower(xr, -y, prec, mode)
    else
      # y > 0
      # puts "x=#{x} y=#{y} regular"
      cnt = 0
      z  = x
      y0 = y
      x0 = x
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
            x = x.round_to_scale(prec+4, mode)
          end
          if (cnt > 1000)
            puts("ipower x=#{x} y=#{y} cnt=#{cnt} z=#{z} t=#{Time.now - t0}")
            cnt = 0
          end

        end
        z = (z*x)
        if (z.kind_of? LongDecimalBase)
          z = z.round_to_scale(prec+3, mode)
          if (z.zero?)
            break
          end
        end
      end
      z = z.round_to_scale(prec, mode)
      return z
    end
  end

  #
  # internal functionality to calculate the y-th power of x assuming
  # that y is an integer
  # prec is a hint on how much internal precision is needed at most
  # final rounding is left to the caller
  #
  def LongMath.ipower_with_measurement(x, y, prec, mode)

    raise TypeError, "base x=#{x} must be numeric" unless x.kind_of? Numeric
    raise TypeError, "exponent y=#{y} must be integer" unless y.kind_of? Integer
    raise TypeError, "base x=#{x.inspect} must not be greater MAX_FLOATABLE=#{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "exponent y=#{y.inspect} must not be greater MAX_FLOATABLE=#{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")

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
      cnt = 0
      z  = x
      y0 = y
      x0 = x
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
      return z
    end
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
