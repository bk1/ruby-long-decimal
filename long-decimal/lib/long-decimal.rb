#
# long-decimal.rb -- Arbitrary precision decimals with fixed decimal point
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/lib/long-decimal.rb,v 1.33 2006/04/11 19:03:22 bk1 Exp $
# CVS-Label: $Name: ALPHA_01_00 $
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

    def inverse
      LongDecimalRoundingMode::INVERSE_MODE[self]
    end

    def hash
      num
    end

  end

  #
  # rounding modes as constants
  #
  ROUND_UP           = RoundingModeClass.new(:ROUND_UP, 0)
  ROUND_DOWN         = RoundingModeClass.new(:ROUND_DOWN, 1)
  ROUND_CEILING      = RoundingModeClass.new(:ROUND_CEILING, 2)
  ROUND_FLOOR        = RoundingModeClass.new(:ROUND_FLOOR, 3)
  ROUND_HALF_UP      = RoundingModeClass.new(:ROUND_HALF_UP, 4)
  ROUND_HALF_DOWN    = RoundingModeClass.new(:ROUND_HALF_DOWN, 5)
  ROUND_HALF_CEILING = RoundingModeClass.new(:ROUND_HALF_CEILING, 6)
  ROUND_HALF_FLOOR   = RoundingModeClass.new(:ROUND_HALF_FLOOR, 7)
  ROUND_HALF_EVEN    = RoundingModeClass.new(:ROUND_HALF_EVEN, 8)
  ROUND_UNNECESSARY  = RoundingModeClass.new(:ROUND_UNNECESSARY, 9)

  INVERSE_MODE = {
    ROUND_UP           =>   ROUND_DOWN,
    ROUND_DOWN         =>   ROUND_UP,
    ROUND_CEILING      =>   ROUND_FLOOR,
    ROUND_FLOOR        =>   ROUND_CEILING,
    ROUND_HALF_UP      =>   ROUND_HALF_DOWN,
    ROUND_HALF_DOWN    =>   ROUND_HALF_UP,
    ROUND_HALF_CEILING =>   ROUND_HALF_FLOOR,
    ROUND_HALF_FLOOR   =>   ROUND_HALF_CEILING,
    ROUND_HALF_EVEN    =>   ROUND_HALF_EVEN,
    ROUND_UNNECESSARY  =>   ROUND_UNNECESSARY
  }

end # LongDecimalRoundingMode

#
# common base class for LongDecimal and LongDecimalQuot
#
class LongDecimalBase < Numeric
  @RCS_ID='-$Id: long-decimal.rb,v 1.33 2006/04/11 19:03:22 bk1 Exp $-'

  include LongDecimalRoundingMode

  #
  # convert self into Rational
  # this works quite straitforward.
  # in case of LongDecimal use int_val as numerator and a power of 10
  # as denominator, which happens to be the way numerator and
  # denominator are defined
  #
  def to_r
    Rational(numerator, denominator)
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
  # unary plus returns self
  #
  def +@
    self
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
    sx = self.scale
    dx = self.sint_digits10
    new_scale = [ 0, 2 * dx + sx - 2].max
    result = 1 / self
    result.scale = new_scale
    result
  end

  alias inverse reciprocal

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
    if (diff.kind_of? LongDecimalBase) then
      diff.sgn
    else
      diff <=> 0
    end
  end

  #
  # <=>-comparison for the scales
  #
  def scale_ufo(other)
    raise TypeError, "only works for LongDecimal or LongDecimalQuot" unless (other.kind_of? LongDecimalBase)
    self.scale <=> other.scale
  end

  #
  # ==-comparison for the scales
  #
  def scale_equal(other)
    scale_ufo(other).zero?
  end

end # class LongDecimalBase

#
# class for holding fixed point long decimal numbers
# these can be considered as a pair of two integer.  One contains the
# digits and the other one the position of the decimal point.
#
class LongDecimal < LongDecimalBase
  @RCS_ID='-$Id: long-decimal.rb,v 1.33 2006/04/11 19:03:22 bk1 Exp $-'

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
      mul_2  = LongMath.multiplicity_of_factor(denom, 2)
      mul_5  = LongMath.multiplicity_of_factor(denom, 5)
      iscale = [mul_2, mul_5].max
      scale += iscale
      denom /= 2 ** mul_2
      denom /= 5 ** mul_5
      iscale2 = Math.log10(denom).ceil
      scale += iscale2
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

      # handle optional e-part of floating point number represented as
      # string
      if num_exp.nil? || num_exp.empty? then
        num_exp = "0"
      end
      num_exp = num_exp.to_i
      iscale  = num_frac.length - num_exp
      scale  += iscale
      if (scale < 0)
        num_frac += "0" * (-scale)
        scale = 0
      end
      int_val  = (num_int + num_frac).to_i
      if negative then
        int_val = -int_val
      end
    end
    # scale is the number of digits that go after the decimal point
    @scale    = scale
    # int_val holds all the digits.  The value actually expressed by self is
    # int_val * 10**(-scale)
    @int_val  = int_val
    # used for storing the number of digits before the decimal point.
    # Is nil, until it is used the first time
    @digits10 = nil

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
      @scale    = s
      @digits10 = nil
    end
  end

  protected :scale=

  #
  # get rid of trailing zeros
  #
  def round_trailing_zeros
    n = LongMath.multiplicity_of_10(int_val)
    if (n.zero?) then
      return self
    end
    if (n > scale) then
      n = scale
    end
    return self.round_to_scale(scale - n)
  end

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
  #
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
      rounded = quot.round_to_scale(0, mode)
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
  # convert self into Float
  # this works straitforward by dividing numerator by power of 10 in
  # float-arithmetic, in all cases where numerator and denominator are
  # within the ranges expressable as Floats.  Goes via string
  # representation otherwise.
  #
  def to_f
    divisor = denominator
    if (divisor == 1) then
      return numerator.to_f
    elsif numerator.abs <= LongMath::MAX_FLOATABLE then
      if (divisor.abs > LongMath::MAX_FLOATABLE) then
        return 0.0
      else
        f = numerator.to_f
        return f / divisor
      end
    elsif numerator.abs < divisor
      # self is between -1 and 1

      # factor = numerator.abs.div(LongMath::MAX_FLOATABLE)
      # digits = factor.to_ld.int_digits10
      # return LongDecimal(numerator.div(10**digits), scale -digits).to_f
      return self.to_s.to_f
    else
      q = numerator.abs / divisor
      if (q.abs > 1000000000000000000000)
        return q.to_f
      else
        return self.to_s.to_f
      end
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
  # optional first argument gives the precision for the desired result
  # optional second argument gives the rouding mode
  #
  def to_ld(prec = nil, mode = LongDecimal::ROUND_HALF_UP)
    if (prec.nil?)
      return self
    else
      return round_to_scale(prec, mode)
    end
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
  #
  def sint_digits10
    if (@digits10.nil?)
      @digits10 = LongMath.int_digits10(int_val) - scale
    end
    @digits10
  end

  #
  # number of decimal digits before the decimal point, not counting a
  # single 0.
  # 0.0xx -> 0
  # 0.xxx -> 0
  # 1.xxx -> 1
  # 10.xxx -> 2
  # ...
  #
  def int_digits10
    return [ sint_digits10, 0 ].max
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
  # self += 1
  #
  def inc!
    @int_val += denominator
    @digits10 = nil
  end

  #
  # self -= 1
  #
  def dec!
    @int_val -= denominator
    @digits10 = nil
  end

  #
  # return the unit by which self is incremented by succ
  #
  def unit
    LongDecimal(1, scale)
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
      if (new_scale.nil?) then
        q = LongDecimal(q)
      else
        q = q.to_ld(new_scale, rounding_mode)
      end
    end
    if (q.kind_of? LongDecimalBase) then
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
    if (other.kind_of? LongDecimalBase) && other.is_int? then
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
      if (other.kind_of? LongDecimalBase) then
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
    LongMath.sqrt(self, new_scale, rounding_mode)
  end

  #
  # calculate the sqrt s of self and remainder r >= 0
  # such that s*s+r = self and (s+1)*(s+1) > self
  # provide the result with given number
  # new_scale of digits after the decimal point
  #
  def sqrt_with_remainder(new_scale)
    LongMath.sqrt_with_remainder(self, new_scale)
  end

  #
  # Absolute value
  #
  def abs
    LongDecimal(int_val.abs, scale)
  end

  #
  # return a pair o, s resembling other, self, but potentially
  # converted to compatible types and ready for
  # arithmetic operations.
  #
  def coerce(other)

    if other.kind_of? LongDecimal then
      # if other is LongDecimal as well, nothing to do
      return other, self

    elsif other.kind_of? LongDecimalQuot then
      # if other is LongDecimalQuot, convert self to LongDecimalQuot
      # as well
      return other, LongDecimalQuot(self.to_r, scale)

    elsif other.kind_of? Rational then
      # if other is Rational, convert self and other to
      # LongDecimalQuot.  This is well adapted to cover both.
      sc = scale
      o  = LongDecimalQuot(other, sc)
      s  = LongDecimalQuot(self.to_r, sc)
      return o, s

      # we could use BigDecimal as common type for combining Float and
      # LongDecimal, but this needs a lot of consideration.  For the
      # time being we assume that we live well enough with converting
      # Float into LongDecimal
      # elsif (other.kind_of? Float) && size > 8 then
      #  return coerce(BigDecimal(other.to_s))

    elsif (other.kind_of? Integer) || (other.kind_of? Float) then
      # if other is Integer or Float, convert it to LongDecimal
      other = LongDecimal(other)
      if (other.scale > scale) then
        other = other.round_to_scale(scale, ROUND_HALF_UP)
      end
      return other, self

    elsif other.kind_of? BigDecimal then
      # if other is BigDecimal convert self to BigDecimal
      s, o = other.coerce(self.to_bd)
      return o, s

    elsif other.kind_of? Complex then
      # if other is Complex, convert self to Float and then to
      # Complex.  It need to be observed that this will fail if self
      # has too many digits before the decimal point to be expressed
      # as Float.
      s, o = other.coerce(Complex(self.to_f, 0))
      return o, s

    elsif other.kind_of? Numeric then
      # all other go by expressing self as Float and seeing how it
      # combines with other.
      s, o = other.coerce(self.to_f)
      return o, s

    else
      # non-numeric types do not work here
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
  # comparison of self with other for equality
  # takes into account the values expressed by self and other and the
  # equality of the number of digits.
  #
  def ===(other)
    # (other.kind_of? LongDecimal) && self.int_val == other.int_val
    (self <=> other).zero?
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
class LongDecimalQuot < LongDecimalBase

  @RCS_ID='-$Id: long-decimal.rb,v 1.33 2006/04/11 19:03:22 bk1 Exp $-'

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
    @digits10 = nil
    if ((first.kind_of? Rational) || (first.kind_of? Integer)) && (second.kind_of? Integer) then
      @rat   = Rational(first.numerator, first.denominator)
      @scale = second

    elsif (first.kind_of? LongDecimal) && (second.kind_of? LongDecimal) then
      # calculate the number of digits after the decimal point we can
      # be confident about.  Use 0, if we do not have any confidence
      # about any digits after the decimal point.  The formula has
      # been obtained by using the partial derivatives of f(x, y) =
      # x/y and assuming that sx and sy are the number of digits we
      # know after the decimal point and dx and dy are the number of
      # digits before the decimal point.  Since division is usually
      # not expressable exactly in decimal digits, it is up to the
      # calling application to decide on the number of digits actually
      # used for the result, which can be more that new_scale.
      sx = first.scale
      sy = second.scale
      dx = first.sint_digits10
      dy = second.sint_digits10
      new_scale = [ 0, 2 * dy + sx + sy - [ dx + sx, dy + sy ].max - 3].max
      # puts("sx=#{sx} sy=#{sy} dx=#{dx} dy=#{dy} sc=#{new_scale} x=#{first} y=#{second}\n")

      first, second = first.anti_equalize_scale(second)
      @rat   = Rational(first.to_i, second.to_i)
      @scale = new_scale
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

  # protected :scale=

  #
  # conversion to string.  Based on the conversion of Rational
  #
  def to_s
    str = @rat.to_s
    str + "[" + scale.to_s + "]"
  end

  #
  # convert into Float
  #
  def to_f
    to_r.to_f
  end

  #
  # conversion to BigDecimal
  #
  def to_bd
    to_ld.to_bd
  end

  #
  # convert into Integer
  #
  def to_i
    to_r.to_i
  end

  #
  # conversion to LongDecimal using the internal scale
  # optional first argument gives the precision for the desired result
  # optional second argument gives the rouding mode
  #
  def to_ld(prec = scale, mode = LongDecimal::ROUND_HALF_UP)
    round_to_scale(prec, mode)
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
  #
  def sint_digits10
    if (@digits10.nil?)
      if zero?
        @digits10 = nil
      else
        n = numerator.abs
        d = denominator
        i = 0
        while (n < d)
          i += 1
          n *= 10
        end
        @digits10 = LongMath.int_digits10(n/d) - i
      end
    end
    @digits10
  end

  #
  # self += 1
  #
  def inc!
    @rat += 1
    @digits10 = nil
  end

  #
  # self -= 1
  #
  def dec!
    @rat -= 1
    @digits10 = nil
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
    if (other.kind_of? LongDecimalBase) then
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
  # Absolute value
  #
  def abs
    LongDecimalQuot(rat.abs, scale)
  end

  #
  # square of absolute value
  # happens to be the square
  #
  alias abs2 square

  #
  # convert LongDecimalQuot to LongDecimal with the given precision
  # and the given rounding mode
  #
  def round_to_scale(new_scale = @scale, mode = ROUND_UNNECESSARY)

    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.kind_of? RoundingModeClass

    sign_quot = numerator <=> 0
    if sign_quot == 0 then
      # finish zero without long calculations at once
      return LongDecimal(0, new_scale)
    end

    factor    = 10**new_scale
    prod      = numerator * factor
    divisor   = denominator
    quot, rem = prod.divmod(divisor)
    sign_rem  = rem  <=> 0
    if (sign_rem == 0)
      # if self can be expressed without loss as LongDecimal with
      # new_scale digits after the decimal point, just do it.
      return LongDecimal(quot, new_scale)
    end

    # we do not expect negative signs of remainder.  To make sure that
    # this does not cause problems in further code, we just throw an
    # exception.  This should never happen (and did not happen during
    # testing).
    raise Error, "signs do not match self=#{self.to_s} f=#{factor} prod=#{prod} divisor=#{divisor} quot=#{quot} rem=#{rem}" if sign_rem <= 0

    if (sign_quot < 0) then
      # handle negative sign of self
      rem -= divisor
      quot += 1
      sign_rem = rem <=> 0
      raise Error, "signs do not match self=#{self.to_s} f=#{factor} prod=#{prod} divisor=#{divisor} quot=#{quot} rem=#{rem}" if sign_rem >= 0
    end

    if mode == ROUND_UNNECESSARY then
      # this mode means that rounding should not be necessary.  But
      # the case that no rounding is needed, has already been covered
      # above, so it is an error, if this mode is required and the
      # result could not be returned above.
      raise ArgumentError, "mode ROUND_UNNECESSARY not applicable, remainder #{rem.to_s} is not zero"
    end

    if (mode == ROUND_CEILING)
      # ROUND_CEILING goes to the closest allowed number >= self, even
      # for negative numbers.  Since sign is handled separately, it is
      # more conveniant to use ROUND_UP or ROUND_DOWN depending on the
      # sign.
      mode = (sign_quot > 0) ? ROUND_UP : ROUND_DOWN

    elsif (mode == ROUND_FLOOR)
      # ROUND_FLOOR goes to the closest allowed number <= self, even
      # for negative numbers.  Since sign is handled separately, it is
      # more conveniant to use ROUND_UP or ROUND_DOWN depending on the
      # sign.
      mode = (sign_quot < 0) ? ROUND_UP : ROUND_DOWN

    else

      if (mode == ROUND_HALF_CEILING)
        # ROUND_HALF_CEILING goes to the closest allowed number >= self, even
        # for negative numbers.  Since sign is handled separately, it is
        # more conveniant to use ROUND_HALF_UP or ROUND_HALF_DOWN depending on the
        # sign.
        mode = (sign_quot > 0) ? ROUND_HALF_UP : ROUND_HALF_DOWN

      elsif (mode == ROUND_HALF_FLOOR)
        # ROUND_HALF_FLOOR goes to the closest allowed number <= self, even
        # for negative numbers.  Since sign is handled separately, it is
        # more conveniant to use ROUND_HALF_UP or ROUND_HALF_DOWN depending on the
        # sign.
        mode = (sign_quot < 0) ? ROUND_HALF_UP : ROUND_HALF_DOWN

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
      quot += sign_quot
    end

    # put together result
    new_int_val = quot
    LongDecimal(new_int_val, new_scale)

  end # round_to_scale

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
      # convert LongDecimal to LongDecimalQuot
      return LongDecimalQuot(other.to_r, other.scale), self

    elsif other.kind_of? LongDecimalQuot then
      # nothing to convert, if both are already LongDecimalQuot
      return other, self

    elsif (other.kind_of? Rational) || (other.kind_of? Integer) then
      # convert Rational or Integer to LongDecimalQuot.  The only
      # missing part, scale, is just taken from self
      s = scale
      return LongDecimalQuot(other, s), self

    elsif other.kind_of? Float then
      # convert Float to LongDecimalQuot via LongDecimal
      return LongDecimalQuot(other.to_ld.to_r, scale), self

    elsif other.kind_of? BigDecimal then
      # for BigDecimal, convert self to BigDecimal as well
      s, o = other.coerce(self.to_bd)

    elsif other.kind_of? Numeric then
      # for all other numeric types convert self to Float.  This may
      # not work, if numerator and denominator have too many digits to
      # be expressed as Float and it may cause loss of information.
      s, o = other.coerce(self.to_f)
      return o, s

    else
      # non-numeric types do not work at all
      raise TypeError, "unsupported type #{other.inspect} for coerce of LongDecimalQuot"
    end

  end # coerce

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
  # check if the number expressed by self is 0 (zero)
  # with any number of 0s after the decimal point.
  #
  def zero?
    @rat.zero?
  end

  #
  # check if the number expressed by self is 1 (one)
  # with any number of 0s after the decimal point.
  #
  def one?
    (@rat == 1)
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
  # optional first argument gives the precision for the desired result
  # optional second argument gives the rouding mode
  #
  def to_ld(prec = nil, mode = LongDecimal::ROUND_HALF_UP)
    l = LongDecimal(self)
    if (prec.nil?)
      return l
    else
      return l.round_to_scale(prec, mode)
    end
  end

  #
  # test if 1 (like zero?)
  #
  def one?
    (self - 1).zero?
  end

end # Numeric

class Rational

  #
  # convert self to LongDecimal.
  # Special handling of Rational to avoid loosing information in the
  # first step that would be needed for the second step
  # optional first argument gives the precision for the desired result
  # optional second argument gives the rouding mode
  #
  def to_ld(prec = nil, mode = LongDecimal::ROUND_HALF_UP)
    if (prec.nil?)
      return LongDecimal(self)
    else
      l = LongDecimalQuot(self, prec)
      return l.round_to_scale(prec, mode)
    end
  end

end # Rational

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

  @@cache = {}

  CacheKey = Struct.new(:fname, :arg, :mode)

  #
  # used as key to store an already calculated value for any triplet
  # of function name (fname), argument (arg, typically 2, 3, 5, 10 or
  # so) and internal rounding mode (mode)
  #
  class CacheKey
    include Comparable

    #
    # introduce some ordering for cache keys
    #
    def <=>(o)
      r = 0
      if o.respond_to?:fname
        r = self.fname <=> o.fname
      else
        r = self.fname <=> o
      end
      return r if (r != 0)
      if o.respond_to?:arg
        r = self.arg <=> o.arg
      else
        r = self.arg <=> o
      end
      return r if (r != 0)
      if o.respond_to?:mode
        r = self.mode <=> o.mode
      else
        r = self.mode <=> o
      end
      return r
    end

  end

  private

  #
  # check if arg is allowed for caching
  # if true, return key for caching
  # else return nil
  #
  def LongMath.get_cache_key(fname, arg, mode, allowed_args)
    key = nil
    if (arg.kind_of? Integer) || (arg.kind_of? LongDecimalBase) && arg.is_int? then
      arg = arg.to_i
      unless (allowed_args.index(arg).nil?)
        key = CacheKey.new(fname, arg, mode)
      end
    end
    return key
  end

  #
  # get a cached value, if available in the required precision
  #
  def LongMath.get_cached(key, arg, iprec)

    val = nil
    if key.nil? then
      return nil
    end
    val = @@cache[key]
    if val.nil? || val.scale < iprec then
      return nil
    end
    return val
  end

  #
  # helper method for the check of type
  #
  def LongMath.check_cacheable(x, s="x")
    raise TypeError, "#{s}=#{x} must be LongDecimal or Array of LongDecimal" unless (x.kind_of? LongDecimal) || (x.kind_of? Array) && (x[0].kind_of? LongDecimal)
  end


  #
  # store new value in cache, if it provides an improvement of
  # precision
  #
  def LongMath.set_cached(key, val)
    unless key.nil? || val.nil?
      oval = @@cache[key]
      unless (oval.nil?)
        check_cacheable(val, "val")
        check_cacheable(oval, "oval")
        if (val.scale <= oval.scale)
          return
        end
      end
      @@cache[key] = val
    end
  end

  public

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
        if (r < 0) then
          was_negative = true
          q = q-1
        else
          q = q+1
        end
        j += 1
        if (j > 10) then
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
  end # multiplicity_of_factor

  #
  # how many times can n be divided by 10?
  #
  def LongMath.multiplicity_of_10(n)
    mul_2  = LongMath.multiplicity_of_factor(n, 2)
    mul_5  = LongMath.multiplicity_of_factor(n, 5)
    [mul_2, mul_5].min
  end


  #
  # find number of digits in base 10 needed to express the given
  # number n
  #
  def LongMath.int_digits10(n)

    n = n.abs
    if n.zero? then
      return 0
    end

    id = 1
    powers = []
    power  = 10
    idx    = 0
    until n.zero? do
      expon       = 1 << idx
      powers[idx] = power
      break if n < power
      id += expon
      n = (n / power).to_i
      idx += 1
      power = power * power
    end

    until n < 10 do
      idx -= 1
      expon = 1 << idx
      power = powers[idx]
      while n >= power
        id += expon
        n = (n / power).to_i
      end
    end
    return id
  end # int_digits10

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
  # parameters
  # prec precision of the end result
  # final_mode rounding mode to be used when creating the end result
  # iprec precision used internally
  # mode rounding_mode used internally
  # cache_result should the result be cached?  Set to false, if an
  # extraordinary long result is really needed only once
  #
  def LongMath.pi(prec, final_mode = LongDecimal::ROUND_HALF_DOWN, iprec = nil, mode = nil, cache_result = true)

    check_is_prec(prec, "prec")
    if (mode.nil?)
      mode  = LongDecimal::ROUND_HALF_DOWN
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    # calculate internal precision
    if (iprec.nil?)
      iprec = 5*(prec+1)
    end
    check_is_prec(iprec, "iprec")
    sprec = (iprec >> 1) + 1
    dprec = (prec+1) << 1

    # use caching so that pi is only calculated again if it has not
    # been done at least with the required precision
    cache_key = get_cache_key("pi", 0, mode, [0])
    curr_pi   = get_cached(cache_key, 0, sprec)
    if curr_pi.nil? then

      a = LongDecimal(1)
      b = (1 / LongDecimal(2).sqrt(iprec,mode)).round_to_scale(iprec, mode)
      c = LongDecimal(5,1)
      k = 1
      pow_k = 2

      curr_pi = 0
      last_pi = 0
      last_diff = 1

      loop do
        a, b    = ((a + b) / 2).round_to_scale(sprec, mode), (a * b).round_to_scale(iprec, mode).sqrt(sprec, mode)
        c       = (c - pow_k * (a * a - b * b)).round_to_scale(iprec, mode)
        curr_pi = (2 * a * a / c).round_to_scale(sprec, mode)
        diff = (curr_pi - last_pi).round_to_scale(dprec, mode).abs
        if (diff.zero? && last_diff.zero?) then
          break
        end
        last_pi   = curr_pi
        last_diff = diff
        k += 1
        pow_k = pow_k << 1
      end
      set_cached(cache_key, curr_pi) if cache_result
    end
    curr_pi.round_to_scale(prec, final_mode)
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
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_EXP_ABLE}" unless x <= MAX_EXP_ABLE
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    exp_internal(x, prec, mode)
  end

  #
  # calc the base-2-exponential function of x to the given precision as
  # LongDecimal.  Only supports values of x such that the result still
  # fits into a float (x <= 709).  This limitation is somewhat
  # arbitrary, but it is enforced in order to avoid producing numbers
  # with the exponential function that exceed the memory.
  #
  def LongMath.exp2(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    LongMath.power(2, x, prec, mode)
  end

  #
  # calc the base-10-exponential function of x to the given precision as
  # LongDecimal.  Only supports values of x such that the result still
  # fits into a float (x <= 709).  This limitation is somewhat
  # arbitrary, but it is enforced in order to avoid producing numbers
  # with the exponential function that exceed the memory.
  #
  def LongMath.exp10(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    LongMath.power(10, x, prec, mode)
  end

  private

  #
  # private helper method for exponentiation
  # calculate internal precision
  #
  def LongMath.calc_iprec_for_exp(x, prec, x_was_neg)
    iprec_extra = 0
    if (x > 1) then
      xf = x.to_f
      iprec_extra = (xf / LOG10).abs
    end
    iprec = ((prec+12) * 1.20 + iprec_extra * 1.10).round
    # iprec = ((prec+15) * 1.20 + iprec_extra * 1.10).round
    # iprec = ((prec+10) * 1.20 + iprec_extra * 1.10).round
    # iprec = ((prec+10)*1.20 + iprec_extra).round
    # iprec = ((prec+10)*1.20 + iprec_extra*1.20).round
    # puts("calc_iprec_for_exp: iprec=#{iprec} iprec_extra=#{iprec_extra}\n")
    if (iprec < prec) then
      iprec = prec
    end
    if (x_was_neg)
      iprec += 2
    end
    iprec
  end

  public

  #
  # internal functionality of exp.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing exp.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.exp_internal(x, prec = nil, final_mode = LongDecimal::ROUND_HALF_DOWN, j = nil, k = nil, iprec = nil, mode = LongDecimal::ROUND_HALF_DOWN, cache_result = true)

    if (prec == nil) then
      if (x.kind_of? LongDecimalBase)
        prec = x.scale
      else
        raise ArgumentError, "precision must be supplied either as precision of x=#{x} or explicitely"
      end
    end
    check_is_prec(prec, "prec")

    if (final_mode == nil)
      final_mode = LongDecimal::ROUND_HALF_DOWN
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    # if the result would come out to zero anyway, cut the work
    xi = x.to_i
    if (xi < -LongMath::MAX_FLOATABLE) || -((xi.to_f - 1) / LOG10) > prec+10 then
      return LongDecimal(25, prec+2).round_to_scale(prec, final_mode)
    end
    x_was_neg = false
    if (x < 0) then
      x = -x
      x_was_neg = true
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
      iprec = calc_iprec_for_exp(x, prec, x_was_neg)
    end
    check_is_prec(iprec, "iprec")

    # we only cache exp(1)
    cache_key = get_cache_key("exp", x, mode, [1, 10, 100, MAX_EXP_ABLE.to_i])
    y_k = get_cached(cache_key, x, iprec)

    if (y_k.nil?) then
      y_k = exp_raw(x, prec, j, k, iprec, mode)

      # keep result around for exp(1)
      set_cached(cache_key, y_k) if (cache_result)
    end
    if (x_was_neg)
      y_k = y_k.reciprocal
    end
    y = y_k.round_to_scale(prec, final_mode)
    y

  end # exp_internal

  #
  # calculation of exp(x) with precision used internally.  Needs to be
  # rounded to be accurate to all digits that are provided.
  #
  def LongMath.exp_raw(x, prec, j, k, iprec, mode)
    # dprec = [ (iprec*0.9).round , (prec + 1) << 1 ].min
    dprec = [ (iprec*0.9).round, prec ].max
    # puts("prec=#{prec} dprec=#{dprec} iprec=#{iprec}")

    unless (x.kind_of? LongDecimal)
      x = x.to_ld(iprec, mode)
    end

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
      y_k += (s[i] * x_i).round_to_scale(iprec, mode)
    end
    k.times do |i|
      y_k = y_k.square.round_to_scale(iprec, mode)
    end

    y_k
  end # exp_raw

  #
  # calculate approximation of sqrt of a LongDecimal.
  #
  def LongMath.sqrt(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    LongMath.sqrt_internal(x, prec, mode, false)
  end

  #
  # calculate approximation of sqrt of a LongDecimal with remainder
  #
  def LongMath.sqrt_with_remainder(x, prec)
    LongMath.sqrt_internal(x, prec, ROUND_DOWN, true)
  end

  private

  #
  # internal helper method for calculationg sqrt and sqrt_with_remainder
  #
  def LongMath.sqrt_internal(x, prec, mode, with_rem, cache_result = true)
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    unless (x.kind_of? LongDecimal)
      x = x.to_ld(2 * (prec+1), mode)
    end
    prec1 = prec
    unless (with_rem) then
      prec1 += 1
    end
    cache_key = nil
    unless (with_rem)
      cache_key = get_cache_key("sqrt", x, mode, [2, 3, 5, 6, 7, 8, 10])
      y_arr = get_cached(cache_key, x, prec)
    end
    if (y_arr.nil?) then
      y_arr = sqrt_raw(x, prec1, mode)
      def y_arr.scale
        self[0].scale
      end
      set_cached(cache_key, y_arr) if cache_result
    end
    if (with_rem) then
      return y_arr
    else
      y, r = y_arr
      if ((mode == ROUND_HALF_EVEN || mode == ROUND_HALF_DOWN) && r > 0) then
        mode = ROUND_HALF_UP
      end
      y = y.round_to_scale(prec, mode)
      return y
    end
  end

  #
  # calculate sqrt with remainder uncached
  #
  def LongMath.sqrt_raw(x, new_scale1, rounding_mode)
    old_scale  = (new_scale1 << 1)
    x = x.round_to_scale(old_scale, rounding_mode)
    root, rem = LongMath.sqrtw_with_remainder(x.int_val)
    y = LongDecimal(root, new_scale1)
    r = LongDecimal(rem, old_scale)
    return [y, r]
  end

  public

  #
  # calculate the natural logarithm function of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)
    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    log_internal(x, prec, mode)
  end

  #
  # calculate the base 10 logarithm of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log10(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)

    check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    iprec = prec + 5
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
  def LongMath.log2(x, prec, mode = LongDecimal::ROUND_HALF_DOWN)

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
  # internal functionality of log.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing log.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.log_internal(x, prec = nil, final_mode = LongDecimal::ROUND_HALF_DOWN, iprec = nil, mode = LongDecimal::ROUND_HALF_DOWN, cache_result = true)

    raise TypeError, "x=#{x.inspect} must not be positive" unless x > 0
    if (prec == nil) then
      if (x.kind_of? LongDecimalBase)
        prec = x.scale
      else
        raise ArgumentError, "precision must be supplied either as precision of x=#{x} or explicitely"
      end
    end
    check_is_prec(prec, "prec")

    if (final_mode == nil)
      final_mode = LongDecimal::ROUND_HALF_DOWN
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    if (iprec == nil) then
      # iprec = ((prec+10)*1.20).round
      iprec = ((prec+12)*1.20).round
    end
    if (iprec < prec) then
      iprec = prec
    end
    check_is_prec(iprec, "iprec")
    unless (x.kind_of? LongDecimal)
      x = x.to_ld(iprec, mode)
    end
    if (x.one?) then
      return LongDecimal.zero!(prec)
    end

    cache_key = get_cache_key("log", x, mode, [2, 3, 5, 10])
    y = get_cached(cache_key, x, iprec)
    if (y.nil?)
      y = log_raw(x, prec, iprec, mode)
      set_cached(cache_key, y) if cache_result
    end

    return y.round_to_scale(prec, final_mode)

  end # log_internal

  #
  # calculate log with all digits used internally.
  # result needs to be rounded in order to ensure that all digits that
  # are provided are correct.
  #
  def LongMath.log_raw(x, prec, iprec, mode)

    # t0 = Time.new
    # puts("log_raw start")

    # we have to rely on iprec being at least 10
    raise TypeError, "iprec=#{iprec} out of range" unless (iprec.kind_of? Fixnum) && iprec >= 10

    # dprec = [ iprec - 1, (prec + 1) << 1 ].min
    # dprec >= 9
    dprec = iprec - 1

    # result is stored in y
    y = 0
    # sign of result
    s = 1
    # make sure x is >= 1
    if (x < 1) then
      x = (1 / x).round_to_scale(iprec, mode)
      s = -1
    end
    # puts("log_raw prepared t=#{Time.new-t0}")

    # number that are beyond the usual range of Float need to be
    # handled specially to reduce to something expressable as Float
    exp_keys = [ MAX_EXP_ABLE.to_i, 100, 10, 1 ]
    exp_keys.each do |exp_key|
      exp_val = exp(exp_key, iprec)
      while (x > exp_val) do
        x = (x / exp_val).round_to_scale(iprec, mode)
        if (s < 0) then
          y -= exp_key
        else
          y += exp_key
        end
      end
    end

    factor = 1
    sprec  = (iprec * 1.5).round
    # delta  = LongDecimal(1, (iprec.to_f**(1/3)).round)
    # delta  = LongDecimal(1, (iprec.to_f**0.3).round)
    delta  = LongDecimal(1, (iprec.to_f**0.45).round)
    # delta  = LongDecimal(1, LongMath.sqrtw(iprec))
    # delta  = LongDecimal(1, LongMath.sqrtw(LongMath.sqrtw(iprec+1)+1))
    while (x - 1).abs > delta do
      x       = LongMath.sqrt(x, sprec, mode)
      factor *= 2
    end

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

    end

    y -= ((s * factor) * sum).round_to_scale(iprec, mode)
    return y
  end

  private

  #
  # internal helper method for calculating the internal precision for power
  #
  def LongMath.calc_iprec_for_power(x, y, prec)
    x_f = x.to_f
    y_f = y.to_f
    logx_f   = Math.log(x_f.abs)
    logy_f   = Math.log(y_f.abs)
    logx_y_f = logx_f * y_f
    iprec_x  = calc_iprec_for_exp(logx_y_f, prec, logx_y_f < 0)
    # iprec_x  = calc_iprec_for_exp(logx_y_f, prec, logx_y_f < 0) + 10
    iprec_y  = iprec_x
    iprec    = iprec_x + 2
    if (logx_f < 0)
      iprec_x -= (logx_f/LOG10).round
    end
    if (logy_f < 0)
      iprec_y -= (logy_f/LOG10).round
    end
    [ iprec, iprec_x, iprec_y ]

  end

  public

  #
  # calc the power of x with exponent y to the given precision as
  # LongDecimal.  Only supports values of y such that exp(y) still
  # fits into a float (y <= 709)
  #
  def LongMath.power(x, y, prec, mode = LongDecimal::ROUND_HALF_DOWN)

    raise TypeError, "x=#{x} must be numeric" unless x.kind_of? Numeric
    raise TypeError, "y=#{y} must be numeric" unless y.kind_of? Numeric
    # raise TypeError, "y=#{y.inspect} must not be greater #{MAX_EXP_ABLE}" unless y <= MAX_EXP_ABLE
    # raise TypeError, "x=#{x.inspect} must not be greater #{MAX_FLOATABLE}" unless x <= MAX_FLOATABLE
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

    iprec, iprec_x, iprec_y = calc_iprec_for_power(x, y, prec)

    unless (x.kind_of? LongDecimalBase) || (x.kind_of? Integer)
      x = x.to_ld(iprec_x, mode)
    end
    unless (y.kind_of? LongDecimalBase) || (y.kind_of? Integer)
      y = y.to_ld(iprec_y, mode)
    end

    # try shortcut if exponent is an integer
    if (y.kind_of? LongDecimalBase) && y.is_int?
      y = y.to_i
    end
    if (y.kind_of? Integer)
      unless x.kind_of? LongDecimal
        # x = x.to_ld(prec)
        x = x.to_ld(iprec_x)
      end
      z = x**y
      return z.to_ld(prec, mode)
    end

    # it can be assumed that the exponent is not an integer, so it should
    # be converted into LongDecimal
    unless (y.kind_of? LongDecimal)
      # y = y.to_ld(prec, mode)
      y = y.to_ld(iprec_y, mode)
    end

    # exponent is split in two parts, an integer part and a
    # LongDecimal with absolute value <= 0.5
    y0 = y.round_to_scale(0, LongDecimal::ROUND_HALF_UP).to_i
    z0 = x**y0
    y1 = y - y0
    prec_extra = 0
    if (y0 > 0)
      prec_extra = (y0*Math.log10(x.to_f).abs).ceil
    end
    # z1 = LongMath.power_internal(x, y1, prec+prec_extra , mode)
    z1 = LongMath.power_internal(x, y1, prec+prec_extra + 3, mode)
    z  = z0 * z1
    return z.to_ld(prec, mode)
  end

  #
  # internal functionality of exp.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing exp.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.power_internal(x, y, prec = nil, final_mode = LongDecimal::ROUND_HALF_DOWN, iprec = nil, mode = LongDecimal::ROUND_HALF_DOWN)

    if (prec == nil) then
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

    if (final_mode == nil)
      final_mode = LongDecimal::ROUND_HALF_DOWN
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    if y.zero? then
      return LongDecimal.one!(prec)
    elsif x.zero? then
      return LongDecimal.zero!(prec)
    end

    if (iprec == nil) then
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

# end of file long-decimal.rb
