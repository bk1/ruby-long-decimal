#
# long-decimal-extra.rb -- Arbitrary precision decimals with fixed decimal point
#
# additional features: all functionality in this file is experimental
# and can be removed without notice in future versions. Or moved to
# long-decimal.rb, if useful.
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2015
#
# TAG:       $TAG v1.00.04$
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

  private

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

  public

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

def LongMath.continued_fraction(x, steps)
  if (x == 0)
    x
  end
  arr = []
  steps.times do
    xi = x.to_ld(0, LongMath::ROUND_FLOOR)
    arr.push(xi.to_i)
    xd = x-xi
    if xd.zero?
      return arr
    end
    x = 1/xd
  end
  arr
end

def LongMath.continued_fraction_to_r(arr)
  result = nil
  arr.reverse.each do |x|
    if (result.nil?)
      result = Rational(x)
    else
      result = Rational(x) + 1/result
    end
  end
  result
end

# end of file long-decimal-extra.rb
