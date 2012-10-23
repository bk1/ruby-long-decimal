#
# longdecimal.rb -- Arbitrary precision decimals with fixed decimal point
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/longdecimal.rb,v 1.5 2006/02/16 20:34:19 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_01 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#
require "complex"
require "rational"

#
# add a functionality to find gcd with a high power of some number
# probably Integer is not the right place for this stuff, because it
# is quite special and should go to some kind of Math-like class in the
# future.
#
class Integer

  MAX_FLOATABLE = Float::MAX.to_i
  MIN_FLOATABLE = Float::MIN.to_i

  #
  # find the gcd of self with b^n0 where n0 is a sufficiently high
  # exponent such that gcd(self, b^m) = gcd(self, b^n)
  # for all m, n > n0
  #
  def gcd_with_high_power(b)
    raise ZeroDivisionError, "gcd_with_high_power of zero with \"#{b.inspect}\" would be infinity" if self.zero?
    raise TypeError, "gcd_with_high_power can only be calculated for integers \"#{b.inspect}\" is no integer" unless b.kind_of? Integer
    raise ZeroDivisionError, "gcd_with_high_power with b < 2 is not defined. b=\"#{b.inspect}\"" if b < 2
    s = self.abs
    exponent = 1
    b = b.abs
    if (b < s && s < MAX_FLOATABLE)
      exponent = (Math.log(s) / Math.log(b)).ceil
    end
    power    = b**exponent
    result   = 1
    begin
      f = s.gcd(power)
      s /= f
      result *= f
    end while f > 1
    result
  end

  #
  # find the exponent of the highest power of prime number p that divides
  # self.  Only works for prime numbers
  # @todo: needs some improvements, in order to work well for numbers
  #        that exceed the range of Float
  #
  def multiplicity_of_factor(prime_number)
    power = gcd_with_high_power(prime_number)
    result = (Math.log(power) / Math.log(prime_number)).round
  end
end

#
# add some functionality to Rational.
# probably Rational is not the right place for this stuff, because it
# is quite special and should go to some kind of Math-like class in the
# future.
#
class Rational

  #
  # find the exponent of the highest power of b that divides
  # self.  Count negative, if it divides the denominator
  # Only works for prime numbers
  # @todo: needs some improvements, in order to work well for numbers
  #        that exceed the range of Float
  #
  def multiplicity_of_factor(prime_number)
    m1 = numerator.multiplicity_of_factor(prime_number)
    m2 = denominator.multiplicity_of_factor(prime_number)
    m1 - m2
  end
end

#
# define rounding modes to be used for LongDecimal
# this serves the purpose of an "enum" in C/C++
#
module LongDecimalRoundingMode
  RoundingModeClass = Struct.new(:name, :num)
  class RoundingModeClass
    include Comparable

    #
    # introduce some ordering for rounding modes
    #
    def <=>(o)
      if o.respond_to?:num
        self.num <=> o.num
      else
        self.num <=> o
      end
    end
  end

  # rounding modes as constants
  #
  ROUND_UP          = RoundingModeClass.new(:ROUND_UP, 0)
  ROUND_DOWN        = RoundingModeClass.new(:ROUND_DOWN, 1)
  ROUND_CEILING     = RoundingModeClass.new(:ROUND_CEILING, 2)
  ROUND_FLOOR       = RoundingModeClass.new(:ROUND_FLOOR, 3)
  ROUND_HALF_UP     = RoundingModeClass.new(:ROUND_HALF_UP, 4)
  ROUND_HALF_DOWN   = RoundingModeClass.new(:ROUND_HALF_DOWN, 5)
  ROUND_HALF_EVEN   = RoundingModeClass.new(:ROUND_HALF_EVEN, 6)
  ROUND_UNNECESSARY = RoundingModeClass.new(:ROUND_UNNECESSARY, 7)

end

#
# class for holding fixed point long decimal numbers
#
class LongDecimal < Numeric
  @RCS_ID='-$Id: longdecimal.rb,v 1.5 2006/02/16 20:34:19 bk1 Exp $-'

  include LongDecimalRoundingMode

#  MINUS_ONE = LongDecimal(-1)
#  ZERO      = LongDecimal(0)
#  ONE       = LongDecimal(1)
#  TWO       = LongDecimal(2)
#  TEN       = LongDecimal(10)

  #
  # initialization
  # parameters:
  # 1. LongDecimal.new!(x) where x is a string or a number
  #    the resulting LongDecimal holds the number x, possibly rounded
  # 2. LongDecimal.new!(x, s) where x is a string or a number and s is the scale
  #    the resulting LongDecimal holds the number x / 10**s
  def LongDecimal.new!(x, s = 0)
    new(x, s)
  end

  #
  # initialization
  # parameters:
  # LongDecimal.new(x, s) where x is a string or a number and s is the scale
  # the resulting LongDecimal holds the number x / 10**s
  #
  def initialize(x, s)

    # handle some obvious errors with x first
    raise TypeError, "non numeric 1st arg \"#{x.inspect}\"" if ! (x.kind_of? Numeric) && ! (x.kind_of? String)
    # we could maybe even work with complex number, if their imaginary part is zero.
    # but this is not so important to deal with, so we raise an error anyway.
    raise TypeError, "complex numbers not supported \"#{x.inspect}\"" if x.kind_of? Complex

    # handle some obvious errors with optional second parameter, if present
    raise TypeError, "non integer 2nd arg \"#{s.inspect}\"" if ! s.kind_of? Integer
    raise TypeError, "negative 2nd arg \"#{s.inspect}\""    if s < 0

    # scale is the second parameter or 0 if it is missing
    scale   = s
    # int_val is the integral value that is multiplied by some 10**-n
    int_val = 0

    if x.kind_of? Integer then
      # integers are trivial to handle
      int_val = x

    elsif x.kind_of? Rational then
      # rationals are rounded somehow
      # we need to come up with a better rule here.
      # if denominator is any product of powers of 2 and 5, we do not need to round
      denom = x.denominator
      mul_2 = denom.multiplicity_of_factor(2)
      mul_5 = denom.multiplicity_of_factor(5)
      iscale = [mul_2, mul_5].max
      scale += iscale
      denom /= 2 ** mul_2
      denom /= 5 ** mul_5
      iscale2 = Math.log10(denom).ceil
      scale += iscale2
      # int_val = (x * 10 ** scale).to_i
      int_val = (x * 10 ** (iscale2+iscale)).to_i

    else
      # we assume a string or a floating point number
      # floating point number is converted to string, so we only deal with strings
      num_str  = x.to_s
      len      = num_str.length

      # handle the obvious error that string is empty
      raise TypeError, "1st arg must not be empty string. \"#{num_str.inspect}\"" if len == 0

      # remove spaces and underscores
      num_str.gsub! /\s/, ""
      num_str.gsub! /_/, ""

      # handle sign
      num_str.gsub! /^\+/, ""
      negative = false
      if num_str.gsub! /^-/, "" then
        negative = true
      end

      # split in parts before and after decimal point
      num_arr = num_str.split /\./
      if num_arr.length > 2 then
        raise TypeError, "1st arg contains more than one . \"#{num_str.inspect}\""
      end
      num_int  = num_arr[0]
      num_rem  = num_arr[1]
      num_frac = nil
      num_exp  = nil
      unless num_rem.nil? then
        num_arr  = num_rem.split /[Ee]/
        num_frac = num_arr[0]
        num_exp  = num_arr[1]
      end

      if num_frac.nil? then
        num_frac = ""
      end

      if num_exp.nil? || num_exp.empty? then
        num_exp = "0"
      end
      num_exp = num_exp.to_i
      iscale  = num_frac.length - num_exp
      scale  += iscale
      int_val  = (num_int + num_frac).to_i
      if negative then
        int_val = -int_val
      end
    end
    @scale  = scale
    @int_val = int_val

  end # initialize

  def int_val
    @int_val
  end

  def scale
    @scale
  end

  # alter scale
  # only for internal use.
  # changes self
  #
  def scale=(s)
    raise TypeError, "non integer arg \"#{s.inspect}\"" if ! s.kind_of? Integer
    raise TypeError, "negative arg \"#{s.inspect}\""    if s < 0

    # do not work too hard, if scale does not really change.
    unless @scale == s then
      # multiply int_val by a power of 10 in order to compensate for
      # the change of scale and to keep number in the same order of magnitude.
      d = s - @scale
      f = 10 ** (d.abs)
      if (d >= 0) then
	@int_val = (@int_val * f).to_i
      else 
	# here we actually do rounding
	@int_val = (@int_val / f).to_i
      end
      @scale   = s
    end
  end

  protected :scale=

  # 
  # create copy of self with different scale
  # param1: new_scale  new scale for result
  # param2: mode       rounding mode to be applied when information is lost
  #
  def round_to_scale(new_scale, mode = ROUND_UNNECESSARY)

    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.kind_of? RoundingModeClass
    if @scale == new_scale then
      self
    else
      diff   = new_scale - scale
      factor = 10 ** (diff.abs)
      if (diff > 0) then
        # we become more precise, no rounding issues
        new_int_val = int_val * factor
      else
        quot, rem = int_val.divmod(factor)
        if (rem == 0) then
          new_int_val = quot
        elsif (mode == ROUND_UNNECESSARY) then
          raise ArgumentError, "mode ROUND_UNNECESSARY not applicable, remainder #{rem.to_s} is not zero"
        else
          return LongDecimalQuot(self, LongDecimal(1)).round_to_scale(new_scale, mode)
        end
      end
      LongDecimal(new_int_val, new_scale)
    end
  end

  # convert into String
  def to_s
    str = @int_val.to_s
    if @scale > 0 then
      missing = @scale - str.length + 1
      if missing > 0 then
        str = ("0" * missing) + str
      end
      str[-@scale, 0] = "."
    end
    str
  end

  # convert into Rational
  def to_r
    Rational(@int_val, 10**@scale)
  end

  # convert into Float
  def to_f
    to_r.to_f
  end

  # convert into Integer
  def to_i
    to_r.to_i
  end

  # convert into LongDecimal (returns self)
  def to_ld
    self
  end

  #
  # before adding or subtracting two LongDecimal numbers
  # it is mandatory to set them to the same scale.  The maximum of the
  # two summands is used, in order to avoid loosing any information.
  #
  def equalize_scale(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimal) then
      new_scale = [s.scale, o.scale].max
      s = s.round_to_scale(new_scale)
      o = o.round_to_scale(new_scale)
    end
    return s, o
  end

  #
  # before dividing two LongDecimal numbers, it is mandatory to set
  # make them both to integers, so the result is simply expressable as
  # a rational
  #
  def anti_equalize_scale(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimal) then
      exponent = [s.scale, o.scale].max
      factor   = 10**exponent
      s *= factor
      o *= factor
      s.round_to_scale(0)
      o.round_to_scale(0)
    end
    return s, o
  end

  def +@
    self
  end

  def -@
    if self.zero? then
      self
    else
      LongDecimal(-int_val, scale)
    end
  end

  def +(other)
    s, o = equalize_scale(other)
    p "adding #{s.inspect} + #{o.inspect}"
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val + o.int_val, s.scale)
    else
      s + o
    end
  end

  def -(other)
    s, o = equalize_scale(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val - o.int_val, s.scale)
    else
      s + o
    end
  end

  def *(other)
    o, s = coerce(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val * o.int_val, s.scale + o.scale)
    else
      s * o
    end
  end

  def divide(other, rounding_mode)
    q = self / other
    q.round_to_scale(q.scale, rounding_mode)
  end

  def divide_s(other, new_scale, rounding_mode)
    q = self / other
    q.round_to_scale(new_scale, rounding_mode)
  end

  def /(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimal) then
      LongDecimalQuot(s, o)
    else
      s / o
    end
  end

  def **(other)
    if other.kind_of? Integer then
      if other >= 0 then
	LongDecimal(int_val ** other, scale * other)
      else
	abs_other = -other
	new_scale = abs_other * scale
	LongDecimalQuot(Rational(10 ** new_scale, int_val ** abs_other), new_scale)
      end
    else
      self.to_f ** other
    end
  end

  def divmod(other)
    q = (self / other).to_i
    return q, self - other * q
  end

  def %(other)
    q, r = divmod other
    r
  end

  # def movePointLeft(n)
  # def movePointRight(n)

  def square
    self * self
  end

  #
  # Absolute value
  #
  def abs
    LongDecimal(int_val.abs, scale)
  end

  def abs2
    self.abs.square
  end

  #
  # Compares the absolute values of the two numbers.
  #
  def <=> (other)
    (self - other).sgn
  end

  def coerce(other)
    if other.kind_of? LongDecimal then
      return other, self
    elsif other.kind_of? LongDecimalQuot then
      return other, LongDecimalQuot(self.to_r, scale)
    elsif other.kind_of? Rational then
      s = scale
      return LongDecimalQuot(other, s), LongDecimalQuot(self.to_r, s)
    elsif (other.kind_of? Integer) || (other.kind_of? Float) then
      other = LongDecimal(other)
      return other.round_to_scale(scale, ROUND_HALF_UP), self
    elsif other.kind_of? Numeric then
      s, o = other.coerce(self.to_f)
      return o, s
    else
      raise TypeError, "unsupported type #{other.inspect} for coerce of LongDecimal"
    end
  end

  def sgn
    int_val <=> 0
  end
  alias signum sgn
  alias sign   sgn

  def ==(other)
    (self <=> other) == 0 && self.scale == other.scale
  end

  #
  # Returns a hash code for the complex number.
  #
  def hash
    int_val.hash ^ scale.hash
  end

  #
  # Returns "<tt>LongDecimal(<i>int_val</i>, <i>scale</i>)</tt>".
  #
  def inspect
    sprintf("LongDecimal(%s, %s)", int_val.inspect, scale.inspect)
  end


end

#
# This class is used for storing intermediate results after having
# performed a division.  The division cannot be completed without
# providing additional information on how to round the result.
#
class LongDecimalQuot < Rational

  @RCS_ID='-$Id: longdecimal.rb,v 1.5 2006/02/16 20:34:19 bk1 Exp $-'

  include LongDecimalRoundingMode

  def LongDecimalQuot.new!(first, second)
    new(first, second)
  end

  #
  # create a new LongDecimalQuot from a rational and a scale or a
  # pair of LongDecimals
  def initialize(first, second)
    if (first.kind_of? Rational) && (second.kind_of? Integer) then
      super(first.numerator, first.denominator)
      @scale = second
    elsif (first.kind_of? LongDecimal) && (second.kind_of? LongDecimal) then
      orig_scale = first.scale
      first, second = first.anti_equalize_scale(second)
      super(first.to_i, second.to_i)
      @scale = orig_scale
    else
      raise TypeError, "parameters must be (LongDecimal, LongDecimal) or (Rational, Integer): first=#{first.inspect} second=#{second.inspect}";
    end
  end


  def scale
    @scale
  end

  # alter scale
  def scale=(s)
    raise TypeError, "non integer arg \"#{s.inspect}\"" if ! s.kind_of? Integer
    raise TypeError, "negative arg \"#{s.inspect}\""    if s < 0
    @scale = s
  end

  private :scale=

  def to_s
    str = super
    str + "[" + scale.to_s + "]"
  end

  def to_r
    Rational(numerator, denominator)
  end

  def to_ld
    LongDecimal(self, scale)
  end

  def +@
    self
  end

  def -@
    if self.zero? then
      self
    else
      LongDecimalQuot(super, scale)
    end
  end

  def +(other)
    o, s = coerce(other)
    p "adding #{s.inspect} + #{o.inspect}"
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(super(other), scale)
    else
      s + o
    end
  end

  def -(other)
    o, s = coerce(other)
    LongDecimalQuot(super(other), scale)
  end

  def *(other)
    o, s = coerce(other)
    LongDecimalQuot(super(other), scale)
  end

  def /(other)
    o, s = coerce(other)
    LongDecimalQuot(super(other), scale)
  end

  def **(other)
    rat = super(other)
    if (rat.kind_of? Rational) then
      LongDecimalQuot(rat, scale)
    else
      rat
    end
  end

  def %(other)
    o, s = coerce(other)
    LongDecimalQuot(super(other), scale)
  end

  def square
    self * self
  end

  #
  # Absolute value
  #
  def abs
    LongDecimalQuot(super, scale)
  end

  def abs2
    self.abs.square
  end

  def round_to_scale(new_scale = @scale, mode = ROUND_UNNECESSARY)

    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.kind_of? RoundingModeClass

    factor    = 10**new_scale
    sign_quot = numerator <=> 0
    if sign_quot == 0 then
      return LongDecimal(0, new_scale)
    end
    prod      = numerator * factor
    divisor   = denominator
    quot, rem = prod.divmod(divisor)
    sign_rem  = rem  <=> 0
    # puts("self=#{self.to_s} f=#{factor} prod=#{prod} divisor=#{divisor} quot=#{quot} rem=#{rem} sign_rem=#{sign_rem.to_s} sign_quot=#{sign_quot.to_s}")
    if (sign_rem == 0)
      return LongDecimal(quot, new_scale)
    end
    raise Error, "signs do not match self=#{self.to_s} f=#{factor} prod=#{prod} divisor=#{divisor} quot=#{quot} rem=#{rem}" if sign_rem <= 0
    if (sign_quot < 0) then
      rem -= divisor
      quot += 1
      sign_rem = rem <=> 0
      raise Error, "signs do not match self=#{self.to_s} f=#{factor} prod=#{prod} divisor=#{divisor} quot=#{quot} rem=#{rem}" if sign_rem >= 0
    end
    # puts("self=#{self.to_s} f=#{factor} prod=#{prod} divisor=#{divisor} quot=#{quot} rem=#{rem} sign_rem=#{sign_rem.to_s} sign_quot=#{sign_quot.to_s}")

    if mode == ROUND_UNNECESSARY then
      raise ArgumentError, "mode ROUND_UNNECESSARY not applicable, remainder #{rem.to_s} is not zero"
    end

    if (mode == ROUND_CEILING)
      mode = (sign_quot > 0) ? ROUND_UP : ROUND_DOWN
    elsif (mode == ROUND_FLOOR)
      mode = (sign_quot < 0) ? ROUND_UP : ROUND_DOWN
    else
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
      quot += sign_quot
    end
    new_int_val = quot
    LongDecimal(new_int_val, new_scale)
  end

  def coerce(other)
    if other.kind_of? LongDecimal then
      return LongDecimalQuot(other.to_r, other.scale), self
    elsif other.kind_of? LongDecimalQuot then
      return other, self
    elsif other.kind_of? Rational then
      s = scale
      return LongDecimalQuot(other, s), self
    elsif (other.kind_of? Integer) || (other.kind_of? Float) then
      return LongDecimalQuot(other.to_r, scale), self
    elsif other.kind_of? Numeric then
      s, o = other.coerce(self.to_f)
      return o, s
    else
      raise TypeError, "unsupported type #{other.inspect} for coerce of LongDecimalQuot"
    end
  end

  def ==(other)
    (self <=> other) == 0 && self.scale == other.scale
  end

  #
  # Returns a hash code for the complex number.
  #
  def hash
    super ^ scale.hash
  end


  def scale
    @scale
  end


  #
  # Returns "<tt>LongDecimalQuot(<i>int_val</i>, <i>scale</i>, <i>num</i>, <i>denom</i>)</tt>".
  #
  def inspect
    sprintf("LongDecimalQuot(%s, %s, %s)", numerator.inspect, denominator.inspect, scale.inspect)
  end

end

#
# Creates a LongDecimal number.  +a+ and +b+ should be Numeric.
#
def LongDecimal(a, b = 0)
  if b == 0 && (a.kind_of? LongDecimal) then
    a
  else
    LongDecimal.new!(a, b)
  end
end

def LongDecimalQuot(first, second)
  LongDecimalQuot.new!(first, second)
end

class Numeric

  def to_ld
    LongDecimal(self)
  end

end

# end
