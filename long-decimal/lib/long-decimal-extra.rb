#
# long-decimal-extra.rb -- Arbitrary precision decimals with fixed decimal point
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2009
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/lib/long-decimal-extra.rb,v 1.29 2011/02/04 23:17:21 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#
require "complex"
require "rational"
require "bigdecimal"

# require "long-decimal.rb"

# require "bigdecimal/math"

class LongDecimal

  # timer for performance measurements
  def ts(i)
    @timer ||= []
    @timer[i] = Time.now
  end

  # helper method for performance measurements
  def te(i)
    @@tt ||= []
    @@tt[i] ||= 0
    @@tt[i] += Time.now - @timer[i]
    @@tc ||= []
    @@tc[i] ||= 0
    @@tc[i] += 1
  end

  # helper method for performance measurements
  def tt(i)
    @@tt ||= []
    @@tt[i] ||= 0
    @@tc ||= []
    @@tc[i] ||= 0
    if (@@tc[i] == 0)
      @@tt[i]
    else
      @@tc[i].to_s + ":" + @@tt[i].to_s + ":" + (@@tt[i]/@@tc[i]).to_s
    end
  end

  #
  # create copy of self with different scale
  # param1: new_scale  new scale for result
  # param2: mode       rounding mode to be applied when information is
  #                    lost.   defaults  to  ROUND_UNNECESSARY,  which
  #                    means that  an exception is  thrown if rounding
  #                    would actually loose any information.
  #
  def round_to_scale2(new_scale, mode = ROUND_UNNECESSARY)

    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.kind_of? RoundingModeClass
    if @scale == new_scale then
      self
    else
      ts 16
      diff   = new_scale - scale
      factor = LongMath.npower10(diff.abs)
      te 16
      if (diff > 0) then
        # we become more precise, no rounding issues
        ts 17
        new_int_val = int_val * factor
        te 17
      else
        ts 18
        quot, rem = int_val.divmod(factor)
        te 18
        if (rem == 0) then
          new_int_val = quot
        elsif (mode == ROUND_UNNECESSARY) then
          raise ArgumentError, "mode ROUND_UNNECESSARY not applicable, remainder #{rem.to_s} is not zero"
        else
          ts 19
          sign_self = sign

          if (sign_self < 0) then
            # handle negative sign of self
            rem -= divisor
            quot += 1
          end
          sign_rem  = rem  <=> 0
          raise Error, "signs do not match self=#{self.to_s} f=#{factor} divisor=#{divisor} rem=#{rem}" if sign_rem >= 0 && sign_self < 0

          if (mode == ROUND_CEILING)
            # ROUND_CEILING goes to the closest allowed number >= self, even
            # for negative numbers.  Since sign is handled separately, it is
            # more conveniant to use ROUND_UP or ROUND_DOWN depending on the
            # sign.
            mode = (sign_self > 0) ? ROUND_UP : ROUND_DOWN

          elsif (mode == ROUND_FLOOR)
            # ROUND_FLOOR goes to the closest allowed number <= self, even
            # for negative numbers.  Since sign is handled separately, it is
            # more conveniant to use ROUND_UP or ROUND_DOWN depending on the
            # sign.
            mode = (sign_self < 0) ? ROUND_UP : ROUND_DOWN
          else
            if (mode == ROUND_HALF_CEILING)
              # ROUND_HALF_CEILING goes to the closest allowed number >= self, even
              # for negative numbers.  Since sign is handled separately, it is
              # more conveniant to use ROUND_HALF_UP or ROUND_HALF_DOWN depending on the
              # sign.
              mode = (sign_self > 0) ? ROUND_HALF_UP : ROUND_HALF_DOWN

            elsif (mode == ROUND_HALF_FLOOR)
              # ROUND_HALF_FLOOR goes to the closest allowed number <= self, even
              # for negative numbers.  Since sign is handled separately, it is
              # more conveniant to use ROUND_HALF_UP or ROUND_HALF_DOWN depending on the
              # sign.
              mode = (sign_self < 0) ? ROUND_HALF_UP : ROUND_HALF_DOWN

            end

            # handle the ROUND_HALF_... stuff and find the adequate ROUND_UP
            # or ROUND_DOWN to use
            abs_rem = rem.abs
            half    = (abs_rem << 1) <=> denominator
            if (mode == ROUND_HALF_UP || mode == ROUND_HALF_DOWN || mode == ROUND_HALF_EVEN) then
              if (half < 0) then
                mode = ROUND_DOWN
              elsif half > 0 then
                mode = ROUND_UP
              else
                # half == 0
                if (mode == ROUND_HALF_UP) then
                  mode = ROUND_UP
                elsif (mode == ROUND_HALF_DOWN) then
                  mode = ROUND_DOWN
                else
                  # mode == ROUND_HALF_EVEN
                  mode = (quot[0] == 1 ? ROUND_UP : ROUND_DOWN)
                end
              end
            end
          end

          if mode == ROUND_UP
            # since the case where we can express the result exactly without
            # loss has already been handled above, ROUND_UP can be handled
            # correctly by adding one unit.
            quot += sign_self
          end

          # put together result
          new_int_val = quot
          te 19
        end
      end
      ts 20
      y = LongDecimal(new_int_val, new_scale)
      te 20
      return y
    end
  end

  #
  # number of decimal digits before the decimal point, not counting a
  # single 0.  negative value, if some zeros follow immediately after
  # decimal point
  #
  # 0.000x -> -3
  # 0.00x -> -2
  # 0.0xx -> -1
  # 0.xxx ->  0
  # 1.xxx  -> 1
  # 10.xxx -> 2
  # 99.xxx -> 2
  # 100.xxx -> 3
  # ...
  # second implementation
  #
  def sint_digits10_2
    if zero?
      return -scale
    else
      n = numerator.abs
      d = denominator
      i = 0
      if (n < d)
        i = (d.size - i.size + 1.size) * 53 / 22
        n *= LongMath.npower10(i)
        if (n < d)
          raise ArgumentError, "still not working well: n=#{n} d=#{d} i=#{i} self=#{self}"
        end
      end
      return LongMath.int_digits10(n/d) - i
    end
  end

  #
  # number of decimal digits before the decimal point, not counting a
  # single 0.  negative value, if some zeros follow immediately after
  # decimal point
  #
  # 0.000x -> -3
  # 0.00x -> -2
  # 0.0xx -> -1
  # 0.xxx ->  0
  # 1.xxx  -> 1
  # 10.xxx -> 2
  # 99.xxx -> 2
  # 100.xxx -> 3
  # ...
  # third implementation
  #
  def sint_digits10_3
    if zero?
      return -scale
    else
      l = LongMath.log10(self.abs, 0, LongDecimal::ROUND_HALF_FLOOR).to_i
      f = LongMath.npower10(l + scale)
      if (f > int_val.abs)
        l -= 1
      end
      return l.to_i + 1
    end
  end

  #
  # number of decimal digits before the decimal point, not counting a
  # single 0.  negative value, if some zeros follow immediately after
  # decimal point
  #
  # 0.000x -> -3
  # 0.00x -> -2
  # 0.0xx -> -1
  # 0.xxx ->  0
  # 1.xxx  -> 1
  # 10.xxx -> 2
  # 99.xxx -> 2
  # 100.xxx -> 3
  # ...
  # forth implementation (for evaluation of algorithms only, will be removed again)
  #
  def sint_digits10_4
    if zero?
      return -scale
    else
      prec_limit = LongMath.prec_limit
      LongMath.prec_limit = LongMath::MAX_PREC
      n = numerator.abs
      s = 0
      imax = LongMath::POWERS_BIG_EXP_LIMIT
      puts "imax=#{imax}"
      fmax = LongMath.npower10(imax)
      puts "fmax: #{fmax.size}"
      imin = 0
      fmin = 1
      while n > fmax
        n /= fmax
        s += imax
      end
      # 1 <= n < 10**imax
      while (imin + 1 < imax)
        # 10**imin <= n < 10**imax
        imed = (imin + imax)/2
        fmed = LongMath.npower10(imed)
        if (n < fmed)
          imax = imed
          fmax = fmed
        else
          imin = imed
          fmin = fmed
        end
      end
      LongMath.prec_limit = prec_limit
      return s + imin - scale + 1
    end
  end

  #
  # convert self into Float
  # this works straitforward by dividing numerator by power of 10 in
  # float-arithmetic, in all cases where numerator and denominator are
  # within the ranges expressable as Floats.  Goes via string
  # representation otherwise.
  #
  def to_g

    # make sure we do not have to deal with negative sign beyond this point
    if (self < 0) then
      return -(-self).to_f
    end

    # handle overflow: raise exception
    if (self > LongMath::MAX_FLOATABLE) then
      raise ArgumentError, "self=#{self.inspect} cannot be expressed as Float"
    end

    # handle underflow: return 0.0
    if (self < LongMath::MIN_FLOATABLE) then
      return 0.0
    end

    dividend = numerator
    divisor  = denominator

    if (divisor == 1) then
      return dividend.to_f
    elsif dividend <= LongMath::MAX_FLOATABLE then
      if (divisor > LongMath::MAX_FLOATABLE) then
        q = LongMath.npower10(scale - Float::MAX_10_EXP)
        f = (dividend / q).to_f
        d = LongMath::MAX_FLOATABLE10
        return f / d
      else
        f = dividend.to_f
        return f / divisor
      end
    elsif dividend < divisor
      # self is between 0 and 1 and dividend > LongMath::MAX_FLOATABLE
      # return LongDecimal(dividend.div(LongMath.npower10(digits)), scale -digits).to_f
      # puts "via s (1): #{self.inspect}"
      return self.to_s.to_f
    else
      q = dividend.abs / divisor
      if (q.abs > 1000000000000000000000)
        return q.to_f
      else
        # puts "via s (2): #{self.inspect}"
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

    prec = check_is_prec(prec, "prec")
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

    prec = check_is_prec(prec, "prec")
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
      x_rounded = x.to_ld(18, LongDecimalRoundingMode::ROUND_HALF_UP)
      if (x_rounded.one?)
        # x rounds to 1, if we cut of the last digits?
        # near 1 the derivative of log(x) is approximately 1, so we can assume log_f(x) ~ x-1
        return x - 1
      else
        x = x_rounded
      end
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
      iprec_x -= (-1.5 + logx_f/LOG10).round
    end
    if (y_f.abs < 1)
      logy_f = LongMath.log_f(y.abs)
      iprec_y -= (- 1.5 + logy_f/LOG10).round
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
    prec = check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    puts "LongMath.power(x=#{x} y=#{y} prec=#{prec} mode=#{mode})"

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
    puts "x=#{x} y=#{y} prec=#{prec} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y} logx_y_f=#{logx_y_f}: checking x < 1 && y > 0 || x > 1 && y < 0=#{x < 1 && y > 0 || x > 1 && y < 0}"
    $stdout.flush
    if (x < 1 && y > 0 || x > 1 && y < 0) then
      puts "checking if zero logx_y_f=#{logx_y_f} <= #{- prec * LOG10 - LOG2}"
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
      puts "x=#{x} y=#{y} prec=#{prec} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y} logx_y_f=#{logx_y_f}: checking x < 1 && y > 0 || x > 1 && y < 0=#{x < 1 && y > 0 || x > 1 && y < 0}"
      $stdout.flush
      if (x < 1 && y > 0 || x > 1 && y < 0) then
        puts "checking if zero logx_y_f=#{logx_y_f} <= #{- prec * LOG10 - LOG2}"
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
    puts "x0=#{x0} y0=#{y0}"
    while x0 > LongMath::MAX_FLOATABLE
      x0 = x0.move_point_left(100)
      point_shift += 100
    end
    iprec2 = 2 * (iprec + point_shift)
    iprec3 = [ iprec2, LongMath.prec_limit() - 24 ].min
    puts "x0=#{x0} y0=#{y0} point_shift=#{point_shift} iprec=#{iprec} iprec2=#{iprec2} iprec3=#{iprec3}"
    z0 = LongMath.ipower(x0, y0, iprec3, mode)
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
    prec = check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    puts "LongMath.ipower(x=#{x} y=#{y} prec=#{prec} mode=#{mode})"

    if (y.zero?)
      return 1
    elsif ! (x.kind_of? LongDecimalBase) || x.scale * y.abs <= prec
      puts "x=#{x} y=#{y} using **"
      return x ** y
    elsif (y < 0)
      l = Math.log10(x.abs.to_f)
      if (l > 0)
        prec += (2*l).ceil
      end
      # return (1/LongMath.ipower(x, -y, prec + 2, mode)).round_to_scale(prec, mode)
      xi = 1/x
      puts "x=#{x} y=#{y} prec=#{prec} using (1/x)**y xi=#{xi}"
      xr = xi.round_to_scale(prec + 6, mode)
      return LongMath.ipower(xr, -y, prec, mode)
    else
      # y > 0
      puts "x=#{x} y=#{y} regular"
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
        z *= x
        if (z.kind_of? LongDecimalBase)
          z = z.round_to_scale(prec+3, mode)
          if (z.zero?)
            break
          end
        end
      end
      puts "z=#{z} rounding prec=#{prec}"
      z = z.round_to_scale(prec, mode)
      puts "rounded -> z=#{z}"
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
    prec = check_is_prec(prec, "prec")
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
    prec = check_is_prec(prec, "prec")

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

  # logarithms of integers to base 2
  LOGARR = [ nil, \
           0.0, \
           1.0, \
           1.58496250072116, \
           2.0, \
           2.32192809488736, \
           2.58496250072116, \
           2.8073549220576, \
           3.0, \
           3.16992500144231, \
           3.32192809488736, \
           3.4594316186373, \
           3.58496250072116, \
           3.70043971814109, \
           3.8073549220576, \
           3.90689059560852, \
           4.0, \
           4.08746284125034, \
           4.16992500144231, \
           4.24792751344359, \
           4.32192809488736, \
           4.39231742277876, \
           4.4594316186373, \
           4.52356195605701, \
           4.58496250072116, \
           4.64385618977472, \
           4.70043971814109, \
           4.75488750216347, \
           4.8073549220576, \
           4.85798099512757, \
           4.90689059560852, \
           4.95419631038688, \
           5.0, \
           5.04439411935845, \
           5.08746284125034, \
           5.12928301694497, \
           5.16992500144231, \
           5.20945336562895, \
           5.24792751344359, \
           5.28540221886225, \
           5.32192809488736, \
           5.35755200461808, \
           5.39231742277876, \
           5.4262647547021, \
           5.4594316186373, \
           5.49185309632967, \
           5.52356195605701, \
           5.55458885167764, \
           5.58496250072116, \
           5.61470984411521, \
           5.64385618977472, \
           5.6724253419715, \
           5.70043971814109, \
           5.7279204545632, \
           5.75488750216347, \
           5.78135971352466, \
           5.8073549220576, \
           5.83289001416474, \
           5.85798099512757, \
           5.88264304936184, \
           5.90689059560852, \
           5.93073733756289, \
           5.95419631038688, \
           5.97727992349992, \
           6.0, \
           6.02236781302845, \
           6.04439411935845, \
           6.06608919045777, \
           6.08746284125034, \
           6.10852445677817, \
           6.12928301694497, \
           6.14974711950468, \
           6.16992500144231, \
           6.18982455888002, \
           6.20945336562895, \
           6.22881869049588, \
           6.24792751344359, \
           6.2667865406949, \
           6.28540221886225, \
           6.3037807481771, \
           6.32192809488736, \
           6.33985000288463, \
           6.35755200461808, \
           6.37503943134693, \
           6.39231742277876, \
           6.4093909361377, \
           6.4262647547021, \
           6.44294349584873, \
           6.4594316186373, \
           6.4757334309664, \
           6.49185309632967, \
           6.5077946401987, \
           6.52356195605701, \
           6.53915881110803, \
           6.55458885167764, \
           6.56985560833095, \
           6.58496250072116, \
           6.59991284218713, \
           6.61470984411521, \
           6.62935662007961, \
           6.64385618977473, \
           6.6582114827518, \
           6.6724253419715, \
           6.68650052718322, \
           6.70043971814109, \
           6.71424551766612, \
           6.7279204545632, \
           6.74146698640115, \
           6.75488750216347, \
           6.76818432477693, \
           6.78135971352466, \
           6.79441586635011, \
           6.8073549220576, \
           6.82017896241519, \
           6.83289001416474, \
           6.84549005094438, \
           6.85798099512757, \
           6.8703647195834, \
           6.88264304936184, \
           6.89481776330794, \
           6.90689059560852, \
           6.9188632372746, \
           6.93073733756289, \
           6.94251450533924, \
           6.95419631038688, \
           6.96578428466209, \
           6.97727992349992, \
           6.98868468677217, \
           7.0, \
           7.01122725542325, \
           7.02236781302845, \
           7.03342300153745, \
           7.04439411935845, \
           7.05528243550119, \
           7.06608919045777, \
           7.07681559705083, \
           7.08746284125034, \
           7.09803208296053, \
           7.10852445677817, \
           7.11894107272351, \
           7.12928301694497, \
           7.13955135239879, \
           7.14974711950468, \
           7.15987133677839, \
           7.16992500144231, \
           7.17990909001493, \
           7.18982455888002, \
           7.19967234483636, \
           7.20945336562895, \
           7.21916852046216, \
           7.22881869049588, \
           7.23840473932508, \
           7.24792751344359, \
           7.25738784269265, \
           7.2667865406949, \
           7.27612440527424, \
           7.28540221886225, \
           7.29462074889163, \
           7.3037807481771, \
           7.31288295528436, \
           7.32192809488736, \
           7.33091687811462, \
           7.33985000288462, \
           7.34872815423108, \
           7.35755200461808, \
           7.36632221424582, \
           7.37503943134693, \
           7.38370429247405, \
           7.39231742277876, \
           7.40087943628218, \
           7.4093909361377, \
           7.4178525148859, \
           7.4262647547021, \
           7.43462822763673, \
           7.44294349584873, \
           7.45121111183233, \
           7.4594316186373, \
           7.467605550083, \
           7.4757334309664, \
           7.48381577726426, \
           7.49185309632967, \
           7.49984588708321, \
           7.5077946401987, \
           7.51569983828404, \
           7.52356195605701, \
           7.53138146051631, \
           7.53915881110803, \
           7.54689445988764, \
           7.55458885167764, \
           7.56224242422107, \
           7.56985560833095, \
           7.57742882803575, \
           7.58496250072116, \
           7.59245703726808, \
           7.59991284218713, \
           7.60733031374961, \
           7.61470984411521, \
           7.62205181945638, \
           7.62935662007961, \
           7.63662462054365, \
           7.64385618977472, \
           7.65105169117893, \
           7.6582114827518, \
           7.66533591718518, \
           7.6724253419715, \
           7.67948009950545, \
           7.68650052718322, \
           7.69348695749933, \
           7.70043971814109, \
           7.70735913208088, \
           7.71424551766612, \
           7.72109918870719, \
           7.7279204545632, \
           7.73470962022584, \
           7.74146698640115, \
           7.74819284958946, \
           7.75488750216347, \
           7.76155123244448, \
           7.76818432477693, \
           7.77478705960117, \
           7.78135971352466, \
           7.78790255939143, \
           7.79441586635011, \
           7.8008998999203, \
           7.8073549220576, \
           7.81378119121704, \
           7.82017896241519, \
           7.82654848729092, \
           7.83289001416474, \
           7.83920378809694, \
           7.84549005094438, \
           7.85174904141606, \
           7.85798099512757, \
           7.86418614465428, \
           7.8703647195834, \
           7.876516946565, \
           7.88264304936184, \
           7.88874324889826, \
           7.89481776330794, \
           7.90086680798075, \
           7.90689059560852, \
           7.91288933622996, \
           7.9188632372746, \
           7.92481250360578, \
           7.93073733756289, \
           7.93663793900257, \
           7.94251450533924, \
           7.94836723158468, \
           7.95419631038688, \
           7.96000193206808, \
           7.96578428466209, \
           7.97154355395077, \
           7.97727992349992, \
           7.98299357469431, \
           7.98868468677217, \
           7.99435343685886, \
           8.0 ]

  def LongMath.log2int(x)
    unless x.kind_of? Integer
      raise TypeError, "x=#{x.inspect} must be Integer"
    end
    if (x <= 0)
      raise ArgumentError, "x=#{x} < 0"
    end
    
    s = x.size
    l = [ 8 * s - 36 , 0 ].max

    xx = x >> l
    while xx >= 256
      l += 1
      xx = xx >> 1
    end
    yy = LOGARR[xx]
    y = l + yy
    y
  end

  # alternative calculations of sqrt using newtons algorithm
  def LongMath.sqrtn(x)
    check_is_int(x, "x")
    s = (x <=> 0)
    if (s == 0) then
      return 0;
    elsif (s == -1)
      raise ArgumentError, "x=#{x} is negative"
    end

    y = 1
    while (true)
      q = x/y
      if (q == y)
        return y
      end
      yn = (y + q) >> 1
      if (yn == y || yn == q)
        ym = x/yn
        y = [ yn, ym ].min
        puts "x=#{x} ym=#{ym} yn=#{yn}" if (y != yn)
        return y

      end
      y = yn
    end
  end

  # geometric mean
  def LongMath.geometric_mean(new_scale, rounding_mode, *args)
    if (args.empty?)
      raise ArgumentError, "cannot calculate average of empty array"
    end
    prod = args.inject(1) do |pprod,x| 
      pprod * x
    end
    unless(prod.kind_of? LongDecimalBase)
      prod = prod.to_ld(new_scale * 3 + 6, rounding_mode)
    end
    result = LongMath.power(prod, Rational(1, args.size), new_scale, rounding_mode)
    return result
  end

  # harmonic mean
  def LongMath.harmonic_mean(new_scale, rounding_mode, *args)
    if (args.empty?)
      raise ArgumentError, "cannot calculate average of empty array"
    end
    sum = args.inject(0) do |psum, x| 
      psum + if (x.kindof? Integer)
               Rational(1, x)
             else
               1/x
             end
    end
    raw_result = args.size / sum
    result = raw_result.to_ld(new_scale, rounding_mode)
    return result
  end

  # quadratic & cubic means

end # LongMath

# to be removed again, but needed now to investigate problems with ./usr/lib/ruby/1.8/rational.rb:547: warning: in a**b, b may be too big
class Bignum

  # Returns a Rational number if the result is in fact rational (i.e. +other+ < 0).
  def rpower(other)
    if other >= 0
      self.power!(other)
    else
      r = Rational.new!(self, 1)
      raise TypeError, "other=#{other} must be integer" unless other.kind_of? Integer
      raise ArgumentError, "other=#{other} must not be too big" unless other.abs < LongMath::MAX_FLOATABLE
      r ** other
    end
  end

end

# end of file long-decimal-extra.rb
