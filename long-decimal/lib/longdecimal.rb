#
# longdecimal.rb -- Arbitrary precision decimals with fixed decimal point
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/lib/longdecimal.rb,v 1.4 2006/03/02 20:20:12 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_08 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#
require "complex"
require "rational"
require "bigdecimal"

# require "bigdecimal/math"

#
# helper functions to support LongDecimal and LongDecimalQuot
# functions for LongDecimal that do not go as methods of LongDecimal
#
module LongMath

  MAX_FLOATABLE = Float::MAX.to_i
  MIN_FLOATABLE = Float::MIN.to_i

  #
  # helper method: checks if word_len is of reasonable for splitting a
  # number into parts
  #
  def LongMath.check_word_len(word_len)
    raise TypeError, "word_len must be a positive number <= 1024" unless (word_len.kind_of? Fixnum) && word_len > 0 && word_len <= 1024
    word_len
  end

  # private :check_word_len

  #
  # split number x into parts of word_len bits each
  # such that the concatenation of these parts as bit patterns is x
  #
  def LongMath.split_to_words(x, word_len = 32)
    check_word_len(word_len)
    raise TypeError, "x must be Integer" unless x.kind_of? Integer
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
  # calculate the square root of an integer using bitwise algorithm
  #
  def LongMath.sqrtb(x)
    a = sqrtb_with_remainder(x)
    a[0]
  end

  def LongMath.sqrtb_with_remainder(x)
    raise TypeError, "x must be integer" unless x.kind_of? Integer

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
  # calculate the square root of an integer using larger chunks of the number
  #
  def LongMath.sqrtw(x, n = 16)
    a = sqrtw_with_remainder(x, n)
    a[0]
  end

  def LongMath.sqrtw_with_remainder(x, n = 16)
    raise TypeError, "x must be integer" unless x.kind_of? Integer
    raise TypeError, "n must be an integer" unless (n.kind_of? Integer)
    n2 = n<<1
    n1 = n+1
    check_word_len(n2)

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
          puts("i=#{i} j=#{j} q=#{q} q0=#{q0} d0=#{d0} d=#{d} r=#{r} yi=#{yi} xi=#{xi}\n")
          break
        end
      end
      xi = r
      yi = (yi << n) + q
    end
    return [ yi, xi ]
  end

  #
  # find the gcd of x with b^n0 where n0 is a sufficiently high
  # exponent such that gcd(x, b^m) = gcd(x, b^n)
  # for all m, n > n0
  #
  def LongMath.gcd_with_high_power(x, b)
    raise TypeError, "gcd_with_high_power can only be calculated for integers, but x=#{x.inspect} is no integer." unless x.kind_of? Integer
    raise ZeroDivisionError, "gcd_with_high_power of zero with \"#{b.inspect}\" would be infinity" if x.zero?
    raise TypeError, "gcd_with_high_power can only be calculated for integers \"#{b.inspect}\" is no integer" unless b.kind_of? Integer
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
  # find the exponent of the highest power of prime number p that divides
  # self.  Only works for prime numbers
  # works even for numbers that exceed the range of Float
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
  # decimal point
  # works fine for 1000 or 2000 digits or so.
  # this method could be optimized more, but if you really want to go
  # for more digits, you will find a specialized and optimized program
  # for this specific purpose.
  # (this is the easter egg ;-) )
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
# these can be considered as a pair of two integer.  One contains the
# digits and the other one the position of the decimal point.
#
class LongDecimal < Numeric
  @RCS_ID='-$Id: longdecimal.rb,v 1.4 2006/03/02 20:20:12 bk1 Exp $-'

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
    new(1, s)
  end


  #
  # creates a LongDecimal representing two with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.two!(s = 0)
    new(2, s)
  end


  #
  # creates a LongDecimal representing ten with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.ten!(s = 0)
    new(10, s)
  end


  #
  # creates a LongDecimal representing minus one with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.minus_one!(s = 0)
    new(-1, s)
  end


  #
  # creates a LongDecimal representing a power of ten with the given
  # exponent e and with the given number of digits after the decimal
  # point (scale=s)
  #
  def LongDecimal.power_of_ten!(e, s = 0)
    new(10**e, s)
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

  #
  # get the integer value of self, disregarding the decimal point.
  # Mostly for internal use.
  #
  def int_val
    @int_val
  end

  #
  # get the scale, i.e. the position of the decimal point.
  # Mostly for internal use.
  #
  def scale
    @scale
  end

  #
  # alter scale
  # only for internal use.
  # changes self
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

  #
  # convert self into String, which is the decimal representation.
  # Use trailing zeros, if int_val has them.
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
      p(quot)
      rounded = quot.round_to_scale(0, mode)
      p(rounded)
      rounded.to_s_internal(base, shown_scale)
    end
  end

  def to_s_10
    to_s_internal(10, scale)
  end

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
    Rational(@int_val, 10**@scale)
  end

  #
  # convert self into Float
  # this works straitforward by dividing int_val by power of 10 in
  # float-arithmetic.
  #
  def to_f
    int_val.to_f / 10**scale
  end

  #
  # convert self into Integer
  # This may loose information.  In most cases it is preferred to
  # control this by calling round_to_scale first and then applying
  # to_i when the number represented by self is actually an integer.
  #
  def to_i
    to_r.to_i
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
  # method is included, returning 10**scale
  #
  def denominator
    10**scale
  end

  #
  # LongDecimals can be seen as a fraction with its int_val as its
  # numerator
  #
  alias numerator int_val

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
  # successor for ranges
  #
  def succ
    LongDecimal(int_val + 1, scale)
  end

  alias next succ

  #
  # predecessor
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

  def divide(other, rounding_mode)
    divide_s(other, nil, rounding_mode)
  end

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

  def rdiv(other)
    q = self / other
    if (q.kind_of? LongDecimalQuot) || (q.kind_of? LongDecimalQuot) then
      r.to_r
    else
      q
    end
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
        other = other.to_f
      end
      self.to_f ** other
    end
  end

  def divmod(other)
    if (other.kind_of? Complex) then
      raise TypeError, "divmod not supported for Complex"
    end
    q = (self / other).to_i
    return q, self - other * q
  end

  def %(other)
    q, r = divmod other
    r
  end

  #
  # performs bitwise AND between self and Numeric
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
  # performs bitwise OR between self and Numeric
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
  # performs bitwise XOR between self and Numeric
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
  # performs bitwise left shift of self by Numeric
  #
  def <<(other)
    unless (other.kind_of? Integer) && other >= 0 then
      raise TypeError, "cannot shift by something other than integer >= 0"
    end
    LongDecimal(s.int_val << other, s.scale)
  end

  #
  # performs bitwise right shift of self by Numeric
  #
  def >>(other)
    unless (other.kind_of? Integer) && other >= 0 then
      raise TypeError, "cannot shift by something other than integer >= 0"
    end
    LongDecimal(s.int_val >> other, s.scale)
  end

  #
  # gets binary digit
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
  # divide by 10**n
  #
  def move_point_left_int(n)
    raise TypeError, "only implemented for Fixnum >= 0" unless n >= 0
    LongDecimal(int_val, scale + n)
  end

  #
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

  def sqrt(new_scale, rounding_mode)
    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless rounding_mode.kind_of? RoundingModeClass

    new_scale1 = new_scale + 1
    old_scale  = (new_scale1 << 1)
    x = round_to_scale(old_scale, rounding_mode)
    root, rem = LongMath.sqrtb_with_remainder(x.int_val)
    if (rem > 0 && (rounding_mode == ROUND_HALF_EVEN || rounding_mode == ROUND_HALF_DOWN)) then
      rounding_mode = ROUND_HALF_UP
    end
    y = LongDecimal(root, new_scale1)
    y.round_to_scale(new_scale, rounding_mode)
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
    LongDecimal(int_val.abs, scale)
  end

  #
  # square of absolute value
  #
  def abs2
    self.abs.square
  end

  #
  # Compares the absolute values of the two numbers.
  #
  def <=> (other)
    diff = (self - other)
    if (diff.kind_of? LongDecimal) || (diff.kind_of? LongDecimalQuot) then
      diff.sgn
    else
      diff <=> 0
    end
  end

  def scale_ufo(other)
    raise TypeError, "only works for LongDecimal and LongDecimalQuot" unless (other.kind_of? LongDecimal) || (other.kind_of? LongDecimalQuot)
    self.scale <=> other.scale
  end

  def scale_equal(other)
    scale_ufo(other).zero?
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
      if (other.scale > scale) then
        other = other.round_to_scale(scale, ROUND_HALF_UP)
      end
      return other, self
    elsif other.kind_of? BigDecimal then
      s, o = other.coerce(self.to_bd)
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

  # is self expressable as an integer without loss of digits?
  def is_int?
    scale == 0 || int_val % 10**scale == 0
  end

  def sgn
    int_val <=> 0
  end
  alias signum sgn
  alias sign   sgn

  def ==(other)
    (other.kind_of? LongDecimal) && (self <=> other) == 0 && self.scale == other.scale
  end

  def zero?
    int_val.zero?
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
class LongDecimalQuot < Numeric

  @RCS_ID='-$Id: longdecimal.rb,v 1.4 2006/03/02 20:20:12 bk1 Exp $-'

  include LongDecimalRoundingMode

  def LongDecimalQuot.new!(first, second)
    new(first, second)
  end

  #
  # create a new LongDecimalQuot from a rational and a scale or a
  # pair of LongDecimals
  def initialize(first, second)
    if (first.kind_of? Rational) && (second.kind_of? Integer) then
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


  def scale
    @scale
  end

  def rat
    @rat
  end

  def numerator
    rat.numerator
  end

  def denominator
    rat.denominator
  end

  # alter scale
  def scale=(s)
    raise TypeError, "non integer arg \"#{s.inspect}\"" if ! s.kind_of? Integer
    raise TypeError, "negative arg \"#{s.inspect}\""    if s < 0
    @scale = s
  end

  private :scale=

  def to_s
    str = @rat.to_s
    str + "[" + scale.to_s + "]"
  end

  def to_r
    Rational(numerator, denominator)
  end

  # convert into Float
  def to_f
    to_r.to_f
  end

  # convert into Integer
  def to_i
    to_r.to_i
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
      LongDecimalQuot(-rat, scale)
    end
  end

  def +(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat + o.rat, [s.scale, o.scale].max)
    else
      s + o
    end
  end

  def -(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat - o.rat, [s.scale, o.scale].max)
    else
      s - o
    end
  end

  def *(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat * o.rat, s.scale + o.scale)
    else
      s * o
    end
  end

  def /(other)
    o, s = coerce(other)
    if (s.kind_of? LongDecimalQuot) then
      LongDecimalQuot(s.rat / o.rat, scale)
    else
      s / o
    end
  end

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

  def divmod(other)
    if (other.kind_of? Complex) then
      raise TypeError, "divmod not supported for Complex"
    end
    q = (self / other).to_i
    return q, self - other * q
  end

  def %(other)
    q, r = divmod other
    r
  end

#   def %(other)
#     o, s = coerce(other)
#     if (s.kind_of? LongDecimalQuot) then
#       LongDecimalQuot(s.rat % o.rat, scale)
#     else
#       s % o
#     end
#   end

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

  def ==(other)
    (other.kind_of? LongDecimalQuot) && (self <=> other) == 0 && self.scale == other.scale
  end

  #
  # Compares the two numbers.
  #
  def <=> (other)
    diff = (self - other)
    if (diff.kind_of? LongDecimal) || (diff.kind_of? LongDecimalQuot) then
      diff.sgn
    else
      diff <=> 0
    end
  end

  def scale_ufo(other)
    raise TypeError, "only works for LongDecimal and LongDecimalQuot" unless (other.kind_of? LongDecimal) || (other.kind_of? LongDecimalQuot)
    self.scale <=> other.scale
  end

  def scale_equal(other)
    scale_ufo(other).zero?
  end

  # is self expressable as an integer without loss of digits?
  def is_int?
    denominator == 1
  end

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


  def scale
    @scale
  end


  #
  # Returns "<tt>LongDecimalQuot(<i>int_val</i>, <i>scale</i>, <i>num</i>, <i>denom</i>)</tt>".
  #
  def inspect
    sprintf("LongDecimalQuot(Rational(%s, %s), %s)", numerator.inspect, denominator.inspect, scale.inspect)
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

# end of file longdecimal.rb
