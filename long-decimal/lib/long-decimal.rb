#
# long-decimal.rb -- Arbitrary precision decimals with fixed decimal point
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/lib/long-decimal.rb,v 1.6 2006/03/20 21:38:32 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_15 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#
require "complex"
require "rational"
require "bigdecimal"

# require "bigdecimal/math"

#
# define rounding modes to be used for LongDecimal
# this serves the purpose of an "enum" in C/C++
#
module LongDecimalRoundingMode

  RoundingModeClass = Struct.new(:name, :num)

  #
  # enumeration class to express the possible rounding modes that are
  # supported by LongDecimal
  #
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

  #
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

end # LongDecimalRoundingMode

#
# class for holding fixed point long decimal numbers
# these can be considered as a pair of two integer.  One contains the
# digits and the other one the position of the decimal point.
#
class LongDecimal < Numeric
  @RCS_ID='-$Id: long-decimal.rb,v 1.6 2006/03/20 21:38:32 bk1 Exp $-'

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
  #
  def LongDecimal.new!(x, s = 0)
    new(x, s)
  end

  #
  # creates a LongDecimal representing zero with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.zero!(s = 0)
    new(0, s)
  end


  #
  # creates a LongDecimal representing one with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.one!(s = 0)
    new(10**s, s)
  end


  #
  # creates a LongDecimal representing two with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.two!(s = 0)
    new(2*10**s, s)
  end


  #
  # creates a LongDecimal representing ten with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.ten!(s = 0)
    new(10**(s+1), s)
  end


  #
  # creates a LongDecimal representing minus one with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.minus_one!(s = 0)
    new(-1*10**s, s)
  end


  #
  # creates a LongDecimal representing a power of ten with the given
  # exponent e and with the given number of digits after the decimal
  # point (scale=s)
  #
  def LongDecimal.power_of_ten!(e, s = 0)
    LongMath.check_is_int(e, "e")
    raise TypeError, "negative 1st arg \"#{e.inspect}\""    if e < 0
    new(10**(s+e), s)
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
      mul_2 = LongMath.multiplicity_of_factor(denom, 2)
      mul_5 = LongMath.multiplicity_of_factor(denom, 5)
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
      # floating point number or BigDecimal is converted to string, so
      # we only deal with strings
      # this operation is not so common, so there is no urgent need to
      # optimize it
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

  attr_reader :int_val, :scale

  #
  # alter scale (changes self)
  #
  # only for internal use:
  # use round_to_scale instead
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
  # param2: mode       rounding mode to be applied when information is
  #                    lost.   defaults  to  ROUND_UNNECESSARY,  which
  #                    means that  an exception is  thrown if rounding
  #                    would actually loose any information.
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

  #
  # convert self into String, which is the decimal representation.
  # Use trailing zeros, if int_val has them.

  # optional parameter shown_scale is the number of digits after the
  # decimal point.  Defaults to the scale of self.
  # optional parameter mode ist the rounding mode to be applied.
  # Defaults to ROUND_UNNECESSARY, in which case an exception is
  # thrown if rounding is actually necessary.
  # optional parameter base is the base to be used when expressing
  # self as string.  defaults to 10.
  #
  def to_s(shown_scale = @scale, mode = ROUND_UNNECESSARY, base = 10)
    if (base == 10) then
      if (shown_scale == @scale)
        to_s_10
      else
        s = self.round_to_scale(shown_scale, mode)
        s.to_s_10
      end
    else
      # base is not 10
      unless (base.kind_of? Integer) && 2 <= base && base <= 36 then
        raise TypeError, "base must be integer between 2 and 36"
      end
      quot    = (self.move_point_right(scale) * base ** shown_scale) / 10 ** scale
      # p(quot)
      rounded = quot.round_to_scale(0, mode)
      # p(rounded)
      rounded.to_s_internal(base, shown_scale)
    end
  end

  #
  # internal helper method, converts self to string in decimal system
  # with default settings.
  #
  def to_s_10
    to_s_internal(10, scale)
  end

  #
  # internal helper method, converts self to string in any number system
  #
  def to_s_internal(b, sc)
    sg = sgn
    i = int_val.abs
    str = i.to_s(b)
    if sc > 0 then
      missing = sc - str.length + 1
      if missing > 0 then
        str = ("0" * missing) + str
      end
      str[-sc, 0] = "."
    end
    str = "-" + str if sg < 0
    str
  end

  protected :to_s_10
  protected :to_s_internal

  #
  # convert self into Rational
  # this works quite straitforward.  use int_val as numerator and a
  # power of 10 as denominator
  #
  def to_r
    Rational(numerator, denominator)
  end

  #
  # convert self into Float
  # this works straitforward by dividing int_val by power of 10 in
  # float-arithmetic, in all cases where numerator and denominator are
  # within the ranges expressable as Floats.  Goes via string
  # representation otherwise.
  #
  def to_f
    divisor = denominator
    if (divisor == 1) then
      return numerator.to_f
    elsif int_val.abs <= LongMath::MAX_FLOATABLE then
      if (divisor.abs > LongMath::MAX_FLOATABLE) then
        return 0.0
      else
        f = int_val.to_f
        return f / divisor
      end
    elsif numerator.abs < divisor
      # self is between -1 and 1
      # factor = numerator.abs.div(LongMath::MAX_FLOATABLE)
      # digits = factor.to_ld.int_digits10
      # return LongDecimal(numerator.div(10**digits), scale -digits).to_f
      return self.to_s.to_f
    else
      # s2 = [scale.div(2), 1].max
      # return LongDecimal(numerator.div(10**s2), scale - s2).to_f
      return self.to_s.to_f
    end
  end

  #
  # convert self into Integer
  # This may loose information.  In most cases it is preferred to
  # control this by calling round_to_scale first and then applying
  # to_i when the number represented by self is actually an integer.
  #
  def to_i
    numerator.div(denominator)
  end

  #
  # convert self into LongDecimal (returns self)
  #
  def to_ld
    self
  end

  #
  # convert selt into BigDecimal
  #
  def to_bd
    # this operation is probably not used so heavily, so we can live with a
    # string as an intermediate step.
    BigDecimal(self.to_s)
  end

  #
  # LongDecimals can be seen as a fraction with a power of 10 as
  # denominator for compatibility with other numeric classes this
  # method is included, returning 10**scale.
  # Please observe that there may be common factors of numerator and
  # denominator in case of LongDecimal, which does not occur in case
  # of Rational
  #
  def denominator
    10**scale
  end

  #
  # LongDecimals can be seen as a fraction with its int_val as its
  # numerator
  # Please observe that there may be common factors of numerator and
  # denominator in case of LongDecimal, which does not occur in case
  # of Rational
  #
  alias numerator int_val

  #
  # number of binary digits before the decimal point, not counting a single 0.
  # 0.xxx -> 0
  # 1.xxx -> 1
  # 2.xxx -> 2
  # 4.xxx -> 3
  # 8.xxx -> 4
  # ...
  #
  def int_digits2
    int_part = self.abs.to_i
    if int_part.zero? then
      return 0
    end

    n = int_part.size * 8 - 31
    int_part = int_part >> n
    until int_part.zero? do
      int_part = int_part >> 1
      n += 1
    end
    n
  end

  #
  # number of decimal digits before the decimal point, not counting a
  # single 0.
  # 0.xxx -> 0
  # 1.xxx -> 1
  # 10.xxx -> 2
  # ...
  #
  def int_digits10
    int_part = self.abs.to_i
    if int_part.zero? then
      return 0
    end

    id = 1
    powers = []
    power  = 10
    idx    = 0
    until int_part.zero? do
      expon       = 1 << idx
      powers[idx] = power
      break if int_part < power
      id += expon
      int_part = (int_part / power).to_i
      idx += 1
      power = power * power
    end
    until int_part < 10 do
      idx -= 1
      expon = 1 << idx
      power = powers[idx]
      # puts("i=#{int_part} p=#{power}\n")
      while int_part >= power
        id += expon
        int_part = (int_part / power).to_i
      end
    end
    id
  end

  #
  # before adding or subtracting two LongDecimal numbers
  # it is mandatory to set them to the same scale.  The maximum of the
  # two summands is used, in order to avoid loosing any information.
  # this method is mostly for internal use
  #
  def equalize_scale(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimal) then
      # make sure Floats do not mess up our number of significant digits when adding
      if (other.kind_of? Float) then
        o = o.round_to_scale(s.scale, ROUND_HALF_UP)
      else
        new_scale = [s.scale, o.scale].max
        s = s.round_to_scale(new_scale)
        o = o.round_to_scale(new_scale)
      end
    end
    return s, o
  end

  #
  # before dividing two LongDecimal numbers, it is mandatory to set
  # make them both to integers, so the result is simply expressable as
  # a rational
  # this method is mostly for internal use
  #
  def anti_equalize_scale(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimal) then
      exponent = [s.scale, o.scale].max
      factor   = 10**exponent
      s *= factor
      o *= factor
      s = s.round_to_scale(0)
      o = o.round_to_scale(0)
    end
    return s, o
  end

  #
  # successor as needed for using LongDecimal in ranges
  # it needs to be observed that this is usually not an increment by
  # 1, but by 1/10**scale.
  #
  def succ
    LongDecimal(int_val + 1, scale)
  end

  alias next succ

  #
  # predecessor (opposite of successor)
  # it needs to be observed that this is usually not an decrement by
  # 1, but by 1/10**scale.
  #
  def pred
    LongDecimal(int_val - 1, scale)
  end

  #
  # self + 1
  #
  def inc
    self + 1
  end

  #
  # self - 1
  #
  def dec
    self - 1
  end

  #
  # self += 1
  #
  def inc!
    @int_val += denominator
  end

  #
  # self -= 1
  #
  def dec!
    @int_val -= denominator
  end

  #
  # return the unit by which self is incremented by succ
  #
  def unit
    LongDecimal(1, scale)
  end

  #
  # apply unary +
  # (returns self)
  #
  def +@
    self
  end

  #
  # apply unary -
  # (returns negated self)
  #
  def -@
    if self.zero? then
      self
    else
      LongDecimal(-int_val, scale)
    end
  end

  #
  # add two numbers
  # if both can immediately be expressed as LongDecimal, the result is
  # a LongDecimal as well.  The number of digits after the decimal
  # point is the max of the scales of the summands
  # if LongDecimal does not cover the two summands, call addition of
  # Complex, Float or LongRationalQuot
  #
  def +(other)
    s, o = equalize_scale(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val + o.int_val, s.scale)
    else
      s + o
    end
  end

  #
  # subtract two numbers
  # if both can immediately be expressed as LongDecimal, the result is
  # a LongDecimal as well.  The number of digits after the decimal
  # point is the max of the scales of self and other.
  # if LongDecimal does not cover self and other, the subtraction of
  # Complex, Float or LongRationalQuot is used
  #
  def -(other)
    s, o = equalize_scale(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val - o.int_val, s.scale)
    else
      s - o
    end
  end

  #
  # multiply two numbers
  # if both can immediately be expressed as LongDecimal, the result is
  # a LongDecimal as well.  The number of digits after the decimal
  # point is the sum of the scales of both factors.
  # if LongDecimal does not cover self and other, the multiplication of
  # Complex, Float or LongRationalQuot is used
  #
  def *(other)
    o, s = coerce(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val * o.int_val, s.scale + o.scale)
    else
      s * o
    end
  end

  #
  # divide self by other and round result to scale of self using the
  # given rounding mode
  #
  def divide(other, rounding_mode)
    divide_s(other, nil, rounding_mode)
  end

  #
  # divide self by other and round result to new_scale using the
  # given rounding mode.  If new_scale is nil, use scale of self.
  #
  def divide_s(other, new_scale, rounding_mode)
    q = self / other
    if (q.kind_of? Float) then
      q = LongDecimal(q)
    end
    if (q.kind_of? LongDecimal) || (q.kind_of? LongDecimalQuot) then
      if (new_scale.nil?) then
        new_scale = q.scale
      end
      q.round_to_scale(new_scale, rounding_mode)
    else
      q
    end
  end

  #
  # divide self by other and return result as Rational, if other
  # allowed exact calculations.
  #
  def rdiv(other)
    q = self / other
    if (q.kind_of? LongDecimalQuot) then
      q.to_r
    else
      q
    end
  end

  #
  # divide self by other and return result as LongDecimalQuot
  # because division does not have an obvious rounding rule like
  # addition, subtraction and multiplication, the result needs to be
  # rounded afterwards to become a LongDecimal again.  This way
  # calculations can still be done in the natural readable way using +,
  # -, *, and /, but the rounding can be provided later.
  # It is very important in complicated calculations put the rounding
  # steps in the right places, usually after having performed a division.
  #
  def /(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimal) then
      LongDecimalQuot(s, o)
    else
      s / o
    end
  end

  #
  # power of self (LongDecimal) with other.
  # if other is expressable as non-negative integer, the power is what
  # would be obtained by successive multiplications.
  # if other is expressable as negative integer, the power is a
  # LongDecimalQuot as would result by successive division, but with
  # the same scale as the positive power would get.  Explicit rounding
  # is needed to convert into a LongDecimal again
  # in all other cases, self is converted into a Rational prior to
  # applying power, usually resulting in a Float as power.
  #
  def **(other)
    if ((other.kind_of? LongDecimal) || (other.kind_of? LongDecimalQuot)) && other.is_int? then
      other = other.to_i
    end
    if other.kind_of? Integer then
      if other >= 0 then
        LongDecimal(int_val ** other, scale * other)
      else
        abs_other = -other
        new_scale = abs_other * scale
        LongDecimalQuot(Rational(10 ** new_scale, int_val ** abs_other), new_scale)
      end
    else
      if (other.kind_of? LongDecimal) || (other.kind_of? LongDecimalQuot) then
        other = other.to_r
      end
      self.to_r ** other
    end
  end

  #
  # do integer division with remainder, returning two values
  #
  def divmod(other)
    if (other.kind_of? Complex) then
      raise TypeError, "divmod not supported for Complex"
    end
    q = (self / other).to_i
    return q, self - other * q
  end

  #
  # remainder of integer division by other
  #
  def %(other)
    q, r = divmod other
    r
  end

  #
  # performs bitwise AND between self and other
  #
  def &(other)
    s, o = equalize_scale(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val & o.int_val, s.scale)
    else
      s & o
    end
  end

  #
  # performs bitwise OR between self and other
  #
  def |(other)
    s, o = equalize_scale(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val | o.int_val, s.scale)
    else
      s | o
    end
  end

  #
  # performs bitwise XOR between self and other
  #
  def ^(other)
    s, o = equalize_scale(other)
    if s.kind_of? LongDecimal then
      LongDecimal(s.int_val ^ o.int_val, s.scale)
    else
      s ^ o
    end
  end

  #
  # bitwise inversion
  #
  def ~
    LongDecimal(~int_val, scale)
  end

  #
  # performs bitwise left shift of self by other
  #
  def <<(other)
    unless (other.kind_of? Fixnum) && other >= 0 then
      raise TypeError, "cannot shift by something other than Fixnum >= 0"
    end
    LongDecimal(int_val << other, scale)
  end

  #
  # performs bitwise right shift of self by other
  #
  def >>(other)
    unless (other.kind_of? Fixnum) && other >= 0 then
      raise TypeError, "cannot shift by something other than Fixnum >= 0"
    end
    LongDecimal(int_val >> other, scale)
  end

  #
  # gets binary digit of self
  #
  def [](other)
    int_val[other]
  end

  #
  # gets size of int_val
  #
  def size
    int_val.size
  end

  #
  # divide by 10**n
  #
  def move_point_left(n)
    raise TypeError, "only implemented for Fixnum" unless n.kind_of? Fixnum
    if (n >= 0) then
      move_point_left_int(n)
    else
      move_point_right_int(-n)
    end
  end

  #
  # multiply by 10**n
  #
  def move_point_right(n)
    raise TypeError, "only implemented for Fixnum" unless n.kind_of? Fixnum
    if (n < 0) then
      move_point_left_int(-n)
    else
      move_point_right_int(n)
    end
  end

  #
  # internal method
  # divide by 10**n
  #
  def move_point_left_int(n)
    raise TypeError, "only implemented for Fixnum >= 0" unless n >= 0
    LongDecimal(int_val, scale + n)
  end

  #
  # internal method
  # multiply by 10**n
  #
  def move_point_right_int(n)
    raise TypeError, "only implemented for Fixnum >= 0" unless n >= 0
    if (n > scale) then
      LongDecimal(int_val * 10**(n-scale), 0)
    else
      LongDecimal(int_val, scale-n)
    end
  end

  protected :move_point_left_int, :move_point_right_int

  #
  # calculate the square of self
  #
  def square
    self * self
  end

  #
  # calculate the sqrt of self
  # provide the result with given number
  # new_scale of digits after the decimal point
  # use rounding_mode if the result is not exact
  #
  def sqrt(new_scale, rounding_mode)
    sqrt_internal(new_scale, rounding_mode, false)
  end

  #
  # calculate the sqrt s of self and remainder r >= 0
  # such that s*s+r = self and (s+1)*(s+1) > self
  # provide the result with given number
  # new_scale of digits after the decimal point
  #
  def sqrt_with_remainder(new_scale)
    sqrt_internal(new_scale, ROUND_DOWN, true)
  end


  #
  # internal helper method for calculationg sqrt and sqrt_with_remainder
  #
  def sqrt_internal(new_scale, rounding_mode, with_rem)
    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless rounding_mode.kind_of? RoundingModeClass

    new_scale1 = new_scale
    unless (with_rem) then
      new_scale1 += 1
    end
    old_scale  = (new_scale1 << 1)
    x = round_to_scale(old_scale, rounding_mode)
    root, rem = LongMath.sqrtw_with_remainder(x.int_val)
    y = LongDecimal(root, new_scale1)
    if (with_rem) then
      r = LongDecimal(rem, old_scale)
      return [ y, r ]
    else
      if ((rounding_mode == ROUND_HALF_EVEN || rounding_mode == ROUND_HALF_DOWN) && rem > 0) then
	rounding_mode = ROUND_HALF_UP
      end
      y = y.round_to_scale(new_scale, rounding_mode)
      return y
    end
  end

  private :sqrt_internal

  #
  # calculate the multiplicative inverse
  #
  def reciprocal
    1 / self
  end

  alias inverse reciprocal

  #
  # Absolute value
  #
  def abs
    LongDecimal(int_val.abs, scale)
  end

  #
  # square of absolute value
  # happens to be the square
  #
  alias abs2 square

  #
  # Compares the two numbers.
  # returns -1 if self < other
  #          0 if self-other = 0
  #         +1 if self > other
  # it needs to be observed, that
  # x == y implies (x <=> y) == 0
  # but not
  # (x <=> y) == 0 implies x == y
  # because == also takes the scale into account and considers two
  # numbers only equal, if they have the same number of potentially
  # zero digits after the decimal point.
  #
  def <=> (other)
    diff = (self - other)
    if (diff.kind_of? LongDecimal) || (diff.kind_of? LongDecimalQuot) then
      diff.sgn
    else
      diff <=> 0
    end
  end

  #
  # <=>-comparison for the scales
  #
  def scale_ufo(other)
    raise TypeError, "only works for LongDecimal and LongDecimalQuot" unless (other.kind_of? LongDecimal) || (other.kind_of? LongDecimalQuot)
    self.scale <=> other.scale
  end

  #
  # ==-comparison for the scales
  #
  def scale_equal(other)
    scale_ufo(other).zero?
  end

  #
  # return a pair o, s resembling other, self, but potentially
  # converted to compatible types and ready for
  # arithmetic operations.
  #
  def coerce(other)
    if other.kind_of? LongDecimal then
      return other, self
    elsif other.kind_of? LongDecimalQuot then
      return other, LongDecimalQuot(self.to_r, scale)
    elsif other.kind_of? Rational then
      sc = scale
      o  = LongDecimalQuot(other, sc)
      s  = LongDecimalQuot(self.to_r, sc)
      return o, s
    elsif (other.kind_of? Integer) || (other.kind_of? Float) then
      other = LongDecimal(other)
      if (other.scale > scale) then
        other = other.round_to_scale(scale, ROUND_HALF_UP)
      end
      return other, self
    elsif other.kind_of? BigDecimal then
      s, o = other.coerce(self.to_bd)
      return o, s
    elsif other.kind_of? Complex then
      # s, o = other.coerce(Complex(self.to_bd, 0))
      s, o = other.coerce(Complex(self.to_f, 0))
      return o, s
    elsif (other.kind_of? Float) && size > 8 then
      return coerce(BigDecimal(other.to_s))
    elsif other.kind_of? Numeric then
      s, o = other.coerce(self.to_f)
      return o, s
    else
      raise TypeError, "unsupported type #{other.inspect} for coerce of LongDecimal"
    end
  end

  #
  # is self expressable as an integer without loss of digits?
  #
  def is_int?
    scale == 0 || int_val % 10**scale == 0
  end

  #
  # get the sign of self
  # -1 if self < 0
  #  0 if self is 0 (with any number of 0s after the decimal point)
  # +1 if self > 0
  #
  def sgn
    int_val <=> 0
  end

  alias signum sgn
  alias sign   sgn

  #
  # comparison of self with other for equality
  # takes into account the values expressed by self and other and the
  # equality of the number of digits.
  #
  def ==(other)
    # (other.kind_of? LongDecimal) && (self <=> other) == 0 && self.scale == other.scale
    (other.kind_of? LongDecimal) && self.int_val == other.int_val && self.scale == other.scale
  end

  #
  # check if the number expressed by self is 0 (zero)
  # with any number of 0s after the decimal point.
  #
  def zero?
    int_val.zero?
  end

  #
  # check if the number expressed by self is 1 (one)
  # with any number of 0s after the decimal point.
  #
  def one?
    (self-1).zero?
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

end # LongDecimal

#
# This class is used for storing intermediate results after having
# performed a division.  The division cannot be completed without
# providing additional information on how to round the result.
#
class LongDecimalQuot < Numeric

  @RCS_ID='-$Id: long-decimal.rb,v 1.6 2006/03/20 21:38:32 bk1 Exp $-'

  include LongDecimalRoundingMode

  #
  # constructor
  # first, second is either a pair of LongDecimals or a Rational and an Integer
  # The resulting LongDecimal will contain a rational obtained by
  # dividing the two LongDecimals or by taking the Rational as it is.
  # The scale is there to provide a default rounding precision for
  # conversion to LongDecimal, but it has no influence on the value
  # expressed by the LongDecimalQuot
  #
  def LongDecimalQuot.new!(first, second)
    new(first, second)
  end

  #
  # create a new LongDecimalQuot from a rational and a scale or a
  # pair of LongDecimals
  #
  def initialize(first, second)
    if ((first.kind_of? Rational) || (first.kind_of? Integer)) && (second.kind_of? Integer) then
      @rat = Rational(first.numerator, first.denominator)
      @scale = second
    elsif (first.kind_of? LongDecimal) && (second.kind_of? LongDecimal) then
      orig_scale = first.scale
      first, second = first.anti_equalize_scale(second)
      @rat = Rational(first.to_i, second.to_i)
      @scale = orig_scale
    else
      raise TypeError, "parameters must be (LongDecimal, LongDecimal) or (Rational, Integer): first=#{first.inspect} second=#{second.inspect}";
    end
  end

  attr_reader :scale, :rat

  #
  # numerator of the included rational number.
  # LongDecimals should duck type like Rationals
  #
  def numerator
    rat.numerator
  end

  #
  # denominator of the included rational number.
  # LongDecimals should duck type like Rationals
  #
  def denominator
    rat.denominator
  end

  #
  # alter scale (only for internal use)
  #
  def scale=(s)
    raise TypeError, "non integer arg \"#{s.inspect}\"" if ! s.kind_of? Integer
    raise TypeError, "negative arg \"#{s.inspect}\""    if s < 0
    @scale = s
  end

  private :scale=

  #
  # conversion to string.  Based on the conversion of Rational
  #
  def to_s
    str = @rat.to_s
    str + "[" + scale.to_s + "]"
  end

  #
  # conversion to rational
  #
  def to_r
    Rational(numerator, denominator)
  end

  #
  # convert into Float
  #
  def to_f
    to_r.to_f
  end

  #
  # convert into Integer
  #
  def to_i
    to_r.to_i
  end

  #
  # conversion to LongDecimal using the internal scale
  #
  def to_ld
    round_to_scale(scale, ROUND_HALF_UP)
  end

  #
  # unary plus returns self
  #
  def +@
    self
  end

  #
  # unary minus returns negation of self
  # leaves self unchanged.
  #
  def -@
    if self.zero? then
      self
    else
      LongDecimalQuot(-rat, scale)
    end
  end

  #
  # addition
  # if other can be converted into LongDecimalQuot, add as
  # LongDecimalQuot, using the addition of Rationals internally
  # otherwise use BigDecimal, Complex or Float
  #
  def +(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat + o.rat, [s.scale, o.scale].max)
    else
      s + o
    end
  end

  #
  # subtraction
  # if other can be converted into LongDecimalQuot, add as
  # LongDecimalQuot, using the subtraction of Rationals internally
  # otherwise use BigDecimal, Complex or Float
  #
  def -(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat - o.rat, [s.scale, o.scale].max)
    else
      s - o
    end
  end

  #
  # multiplication
  # if other can be converted into LongDecimalQuot, add as
  # LongDecimalQuot, using the multiplication of Rationals internally
  # otherwise use BigDecimal, Complex or Float
  #
  def *(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat * o.rat, s.scale + o.scale)
    else
      s * o
    end
  end

  #
  # division
  # if other can be converted into LongDecimalQuot, add as
  # LongDecimalQuot, using the division of Rationals internally
  # otherwise use BigDecimal, Complex or Float
  #
  def /(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat / o.rat, scale)
    else
      s / o
    end
  end

  #
  # potentiation
  # if other can be converted into integer, use power of rational base
  # with integral exponent internally
  # otherwise result will be Float, BigDecimal or Complex
  #
  def **(other)
    if (other.kind_of? LongDecimal) || (other.kind_of? LongDecimalQuot) then
      if other.is_int? then
        other = other.to_i
      else
        other = other.to_r
      end
    end
    rat_result = rat ** other
    if (rat_result.kind_of? Rational) then
      if (other.kind_of? Integer) && other >= 0 then
        new_scale = scale * other
      else
        new_scale = scale
      end
      LongDecimalQuot(rat_result, new_scale)
    else
      rat_result
    end
  end

  #
  # division with remainder
  # calculate q and r such that 
  # q is an integer and r is non-negative and less or equal the
  # divisor. 
  #
  def divmod(other)
    if (other.kind_of? Complex) then
      raise TypeError, "divmod not supported for Complex"
    end
    q = (self / other).to_i
    return q, self - other * q
  end
  
  #
  # division with remainder
  # only return the remainder
  #
  def %(other)
    q, r = divmod other
    r
  end

  #
  # calculate the square of self
  #
  def square
    self * self
  end

  #
  # calculate the multiplicative inverse
  #
  def reciprocal
    1 / self
  end

  #
  # Absolute value
  #
  def abs
    LongDecimalQuot(rat.abs, scale)
  end

  #
  # square of absolute value
  #
  def abs2
    self.abs.square
  end

  #
  # convert LongDecimalQuot to LongDecimal with the given precision
  # and the given rounding mode
  #
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

  #
  # prepare binary operation of other with LongDecimalQuot
  # Integer, LongDecimal, Rational and LongDecimalQuot can be
  # expressed as LongDecimalQuot, using the scale of self in case of
  # Integer and Rational.  Floats can be approximated by LongDecimals
  # and thus be expressed as LongDecimalQuot
  # In case of BigDecimal, Complex or any unknown type, convert self
  # to BigDecimal or Float.
  #
  def coerce(other)
    if other.kind_of? LongDecimal then
      return LongDecimalQuot(other.to_r, other.scale), self
    elsif other.kind_of? LongDecimalQuot then
      return other, self
    elsif other.kind_of? Rational then
      s = scale
      return LongDecimalQuot(other, s), self
    elsif (other.kind_of? Integer) then
      return LongDecimalQuot(other.to_r, scale), self
    elsif other.kind_of? Float then
      return LongDecimalQuot(other.to_ld.to_r, scale), self
    elsif other.kind_of? BigDecimal then
      s, o = other.coerce(self.to_bd)
    elsif other.kind_of? Numeric then
      s, o = other.coerce(self.to_f)
      return o, s
    else
      raise TypeError, "unsupported type #{other.inspect} for coerce of LongDecimalQuot"
    end
  end

  #
  # compare two numbers for equality.
  # The LongDecimalQuot self is considered == to other if and only if
  # other is also LongDecimalQuot, expresses the same value and has the
  # same scale.
  # It needs to be observed that scale does not influence the value expressed
  # by the number, but only how rouding is performed by default if no
  # explicit number of digits after the decimal point is given.  But
  # scale needs to match for equality.
  #
  def ==(other)
    (other.kind_of? LongDecimalQuot) && (self <=> other) == 0 && self.scale == other.scale
  end

  #
  # Compares the two numbers for < and > etc.
  #
  def <=> (other)
    diff = (self - other)
    if (diff.kind_of? LongDecimal) || (diff.kind_of? LongDecimalQuot) then
      diff.sgn
    else
      diff <=> 0
    end
  end

  #
  # compare scales with <=>
  #
  def scale_ufo(other)
    raise TypeError, "only works for LongDecimal and LongDecimalQuot" unless (other.kind_of? LongDecimal) || (other.kind_of? LongDecimalQuot)
    self.scale <=> other.scale
  end

  #
  # check if scales are equal
  #
  def scale_equal(other)
    scale_ufo(other).zero?
  end

  #
  # is self expressable as an integer without loss of digits?
  #
  def is_int?
    denominator == 1
  end

  #
  # sign of self
  #
  def sgn
    numerator <=> 0
  end
  alias signum sgn
  alias sign   sgn

  #
  # Returns a hash code for the complex number.
  #
  def hash
    rat.hash ^ scale.hash
  end


  #
  # Returns "<tt>LongDecimalQuot(<i>int_val</i>, <i>scale</i>, <i>num</i>, <i>denom</i>)</tt>".
  #
  def inspect
    sprintf("LongDecimalQuot(Rational(%s, %s), %s)", numerator.inspect, denominator.inspect, scale.inspect)
  end

end # LongDecimalQuot

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

#
# construct a LongDecimalQuot from the given parameters
# 1st case: both are LongDecimals
# 2nd case: first is Rational, second is scale
#
def LongDecimalQuot(first, second)
  LongDecimalQuot.new!(first, second)
end


class Numeric

  #
  # convert self to LongDecimal
  #
  def to_ld
    LongDecimal(self)
  end

end # Numeric

#
# LongMath provides some helper functions to support LongDecimal and
# LongDecimalQuot, mostly operating on integers.  They are used
# internally here, but possibly they can be used elsewhere as well.
# In addition LongMath provides methods like those in Math, but for
# LongDecimal instead of Float.
#
module LongMath

  include LongDecimalRoundingMode

  MAX_FLOATABLE = Float::MAX.to_i
  MAX_EXP_ABLE  = Math.log(MAX_FLOATABLE).to_i
  LOG2          = Math.log(2.0)
  LOG10         = Math.log(10.0)

  #
  # helper method for internal use: checks if word_len is a reasonable
  # size for splitting a number into parts
  #
  def LongMath.check_word_len(word_len, name="word_len")
    raise TypeError, "#{name} must be a positive number <= 1024" unless (word_len.kind_of? Fixnum) && word_len > 0 && word_len <= 1024
    word_len
  end

  #
  # helper method for internal use: checks if parameter x is an Integer
  #
  def LongMath.check_is_int(x, name="x")
    raise TypeError, "#{name}=#{x.inspect} must be Integer" unless x.kind_of? Integer
  end

  #
  # helper method for internal use: checks if parameter x is a LongDecimal
  #
  def LongMath.check_is_ld(x, name="x")
    raise TypeError, "x=#{x.inspect} must be LongDecimal" unless x.kind_of? LongDecimal
  end

  #
  # helper method for internal use: checks if parameter x is a
  # reasonable value for the precision (scale) of a LongDecimal
  #
  def LongMath.check_is_prec(prec, name="prec")
    check_is_int(prec, "prec")
    raise TypeError, "#{name}=#{prec.inspect} must be >= 0" unless prec >= 0
  end

  #
  # helper method for internal use: checks if parameter x is a
  # rounding mode (instance of RoundingModeClass)
  #
  def LongMath.check_is_mode(mode, name="mode")
    raise TypeError, "#{name}=#{mode.inspect} must be legal rounding mode" unless mode.kind_of? RoundingModeClass
  end

  #
  # split number (Integer) x into parts of word_len bits each such
  # that the concatenation of these parts as bit patterns is x
  # (the opposite of merge_from_words)
  #
  def LongMath.split_to_words(x, word_len = 32)
    check_word_len(word_len)
    check_is_int(x, "x")
    m = x.abs
    s = (x <=> 0)
    bit_pattern = (1 << word_len) - 1
    words = []
    while (m != 0 || words.length == 0) do
      w = m & bit_pattern
      m = m >> word_len
      words.unshift(w)
    end
    if (s < 0) then
      words[0] = -words[0]
    end
    words
  end

  #
  # concatenate numbers given in words as bit patterns
  # (the opposite of split_to_words)
  #
  def LongMath.merge_from_words(words, word_len = 32)
    check_word_len(word_len)
    raise TypeError, "words must be array of length > 0" unless (words.kind_of? Array) && words.length > 0
    y = 0
    s = (words[0] <=> 0)
    if (s < 0) then
      words[0] = -words[0]
    end
    words.each do |w|
      y = y << word_len
      y += w
    end
    if (s < 0) then
      y = -y
    end
    y
  end

  #

  # calculate the square root of an integer x using bitwise algorithm
  # the result is rounded to an integer y such that
  # y**2 <= x < (y+1)**2
  #
  def LongMath.sqrtb(x)
    a = sqrtb_with_remainder(x)
    a[0]
  end

  #
  # calculate the an integer s >= 0 and a remainder r >= 0 such that
  # x = s**2 + r and s**2 <= x < (s+1)**2
  # the bitwise algorithm is used, which works well for relatively
  # small values of x.
  #
  def LongMath.sqrtb_with_remainder(x)
    check_is_int(x, "x")

    s = (x <=> 0)
    if (s == 0) then
      return [0, 0]
    elsif (s < 0)
      a = sqrtb_with_remainder(-x)
      return [ Complex(0, a[0]), a[1]]
    end

    xwords = split_to_words(x, 2)
    xi = xwords[0] - 1
    yi = 1

    1.upto(xwords.length-1) do |i|
      xi = (xi << 2) + xwords[i]
      d0 = (yi << 2) + 1
      r  = xi - d0
      b  = 0
      if (r >= 0) then
        b  = 1
        xi = r
      end
      yi = (yi << 1) + b
    end
    return [yi, xi]
  end

  #

  # calculate the square root of an integer using larger chunks of the
  # number.  The optional parameter n provides the size of these
  # chunks.  It is by default chosen to be 16, which is optimized for
  # 32 bit systems, because internally parts of the double size are
  # used.
  # the result is rounded to an integer y such that
  # y**2 <= x < (y+1)**2
  #
  def LongMath.sqrtw(x, n = 16)
    a = sqrtw_with_remainder(x, n)
    a[0]
  end

  #
  # calculate the an integer s >= 0 and a remainder r >= 0 such that
  # x = s**2 + r and s**2 <= x < (s+1)**2
  # the wordwise algorithm is used, which works well for relatively
  # large values of x.  n defines the word size to be used for the
  # algorithm.  It is good to use half of the machine word, but the
  # algorithm would also work for other values.
  #
  def LongMath.sqrtw_with_remainder(x, n = 16)
    check_is_int(x, "x")
    check_is_int(n, "n")
    n2 = n<<1
    n1 = n+1
    check_word_len(n2, "2*n")

    s = (x <=> 0)
    if (s == 0) then
      return [0, 0]
    elsif (s < 0)
      a = sqrtw_with_remainder(-x)
      return [ Complex(0, a[0]), a[1]]
    end

    xwords = split_to_words(x, n2)
    if (xwords.length == 1) then
      return sqrtb_with_remainder(xwords[0])
    end

    # puts(xwords.inspect + "\n")
    xi = (xwords[0] << n2) + xwords[1]
    a  = sqrtb_with_remainder(xi)
    yi = a[0]
    if (xwords.length <= 2) then
      return a
    end

    xi -= yi*yi
    2.upto(xwords.length-1) do |i|
      xi = (xi << n2) + xwords[i]
      d0 = (yi << n1)
      q  = (xi / d0).to_i
      q0 = q
      j  = 0
      was_negative = false
      while (true) do
        d = d0 + q
        r = xi - (q * d)
        break if (0 <= r && (r < d || was_negative))
        # puts("i=#{i} j=#{j} q=#{q} d0=#{d0} d=#{d} r=#{r} yi=#{yi} xi=#{xi}\n")
        if (r < 0) then
          was_negative = true
          q = q-1
        else
          q = q+1
        end
        j += 1
        if (j > 10) then
          # puts("i=#{i} j=#{j} q=#{q} q0=#{q0} d0=#{d0} d=#{d} r=#{r} yi=#{yi} xi=#{xi}\n")
          break
        end
      end
      xi = r
      yi = (yi << n) + q
    end
    return [ yi, xi ]
  end

  #

  # find the gcd of an Integer x with b**n0 where n0 is a sufficiently
  # high exponent
  # such that gcd(x, b**m) = gcd(x, b**n) for all m, n >= n0
  #
  def LongMath.gcd_with_high_power(x, b)
    check_is_int(x, "x")
    raise ZeroDivisionError, "gcd_with_high_power of zero with \"#{b.inspect}\" would be infinity" if x.zero?
    check_is_int(b, "b")
    raise ZeroDivisionError, "gcd_with_high_power with b < 2 is not defined. b=\"#{b.inspect}\"" if b < 2
    s = x.abs
    exponent = 1
    b = b.abs
    if (b < s && s < MAX_FLOATABLE)
      exponent = (Math.log(s) / Math.log(b)).ceil
    end
    power  = b**exponent
    result = 1
    begin
      f = s.gcd(power)
      s /= f
      result *= f
    end while f > 1
    result
  end

  #
  # Find the exponent of the highest power of prime number p that divides
  # the Integer x.  Only works for prime numbers p (parameter prime_number).
  # The caller has to make sure that p (parameter prime_number) is
  # actually a prime number, because checks for primality actually cost
  # something and should not be duplicated more than necessary.
  # This method works even for numbers x that exceed the range of Float
  #
  def LongMath.multiplicity_of_factor(x, prime_number)

    if (x.kind_of? Rational) || (x.kind_of? LongDecimalQuot) then
      m1 = multiplicity_of_factor(x.numerator, prime_number)
      m2 = multiplicity_of_factor(x.denominator, prime_number)
      return m1 - m2

    elsif (x.kind_of? LongDecimal)
      m1 = multiplicity_of_factor(x.numerator, prime_number)
      if (prime_number == 2 || prime_number == 5) then
        return m1 - x.scale
      else
        return m1
      end

    elsif (x.kind_of? Integer)

      power = gcd_with_high_power(x, prime_number)
      if (power.abs < MAX_FLOATABLE) then
        result = (Math.log(power) / Math.log(prime_number)).round
      else
        e = (Math.log(MAX_FLOATABLE) / Math.log(prime_number)).floor
        result = 0
        partial = prime_number ** e
        while (power > partial) do
          power /= partial
          result += e
        end
        result += (Math.log(power) / Math.log(prime_number)).round
      end
      return result
    else
      raise TypeError, "type of x is not supported #{x.class} #{x.inpect}"
    end
  end

  #
  # method for calculating pi to the given number of digits after the
  # decimal point.
  # It works fine for 1000 or 2000 digits or so.
  # This method could be optimized more, but if you really want to go
  # for more digits, you will find a specialized and optimized program
  # for this specific purpose, probably written in C or C++.
  # Since calculation of pi is not what should typically be done with
  # LongDecimal, you may consider this method to be the easter egg of
  # LongDecimal. ;-)
  #
  def LongMath.calc_pi(prec, final_mode = LongDecimal::ROUND_HALF_DOWN)
    mode  = LongDecimal::ROUND_HALF_DOWN
    iprec = 5*(prec+1)
    sprec = (iprec >> 1) + 1
    dprec = (prec+1) << 1

    a = LongDecimal(1)
    b = (1 / LongDecimal(2).sqrt(iprec,mode)).round_to_scale(iprec, mode)
    c = LongDecimal(5,1)
    k = 1
    pow_k = 2

    pi = 0
    last_pi = 0
    last_diff = 1

    loop do
      a, b = ((a + b) / 2).round_to_scale(sprec, mode), (a * b).round_to_scale(iprec, mode).sqrt(sprec, mode)
      c    = (c - pow_k * (a * a - b * b)).round_to_scale(iprec, mode)
      pi   = (2 * a * a / c).round_to_scale(sprec, mode)
      diff = (pi - last_pi).round_to_scale(dprec, mode).abs
      if (diff.zero? && last_diff.zero?) then
        break
      end
      last_pi = pi
      last_diff = diff
      k += 1
      pow_k = pow_k << 1
      # puts("k=#{k} pi=#{pi.to_s}\nd=#{diff}\n\n")
    end
    pi.round_to_scale(prec, final_mode)
  end

  #
  # calc the exponential function of x to the given precision as
  # LongDecimal.  Only supports values of x such that the result still
  # fits into a float (x <= 709).  This limitation is somewhat
  # arbitrary, but it is enforced in order to avoid producing numbers
  # with the exponential function that exceed the memory.  It may be
  # removed in future versions.
  #
  def LongMath.exp(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x, "x")
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_EXP_ABLE}" unless x <= MAX_EXP_ABLE
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    exp_internal(x, prec, mode)
  end

  #
  # private helper method for exponentiation
  # calculate internal precision
  #
  def LongMath.calc_iprec_for_exp(x, prec)
    iprec_extra = 0
    if (x > 1) then
      xf = x.to_f
      iprec_extra = (xf / LOG10).abs
    end
    iprec = ((prec+10)*1.20 + iprec_extra).round
    if (iprec < prec) then
      iprec = prec
    end
    # puts("calc_iprec_for_exp: x=#{x} prec=#{prec} iprec=#{iprec} iprec_extra=#{iprec_extra}\n")
    iprec
  end

  # private :calc_iprec_for_exp

  #
  # internal functionality of exp.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing exp.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.exp_internal(x, prec = nil, final_mode = LongDecimal::ROUND_HALF_DOWN, j = nil, k = nil, iprec = nil, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x, "x")
    if (prec == nil) then
      prec = x.scale
    end
    check_is_prec(prec, "prec")

    if (final_mode == nil)
      final_mode = LongDecimal::ROUND_HALF_DOWN
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    # if the result would come out to zero anyway, cut the work
    xi = x.to_i
    if (xi < -LongMath::MAX_FLOATABLE) || -((xi.to_f - 1) / LOG10) > prec+1 then
      return LongDecimal(25, prec+2).round_to_scale(prec, final_mode)
    end

    if j == nil || k == nil then
      s1 = (prec * LOG10 / LOG2) ** (1.0/3.0)
      if (j == nil) then
        j = s1.round
      end
      if (k == nil) then
        k = (s1 + Math.log([1, prec].max) / LOG2).round
      end
      if (x > 1) then
        k += (Math.log(x.to_f) / LOG2).abs.round
      end
    end
    if (j <= 0) then
      j = 1
    end
    if (k < 0) then
      k = 0
    end
    check_is_int(j, "j")
    check_is_int(k, "k")

    if (iprec == nil) then
      iprec = calc_iprec_for_exp(x, prec)
    end
    check_is_prec(iprec, "iprec")
    # puts("exp_internal: x=#{x} prec=#{prec} iprec=#{iprec}\n")

    dprec = [ iprec, (prec + 1) << 1 ].min

    x_k = (x / (1 << k)).round_to_scale(iprec, mode)
    x_j = (x_k ** j).round_to_scale(iprec, mode)
    s = [ LongDecimal(0) ] * j
    t = LongDecimal(1)
    last_t = 1
    f = 0
    loop do
      j.times do |i|
        s[i] += t
        f += 1
        t = (t / f).round_to_scale(iprec, mode)
      end
      t = (t * x_j).round_to_scale(iprec, mode)
      break if (t.zero?)
      tr = t.round_to_scale(dprec, LongDecimal::ROUND_DOWN).abs
      break if (t.zero?)
      tu = t.unit
      break if (tr <= tu && last_t <= tu)
      last_t = tr
    end
    x_i = 1
    y_k = LongDecimal(0)
    j.times do |i|
      if (i > 0) then
        x_i = (x_i * x_k).round_to_scale(iprec, mode)
      end
      # puts("y_k=#{y_k}\ni=#{i} j=#{j} k=#{k} x=#{x}\nx_k=#{x_k}\nx_j=#{x_j}\nx_i=#{x_i}\ns[i]=#{s[i]}\n\n")
      y_k += (s[i] * x_i).round_to_scale(iprec, mode)
    end
    # puts("y_k = #{y_k}\n")
    k.times do |i|
      y_k = y_k.square.round_to_scale(iprec, mode)
      # puts("i=#{i} y_k = #{y_k}\n")
    end
    y = y_k.round_to_scale(prec, final_mode)
    y
  end

  #
  # calculate the natural logarithm function of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x, "x")
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    log_internal(x, prec, mode)
  end

  #
  # calculate the base 10 logarithm of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log10(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x, "x")
    check_is_prec(prec, "prec")
    if (x.one?) then
      return LongDecimal.zero!(prec)
    end
    check_is_mode(mode, "mode")
    iprec = prec + 2
    id = x.int_digits10
    xx = x.move_point_left(id)
    # puts("x=#{x} xx=#{xx} id=#{id} iprec=#{iprec}\n")
    lnxx = log_internal(xx, iprec, mode)
    ln10 = log_internal(10.to_ld, iprec, mode)
    y  = id + (lnxx / ln10).round_to_scale(prec, mode)
    return y
  end

  #
  # calculate the base 2 logarithm of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log2(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x, "x")
    check_is_prec(prec, "prec")
    if (x.one?) then
      return LongDecimal.zero!(prec)
    end
    check_is_mode(mode, "mode")
    iprec = prec + 2
    id = x.int_digits2
    xx = (x / (1 << id)).round_to_scale(x.scale+id)
    # puts("x=#{x} xx=#{xx} id=#{id} iprec=#{iprec}\n")
    lnxx = log_internal(xx, iprec, mode)
    ln2  = log_internal(2.to_ld, iprec, mode)
    y    = id + (lnxx / ln2).round_to_scale(prec, mode)
    return y
  end

  #
  # internal functionality of log.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing log.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.log_internal(x, prec = nil, final_mode = LongDecimal::ROUND_HALF_DOWN, iprec = nil, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x)
    raise TypeError, "x=#{x.inspect} must not be positive" unless x > 0
    if (prec == nil) then
      prec = x.scale
    end
    check_is_prec(prec, "prec")
    if (x.one?) then
      return LongDecimal.zero!(prec)
    end

    if (final_mode == nil)
      final_mode = LongDecimal::ROUND_HALF_DOWN
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    if (iprec == nil) then
      iprec = ((prec+10)*1.20).round
    end
    if (iprec < prec) then
      iprec = prec
    end
    check_is_prec(iprec, "iprec")

    #    dprec = [ iprec - 1, (prec + 1) << 1 ].min
    dprec = iprec - 1

    y = 0
    s = 1
    if (x < 1) then
      # puts("x=#{x} iprec=#{iprec}\n")
      x = (1 / x).round_to_scale(iprec, mode)
      s = -1
      # puts("s=#{s} x=#{x} iprec=#{iprec}\n")
    end
    exp_part = 0
    estimate = 0
    while (x > MAX_FLOATABLE) do
      if (exp_part == 0) then
        estimate = MAX_EXP_ABLE.to_ld
        exp_part = exp(estimate, iprec)
      end
      x = (x / exp_part).round_to_scale(iprec, mode)
      if (s < 0) then
        y -= estimate
      else
        y += estimate
      end
    end

    delta = LongDecimal(1, 3)
    while (x - 1).abs > delta do
      # puts("too far from 1: x=#{x}\n")
      xf = x.to_f
      # puts("xf=#{xf}\n")
      mlx = Math.log(xf)
      # puts("log(xf)=#{mlx}\n")
      estimate = mlx.to_ld.round_to_scale(20, mode)
      exp_part = exp(estimate, iprec << 1)
      # puts("y=#{y} s=#{s} est=#{estimate} part=#{exp_part} x=#{x}\n")
      x = (x / exp_part).round_to_scale(iprec, mode)
      # puts("divided by exp_part=#{exp_part}: #{x}\n")
      if (s < 0) then
        y -= estimate
      else
        y += estimate
      end
      # puts("y=#{y} s=#{s} est=#{estimate} part=#{exp_part} x=#{x}\n")
    end

    factor = 1
    # delta  = LongDecimal(1, (iprec.to_f**(1/3)).round)
    # while (x - 1).abs > delta do
    #  x       = sqrt(x)
    #  factor *= 2
    # end

    sum = 0
    z   = 1 - x
    i   = 1
    p   = 1.to_ld
    d   = 1.to_ld
    until p.abs.round_to_scale(dprec, LongDecimal::ROUND_DOWN).zero? do
      p = (p * z).round_to_scale(iprec, mode)
      d = (p / i).round_to_scale(iprec, mode)
      i += 1
      sum += d

      # puts("log_internal: s=#{sum} d=#{d} x=#{x} i=#{i} p=#{p} iprec=#{iprec} dprec=#{dprec}\n") if (i & 0x0f == 0x0f)
    end

    # puts("y=#{y} s=#{s} f=#{factor} sum=#{sum}\n")
    y -= ((s * factor) * sum).round_to_scale(iprec, mode)
    # puts("y=#{y} s=#{s} f=#{factor} sum=#{sum}\n")
    return y.round_to_scale(prec, final_mode)

  end

  #
  # calc the power of x with exponent y to the given precision as
  # LongDecimal.  Only supports values of y such that exp(y) still
  # fits into a float (y <= 709)
  #
  def LongMath.power(x, y, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x, "x")
    check_is_ld(y, "y")
    raise TypeError, "y=#{y.inspect} must not be greater #{MAX_EXP_ABLE}" unless y <= MAX_EXP_ABLE
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_FLOATABLE}" unless x <= MAX_FLOATABLE
    raise TypeError, "x=#{x.inspect} must not positive" unless x > 0
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    LongMath.power_internal(x, y, prec, mode)
  end

  #
  # internal functionality of exp.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing exp.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.power_internal(x, y, prec = nil, final_mode = LongDecimal::ROUND_HALF_DOWN, iprec = nil, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_ld(x, "x")
    if (prec == nil) then
      prec = x.scale
    end
    check_is_prec(prec, "prec")

    if (final_mode == nil)
      final_mode = LongDecimal::ROUND_HALF_DOWN
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    logx_y_f = Math.log(x.to_f) * (y.to_f)

    # iprec = (prec * 1.2 + 20 + (y.abs.to_f) * 1.5 * x.int_digits2).round
    if (iprec == nil) then
      iprec = calc_iprec_for_exp(logx_y_f, prec) + 2
    end
    # puts("power_internal: x=#{x} y=#{y} logx_y=#{logx_y_f} iprec=#{iprec} prec=#{prec}\n")
    logx = log(x, iprec, mode)
    logx_y = logx*y
    xy = exp_internal(logx_y, prec + 1, mode)
    # puts("power_internal: x=#{x} logx=#{logx} y=#{y} logx_y=#{logx_y} xy=#{xy} iprec=#{iprec} prec=#{prec}\n")
    xy.round_to_scale(prec, final_mode)
  end

end # LongMath

# end of file long-decimal.rb
