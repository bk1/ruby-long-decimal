# frozen_string_literal: true

#
# long-decimal.rb -- Arbitrary precision decimals with fixed decimal point
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2018
#
# This class contains the basic functionality for working with LongDecimal
# additional functionality, mostly transcendental functions,
# may be found in long-decimal-extra.rb
#
# TAG:       $TAG v1.00.04$
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require 'bigdecimal'

# require "bigdecimal/math"

BYTE_SIZE_OF_ONE = 1.size

# one bit is used as marker, so only 31 bits 2s-complement 2**30-1
MAX_32BIT_FIXNUM = 1_073_741_823

#
# define rounding modes to be used for LongDecimal
# this serves the purpose of an "enum" in C/C++/Java
#
module LongDecimalRoundingMode
  RoundingMinorMode = Struct.new(:name, :part)

  # exactly on the boundary round away from zero
  MINOR_UP = RoundingMinorMode.new(:MINOR_UP, :_UP)
  # exactly on the boundary round towards zero
  MINOR_DOWN = RoundingMinorMode.new(:MINOR_DOWN, :_DOWN)
  # exactly on the boundary round towards positive infinitiy (to the higher of the two possible values)
  MINOR_CEILING = RoundingMinorMode.new(:MINOR_CEILING, :_CEILING)
  # exactly on the boundary round towards negative infinitiy (to the lower of the two possible values)
  MINOR_FLOOR = RoundingMinorMode.new(:MINOR_FLOOR, :_FLOOR)
  # exactly on the boundary pick the one with even end digit
  MINOR_EVEN = RoundingMinorMode.new(:MINOR_EVEN, :_EVEN)
  # exactly on the boundary pick the one with even end digit
  MINOR_ODD = RoundingMinorMode.new(:MINOR_ODD, :_ODD)
  # (away from zero if last digit after rounding towards zero would have been 0 or 5; otherwise towards zero)
  # MINOR_05UP = RoundingMinorMode.new(:MINOR_05UP, :_05UP)
  # for major modes that are completely defined by themselves and do not need to rely on minor modes for the boundary stuff
  MINOR_UNUSED = RoundingMinorMode.new(:MINOR_UNUSED, '')

  ALL_MINOR = [MINOR_UP, MINOR_DOWN, MINOR_CEILING, MINOR_FLOOR, MINOR_EVEN, MINOR_ODD].freeze
  # puts(ALL_MINOR)
  # puts

  NO_MINOR = [MINOR_UNUSED].freeze

  # which mode is to be used instead when we do an multiplicative inversion?
  MUL_INVERSE_MINOR_MODE = {
    MINOR_UNUSED => MINOR_UNUSED,
    MINOR_UP => MINOR_DOWN,
    MINOR_DOWN => MINOR_UP,
    MINOR_CEILING => MINOR_FLOOR,
    MINOR_FLOOR => MINOR_CEILING,
    MINOR_EVEN => MINOR_EVEN,
    MINOR_ODD => MINOR_ODD
  }.freeze

  # which mode is to be used instead when we do an additive inversion?
  ADD_INVERSE_MINOR_MODE = {
    MINOR_UNUSED => MINOR_UNUSED,
    MINOR_UP => MINOR_UP,
    MINOR_DOWN => MINOR_DOWN,
    MINOR_CEILING => MINOR_FLOOR,
    MINOR_FLOOR => MINOR_CEILING,
    MINOR_EVEN => MINOR_EVEN,
    MINOR_ODD => MINOR_ODD
  }.freeze

  RoundingMajorMode = Struct.new(:name, :part, :minor)

  # round away from zero
  MAJOR_UP = RoundingMajorMode.new(:MAJOR_UP, :UP, NO_MINOR)
  # round towards zero
  MAJOR_DOWN = RoundingMajorMode.new(:MAJOR_DOWN, :DOWN, NO_MINOR)
  # pick the higher of the two possible values
  MAJOR_CEILING = RoundingMajorMode.new(:MAJOR_CEILING, :CEILING, NO_MINOR)
  # pick the lower of the two possible values
  MAJOR_FLOOR = RoundingMajorMode.new(:MAJOR_FLOOR, :FLOOR, NO_MINOR)
  # use the original value, if it is not already rounded, raise an error
  MAJOR_UNNECESSARY = RoundingMajorMode.new(:MAJOR_UNNECESSARY, :UNNECESSARY, NO_MINOR)
  # (away from zero if last digit after rounding towards zero would have been 0 or 5; otherwise towards zero)
  MAJOR_05UP        = RoundingMajorMode.new(:MAJOR_05UP, :_05UP, NO_MINOR)

  # the arithmetic mean of two adjacent rounded values is the boundary
  MAJOR_HALF = RoundingMajorMode.new(:MAJOR_HALF, :HALF, ALL_MINOR)
  # the arithmetic mean of two adjacent rounded values is the boundary
  MAJOR_GEOMETRIC = RoundingMajorMode.new(:MAJOR_GEOMETRIC, :GEOMETRIC, ALL_MINOR)
  # the harmonic mean of two adjacent rounded values is the boundary
  MAJOR_HARMONIC = RoundingMajorMode.new(:MAJOR_HARMONIC, :HARMONIC, ALL_MINOR)
  # the quadratic mean of two adjacent rounded values is the boundary
  MAJOR_QUADRATIC = RoundingMajorMode.new(:MAJOR_QUADRATIC, :QUADRATIC, ALL_MINOR)
  # the cubic mean of two adjacent rounded values is the boundary
  MAJOR_CUBIC = RoundingMajorMode.new(:MAJOR_CUBIC, :CUBIC, ALL_MINOR)

  ALL_MAJOR_MODES = [MAJOR_UP, MAJOR_DOWN, MAJOR_CEILING, MAJOR_FLOOR, MAJOR_UNNECESSARY,
                     MAJOR_05UP, MAJOR_HALF, MAJOR_GEOMETRIC, MAJOR_HARMONIC, MAJOR_QUADRATIC, MAJOR_CUBIC].freeze

  # puts("ALL_MAJOR_MODES:")
  # puts(ALL_MAJOR_MODES)
  # puts

  MUL_INVERSE_MAJOR_MODE = {
    MAJOR_UP => MAJOR_DOWN,
    MAJOR_DOWN => MAJOR_UP,
    MAJOR_CEILING => MAJOR_FLOOR,
    MAJOR_FLOOR => MAJOR_CEILING,
    MAJOR_05UP => MAJOR_05UP,
    MAJOR_HALF => MAJOR_HALF,
    MAJOR_UNNECESSARY => MAJOR_UNNECESSARY
  }.freeze

  # which mode is to be used instead when we do an additive inversion?
  ADD_INVERSE_MAJOR_MODE = {
    MAJOR_UP => MAJOR_UP,
    MAJOR_DOWN => MAJOR_DOWN,
    MAJOR_CEILING => MAJOR_FLOOR,
    MAJOR_FLOOR => MAJOR_CEILING,
    MAJOR_05UP => MAJOR_05UP,
    MAJOR_HALF => MAJOR_HALF,
    MAJOR_UNNECESSARY => MAJOR_UNNECESSARY
  }.freeze

  RoundingModeClass = Struct.new(:name, :major, :minor, :num)

  #
  # enumeration class to express the possible rounding modes that are
  # supported by LongDecimal
  #
  class RoundingModeClass
    include Comparable

    #
    # introduce some ordering for rounding modes
    #
    def <=>(other)
      if other.respond_to? :num
        num <=> other.num
      elsif other.is_a? Numeric
        num <=> other
      else
        puts("stack=#{caller.join("\n")}")
        raise TypeError, "o=#{other.inspect} must be numeric or RoundingMode"
      end
    end

    #
    # inverse mode in terms of multiplication
    #
    def minverse
      LongDecimalRoundingMode::MUL_INVERSE_MODE[self]
    end

    #
    # inverse mode in terms of addition
    #
    def ainverse
      LongDecimalRoundingMode::ADD_INVERSE_MODE[self]
    end

    def rem5(val)
      if val.is_a? Integer
        val % 5
      else
        val.int_val % 5
      end
    end

    # internal use
    # no special checks included
    # we assume: lower <= unrounded <= upper
    # we assume: sign = sgn(unrounded)
    def pick_value(unrounded, sign, lower, upper, even_or_odd)
      if sign.zero? || major == MAJOR_UNNECESSARY
        if lower == unrounded
          return lower
        elsif upper == unrounded
          return upper
        end
      end
      if major == MAJOR_UP && sign.positive?
        return upper
      elsif major == MAJOR_UP && sign.negative?
        return lower
      elsif major == MAJOR_DOWN && sign.positive?
        return lower
      elsif major == MAJOR_DOWN && sign.negative?
        return upper
      elsif major == MAJOR_CEILING
        return upper
      elsif major == MAJOR_FLOOR
        return lower
      elsif major == MAJOR_05UP
        if rem5(upper).zero?
          return upper
        else
          return lower
        end
      elsif major == MAJOR_UNNECESSARY
        raise ArgumentError,
              "rounding #{name} of unrounded=#{unrounded} (sign=#{sign}) is not applicable for lower=#{lower} and upper=#{upper}"
      end

      on_boundary = false
      case major
      when MAJOR_HALF
        d = unrounded - lower <=> upper - unrounded
        if d.negative?
          # unrounded is below half
          return lower
        elsif d.positive?
          # unrounded is below half
          return upper
        else
          on_boundary = true
        end
      when MAJOR_GEOMETRIC
        prod = lower * upper
        if prod.negative?
          raise ArgumentError,
                "geometric rounding #{name} of unrounded=#{unrounded} (sign=#{sign}) is not applicable for lower=#{lower} and upper=#{upper} with different signs"
        elsif prod.zero?
          # lower or upper is 0
          # we only round 0 to 0
          if sign.zero?
            raise ArgumentError,
                  "geometric rounding #{name} of unrounded=#{unrounded} (sign=#{sign}) is not applicable for lower=#{lower} and upper=#{upper} with 0 cannot be decided"
          elsif sign.negative?
            return lower
          else
            return upper
          end
        end

        # now prod > 0
        square = unrounded * unrounded
        d = square <=> prod
        if d.negative?
          # |unrounded| < sqrt(lower*upper)
          if sign.negative?
            # lower < unrounded < upper < 0
            return upper
          else
            # (sign > 0)
            return lower
          end
        elsif d.positive?
          # |unrounded| > sqrt(lower*upper)
          if sign.negative?
            # lower < unrounded < upper < 0
            return lower
          else
            # (sign > 0)
            return upper
          end
        else
          # (d == 0)
          on_boundary = true
        end
      when MAJOR_HARMONIC
        prod = lower * upper
        if prod.negative?
          raise ArgumentError,
                "harmonic rounding #{name} of unrounded=#{unrounded} is not applicable for lower=#{lower} and upper=#{upper} with different signs"
        elsif prod.zero?
          # lower or upper is 0
          # we only round 0 to 0
          if sign.zero?
            raise ArgumentError,
                  "harmonic rounding #{name} of unrounded=#{unrounded} is not applicable for lower=#{lower} and upper=#{upper} with 0 cannot be decided"
          elsif sign.negative?
            return lower
          else
            return upper
          end
        end

        # now prod > 0
        # so either lower < unrounded < upper < 0
        # or 0 < lower < unrounded < upper
        sum = lower + upper
        lhs = unrounded * sum
        rhs = 2 * prod
        d = lhs <=> rhs
        if sign.negative?
          # lower + upper < 0
          d = -d
        end
        if d.negative?
          # unrounded < 2*upper*lower/(upper+lower)
          return lower
        elsif d.positive?
          # unrounded > 2*upper*lower/(upper+lower)
          return upper
        else
          # (d == 0)
          on_boundary = true
        end
      when MAJOR_QUADRATIC
        square = unrounded * unrounded
        lhs = 2 * square
        rhs = (lower * lower) + (upper * upper)
        d = lhs <=> rhs
        if sign.negative?
          # lower <= unrounded <= upper <= 0
          # lower^2 >= unrounded >= upper^2 >= 0
          d = -d
        end
        if d.negative?
          # unrounded < sqrt(...)
          return lower
        elsif d.positive?
          # unrounded > sqrt(...)
          return upper
        else
          # (d == 0)
          on_boundary = true
        end
      when MAJOR_CUBIC
        cube = unrounded**3
        lhs = 2 * cube
        rhs = (lower**3) + (upper**3)
        d = lhs <=> rhs
        if d.negative?
          # unrounded < x_cubic(lower, upper)
          return lower
        elsif d.positive?
          # unrounded > x_cubic(lower, upper)
          return upper
        else
          # (d == 0)
          on_boundary = true
        end
      else
        raise ArgumentError, "unsupported rounding mode (#{name}: major=#{major})"
      end
      unless on_boundary
        raise ArgumentError,
              "rounding #{name} of unrounded=#{unrounded} failed for lower=#{lower} and upper=#{upper}: not on boundary"
      end

      case minor
      when MINOR_UP
        ROUND_UP.pick_value(unrounded, sign, lower, upper, even_or_odd)
      when MINOR_DOWN
        ROUND_DOWN.pick_value(unrounded, sign, lower, upper, even_or_odd)
      when MINOR_CEILING
        ROUND_CEILING.pick_value(unrounded, sign, lower, upper, even_or_odd)
      when MINOR_FLOOR
        ROUND_FLOOR.pick_value(unrounded, sign, lower, upper, even_or_odd)
      when MINOR_UNUSED
        raise ArgumentError,
              "rounding #{name} of unrounded=#{unrounded} failed for lower=#{lower} and upper=#{upper}: on boundary but no applicable minor mode"
      when MINOR_EVEN
        even_or_odd
      when MINOR_ODD
        if lower == even_or_odd
          upper
        else
          lower
        end
      else
        raise ArgumentError,
              "rounding #{name} of unrounded=#{unrounded} failed for lower=#{lower} and upper=#{upper}: on boundary but no applicable minor mode"
      end
    end

    def hash
      num
    end

    def to_long_s
      "RM(#{name} major=#{major.name} minor=#{minor.name} num=#{num})"
    end

    def to_s
      name.to_s
    end
  end

  # filled using reflection
  MODE_LOOKUP = {}.freeze

  rounding_mode_counter = 0

  # filled using reflection
  ALL_ROUNDING_MODES = [].freeze

  # filled using reflection
  ALL_ROUNDING_MODE_NAMES = [].freeze

  MUL_INVERSE_MODE = {}.freeze

  ADD_INVERSE_MODE = {}.freeze

  ALL_MAJOR_MODES.each do |majm|
    majm_str = majm.part.to_s
    majm.minor.each do |minm|
      minm_str = minm.part.to_s
      const_str = "ROUND_#{majm_str}#{minm_str}"
      class_eval(
        "#{const_str} = RoundingModeClass.new(:#{const_str}, #{majm.name}, #{minm.name}, rounding_mode_counter)", __FILE__, __LINE__
      )
      class_eval("#{const_str}.freeze", __FILE__, __LINE__)
      rounding_mode_counter += 1
      class_eval("ALL_ROUNDING_MODES.push(#{const_str})", __FILE__, __LINE__)
      class_eval("ALL_ROUNDING_MODE_NAMES.push('#{const_str}')", __FILE__, __LINE__)
      class_eval("MODE_LOOKUP[[#{majm.name}, #{minm.name}]] = #{const_str}", __FILE__, __LINE__)
    end
  end

  ALL_ROUNDING_MODES.freeze
  ALL_ROUNDING_MODE_NAMES.freeze
  MODE_LOOKUP.freeze

  ALL_ROUNDING_MODES.each do |rm|
    majm = rm.major
    minm = rm.minor
    mul_inv = MODE_LOOKUP[[MUL_INVERSE_MAJOR_MODE[majm], MUL_INVERSE_MINOR_MODE[minm]]]
    MUL_INVERSE_MODE[rm] = mul_inv
    add_inv = MODE_LOOKUP[[ADD_INVERSE_MAJOR_MODE[majm], ADD_INVERSE_MINOR_MODE[minm]]]
    ADD_INVERSE_MODE[rm] = add_inv
    # puts("rm=#{rm} mul_inv=#{mul_inv} add_inv=#{add_inv}")
  end

  MUL_INVERSE_MODE.freeze
  ADD_INVERSE_MODE.freeze

  #
  # rounding modes as constants
  #
  # ROUND_UP           = RoundingModeClass.new(:ROUND_UP, 0)
  # ROUND_DOWN         = RoundingModeClass.new(:ROUND_DOWN, 1)
  # ROUND_CEILING      = RoundingModeClass.new(:ROUND_CEILING, 2)
  # ROUND_FLOOR        = RoundingModeClass.new(:ROUND_FLOOR, 3)
  # ROUND_HALF_UP      = RoundingModeClass.new(:ROUND_HALF_UP, 4)
  # ROUND_HALF_DOWN    = RoundingModeClass.new(:ROUND_HALF_DOWN, 5)
  # ROUND_HALF_CEILING = RoundingModeClass.new(:ROUND_HALF_CEILING, 6)
  # ROUND_HALF_FLOOR   = RoundingModeClass.new(:ROUND_HALF_FLOOR, 7)
  # ROUND_HALF_EVEN    = RoundingModeClass.new(:ROUND_HALF_EVEN, 8)
  # ROUND_UNNECESSARY  = RoundingModeClass.new(:ROUND_UNNECESSARY, 9)

  # # which mode is to be used instead when we do an multiplicative inversion?
  # MUL_INVERSE_MODE = {
  #   ROUND_UP           =>   ROUND_DOWN,
  #   ROUND_DOWN         =>   ROUND_UP,
  #   ROUND_CEILING      =>   ROUND_FLOOR,
  #   ROUND_FLOOR        =>   ROUND_CEILING,
  #   ROUND_HALF_UP      =>   ROUND_HALF_DOWN,
  #   ROUND_HALF_DOWN    =>   ROUND_HALF_UP,
  #   ROUND_HALF_CEILING =>   ROUND_HALF_FLOOR,
  #   ROUND_HALF_FLOOR   =>   ROUND_HALF_CEILING,
  #   ROUND_HALF_EVEN    =>   ROUND_HALF_EVEN,
  #   ROUND_UNNECESSARY  =>   ROUND_UNNECESSARY
  # }

  # # which mode is to be used instead when we do an additive inversion?
  # ADD_INVERSE_MODE = {
  #   ROUND_UP           =>   ROUND_UP,
  #   ROUND_DOWN         =>   ROUND_DOWN,
  #   ROUND_CEILING      =>   ROUND_FLOOR,
  #   ROUND_FLOOR        =>   ROUND_CEILING,
  #   ROUND_HALF_UP      =>   ROUND_HALF_UP,
  #   ROUND_HALF_DOWN    =>   ROUND_HALF_DOWN,
  #   ROUND_HALF_CEILING =>   ROUND_HALF_FLOOR,
  #   ROUND_HALF_FLOOR   =>   ROUND_HALF_CEILING,
  #   ROUND_HALF_EVEN    =>   ROUND_HALF_EVEN,
  #   ROUND_UNNECESSARY  =>   ROUND_UNNECESSARY
  # }

  ZeroRoundingModeClass = Struct.new(:name, :num)

  #
  # enumeration class to express the possible rounding modes that are
  # supported by LongDecimal
  #
  class ZeroRoundingModeClass
    include Comparable

    #
    # introduce some ordering for rounding modes
    #
    def <=>(other)
      if other.respond_to? :num
        num <=> other.num
      elsif other.is_a? Numeric
        num <=> other
      else
        puts("stack=#{caller.join("\n")}")
        raise TypeError, "o=#{other.inspect} must be numeric or ZeroRoundingMode"
      end
    end

    def hash
      num
    end

    def to_long_s
      "ZM(#{name} num=#{num})"
    end

    def to_s
      name.to_s
    end
  end

  #
  # rounding modes as constants
  #
  ZERO_ROUND_TO_PLUS                 = ZeroRoundingModeClass.new(:ZERO_ROUND_TO_PLUS, 0)
  ZERO_ROUND_TO_MINUS                = ZeroRoundingModeClass.new(:ZERO_ROUND_TO_MINUS, 1)
  ZERO_ROUND_TO_CLOSEST_PREFER_PLUS  = ZeroRoundingModeClass.new(
    :ZERO_ROUND_TO_CLOSEST_PREFER_PLUS, 2
  )
  ZERO_ROUND_TO_CLOSEST_PREFER_MINUS = ZeroRoundingModeClass.new(
    :ZERO_ROUND_TO_CLOSEST_PREFER_MINUS, 3
  )
  ZERO_ROUND_UNNECESSARY = ZeroRoundingModeClass.new(:ZERO_ROUND_UNNECESSARY, 4)

  ALL_ZERO_MODES = [LongDecimalRoundingMode::ZERO_ROUND_TO_PLUS,\
                    LongDecimalRoundingMode::ZERO_ROUND_TO_MINUS,\
                    LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_PLUS,\
                    LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_MINUS,\
                    LongDecimalRoundingMode::ZERO_ROUND_UNNECESSARY].freeze
end

# JRuby has a bug to be fixed in version > 1.2 that implies results of
# 0 for multiplications of two Fixnums neither of which is 0 in some
# cases.  This code fixes the bug for the purposes of long-decimal.
if RUBY_PLATFORM == 'java' && JRUBY_VERSION.match(/^[01]\.[012]/)
  class Integer
    alias mul *

    # fix multiplication
    def *(other)
      if zero? || other.zero?
        mul(other)
      elsif other.is_a? Integer
        x = self
        s = 0
        while (x & 0xff).zero?
          x >>= 8
          s += 8
        end
        while (other & 0xff).zero?
          other >>= 8
          s += 8
        end
        x.mul(other) << s
      else
        mul(other)
      end
    end
  end
end

#
# add one method to Integer
#
class Integer
  #
  # get the sign of self
  # -1 if self < 0
  #  0 if self is 0 (with any number of 0s after the decimal point)
  # +1 if self > 0
  #
  def sgn
    self <=> 0
  end

  alias signum sgn
  alias sign   sgn

  #
  # create copy of self round in such a way that the result is
  # congruent modulo modulus to one of the members of remainders
  #
  # param1: remainders array of allowed remainders
  # param2: modulus    modulus of the remainders
  # param3: rounding_mode rounding mode to be applied when information is
  #                       lost.   defaults  to  ROUND_UNNECESSARY,  which
  #                       means that  an exception is  thrown if rounding
  #                       would actually loose any information.
  # param4: zero_rounding_mode if self is zero, but zero is not among
  #                            the available remainders, it has to be
  #                            rounded to positive or negative value.
  #                            If the rounding_mode does not allow to
  #                            determine which of the two values to
  #                            use, zero_rounding_mode has to be used
  #                            to decide.
  #
  def round_to_allowed_remainders(remainders_param,
                                  modulus,
                                  rounding_mode = LongDecimalRoundingMode::ROUND_UNNECESSARY,
                                  zero_rounding_mode = LongDecimalRoundingMode::ZERO_ROUND_UNNECESSARY)

    raise TypeError, 'remainders must be Array' unless remainders_param.is_a? Array
    raise TypeError, 'remainders must be non-empty Array' if remainders_param.empty?
    raise TypeError, "modulus #{modulus.inspect} must be integer" unless modulus.is_a? Integer
    raise TypeError, "modulus #{modulus.inspect} must be >= 2" unless modulus >= 2
    raise TypeError, "rounding_mode #{rounding_mode.inspect} must be legal rounding rounding_mode" unless rounding_mode.is_a? LongDecimalRoundingMode::RoundingModeClass
    raise TypeError, "#{rounding_mode} is not applicable here" if rounding_mode.minor == LongDecimalRoundingMode::MINOR_EVEN
    raise TypeError, "#{rounding_mode} is not applicable here" if rounding_mode.minor == LongDecimalRoundingMode::MINOR_ODD

    unless zero_rounding_mode.is_a? LongDecimalRoundingMode::ZeroRoundingModeClass
      raise TypeError,
            "zero_rounding_mode #{zero_rounding_mode.inspect} must be legal zero_rounding zero_rounding_mode"
    end

    remainders = remainders_param.clone
    r_self     = self % modulus
    r_self_00  = r_self
    remainders = remainders.collect do |r|
      raise TypeError, 'remainders must be integral numbers' unless r.is_a? Integer

      r % modulus
    end
    remainders.sort!.uniq!
    r_first = remainders[0]
    r_last  = remainders[-1]
    r_first_again = r_first + modulus
    remainders.push r_first_again
    r_self += modulus if r_self < r_first
    r_lower = -1
    r_upper = -1
    remainders.each_index do |i|
      r = remainders[i]
      if r == r_self
        return self
      elsif r < r_self
        r_lower = r
      elsif r > r_self
        r_upper = r
        break
      end
    end
    raise ArgumentError, "self=#{self} r_self=#{r_self} r_lower=#{r_lower} r_upper=#{r_upper}" if r_lower.negative?
    raise ArgumentError, "self=#{self} r_self=#{r_self} r_lower=#{r_lower} r_upper=#{r_upper}" if r_upper.negative?

    lower = self - (r_self - r_lower)
    upper = self + (r_upper - r_self)
    # puts "round_to_allowed_remainders(remainders_param=#{remainders_param} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}) remainders=#{remainders} lower=#{lower} upper=#{upper} r_lower=#{r_lower} r_upper=#{r_upper} r_self=#{r_self}"

    unless lower < self && self < upper
      raise ArgumentError,
            "self=#{self} not in (#{lower}, #{upper}) with r_self=#{r_self} r_lower=#{r_lower} r_upper=#{r_upper}"
    end
    if rounding_mode == LongDecimalRoundingMode::ROUND_UNNECESSARY
      raise ArgumentError,
            "mode ROUND_UNNECESSARY not applicable, self=#{self} is in open interval (#{lower}, #{upper})"
    end

    case rounding_mode
    when LongDecimalRoundingMode::ROUND_FLOOR
      if lower.nil?
        raise ArgumentError,
              "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
      end

      return lower
    when LongDecimalRoundingMode::ROUND_CEILING
      if upper.nil?
        raise ArgumentError,
              "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
      end

      return upper
    end

    sign_self = sgn
    if sign_self.zero? && (rounding_mode == LongDecimalRoundingMode::ROUND_UP \
          || rounding_mode == LongDecimalRoundingMode::ROUND_DOWN \
          || rounding_mode.major == LongDecimalRoundingMode::MAJOR_GEOMETRIC \
          || rounding_mode.major == LongDecimalRoundingMode::MAJOR_HARMONIC \
          || rounding_mode.major == LongDecimalRoundingMode::MAJOR_QUADRATIC \
          || (lower == -upper && (rounding_mode.minor == LongDecimalRoundingMode::MINOR_UP || rounding_mode.minor == LongDecimalRoundingMode::MINOR_DOWN)))
      if zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_UNNECESSARY
        raise ArgumentError,
              "self=#{self} is 0 in open interval (#{lower}, #{upper}) and cannot be resolved with ZERO_ROUND_UNNECESSARY (rounding_mode=#{rounding_mode} modulus=#{modulus} remainders=#{remainders}"
      elsif [LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_PLUS,
             LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_MINUS].include?(zero_rounding_mode)
        diff = lower.abs <=> upper.abs
        if diff.negative?
          if lower.nil?
            raise ArgumentError,
                  "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
          end

          return lower
        elsif diff.positive?
          if upper.nil?
            raise ArgumentError,
                  "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
          end

          return upper
        elsif zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_PLUS
          if upper.nil?
            raise ArgumentError,
                  "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
          end

          return upper
        elsif zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_MINUS
          if lower.nil?
            raise ArgumentError,
                  "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
          end

          return lower
        else
          raise ArgumentError,
                "this case can never happen: zero_rounding_mode=#{zero_rounding_mode}"
        end
      elsif zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_PLUS
        if upper.nil?
          raise ArgumentError,
                "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
        end

        return upper
      elsif zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_MINUS
        if lower.nil?
          raise ArgumentError,
                "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
        end

        return lower
      else
        raise ArgumentError,
              "this case can never happen: zero_rounding_mode=#{zero_rounding_mode}"
      end
    end

    # for geometric and harmonic never round across 0
    if rounding_mode.major == LongDecimalRoundingMode::MAJOR_GEOMETRIC || rounding_mode.major == LongDecimalRoundingMode::MAJOR_HARMONIC || rounding_mode.major == LongDecimalRoundingMode::MAJOR_QUADRATIC
      if sign_self.positive? && lower.negative?
        if upper.nil?
          raise ArgumentError,
                "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
        end

        return upper
      elsif sign_self.negative? && upper.positive?
        if lower.nil?
          raise ArgumentError,
                "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
        end

        return lower
      end
    end

    # now we can assume that sign_self (and self) is != 0, which allows to decide on the rounding_mode
    pick = rounding_mode.pick_value(self, sign_self, lower, upper, nil)
    # if (rounding_mode == LongDecimalRoundingMode::ROUND_UP)
    #   # ROUND_UP goes to the closest possible value away from zero
    #   rounding_mode = (sign_self < 0) ? LongDecimalRoundingMode::ROUND_FLOOR : LongDecimalRoundingMode::ROUND_CEILING
    # elsif (rounding_mode == LongDecimalRoundingMode::ROUND_DOWN)
    #   # ROUND_DOWN goes to the closest possible value towards zero or beyond zero
    #   rounding_mode = (sign_self < 0) ? LongDecimalRoundingMode::ROUND_CEILING : LongDecimalRoundingMode::ROUND_FLOOR
    # elsif (rounding_mode.minor == LongDecimalRoundingMode::MINOR_UP)
    #   # ROUND_*_UP goes to the closest possible value preferring away from zero
    #   rounding_mode_minor = (sign_self < 0) ? LongDecimalRoundingMode::MINOR_FLOOR : LongDecimalRoundingMode::MINOR_CEILING
    #   rounding_mode = LongDecimalRoundingMode::MODE_LOOKUP[[rounding_mode.major, rounding_mode_minor]]
    # elsif (rounding_mode.minor == LongDecimalRoundingMode::MINOR_DOWN)
    #   # ROUND_*_DOWN goes to the closest possible value preferring towards zero or beyond zero
    #   rounding_mode_minor = (sign_self < 0) ? LongDecimalRoundingMode::MINOR_CEILING : LongDecimalRoundingMode::MINOR_FLOOR
    #   rounding_mode = LongDecimalRoundingMode::MODE_LOOKUP[[rounding_mode.major, rounding_mode_minor]]
    # end
    # if (rounding_mode.minor == LongDecimalRoundingMode::MINOR_FLOOR \
    #     || rounding_mode.minor == LongDecimalRoundingMode::MINOR_CEILING) then
    #   d_lower = self - lower
    #   d_upper = upper - self
    #   if (d_lower < d_upper) then
    #     return lower
    #   elsif (d_upper < d_lower) then
    #     return upper
    #   elsif (rounding_mode == LongDecimalRoundingMode::ROUND_HALF_FLOOR) then
    #     rounding_mode = LongDecimalRoundingMode::ROUND_FLOOR
    #   elsif (rounding_mode == LongDecimalRoundingMode::ROUND_HALF_CEILING) then
    #     rounding_mode = LongDecimalRoundingMode::ROUND_CEILING
    #   else
    #     raise ArgumentError, "this case can never happen: rounding_mode=#{rounding_mode}"
    #   end
    # end

    # if (rounding_mode == LongDecimalRoundingMode::ROUND_FLOOR) then
    #   return lower
    # elsif (rounding_mode == LongDecimalRoundingMode::ROUND_CEILING) then
    #   return upper
    # else
    #   raise ArgumentError, "this case can never happen: rounding_mode=#{rounding_mode}"
    # end
    if pick.nil?
      raise ArgumentError,
            "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
    end

    pick
  end
end

#
# common base class for LongDecimal and LongDecimalQuot
#
class LongDecimalBase < Numeric
  # allow easy check if running with version 1.9
  RUNNING_AT_LEAST_19 = RUBY_VERSION.match(/^(1\.9|[2-9]\.)/)

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
  # calculate the cube of self
  #
  def cube
    self * self * self
  end

  #
  # calculate the multiplicative inverse
  #
  def reciprocal
    sx = scale
    dx = sint_digits10
    new_scale = [0, (2 * dx) + sx - 2].max
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
  def <=>(other)
    diff = (self - other)
    if diff.is_a? LongDecimalBase
      diff.sgn
    else
      diff <=> 0
    end
  end

  #
  # <=>-comparison for the scales
  #
  def scale_ufo(other)
    raise TypeError, 'only works for LongDecimal or LongDecimalQuot' unless other.is_a? LongDecimalBase

    scale <=> other.scale
  end

  #
  # ==-comparison for the scales
  #
  def scale_equal(other)
    scale_ufo(other).zero?
  end

  private

  #
  # helper method for round_to_scale
  #
  def round_to_scale_helper(dividend, divisor, new_scale, mode)
    sign_quot = dividend <=> 0
    if sign_quot.zero?
      # finish zero without long calculations at once
      return LongDecimal(0, new_scale)
    end

    quot, rem = dividend.divmod(divisor)
    sign_rem  = rem <=> 0
    if sign_rem.zero?
      # if self can be expressed without loss as LongDecimal with
      # new_scale digits after the decimal point, just do it.
      return LongDecimal(quot, new_scale)
    end

    # we do not expect negative signs of remainder.  To make sure that
    # this does not cause problems in further code, we just throw an
    # exception.  This should never happen (and did not happen during
    # testing).
    if sign_rem <= 0
      raise ArgumentError,
            "signs do not match self=#{self} f=#{factor} dividend=#{dividend} divisor=#{divisor} quot=#{quot} rem=#{rem}"
    end

    # now we have
    # dividend == quot * divisor + rem
    # where 0 < rem < quot (the case rem == 0 has already been handled
    # so
    # quot < divisor/dividend < quot+1
    lower = quot
    upper = quot + 1
    even_or_odd = if mode.minor == MINOR_EVEN || mode.minor == MINOR_ODD
                    even_or_odd = if lower[0] == 1
                                    upper
                                  else
                                    lower
                                  end
                  end
    value = mode.pick_value(Rational(dividend, divisor), sign_quot, lower, upper, even_or_odd)
    LongDecimal(value, new_scale)
  end

  #
  # helper method for round_to_scale
  # will be replaced by shorter implementation
  #
  def round_to_scale_helper_old(dividend, divisor, new_scale, mode)
    sign_quot = dividend <=> 0
    if sign_quot.zero?
      # finish zero without long calculations at once
      return LongDecimal(0, new_scale)
    end

    quot, rem = dividend.divmod(divisor)
    sign_rem  = rem <=> 0
    if sign_rem.zero?
      # if self can be expressed without loss as LongDecimal with
      # new_scale digits after the decimal point, just do it.
      return LongDecimal(quot, new_scale)
    end

    # we do not expect negative signs of remainder.  To make sure that
    # this does not cause problems in further code, we just throw an
    # exception.  This should never happen (and did not happen during
    # testing).
    if sign_rem <= 0
      raise ArgumentError,
            "signs do not match self=#{self} f=#{factor} dividend=#{dividend} divisor=#{divisor} quot=#{quot} rem=#{rem}"
    end

    if sign_quot.negative?
      # handle negative sign of self
      rem -= divisor
      quot += 1
      sign_rem = rem <=> 0
      if sign_rem >= 0
        raise ArgumentError,
              "signs do not match self=#{self} f=#{factor} dividend=#{dividend} divisor=#{divisor} quot=#{quot} rem=#{rem}"
      end
    end

    if mode == ROUND_UNNECESSARY
      # this mode means that rounding should not be necessary.  But
      # the case that no rounding is needed, has already been covered
      # above, so it is an error, if this mode is required and the
      # result could not be returned above.
      raise ArgumentError, "mode ROUND_UNNECESSARY not applicable, remainder #{rem} is not zero"
    end

    case mode
    when ROUND_CEILING
      # ROUND_CEILING goes to the closest allowed number >= self, even
      # for negative numbers.  Since sign is handled separately, it is
      # more conveniant to use ROUND_UP or ROUND_DOWN depending on the
      # sign.
      mode = sign_quot.positive? ? ROUND_UP : ROUND_DOWN

    when ROUND_FLOOR
      # ROUND_FLOOR goes to the closest allowed number <= self, even
      # for negative numbers.  Since sign is handled separately, it is
      # more conveniant to use ROUND_UP or ROUND_DOWN depending on the
      # sign.
      mode = sign_quot.negative? ? ROUND_UP : ROUND_DOWN

    else

      case mode.minor
      when MINOR_CEILING
        # ROUND_HALF_CEILING goes to the closest allowed number >= self, even
        # for negative numbers.  Since sign is handled separately, it is
        # more conveniant to use ROUND_HALF_UP or ROUND_HALF_DOWN depending on the
        # sign.
        minor_mode = sign_quot.positive? ? MINOR_UP : MINOR_DOWN
        mode = MODE_LOOKUP[[mode.major, minor_mode]]
      when MINOR_FLOOR
        # ROUND_HALF_FLOOR goes to the closest allowed number <= self, even
        # for negative numbers.  Since sign is handled separately, it is
        # more conveniant to use ROUND_HALF_UP or ROUND_HALF_DOWN depending on the
        # sign.
        minor_mode = sign_quot.negative? ? MINOR_UP : MINOR_DOWN
        mode = MODE_LOOKUP[[mode.major, minor_mode]]
      end

      # handle the ROUND_HALF_... stuff and find the adequate ROUND_UP
      # or ROUND_DOWN to use
      abs_rem = rem.abs
      direction_criteria = nil
      if mode.major == MAJOR_HALF
        direction_criteria = (abs_rem << 1) <=> divisor

        mode = if direction_criteria.negative?
                 ROUND_DOWN
               elsif direction_criteria.positive?
                 ROUND_UP
               else
                 # direction_criteria == 0
                 case mode
                 when ROUND_HALF_UP
                   ROUND_UP
                 when ROUND_HALF_DOWN
                   ROUND_DOWN
                 else
                   # mode == ROUND_HALF_EVEN
                   (quot[0] == 1 ? ROUND_UP : ROUND_DOWN)
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
  end
end

#
# class for holding fixed point long decimal numbers
# these can be considered as a pair of two integer.  One contains the
# digits and the other one the position of the decimal point.
#
class LongDecimal < LongDecimalBase
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
  def self.new!(x, s = 0)
    new(x, s)
  end

  #
  # creates a LongDecimal representing zero with the given number of
  # digits after the decimal point (scale=s)
  #
  def self.zero!(s = 0)
    new(0, s)
  end

  #
  # creates a LongDecimal representing one with the given number of
  # digits after the decimal point (scale=s)
  #
  def self.one!(s = 0)
    new(LongMath.npower10(s), s)
  end

  #
  # creates a LongDecimal representing two with the given number of
  # digits after the decimal point (scale=s)
  #
  def self.two!(s = 0)
    new(2 * LongMath.npower10(s), s)
  end

  #
  # creates a LongDecimal representing ten with the given number of
  # digits after the decimal point (scale=s)
  #
  def self.ten!(s = 0)
    new(LongMath.npower10(s + 1), s)
  end

  #
  # creates a LongDecimal representing 1/2 with the given number of
  # digits after the decimal point (scale=s)
  #
  def self.half!(s = 1)
    new(5 * LongMath.npower10(s - 1), s)
  end

  #
  # creates a LongDecimal representing minus one with the given number of
  # digits after the decimal point (scale=s)
  #
  def self.minus_one!(s = 0)
    new(-1 * LongMath.npower10(s), s)
  end

  #
  # creates a LongDecimal representing a power of ten with the given
  # exponent e and with the given number of digits after the decimal
  # point (scale=s)
  #
  def self.power_of_ten!(e, s = 0)
    LongMath.check_is_int(e, 'e')
    raise TypeError, "negative 1st arg \"#{e.inspect}\"" if e.negative?

    new(LongMath.npower10(s + e), s)
  end

  #
  # needed for clone()
  #
  def initialize_copy(x)
    @int_val  = x.int_val
    @scale    = x.scale
  end

  #
  # initialization
  # parameters:
  # LongDecimal.new(x, s) where x is a string or a number and s is the scale
  # the resulting LongDecimal holds the number x / 10**s
  #
  def initialize(x, s)
    # handle some obvious errors with x first
    raise TypeError, "non numeric 1st arg \"#{x.inspect}\"" if !(x.is_a? Numeric) && !(x.is_a? String)
    # we could maybe even work with complex number, if their imaginary part is zero.
    # but this is not so important to deal with, so we raise an error anyway.
    raise TypeError, "complex numbers not supported \"#{x.inspect}\"" if x.is_a? Complex

    # handle some obvious errors with optional second parameter, if present
    LongMath.check_is_prec(s, 'scale', :raise_error)
    #    raise TypeError, "non integer 2nd arg \"#{s.inspect}\"" if ! s.kind_of? Integer
    #    raise TypeError, "negative 2nd arg \"#{s.inspect}\""    if s < 0

    # scale is the second parameter or 0 if it is missing
    scale   = s
    # int_val is the integral value that is multiplied by some 10**-n
    int_val = 0

    case x
    when Integer
      # integers are trivial to handle
      int_val = x

    when Rational
      # rationals are rounded somehow
      # we need to come up with a better rule here.
      # if denominator is any product of powers of 2 and 5, we do not need to round
      denom = x.denominator
      mul_2 = LongMath.multiplicity_of_factor(denom, 2)
      mul_5 = LongMath.multiplicity_of_factor(denom, 5)
      iscale = [mul_2, mul_5].max
      scale += iscale
      denom /= 2**mul_2
      denom /= 5**mul_5
      iscale2 = Math.log10(denom).ceil
      scale += iscale2
      int_val = (x * LongMath.npower10(iscale2 + iscale)).to_i

    else
      # we assume a string or a floating point number
      # floating point number or BigDecimal is converted to string, so
      # we only deal with strings
      # this operation is not so common, so there is no urgent need to
      # optimize it
      num_str  = x.to_s
      len      = num_str.length

      # handle the obvious error that string is empty
      raise TypeError, "1st arg must not be empty string. \"#{num_str.inspect}\"" if len.zero?

      # remove spaces and underscores
      num_str = num_str.gsub(/\s/, '')
      num_str.gsub!(/_/, '')

      # handle sign
      num_str.gsub!(/^\+/, '')
      negative = false
      negative = true if num_str.gsub!(/^-/, '')

      # split in parts before and after decimal point
      num_arr = num_str.split(/\./)
      raise TypeError, "1st arg contains more than one . \"#{num_str.inspect}\"" if num_arr.length > 2

      num_int = num_arr[0]
      num_rem = num_arr[1]
      num_frac = nil
      num_exp  = nil
      unless num_rem.nil?
        num_arr  = num_rem.split(/[Ee]/)
        num_frac = num_arr[0]
        num_exp  = num_arr[1]
      end

      num_frac = '' if num_frac.nil?

      # handle optional e-part of floating point number represented as
      # string
      num_exp = '0' if num_exp.nil? || num_exp.empty?
      num_exp = num_exp.to_i
      iscale  = num_frac.length - num_exp
      scale  += iscale
      if scale.negative?
        num_frac += '0' * -scale
        scale = 0
      end
      int_val = (num_int + num_frac).to_i
      int_val = -int_val if negative
    end
    # scale is the number of digits that go after the decimal point
    @scale    = scale
    # int_val holds all the digits.  The value actually expressed by self is
    # int_val * 10**(-scale)
    @int_val  = int_val
    # used for storing the number of digits before the decimal point.
    # Is nil, until it is used the first time
    @digits10 = nil
  end

  attr_reader :int_val, :scale

  #
  # alter scale (changes self)
  #
  # only for internal use:
  # use round_to_scale instead
  #
  def scale=(s)
    raise TypeError, "non integer arg \"#{s.inspect}\"" unless s.is_a? Integer
    raise TypeError, "negative arg \"#{s.inspect}\""    if s.negative?

    # do not work too hard, if scale does not really change.
    unless @scale == s
      # multiply int_val by a power of 10 in order to compensate for
      # the change of scale and to keep number in the same order of magnitude.
      d = s - @scale
      f = LongMath.npower10(d.abs)
      @int_val = if d >= 0
                   (@int_val * f).to_i
                 else
                   # here we actually do rounding
                   (@int_val / f).to_i
                 end
      @scale = s
      @digits10 = nil
    end
  end

  protected :scale=

  #
  # get rid of trailing zeros
  #
  def round_trailing_zeros
    n = LongMath.multiplicity_of_10(int_val)
    return self if n.zero?

    n = scale if n > scale
    round_to_scale(scale - n)
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
    new_scale = LongMath.check_is_prec(new_scale)
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.is_a? RoundingModeClass

    if @scale == new_scale
      self
    else
      diff   = new_scale - scale
      factor = LongMath.npower10(diff.abs)
      if diff.positive?
        # we become more precise, no rounding issues
        new_int_val = int_val * factor
        LongDecimal(new_int_val, new_scale)
      else
        round_to_scale_helper(int_val, factor, new_scale, mode)
      end
    end
  end

  #
  # create copy of self round in such a way that the result times
  # 10**scale is congruent modulo modulus to one of the members of
  # remainders
  #
  # param1: new_scale  new scale for result
  # param2: remainders array of allowed remainders
  # param3: modulus    modulus of the remainders
  # param4: rounding_mode rounding mode to be applied when information is
  #                       lost.   defaults  to  ROUND_UNNECESSARY,  which
  #                       means that  an exception is  thrown if rounding
  #                       would actually loose any information.
  # param5: zero_rounding_mode if self is zero, but zero is not among
  #                            the available remainders, it has to be
  #                            rounded to positive or negative value.
  #                            If the rounding_mode does not allow to
  #                            determine which of the two values to
  #                            use, zero_rounding_mode has to be used
  #                            to decide.
  #
  def round_to_allowed_remainders(new_scale,
                                  remainders,
                                  modulus,
                                  rounding_mode = LongDecimalRoundingMode::ROUND_UNNECESSARY,
                                  zero_rounding_mode = LongDecimalRoundingMode::ZERO_ROUND_UNNECESSARY)

    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.is_a? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, 'remainders must be Array' unless remainders.is_a? Array
    raise TypeError, 'remainders must be non-empty Array' if remainders.empty?
    raise TypeError, "modulus #{modulus.inspect} must be integer" unless modulus.is_a? Integer
    raise TypeError, "modulus #{modulus.inspect} must be >= 2" unless modulus >= 2
    raise TypeError, "rounding_mode #{rounding_mode.inspect} must be legal rounding rounding_mode" unless rounding_mode.is_a? RoundingModeClass
    raise TypeError, 'ROUND_HALF_EVEN is not applicable here' if rounding_mode == LongDecimalRoundingMode::ROUND_HALF_EVEN
    raise TypeError, 'ROUND_HALF_ODD is not applicable here' if rounding_mode == LongDecimalRoundingMode::ROUND_HALF_ODD

    unless zero_rounding_mode.is_a? ZeroRoundingModeClass
      raise TypeError,
            "zero_rounding_mode #{zero_rounding_mode.inspect} must be legal zero_rounding zero_rounding_mode"
    end

    if @scale < new_scale
      expanded = round_to_scale(new_scale, rounding_mode)
      return expanded.round_to_allowed_remainders(new_scale, remainders, modulus, rounding_mode,
                                                  zero_rounding_mode)
    elsif @scale > new_scale
      factor = LongMath.npower10(@scale - new_scale)
      remainders = remainders.collect do |r|
        r * factor
      end
      modulus *= factor
    end

    int_val_2 = @int_val.round_to_allowed_remainders(remainders, modulus, rounding_mode,
                                                     zero_rounding_mode)
    self_2 = LongDecimal.new(int_val_2, @scale)

    self_2.round_to_scale(new_scale, rounding_mode)
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
    if base == 10
      if shown_scale == @scale
        to_s_10
      else
        s = round_to_scale(shown_scale, mode)
        s.to_s_10
      end
    else
      # base is not 10
      raise TypeError, 'base must be integer between 2 and 36' unless (base.is_a? Integer) && base >= 2 && base <= 36

      quot    = (move_point_right(scale) * (base**shown_scale)) / LongMath.npower10(scale)
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
    if sc.positive?
      missing = sc - str.length + 1
      str = ('0' * missing) + str if missing.positive?
      str[-sc, 0] = '.'
    end
    str = "-#{str}" if sg.negative?
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
  # to_f has to consider the following cases:
  # if 10**scale or int_val > MAX_FLOATABLE, divide by an adequate power of 10 to reach the ranges, where the conversion below works.
  # if 10**scale and int_val both < MAX_FLOATABLE, use lookup for float-representation 1/10**scale -> int_val.to_f * (1/10**scale)
  # special care has to be taken for the "border cases".
  #
  def to_f
    # result 0.0 if int_val == 0
    if int_val.zero?
      # t1
      # puts "t1 #{self.to_s}=#{self.inspect} -> 0.0"
      return 0.0
    end

    if scale.zero?
      if int_val.abs <= LongMath::MAX_FLOATABLE
        y = int_val.to_f
        # t2
        # puts "t2 #{self.to_s}=#{self.inspect} -> #{y}"
        return y
      elsif int_val.negative?
        # t13
        # puts "t13 #{self.to_s}=#{self.inspect} -> -Infinity"
        return -1.0 / 0.0
      elsif int_val.positive?
        # t14
        # puts "t13 #{self.to_s}=#{self.inspect} -> Infinity"
        return 1.0 / 0.0
      end
    end

    # negative: can be handled by doing to_f of the absolute value and negating the result.
    if negative?
      y = -(-self).to_f
      # t3
      # puts "t3 #{self.to_s}=#{self.inspect} -> #{y}"
      return y
    end

    # handle the usual case first, avoiding expensive calculations
    if int_val <= LongMath::MAX_FLOATABLE && scale <= Float::MAX_10_EXP
      y = to_f_simple(int_val, scale)
      # t4
      # puts "t4 #{self.to_s}=#{self.inspect} -> #{y}"
      return y
    end

    divisor = denominator

    # result NaN if int_val > MAX_FLOATABLE * 10**scale
    # handle overflow: raise exception
    if int_val > divisor * LongMath::MAX_FLOATABLE
      # t5
      # puts "t5 #{self.to_s}=#{self.inspect} -> Infinity"
      return 1 / 0.0 # Infinity
    end

    # result 0.0 if int_val * MAX_FLOATABLE < 10**scale
    # handle underflow: return 0.0
    if int_val * LongMath::INV_MIN_FLOATABLE * 20 < divisor
      # t6
      # puts "t6 #{self.to_s}=#{self.inspect} -> 0.0"
      p = int_val * LongMath::INV_MIN_FLOATABLE * 20
      d = divisor
      n = int_val
      return 0.0
    end

    if int_val <= LongMath::MAX_FLOATABLE
      # the case divisor <= LongMath::MAX_FLOATABLE has been dealt with above already.
      # ==> denominator > LongMath::MAX_FLOATABLE is true
      # the case self < LongMath::MIN_FLOATABLE has been handed above
      # int_val beeing < LongMath::MAX_FLOATABLE we know that qe < 2 * Float::MAX_10_EXP
      y = int_val.to_f
      s = scale
      while s.positive?
        qe = [s, Float::MAX_10_EXP].min
        q  = LongMath.neg_float_npower10(qe)
        y *= q
        if y == 0.0
          # t7
          # puts "t7 #{self.to_s}=#{self.inspect} -> #{y}"
          return y
        end

        s -= qe
      end
      # t8
      # puts "t8 #{self.to_s}=#{self.inspect} -> #{y}"
      return y
    end

    # we can now assume that int_val > LongMath::MAX_FLOATABLE, but not self > LongMath::MAX_FLOATABLE
    # so rounding should help.
    # we need to retain some 16 digits to be safely when going via integer
    if int_val >= LongMath::FLOATABLE_WITHOUT_FRACTION * divisor
      $stdout.flush
      rounded_ld = round_to_scale(0, ROUND_HALF_UP)
      # scale = 0, 0 < int_val <= MAX_FLOATABLE
      y = to_f_simple(rounded_ld.int_val, rounded_ld.scale)
      # t9
      # puts "t9 #{self.to_s}=#{self.inspect} #{rounded_ld.to_s}=#{rounded_ld.inspect} -> #{y}"
      return y
    end

    # we need to retain some digits after the decimal point
    # it can be assumed that self < LongMath::FLOATABLE_WITHOUT_FRACTION, so retaining some digits is necessary

    cmp = int_val <=> divisor

    if cmp.zero?
      # t10
      # puts "t10 #{self.to_s}=#{self.inspect} -> 1.0"
      1.0
    elsif cmp.positive?
      # self > 1, retain MAX_SIGNIFICANT_FLOATABLE_DIGITS
      rounded_ld = round_to_scale(LongMath::MAX_SIGNIFICANT_FLOATABLE_DIGITS, ROUND_HALF_UP)
      # self >= LongMath::FLOATABLE_WITHOUT_FRACTION > self > 1, scale = 16,
      to_f_simple(rounded_ld.int_val, rounded_ld.scale)
      # t11
      # puts "t11 #{self.to_s}=#{self.inspect} #{rounded_ld.to_s}=#{rounded_ld.inspect} -> #{y}"

    else
      # self < 1
      # sd <= 0, since self <= 0
      sd = sint_digits10
      # add some reserve, to keep room for to_f's rounding
      reserve = 5
      # significant_digits = sd + scale
      # reduction = significant_digits - MAX_SIGNIFICANT_FLOATABLE_DIGITS
      # new_scale = scale - reduction + reserve
      # simplifies to the following expression
      new_scale = LongMath::MAX_SIGNIFICANT_FLOATABLE_DIGITS - sd + reserve
      rounded_ld = round_to_scale(new_scale, ROUND_HALF_UP)
      to_f_simple(rounded_ld.int_val, rounded_ld.scale)
      # t12
      # puts "t12 #{self.to_s}=#{self.inspect} #{rounded_ld.to_s}=#{rounded_ld.inspect} sd=#{sd} #{self <=> 1} -> #{y}"

    end
  end

  private

  # private helper method for to_f
  def to_f_simple(int_val, scale)
    if scale > Float::MAX_10_EXP - 10
      ds1 = scale >> 1
      ds2 = scale - ds1
      f1 = int_val.to_f
      f2 = LongMath.neg_float_npower10(ds1)
      f3 = LongMath.neg_float_npower10(ds2)
      f1 * f2 * f3
    else
      int_val.to_f * LongMath.neg_float_npower10(scale)
    end
  end

  public

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
  def to_ld(prec = nil, mode = LongMath.standard_mode)
    if prec.nil?
      self
    else
      round_to_scale(prec, mode)
    end
  end

  #
  # convert self into BigDecimal
  #
  def to_bd
    # this operation is probably not used so heavily, so we can live with a
    # string as an intermediate step.
    BigDecimal(to_s)
  end

  #
  # LongDecimals can be seen as a fraction with a power of 10 as
  # denominator for compatibility with other numeric classes this
  # method is included, returning LongMath.npower10(scale).
  # Please observe that there may be common factors of numerator and
  # denominator in case of LongDecimal, which does not occur in case
  # of Rational
  #
  def denominator
    LongMath.npower10(scale)
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
    int_part = abs.to_i
    return 0 if int_part.zero?

    n = ((int_part.size - BYTE_SIZE_OF_ONE) << 3) + 1
    int_part = int_part >> n
    until int_part.zero?
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
    if @digits10.nil?
      result = LongMath.int_digits10(int_val) - scale
      return result if frozen?

      @digits10 = result
    end
    @digits10
  end

  # freeze but calcuate sint_digits10 before
  def freeze_ld
    sint_digits10
    freeze
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
    [sint_digits10, 0].max
  end

  #
  # before adding or subtracting two LongDecimal numbers
  # it is mandatory to set them to the same scale.  The maximum of the
  # two summands is used, in order to avoid loosing any information.
  # this method is mostly for internal use
  #
  def equalize_scale(other)
    o, s = coerce(other)
    if s.is_a? LongDecimal
      # make sure Floats do not mess up our number of significant digits when adding
      if other.is_a? Float
        o = o.round_to_scale(s.scale, ROUND_HALF_UP)
      else
        new_scale = [s.scale, o.scale].max
        s = s.round_to_scale(new_scale)
        o = o.round_to_scale(new_scale)
      end
    end
    [s, o]
  end

  #
  # before dividing two LongDecimal numbers, it is mandatory to set
  # make them both to integers, so the result is simply expressable as
  # a rational
  # this method is mostly for internal use
  #
  def anti_equalize_scale(other)
    o, s = coerce(other)
    if s.is_a? LongDecimal
      exponent = [s.scale, o.scale].max
      factor   = LongMath.npower10(exponent)
      s *= factor
      o *= factor
      s = s.round_to_scale(0)
      o = o.round_to_scale(0)
    end
    [s, o]
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
  # return the unit by which self is incremented by succ times sign
  #
  def sunit
    LongDecimal(sign, scale)
  end

  #
  # apply unary -
  # (returns negated self)
  #
  def -@
    if zero?
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
    if s.is_a? LongDecimal
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
    if s.is_a? LongDecimal
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
    if s.is_a? LongDecimal
      new_scale = s.scale + o.scale
      prod      = s.int_val * o.int_val
      if new_scale > LongMath.prec_limit
        reduced_scale = LongMath.check_is_prec(new_scale)
        reduction     = new_scale - reduced_scale
        LongDecimal(prod / LongMath.npower10(reduction), reduced_scale)
      else
        LongDecimal(prod, new_scale)
      end
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
    if q.is_a? Float
      q = if new_scale.nil?
            LongDecimal(q)
          else
            q.to_ld(new_scale, rounding_mode)
          end
    end
    if q.is_a? LongDecimalBase
      new_scale = q.scale if new_scale.nil?
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
    if q.is_a? LongDecimalQuot
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
    if s.is_a? LongDecimal
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
    other = other.to_i if (other.is_a? LongDecimalBase) && other.is_int?
    if other.is_a? Integer
      if other >= 0
        LongDecimal(int_val**other, scale * other)
      else
        abs_other = -other
        new_scale = abs_other * scale
        LongDecimalQuot(Rational(LongMath.npower10(new_scale), int_val**abs_other), new_scale)
      end
    else
      other = other.to_r if other.is_a? LongDecimalBase
      to_r**other
    end
  end

  #
  # do integer division with remainder, returning two values
  #
  def divmod(other)
    raise TypeError, 'divmod not supported for Complex' if other.is_a? Complex

    q = (self / other).to_i
    [q, self - (other * q)]
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
    if s.is_a? LongDecimal
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
    if s.is_a? LongDecimal
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
    if s.is_a? LongDecimal
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
    raise TypeError, 'cannot shift by something other than Fixnum >= 0' unless (other.is_a? Integer) && other >= 0 && other <= MAX_32BIT_FIXNUM

    LongDecimal(int_val << other, scale)
  end

  #
  # performs bitwise right shift of self by other
  #
  def >>(other)
    raise TypeError, 'cannot shift by something other than Fixnum >= 0' unless (other.is_a? Integer) && other >= 0 && other <= MAX_32BIT_FIXNUM

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
    raise TypeError, 'only implemented for Fixnum' unless (n.is_a? Integer) && -MAX_32BIT_FIXNUM <= n && n <= MAX_32BIT_FIXNUM

    if n >= 0
      move_point_left_int(n)
    else
      move_point_right_int(-n)
    end
  end

  #
  # multiply by 10**n
  #
  def move_point_right(n)
    raise TypeError, 'only implemented for Fixnum' unless (n.is_a? Integer) && -MAX_32BIT_FIXNUM <= n && n <= MAX_32BIT_FIXNUM

    if n.negative?
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
    raise TypeError, 'only implemented for Fixnum >= 0' unless n >= 0

    LongDecimal(int_val, scale + n)
  end

  #
  # internal method
  # multiply by 10**n
  #
  def move_point_right_int(n)
    raise TypeError, 'only implemented for Fixnum >= 0' unless n >= 0

    if n > scale
      LongDecimal(int_val * LongMath.npower10(n - scale), 0)
    else
      LongDecimal(int_val, scale - n)
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
  # calculate the cbrt (cubic root) of self
  # provide the result with given number
  # new_scale of digits after the decimal point
  # use rounding_mode if the result is not exact
  #
  def cbrt(new_scale, rounding_mode)
    LongMath.cbrt(self, new_scale, rounding_mode)
  end

  #
  # calculate the cbrt s (cubic root) of self and remainder r >= 0
  # such that s**3+r = self and (s+1)**3 > self
  # provide the result with given number
  # new_scale of digits after the decimal point
  #
  def cbrt_with_remainder(new_scale)
    LongMath.cbrt_with_remainder(self, new_scale)
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
    case other
    when LongDecimal
      # if other is LongDecimal as well, nothing to do
      [other, self]

    when LongDecimalQuot
      # if other is LongDecimalQuot, convert self to LongDecimalQuot
      # as well
      [other, LongDecimalQuot(to_r, scale)]

    when Rational
      # if other is Rational, convert self and other to
      # LongDecimalQuot.  This is well adapted to cover both.
      sc = scale
      o  = LongDecimalQuot(other, sc)
      s  = LongDecimalQuot(to_r, sc)
      [o, s]

      # we could use BigDecimal as common type for combining Float and
      # LongDecimal, but this needs a lot of consideration.  For the
      # time being we assume that we live well enough with converting
      # Float into LongDecimal
      # elsif (other.kind_of? Float) && size > 8 then
      #  return coerce(BigDecimal(other.to_s))

    when Integer, Float
      # if other is Integer or Float, convert it to LongDecimal
      other = LongDecimal(other)
      other = other.round_to_scale(scale, ROUND_HALF_UP) if other.scale > scale
      [other, self]

    when BigDecimal
      # if other is BigDecimal convert self to BigDecimal
      s, o = other.coerce(to_bd)
      [o, s]

    when Complex
      # if other is Complex, convert self to Float and then to
      # Complex.  It need to be observed that this will fail if self
      # has too many digits before the decimal point to be expressed
      # as Float.
      # s, o = other.coerce(self.to_f)
      if RUNNING_AT_LEAST_19
        s, o = other.coerce(self)
        # puts "complex coerce 19: #{self}, #{other} -> #{s}, #{o}"
      else
        s, o = other.coerce(Complex(self, 0))
        # puts "complex coerce 18/J: #{self}, #{other} -> #{s}, #{o}"
      end
      [o, s]
      # s, o = other.coerce(Complex(self.to_f, 0))
      # return o, s

    when Numeric
      # all other go by expressing self as Float and seeing how it
      # combines with other.
      s, o = other.coerce(to_f)
      [o, s]

    else
      # non-numeric types do not work here
      raise TypeError, "unsupported type #{other.inspect} for coerce of LongDecimal"
    end
  end

  #
  # is self expressable as an integer without loss of digits?
  #
  def is_int?
    scale.zero? || (int_val % LongMath.npower10(scale)).zero?
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
  def eql?(other)
    (other.is_a? LongDecimal) && (self <=> other).zero? && scale == other.scale
  end

  #
  # comparison of self with other for equality
  # takes into account the values expressed by self
  #
  def ==(other)
    # (other.kind_of? LongDecimal) && (self <=> other) == 0 && self.scale == other.scale
    case other
    when LongDecimal
      scale_diff = scale - other.scale
      if scale_diff.zero?
        int_val == other.int_val
      elsif scale_diff.negative?
        int_val * LongMath.npower10(-scale_diff) == other.int_val
      else
        int_val == other.int_val * LongMath.npower10(scale_diff)
      end
    when Integer
      int_val == other * LongMath.npower10(scale)
    when Numeric
      (self <=> other).zero?
    else
      false
    end
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
    (self - 1).zero?
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
    format('LongDecimal(%s, %s)', int_val.inspect, scale.inspect)
  end
end

#
# This class is used for storing intermediate results after having
# performed a division.  The division cannot be completed without
# providing additional information on how to round the result.
#
class LongDecimalQuot < LongDecimalBase
  #
  # constructor
  # first, second is either a pair of LongDecimals or a Rational and an Integer
  # The resulting LongDecimal will contain a rational obtained by
  # dividing the two LongDecimals or by taking the Rational as it is.
  # The scale is there to provide a default rounding precision for
  # conversion to LongDecimal, but it has no influence on the value
  # expressed by the LongDecimalQuot
  #
  def self.new!(first, second)
    new(first, second)
  end

  #
  # needed for clone()
  #
  def initialize_copy(x)
    @rat   = x.rat
    @scale = x.scale
  end

  #
  # create a new LongDecimalQuot from a rational and a scale or a
  # pair of LongDecimals
  #
  def initialize(first, second)
    @digits10 = nil
    if ((first.is_a? Rational) || (first.is_a? LongDecimalQuot) || (first.is_a? Integer)) && (second.is_a? Integer)
      LongMath.check_is_prec(second)
      @rat   = Rational(first.numerator, first.denominator)
      @scale = second

    elsif (first.is_a? LongDecimal) && (second.is_a? LongDecimal)
      # calculate the number of digits after the decimal point we can
      # be confident about.  Use 0, if we do not have any confidence
      # about any digits after the decimal point.  The formula has
      # been obtained by using the partial derivatives of f(x, y) =
      # x/y and assuming that sx and sy are the number of digits we
      # know after the decimal point and dx and dy are the number of
      # digits before the decimal point.  Since division is usually
      # not expressable exactly in decimal digits, it is up to the
      # calling application to decide on the number of digits actually
      # used for the result, which can be more than new_scale.
      sx = first.scale
      sy = second.scale
      dx = first.sint_digits10
      dy = second.sint_digits10
      new_scale = [0, (2 * dy) + sx + sy - [dx + sx, dy + sy].max - 3].max

      first, second = first.anti_equalize_scale(second)
      if second.zero?
        raise ZeroDivisionError,
              "second=#{second.inspect} must not be zero. (first=#{first.inspect})"
      end

      @rat = Rational(first.to_i, second.to_i)
      @scale = new_scale
    else
      raise TypeError,
            "parameters must be (LongDecimal, LongDecimal) or (Rational, Integer): first=#{first.inspect} second=#{second.inspect}"
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
    raise TypeError, "non integer arg \"#{s.inspect}\"" unless s.is_a? Integer
    raise TypeError, "negative arg \"#{s.inspect}\""    if s.negative?

    @scale = s
  end

  # protected :scale=

  #
  # conversion to string.  Based on the conversion of Rational
  #
  def to_s
    str = @rat.to_s
    "#{str}[#{scale}]"
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
  def to_bd(prec = scale, mode = LongMath.standard_mode)
    to_ld(prec, mode).to_bd
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
  def to_ld(prec = scale, mode = LongMath.standard_mode)
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
    if @digits10.nil?
      if zero?
        @digits10 = nil
      else
        n = numerator.abs
        d = denominator
        i = 0
        while n < d
          i += 1
          n *= 10
        end
        @digits10 = LongMath.int_digits10(n / d) - i
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
    if zero?
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
    if s.is_a? LongDecimalQuot
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
    if s.is_a? LongDecimalQuot
      LongDecimalQuot(s.rat - o.rat, [s.scale, o.scale].max)
    else
      # puts "ldq-coerce: s=#{s} o=#{o} self=#{self} other=#{other}"
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
    if s.is_a? LongDecimalQuot
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
    if s.is_a? LongDecimalQuot
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
    if other.is_a? LongDecimalBase
      other = if other.is_int?
                other.to_i
              else
                other.to_r
              end
    end
    rat_result = rat**other
    if rat_result.is_a? Rational
      new_scale = if (other.is_a? Integer) && other >= 0
                    scale * other
                  else
                    scale
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
    raise TypeError, 'divmod not supported for Complex' if other.is_a? Complex

    q = (self / other).to_i
    [q, self - (other * q)]
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
    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.is_a? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.is_a? RoundingModeClass

    factor    = LongMath.npower10(new_scale)
    prod      = numerator * factor
    raise TypeError, "numerator=#{numerator} must be integer" unless numerator.is_a? Integer
    raise TypeError, "denominator=#{denominator}=#{denominator.inspect} must be integer" unless denominator.is_a? Integer
    raise TypeError, "factor=#{factor} (new_scale=#{new_scale}) must be integer" unless factor.is_a? Integer
    raise TypeError, "prod=#{prod} must be integer" unless prod.is_a? Integer

    round_to_scale_helper(prod, denominator, new_scale, mode)
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
    case other
    when LongDecimal
      # convert LongDecimal to LongDecimalQuot
      [LongDecimalQuot(other.to_r, other.scale), self]

    when LongDecimalQuot
      # nothing to convert, if both are already LongDecimalQuot
      [other, self]

    when Rational, Integer
      # convert Rational or Integer to LongDecimalQuot.  The only
      # missing part, scale, is just taken from self
      s = scale
      [LongDecimalQuot(other, s), self]

    when Float
      # convert Float to LongDecimalQuot via LongDecimal
      [LongDecimalQuot(other.to_ld.to_r, scale), self]

    when BigDecimal
      # for BigDecimal, convert self to BigDecimal as well
      s, o = other.coerce(to_bd(scale + 10))
      [o, s]

    when Numeric
      # for all other numeric types convert self to Float.  This may
      # not work, if numerator and denominator have too many digits to
      # be expressed as Float and it may cause loss of information.
      s, o = other.coerce(to_f)
      [o, s]

    else
      # non-numeric types do not work at all
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
  def eql?(other)
    (other.is_a? LongDecimalQuot) && (self <=> other).zero? && scale == other.scale
  end

  #
  # compare two numbers for equality.
  # The LongDecimalQuot self is considered == to other if and only if
  # it expresses the same value
  # It needs to be observed that scale does not influence the value expressed
  # by the number, but only how rouding is performed by default if no
  # explicit number of digits after the decimal point is given.
  #
  def ==(other)
    if other.is_a? Numeric
      (self <=> other).zero?
    else
      false
    end
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
    format('LongDecimalQuot(Rational(%s, %s), %s)', numerator.inspect, denominator.inspect,
           scale.inspect)
  end
end

#
# Creates a LongDecimal number.  +a+ and +b+ should be Numeric.
#
def LongDecimal(a, b = 0)
  if b.zero? && (a.is_a? LongDecimal)
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
  def to_ld(prec = nil, mode = LongMath.standard_mode)
    return Complex(real.to_ld(prec, mode), imaginary.to_ld(prec, mode)) if is_a? Complex

    l = LongDecimal(self)
    if prec.nil?
      l
    else
      l.round_to_scale(prec, mode)
    end
  end

  #
  # test if 1 (like zero?)
  #
  def one?
    (self - 1).zero?
  end

  def sgn
    raw_sign = self <=> 0
    if raw_sign.negative?
      -1
    elsif raw_sign.zero?
      0
    else
      +1
    end
  end
end

class Complex
  alias cdiv /

  # fix problems with complex division depending on Ruby version
  case RUBY_VERSION
  when /^1\.8/
    #
    # Division by real or complex number for Ruby 1.8
    #
    def /(other)
      if other.is_a?(Complex)
        p = self * other.conjugate
        d = other.abs2
        r = p.real / d
        i = p.imag / d
        Complex(r, i)
      elsif Complex.generic?(other)
        Complex(@real / other, @image / other)
      elsif other.is_a? BigDecimal
        Complex(@real / other, @image / other)
      else
        x, y = other.coerce(self)
        x / y
      end
    end
  when /^1\.9/, /^2\.[0-9]/
    #
    # Division by real or complex number for Ruby >=1.9
    #
    def /(other)
      case other
      when Complex
        p = self * other.conjugate
        d = other.abs2
        r = nil
        i = nil
        r = if (d.is_a? Integer) && (p.real.is_a? Integer)
              Rational(p.real, d)
            else
              p.real / d
            end
        i = if (d.is_a? Integer) && (p.imag.is_a? Integer)
              Rational(p.imag, d)
            else
              p.imag / d
            end
        Complex(r, i)
      when Integer
        r = nil
        i = nil
        r = if (other.is_a? Integer) && (real.is_a? Integer)
              Rational(real, other)
            else
              real / other
            end
        i = if (other.is_a? Integer) && (imag.is_a? Integer)
              Rational(imag, other)
            else
              imag / other
            end
        Complex(r, i)
      when BigDecimal, Float, LongDecimal, Rational
        Complex(real / other, imag / other)
      else
        x, y = other.coerce(self)
        x / y
      end
    end
  end
end

class Rational
  #
  # convert self to LongDecimal.
  # Special handling of Rational to avoid loosing information in the
  # first step that would be needed for the second step
  # optional first argument gives the precision for the desired result
  # optional second argument gives the rouding mode
  #
  def to_ld(prec = nil, mode = LongMath.standard_mode)
    if prec.nil?
      LongDecimal(self)
    else
      l = LongDecimalQuot(self, prec)
      l.round_to_scale(prec, mode)
    end
  end

  # retain original to_f under different name
  alias to_f_orig to_f

  FLOAT_MAX_I         = Float::MAX.to_i
  FLOAT_SIGNIFICANT_I = 2**56

  unless RUBY_VERSION.match(/^1\.9/)

    # fix eql? for Ruby 1.8
    def eql?(other)
      (other.is_a? Rational) && numerator == other.numerator && denominator == other.denominator
    end

    # improved to_f, works better where numerator and denominator are integers beyond the range of float, but their Quotient is still expressable as Float
    def to_f
      num = numerator
      den = denominator
      # puts("num=#{num} den=#{den}")
      sign = num <=> 0
      # puts("num=#{num} den=#{den} sign=#{sign}")
      if sign.zero?
        return 0.0
      elsif sign.negative?
        num = -num
      end

      num_big = nil
      den_big = nil
      while num >= FLOAT_SIGNIFICANT_I && den >= FLOAT_SIGNIFICANT_I && (num >= FLOAT_MAX_I || den >= FLOAT_MAX_I)
        num += 0x80
        num >>= 8
        den += 0x80
        den >>= 8
      end

      if num >= FLOAT_MAX_I
        num = (num + (den / 2)) / den
        (sign * num).to_f
      elsif den >= FLOAT_MAX_I
        den = (den + (num / 2)) / num
        if den >= FLOAT_MAX_I
          0.0
        else
          sign / den.to_f
        end
      else
        sign * (num.to_f / den)
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
  include LongDecimalRoundingMode

  MAX_FLOATABLE   = Float::MAX.to_i
  MAX_FLOATABLE2  = MAX_FLOATABLE / 2
  # moved to bottom because of dependencies
  # MAX_FLOATABLE10 = 10.0 ** Float::MAX_10_EXP
  MAX_EXP_ABLE    = 709
  # moved to the bottom because of dependencies
  # MIN_FLOATABLE   = Float::MIN.to_ld(340, LongMath::ROUND_UP)

  # some arbritrary limit, so we do not exhaust too much memory.
  MAX_PREC = 2_097_161 # largest integral number n such that 10**n can be calculated in Ruby.
  DEFAULT_MAX_PREC = MAX_PREC / 10

  # maximum exponent of 0.1 yielding a non-zero result 0.1**n
  MAX_NEG_10_EXP  = Float::MAX_10_EXP + 16
  LOG2            = Math.log(2.0)
  LOG10           = Math.log(10.0)

  #
  # constants and module variables for LongMath.npower10
  #
  POWERS_SMALL_EXP_PARAM = 8
  POWERS_SMALL_EXP_LIMIT = 1 << POWERS_SMALL_EXP_PARAM  # 256
  POWERS_SMALL_EXP_MASK  = POWERS_SMALL_EXP_LIMIT - 1   # 255
  POWERS_MED_EXP_PARAM   = 16
  POWERS_MED_EXP_LIMIT   = 1 << POWERS_MED_EXP_PARAM  # 65536
  POWERS_MED_EXP_MASK    = POWERS_MED_EXP_LIMIT - 1   # 65535
  POWERS_BIG_EXP_LIMIT   = MAX_PREC

  # POWERS_BIG_BASE = 10**POWERS_MED_EXP_LIMIT: calculate on demand
  def self.powers_big_base
    npower10_cached(POWERS_MED_EXP_LIMIT)
  end

  # powers of powers_big_base
  def self.npower_of_big_base(n1)
    power = @@powers_of_big_base[n1]
    if power.nil?
      power = powers_big_base**n1
      @@powers_of_big_base[n1] = power
      # puts "npower_of_big_base(n1=#{n1}) c->#{power.size}"
    else
      # puts "npower_of_big_base(n1=#{n1}) c<-#{power.size}"
    end
    power
  end

  # stores power 10**i at position i (memoize pattern)
  @@small_powers_of_10 = []
  # stores power (POWERS_BIG_BASE)**i at position i (memoize pattern)
  @@powers_of_big_base = []

  # stores power 10.0**(-i) at position i (memoize pattern)
  @@negative_powers_of_10_f = []

  # keep certain common calculations in memory (memoize-pattern)
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
    def <=>(other)
      r = 0
      r = fname <=> if other.respond_to? :fname
                      other.fname
                    else
                      other
                    end
      return r if r != 0

      r = arg <=> if other.respond_to? :arg
                    other.arg
                  else
                    other
                  end
      return r if r != 0

      mode <=> if other.respond_to? :mode
                 other.mode
               else
                 other
               end
    end
  end

  #
  # lookup the upper limit for scale of LongDecimal
  #
  def self.prec_limit
    @@prec_limit ||= LongMath::DEFAULT_MAX_PREC
  end

  #
  # lookup the rule for handling errors with overflow of LongDecimal scale
  #
  def self.prec_overflow_handling
    @@prec_overflow_handling ||= :raise_error
  end

  #
  # set the rule for handling errors with overflow of LongDecimal scale
  # possible values are:
  # :raise_error  : immediately raise an error
  # :use_max      : tacitely reduce scale to the maximum allowed value
  # :warn_use_max : print a warning and reduce scale to the max allowed
  #
  def self.prec_overflow_handling=(poh)
    raise ArgumentError, "poh=#{poh} no accepted value" unless %i[raise_error use_max warn_use_max].include?(poh)

    @@prec_overflow_handling = poh
  end

  #
  # get the rule for handling errors with overflow of LongDecimal scale
  # possible values are:
  # :raise_error  : immediately raise an error
  # :use_max      : tacitely reduce scale to the maximum allowed value
  # :warn_use_max : print a warning and reduce scale to the max allowed
  #
  def self.prec_limit=(l = LongMath::DEFAULT_MAX_PREC)
    LongMath.check_is_int(l)
    raise ArgumentError, "#{l} must be >= #{Float::MAX_10_EXP}" unless l >= Float::MAX_10_EXP
    raise ArgumentError, "#{l} must be <= #{LongMath::MAX_PREC}" unless l <= LongMath::MAX_PREC

    @@prec_limit = l
  end

  #
  # check if arg is allowed for caching
  # if true, return key for caching
  # else return nil
  #
  def self.get_cache_key(fname, arg, mode, allowed_args)
    key = nil
    if (arg.is_a? Integer) || ((arg.is_a? LongDecimalBase) && arg.is_int?)
      arg = arg.to_i
      key = CacheKey.new(fname, arg, mode) unless allowed_args.index(arg).nil?
    end
    key
  end

  #
  # get a cached value, if available in the required precision
  #
  def self.get_cached(key, _arg, iprec)
    val = nil
    return nil if key.nil?

    val = @@cache[key]
    return nil if val.nil? || val.scale < iprec

    val
  end

  #
  # helper method for the check of type
  #
  def self.check_cacheable(x, s = 'x')
    raise TypeError, "#{s}=#{x} must be LongDecimal or Array of LongDecimal" unless (x.is_a? LongDecimal) || ((x.is_a? Array) && (x[0].is_a? LongDecimal))
  end

  #
  # store new value in cache, if it provides an improvement of
  # precision
  #
  def self.set_cached(key, val)
    unless key.nil? || val.nil?
      oval = @@cache[key]
      unless oval.nil?
        check_cacheable(val, 'val')
        check_cacheable(oval, 'oval')
        return if val.scale <= oval.scale
      end
      key.freeze
      case val
      when LongDecimal
        val.freeze_ld
      when Array
        val.each do |entry|
          if entry.is_a? LongDecimal
            entry.freeze_ld
          else
            entry.freeze
          end
        end
        val.freeze
      else
        val.freeze
      end
      @@cache[key] = val
    end
  end

  LOG_1E100 = Math.log(1e100)

  #
  # internal helper method for calculating the internal precision for power
  #
  def self.calc_iprec_for_power(x, y, prec)
    logx_f = LongMath.log_f(x.abs)
    x1 = (x.abs - 1).abs
    logx1_f = 0
    logx1_f = LongMath.log_f(x1).abs if x1.positive?
    prec = ((prec * Math.log(logx1_f)) + 5) if logx1_f > 5

    y_f = nil
    y_f = if y.abs <= LongMath::MAX_FLOATABLE
            y.to_f
          else
            y.round_to_scale(18, LongMath::ROUND_UP)
          end

    logx_y_f = logx_f * y_f

    raise ArgumentError, "power would be way too big: y*log(x)=#{logx_y_f}" if logx_y_f.abs > LongMath::MAX_FLOATABLE

    logx_y_f = logx_y_f.to_f unless logx_y_f.is_a? Float

    iprec_x  = calc_iprec_for_exp(logx_y_f.abs.ceil, prec, logx_y_f.negative?)
    iprec_y  = iprec_x
    iprec    = iprec_x + 2
    iprec_x -= (-1.5 + (logx_f / LOG10)).round if logx_f.negative?
    if y_f.abs < 1
      logy_f = LongMath.log_f(y.abs)
      iprec_y -= (- 1.5 + (logy_f / LOG10)).round
    end
    iprec = prec_limit if iprec > prec_limit
    iprec_x = prec_limit if iprec_x > prec_limit
    iprec_y = prec_limit if iprec_y > prec_limit
    [iprec, iprec_x, iprec_y, logx_y_f]
  end

  #
  # optimize calculation of power of 10 by non-negative integer,
  # because it is essential to LongDecimal to us it very often.
  # n is the exponent (must be >= 0 and Integer)
  #
  def self.npower10(n)
    check_is_prec(n, 'n', :raise_error, MAX_PREC)
    n0 = n & POWERS_MED_EXP_MASK
    n1 = n >> POWERS_MED_EXP_PARAM
    p  = npower10_cached(n0)
    if n1.positive?
      # puts "n0=#{n0} n1=#{n1}"
      p1 = npower_of_big_base(n1)
      # puts "n0=#{n0} n1=#{n1} p1"
      p *= p1
      # puts "n0=#{n0} n1=#{n1} p"
    end
    p
  end

  #
  # helper method for npower10
  # only for internal use
  #
  def self.npower10_cached(n)
    p = @@small_powers_of_10[n]
    if p.nil?
      n0 = n &  POWERS_SMALL_EXP_MASK
      n1 = n >> POWERS_SMALL_EXP_PARAM
      p = npower10_cached_small(n0)
      p *= npower10_cached_small(POWERS_SMALL_EXP_LIMIT)**n1 if n1.positive?
      @@small_powers_of_10[n] = p
    end
    p
  end

  #
  # helper method for npower10
  # only for internal use
  #
  def self.npower10_cached_small(n)
    p = @@small_powers_of_10[n]
    if p.nil?
      p = 10**n
      @@small_powers_of_10[n] = p
    end
    p
  end

  #
  # helper method for npower10
  # only for internal use
  #
  def self.neg_float_npower10(n)
    return 0.0 if n > MAX_NEG_10_EXP

    p = @@negative_powers_of_10_f[n]
    if p.nil?
      # p = 0.1 ** n
      p = "1e-#{n}".to_f # 0.1 ** n
      @@negative_powers_of_10_f[n] = p
    end
    p
  end

  #
  # helper method for internal use: checks if word_len is a reasonable
  # size for splitting a number into parts
  #
  def self.check_word_len(word_len, name = 'word_len')
    raise TypeError, "#{name} must be a positive number <= 1024" unless (word_len.is_a? Integer) && word_len.positive? && word_len <= 1024

    word_len
  end

  #
  # helper method for internal use: checks if parameter x is an Integer
  #
  def self.check_is_int(x, name = 'x')
    raise TypeError, "#{name}=#{x.inspect} must be Integer" unless x.is_a? Integer
  end

  #
  # helper method for internal use: checks if parameter x is a LongDecimal
  #
  def self.check_is_ld(x, _name = 'x')
    raise TypeError, "x=#{x.inspect} must be LongDecimal" unless x.is_a? LongDecimal
  end

  #
  # helper method for internal use: checks if parameter x is a
  # reasonable value for the precision (scale) of a LongDecimal
  #
  def self.check_is_prec(prec, name = 'prec', error_handling = nil, pl = prec_limit)
    raise TypeError, "#{name}=#{prec.inspect} must be Fixnum" unless prec.is_a? Integer
    raise ArgumentError, "#{name}=#{prec.inspect} must be >= 0" unless prec >= 0

    unless (prec.is_a? Integer) && prec <= MAX_32BIT_FIXNUM && prec <= pl
      poh = LongMath.prec_overflow_handling
      if poh == :raise_error || error_handling == :raise_error
        raise ArgumentError, "#{name}=#{prec.inspect} must be <= #{pl}"
      elsif poh == :warn_use_max
        warn "WARNING: #{name}=#{prec} too big => reduced to #{pl}"
        prec = pl
      elsif poh == :use_max
        prec = pl
      else
        raise ArgumentError,
              "unsupported value for prec_overflow_handling=#{poh} found #{name}=#{prec} > #{pl}"
      end
    end
    prec
  end

  #
  # helper method for internal use: checks if parameter x is a
  # rounding mode (instance of RoundingModeClass)
  #
  def self.check_is_mode(mode, name = 'mode')
    raise TypeError, "#{name}=#{mode.inspect} must be legal rounding mode" unless mode.is_a? RoundingModeClass
  end

  #
  # split number (Integer) x into parts of word_len bits each such
  # that the concatenation of these parts as bit patterns is x
  # (the opposite of merge_from_words)
  #
  def self.split_to_words(x, word_len = 32)
    check_word_len(word_len)
    check_is_int(x, 'x')
    m = x.abs
    s = (x <=> 0)
    bit_pattern = (1 << word_len) - 1
    words = []
    while m != 0 || words.empty?
      w = m & bit_pattern
      m = m >> word_len
      words.unshift(w)
    end
    words[0] = -words[0] if s.negative?
    words
  end

  #
  # concatenate numbers given in words as bit patterns
  # (the opposite of split_to_words)
  #
  def self.merge_from_words(words, word_len = 32)
    check_word_len(word_len)
    raise TypeError, 'words must be array of length > 0' unless (words.is_a? Array) && !words.empty?

    y = 0
    s = (words[0] <=> 0)
    words[0] = -words[0] if s.negative?
    words.each do |w|
      y = y << word_len
      y += w
    end
    y = -y if s.negative?
    y
  end

  #
  # calculate the square root of an integer x using bitwise algorithm
  # the result is rounded to an integer y such that
  # y**2&nbsp;<=&nbsp;x&nbsp;<&nbsp;(y+1)**2
  #
  def self.sqrtb(x)
    a = sqrtb_with_remainder(x)
    a[0]
  end

  #
  # calculate an integer s&nbsp;>=&nbsp;0 and a remainder r&nbsp;>=&nbsp;0 such that
  # x&nbsp;=&nbsp;s**2&nbsp;+&nbsp;r and s**2&nbsp;<=&nbsp;x&nbsp;<&nbsp;(s+1)**2
  # the bitwise algorithm is used, which works well for relatively
  # small values of x.
  #
  def self.sqrtb_with_remainder(x)
    check_is_int(x, 'x')

    s = (x <=> 0)
    if s.zero?
      return [0, 0]
    elsif s.negative?
      a = sqrtb_with_remainder(-x)
      return [Complex(0, a[0]), -a[1]]
    end

    xwords = split_to_words(x, 2)
    xi = xwords[0] - 1
    yi = 1

    1.upto(xwords.length - 1) do |i|
      xi = (xi << 2) + xwords[i]
      d0 = (yi << 2) + 1
      r  = xi - d0
      b  = 0
      if r >= 0
        b  = 1
        xi = r
      end
      yi = (yi << 1) + b
    end
    [yi, xi]
  end

  #
  # calculate the square root of an integer using larger chunks of the
  # number.  The optional parameter n provides the size of these
  # chunks.  It is by default chosen to be 16, which is optimized for
  # 32 bit systems, because internally parts of the double size are
  # used.
  # the result is rounded to an integer y such that
  # y**2&nbsp;<=&nbsp;x&nbsp;<&nbsp;(y+1)**2
  #
  def self.sqrtw(x, n = 16)
    a = sqrtw_with_remainder(x, n)
    a[0]
  end

  #
  # calculate the an integer s >= 0 and a remainder r >= 0 such that
  # x&nbsp;=&nbsp;s**2&nbsp;+&nbsp;r and s**2&nbsp;<=&nbsp;x&nbsp;<&nbsp;(s+1)**2
  # the wordwise algorithm is used, which works well for relatively
  # large values of x.  n defines the word size to be used for the
  # algorithm.  It is good to use half of the machine word, but the
  # algorithm would also work for other values.
  #
  def self.sqrtw_with_remainder(x, n = 16)
    check_is_int(x, 'x')
    check_is_int(n, 'n')

    n2 = n << 1
    n1 = n + 1
    check_word_len(n2, '2*n')

    s = (x <=> 0)
    if s.zero?
      return [0, 0]
    elsif s.negative?
      a = sqrtw_with_remainder(-x)
      return [Complex(0, a[0]), -a[1]]
    end

    xwords = split_to_words(x, n2)
    return sqrtb_with_remainder(xwords[0]) if xwords.length == 1

    xi = (xwords[0] << n2) + xwords[1]
    a  = sqrtb_with_remainder(xi)
    yi = a[0]
    return a if xwords.length <= 2

    # xi -= yi*yi
    xi = a[1]
    2.upto(xwords.length - 1) do |i|
      xi = (xi << n2) + xwords[i]
      d0 = (yi << n1)
      q  = (xi / d0).to_i
      j  = 10
      was_negative = false
      while true
        d = d0 + q
        r = xi - (q * d)
        break if r >= 0 && (r < d || was_negative)

        if r.negative?
          was_negative = true
          q -= 1
        else
          q += 1
        end
        j -= 1
        break if j <= 0
      end
      xi = r
      yi = (yi << n) + q
    end
    [yi, xi]
  end

  #
  # calculate the cubic root of an integer x using bitwise algorithm
  # the result is rounded to an integer y such that
  # y**3&nbsp;<=&nbsp;x&nbsp;<&nbsp;(y+1)**3
  #
  def self.cbrtb(x)
    a = cbrtb_with_remainder(x)
    a[0]
  end

  #
  # calculate an integer s&nbsp;>=&nbsp;0 and a remainder r&nbsp;>=&nbsp;0 such that
  # x&nbsp;=&nbsp;s**3&nbsp;+&nbsp;r and s**3&nbsp;<=&nbsp;x&nbsp;<&nbsp;(s+1)**3
  # for negative numbers x return negative remainder and result.
  # the bitwise algorithm is used, which works well for relatively
  # small values of x.
  #
  def self.cbrtb_with_remainder(x)
    check_is_int(x, 'x')

    s = (x <=> 0)
    if s.zero?
      return [0, 0]
    elsif s.negative?
      a = cbrtb_with_remainder(-x)
      return [-a[0], -a[1]]
    end

    # split into groups of three bits
    xwords = split_to_words(x, 3)
    xi = xwords[0] - 1
    yi = 1

    1.upto(xwords.length - 1) do |i|
      xi = (xi << 3) + xwords[i]
      d0 = (6 * yi * ((2 * yi) + 1)) + 1
      r  = xi - d0
      b  = 0
      if r >= 0
        b  = 1
        xi = r
      end
      yi = (yi << 1) + b
    end
    [yi, xi]
  end

  #
  # find the gcd of an Integer x with b**n0 where n0 is a sufficiently
  # high exponent
  # such that gcd(x, b**m) = gcd(x, b**n) for all m, n >= n0
  #
  def self.gcd_with_high_power(x, b)
    check_is_int(x, 'x')
    raise ZeroDivisionError, "gcd_with_high_power of zero with \"#{b.inspect}\" would be infinity" if x.zero?

    check_is_int(b, 'b')
    raise ZeroDivisionError, "gcd_with_high_power with b < 2 is not defined. b=\"#{b.inspect}\"" if b < 2

    s = x.abs
    exponent = 1
    b = b.abs
    exponent = (Math.log(s) / Math.log(b)).ceil if b < s && s < MAX_FLOATABLE
    power = b**exponent
    result = 1
    loop do
      f = s.gcd(power)
      s /= f
      result *= f
      break unless f > 1
    end
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
  def self.multiplicity_of_factor(x, prime_number)
    case x
    when Rational, LongDecimalQuot
      m1 = multiplicity_of_factor(x.numerator, prime_number)
      m2 = multiplicity_of_factor(x.denominator, prime_number)
      m1 - m2

    when LongDecimal
      m1 = multiplicity_of_factor(x.numerator, prime_number)
      if [2, 5].include?(prime_number)
        m1 - x.scale
      else
        m1
      end

    when Integer

      power = gcd_with_high_power(x, prime_number)
      if power.abs < MAX_FLOATABLE
        result = (Math.log(power) / Math.log(prime_number)).round
      else
        e = (Math.log(Float::MAX) / Math.log(prime_number)).floor
        result = 0
        partial = prime_number**e
        while power > partial
          power /= partial
          result += e
        end
        result += (Math.log(power) / Math.log(prime_number)).round
      end
      result
    else
      raise TypeError, "type of x is not supported #{x.class} #{x.inpect}"
    end
  end

  #
  # how many times can n be divided by 10?
  #
  def self.multiplicity_of_10(n)
    mul_2  = LongMath.multiplicity_of_factor(n, 2)
    mul_5  = LongMath.multiplicity_of_factor(n, 5)
    [mul_2, mul_5].min
  end

  #
  # find number of digits in base 10 needed to express the given
  # number n
  #
  def self.int_digits10(n)
    n = n.abs
    return 0 if n.zero?

    id = 1
    powers = []
    power  = 10
    idx    = 0
    until n.zero?
      expon       = 1 << idx
      powers[idx] = power
      break if n < power

      id += expon
      n = (n / power).to_i
      idx += 1
      power *= power
    end

    until n < 10
      idx -= 1
      expon = 1 << idx
      power = powers[idx]
      while n >= power
        id += expon
        n = (n / power).to_i
      end
    end
    id
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
  # parameters
  # prec precision of the end result
  # final_mode rounding mode to be used when creating the end result
  # iprec precision used internally
  # mode rounding_mode used internally
  # cache_result should the result be cached?  Set to false, if an
  # extraordinary long result is really needed only once
  #
  # DOWN?
  def self.pi(prec, final_mode = LongMath.standard_mode, iprec = nil, mode = nil, cache_result = true)
    prec = check_is_prec(prec, 'prec')
    mode = LongMath.standard_mode if mode.nil?
    check_is_mode(final_mode, 'final_mode')
    check_is_mode(mode, 'mode')

    # calculate internal precision
    iprec = 5 * (prec + 1) if iprec.nil?
    iprec = check_is_prec(iprec, 'iprec')
    sprec = (iprec >> 1) + 1
    dprec = (prec + 1) << 1

    # use caching so that pi is only calculated again if it has not
    # been done at least with the required precision
    cache_key = get_cache_key('pi', 0, mode, [0])
    curr_pi   = get_cached(cache_key, 0, sprec)
    if curr_pi.nil?

      a = LongDecimal(1)
      b = (1 / LongDecimal(2).sqrt(iprec, mode)).round_to_scale(iprec, mode)
      c = LongDecimal(5, 1)
      k = 1
      pow_k = 2

      curr_pi = 0
      last_pi = 0
      last_diff = 1

      loop do
        a, b    = ((a + b) / 2).round_to_scale(sprec, mode),
(a * b).round_to_scale(iprec, mode).sqrt(sprec, mode)
        c       = (c - (pow_k * ((a * a) - (b * b)))).round_to_scale(iprec, mode)
        curr_pi = (2 * a * a / c).round_to_scale(sprec, mode)
        diff = (curr_pi - last_pi).round_to_scale(dprec, mode).abs
        break if diff.zero? && last_diff.zero?

        last_pi = curr_pi
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
  # down?
  def self.exp(x, prec, mode = LongMath.standard_mode)
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_EXP_ABLE}" unless x <= MAX_EXP_ABLE

    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    exp_internal(x, prec, mode)
  end

  #
  # calc the base-2-exponential function of x to the given precision as
  # LongDecimal.  Only supports values of x such that the result still
  # fits into a float (x <= 709).  This limitation is somewhat
  # arbitrary, but it is enforced in order to avoid producing numbers
  # with the exponential function that exceed the memory.
  #
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
  #
  # down?
  def self.exp2(x, prec, mode = LongMath.standard_mode)
    LongMath.power(2, x, prec, mode)
  end

  #
  # calc the base-10-exponential function of x to the given precision as
  # LongDecimal.  Only supports values of x such that the result still
  # fits into a float (x <= 709).  This limitation is somewhat
  # arbitrary, but it is enforced in order to avoid producing numbers
  # with the exponential function that exceed the memory.
  #
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
  #
  # down?
  def self.exp10(x, prec, mode = LongMath.standard_mode)
    LongMath.power(10, x, prec, mode)
  end

  #
  # private helper method for exponentiation
  # calculate internal precision
  #
  def self.calc_iprec_for_exp(x, prec, x_was_neg)
    iprec_extra = 0
    if x > 1
      xf = x.to_f
      iprec_extra = (xf / LOG10).abs
    end
    iprec = (((prec + 12) * 1.20) + (iprec_extra * 1.10)).round
    iprec = [iprec, prec].max
    iprec += 2 if x_was_neg
    check_is_prec(iprec, 'iprec')
  end

  #
  # internal functionality of exp.  exposes some more parameters, that
  # should usually be set to default values, in order to allow better testing.
  # do not actually call this method unless you are testing exp.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  # x is the number of which we want to calculate the exponential function.
  # prec is the precision that we need to achieve for the final result.
  # final_mode is the rounding mode that we use for the end result
  # j number of summands that are grouped together for better performance of the calculation
  #   (defaults to the cube root of the desired number of base 2 digits to express the fractonal part of result.)
  # k is an integer such that calculation of exp(x/2**k) has good convergence.  We calculate that and finally take a power of the result:
  #   exp(x) = exp(x/2**k)**(2**k)
  # iprec is the precision used internally during the calculation
  # mode is the rounding mode used internally
  # cache_result indicates if the result of the calculation should be cached.
  #
  # down?
  def self.exp_internal(x, prec = nil, final_mode = LongMath.standard_mode, j = nil, k = nil, iprec = nil, mode = LongMath.standard_imode, cache_result = true)
    if prec.nil?
      if x.is_a? LongDecimalBase
        prec = x.scale
      else
        raise ArgumentError,
              "precision must be supplied either as precision of x=#{x} or explicitely"
      end
    end
    prec = check_is_prec(prec, 'prec')

    final_mode = LongMath.standard_mode if final_mode.nil?
    check_is_mode(final_mode, 'final_mode')
    check_is_mode(mode, 'mode')

    # if the result would come out to zero anyway, cut the work
    xi = x.to_i
    if (xi < -LongMath::MAX_FLOATABLE) || xi + 1 < (-prec * LOG10) - LOG2
      # the result is 1/4 of the smallest positive number that can be expressed with the given precision.
      # this is rounded according to the final rounding mode, yielding 0.00000...00 or 0.00000...01.
      return LongDecimal(25, prec + 2).round_to_scale(prec, final_mode)
    end

    # if x is negative, do the calculation with -x and take 1/exp(-x) as the final result later.
    x_was_neg = false
    if x.negative?
      x = -x
      x_was_neg = true
    end

    # calculate j and k if they are not given.
    if j.nil? || k.nil?
      s1 = (prec * LOG10 / LOG2)**(1.0 / 3.0)
      j = s1.round if j.nil?
      k = (s1 + (Math.log([1, prec].max) / LOG2)).round if k.nil?
      k += (Math.log(x.to_f) / LOG2).abs.round if x > 1
    end
    j = 1 if j <= 0
    k = 0 if k.negative?
    check_is_int(j, 'j')
    check_is_int(k, 'k')

    # calculate iprec if it is not given.
    iprec = calc_iprec_for_exp(x, prec, x_was_neg) if iprec.nil?
    iprec = check_is_prec(iprec, 'iprec')

    # we only cache exp(1), exp(10), exp(100), exp(MAX_EXP_ABLE.to_i), otherwise cache_key is returned as nil.
    cache_key = get_cache_key('exp', x, mode, [1, 10, 100, MAX_EXP_ABLE.to_i])
    y_k = get_cached(cache_key, x, iprec)

    # if the cache did not yield our result, calculate it.
    if y_k.nil?
      y_k = exp_raw(x, prec, j, k, iprec, mode)

      # keep result around for exp(1), exp(10), exp(100), exp(MAX_EXP_ABLE.to_i)
      set_cached(cache_key, y_k) if cache_result
    end

    # take 1/exp(-x) as result, if x was negative.
    y_k = y_k.reciprocal if x_was_neg
    y_k.round_to_scale(prec, final_mode)
  end

  #
  # calculation of exp(x) with precision used internally.  Needs to be
  # rounded to be accurate to all digits that are provided.
  #
  # x is the number of which we want to calculate the exponential function.
  # prec is the precision that we need to achieve for the final result.
  # final_mode is the rounding mode that we use for the end result
  # j number of summands that are grouped together for better performance of the calculation
  # k is an integer such that calculation of exp(x/2**k) has good convergence.  We calculate that and finally take a power of the result:
  #   exp(x) = exp(x/2**k)**(2**k)
  # iprec is the precision used internally during the calculation
  # mode is the rounding mode used internally
  # cache_result indicates if the result of the calculation should be cached.
  #
  def self.exp_raw(x, prec, j, k, iprec, mode)
    dprec = [(iprec * 0.9).round, prec].max

    # convert to LongDecimal, if necessary:
    x = x.to_ld(iprec, mode) unless x.is_a? LongDecimal

    # we use this x_k in the Taylor row:
    x_k = (x / (1 << k)).round_to_scale(iprec, mode)
    # x_k ** j
    x_j = (x_k**j).round_to_scale(iprec, mode)
    # vector with j entries
    s = [LongDecimal(0)] * j
    t = LongDecimal(1)
    last_t = 1
    f = 0

    # do the Taylor sum
    loop do
      # do the partial loop: i=0..j-1
      # we avoid excessive multiplication with powers of x_k and keep these to the final calculation, thus having to apply them only once for each i.
      j.times do |i|
        # s[i] = 1 / i! + x_k ** j / (i+j)! + x_k ** (2j) / (i+2*j)! + ...  + x_k ** (n*j) / f!
        s[i] += t
        f += 1
        # adjust: t = x_k**(n*j)/f!
        t = (t / f).round_to_scale(iprec, mode)
        break if t.zero?
      end
      # multiply t by x_k**j.  Detect when we can stop, if summands are zero or irrelevant for final result.
      break if t.zero?

      t = (t * x_j).round_to_scale(iprec, mode)
      break if t.zero?

      tr = t.round_to_scale(dprec, LongDecimal::ROUND_DOWN).abs
      break if t.zero?

      tu = t.unit
      break if tr <= tu && last_t <= tu

      last_t = tr
    end

    # calculate result exp(x_k)
    x_i = 1
    y_k = LongDecimal(0)
    j.times do |i|
      x_i = (x_i * x_k).round_to_scale(iprec, mode) if i.positive?
      y_k += (s[i] * x_i).round_to_scale(iprec, mode)
    end

    # square exp(x_k) k times to get exp(x):
    k.times do |_i|
      y_k = y_k.square.round_to_scale(iprec, mode)
    end

    y_k
  end

  #
  # calculate approximation of sqrt of a LongDecimal.
  #
  # down
  def self.sqrt(x, prec, mode = LongMath.standard_mode)
    LongMath.sqrt_internal(x, prec, mode, false)
  end

  #
  # calculate approximation of sqrt of a LongDecimal with remainder
  #
  def self.sqrt_with_remainder(x, prec)
    LongMath.sqrt_internal(x, prec, ROUND_DOWN, true)
  end

  #
  # internal helper method for calculationg sqrt and sqrt_with_remainder
  #
  def self.sqrt_internal(x, prec, mode, with_rem, cache_result = true)
    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    x = x.to_ld(2 * (prec + 1), mode) unless x.is_a? LongDecimal
    prec1 = prec
    prec1 += 1 unless with_rem
    cache_key = nil
    y_arr = nil
    unless with_rem || mode.major == MAJOR_GEOMETRIC || mode.major == MAJOR_QUADRATIC
      cache_key = get_cache_key('sqrt', x, mode, [2, 3, 5, 6, 7, 8, 10])
      y_arr = get_cached(cache_key, x, prec)
    end
    if y_arr.nil?
      y_arr = sqrt_raw(x, prec1, mode)
      def y_arr.scale
        self[0].scale
      end
      set_cached(cache_key, y_arr) if cache_result
    end
    if with_rem
      y_arr
    else
      y, r = y_arr
      if mode.major == MAJOR_GEOMETRIC || mode.major == MAJOR_QUADRATIC
        # we need to deal with the case that the square root is on the exact border
        y_lower = y.round_to_scale(prec, ROUND_DOWN)
        y_upper = y.round_to_scale(prec, ROUND_UP)
        # puts "mode=#{mode} x=#{x} y=#{y} r=#{r} y_lower=#{y_lower} y_upper=#{y_upper} prec=#{prec} prec1=#{prec1}"
        if r.zero?
          if y == y_lower
            # puts "r=0 y=y_lower=#{y_lower} (x=#{x} y_upper=#{y_upper} mode=#{mode})"
            return y_lower
          elsif y == y_upper
            # puts "r=0 y=y_upper=#{y_upper} (x=#{x} y_lower=#{y_lower} mode=#{mode})"
            return y_upper
          end
        end
        # puts "mode=#{mode} x=#{x} gm2=#{y_lower * y_upper} qm2=#{arithmetic_mean(prec*2+1, ROUND_HALF_UP, y_lower*y_lower, y_upper*y_upper)}"
        if (mode.major == MAJOR_GEOMETRIC && x == y_lower * y_upper) \
            || (mode.major == MAJOR_QUADRATIC && x == arithmetic_mean((prec1 * 2) + 1, ROUND_HALF_UP,
                                                                      y_lower * y_lower, y_upper * y_upper))
          if mode.minor == MINOR_UP || mode.minor == MINOR_CEILING
            # puts "r=0 y=#{y} on boundary: y_upper=#{y_upper} (x=#{x} y_lower=#{y_lower} mode=#{mode})"
            return y_upper
          elsif mode.minor == MINOR_DOWN || mode.minor == MINOR_FLOOR
            # puts "r=0 y=#{y} on boundary: y_lower=#{y_lower} (x=#{x} y_upper=#{y_upper} mode=#{mode})"
            return y_lower
          elsif (mode.minor == MINOR_EVEN && (y_upper[0]).zero?) || (mode.minor == MINOR_ODD && y_upper[0] == 1)
            # puts "r=0 y=#{y} on boundary odd/even: y_upper=#{y_upper} (x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} mode=#{mode})"
            return y_upper
          elsif (mode.minor == MINOR_EVEN && (y_lower[0]).zero?) || (mode.minor == MINOR_ODD && y_lower[0] == 1)
            # puts "r=0 y=#{y} on boundary odd/even: y_lower=#{y_lower} (x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} mode=#{mode})"
            return y_lower
          else
            raise ArgumentError,
                  "unsupported combination: x=#{x} prec=#{prec} prec1=#{prec1} mode=#{mode} y=#{y} r=#{r} y_lower=#{y_lower} y_upper=#{y_upper}"
          end
        end
      end

      mode = MODE_LOOKUP[[mode.major, MINOR_UP]] if (mode.minor == MINOR_EVEN || mode.minor == MINOR_ODD || mode.minor == MINOR_DOWN || mode.minor == MINOR_FLOOR) && r.positive?
      y.round_to_scale(prec, mode)

    end
  end

  #
  # calculate sqrt with remainder uncached
  #
  def self.sqrt_raw(x, new_scale1, rounding_mode)
    old_scale = (new_scale1 << 1)
    x = x.round_to_scale(old_scale, rounding_mode)
    root, rem = LongMath.sqrtw_with_remainder(x.int_val)
    y = LongDecimal(root, new_scale1)
    r = LongDecimal(rem, old_scale)
    [y, r]
  end

  #
  # calculate approximation of cbrt of a LongDecimal.
  #
  # down
  def self.cbrt(x, prec, mode = LongMath.standard_mode)
    LongMath.cbrt_internal(x, prec, mode, false)
  end

  #
  # calculate approximation of cbrt of a LongDecimal with remainder
  #
  def self.cbrt_with_remainder(x, prec)
    LongMath.cbrt_internal(x, prec, ROUND_DOWN, true)
  end

  #
  # internal helper method for calculationg cbrt and cbrt_with_remainder
  #
  def self.cbrt_internal(x, prec, mode, with_rem, cache_result = true)
    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    x = x.to_ld(3 * (prec + 1), mode) unless x.is_a? LongDecimal
    prec1 = prec
    prec1 += 1 unless with_rem
    cache_key = nil
    y_arr = nil
    unless with_rem || mode.major == MAJOR_CUBIC
      cache_key = get_cache_key('cbrt', x, mode, [2, 3, 5, 6, 7, 8, 10])
      y_arr = get_cached(cache_key, x, prec)
    end
    if y_arr.nil?
      y_arr = cbrt_raw(x, prec1, mode)
      def y_arr.scale
        self[0].scale
      end
      set_cached(cache_key, y_arr) if cache_result
    end
    if with_rem
      y_arr
    else
      y, r = y_arr
      if mode.major == MAJOR_CUBIC
        # we need to deal with the case that the square root is on the exact border
        y_lower = y.round_to_scale(prec, ROUND_DOWN)
        y_upper = y.round_to_scale(prec, ROUND_UP)
        # puts "mode=#{mode} x=#{x} y=#{y} r=#{r} y_lower=#{y_lower} y_upper=#{y_upper} prec=#{prec} prec1=#{prec1}"
        if r.zero?
          if y == y_lower
            # puts "r=0 y=y_lower=#{y_lower} (x=#{x} y_upper=#{y_upper} mode=#{mode})"
            return y_lower
          elsif y == y_upper
            # puts "r=0 y=y_upper=#{y_upper} (x=#{x} y_lower=#{y_lower} mode=#{mode})"
            return y_upper
          end
        end
        # puts "mode=#{mode} x=#{x} gm2=#{y_lower * y_upper} qm2=#{arithmetic_mean(prec*2+1, ROUND_HALF_UP, y_lower*y_lower, y_upper*y_upper)}"
        if mode.major == MAJOR_CUBIC && x == arithmetic_mean((prec1 * 3) + 1, ROUND_HALF_UP,
                                                             y_lower.cube, y_upper.cube)
          if mode.minor == MINOR_UP || mode.minor == MINOR_CEILING
            # puts "r=0 y=#{y} on boundary: y_upper=#{y_upper} (x=#{x} y_lower=#{y_lower} mode=#{mode})"
            return y_upper
          elsif mode.minor == MINOR_DOWN || mode.minor == MINOR_FLOOR
            # puts "r=0 y=#{y} on boundary: y_lower=#{y_lower} (x=#{x} y_upper=#{y_upper} mode=#{mode})"
            return y_lower
          elsif (mode.minor == MINOR_EVEN && (y_upper[0]).zero?) || (mode.minor == MINOR_ODD && y_upper[0] == 1)
            # puts "r=0 y=#{y} on boundary odd/even: y_upper=#{y_upper} (x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} mode=#{mode})"
            return y_upper
          elsif (mode.minor == MINOR_EVEN && (y_lower[0]).zero?) || (mode.minor == MINOR_ODD && y_lower[0] == 1)
            # puts "r=0 y=#{y} on boundary odd/even: y_lower=#{y_lower} (x=#{x} y_lower=#{y_lower} y_upper=#{y_upper} mode=#{mode})"
            return y_lower
          else
            raise ArgumentError,
                  "unsupported combination: x=#{x} prec=#{prec} prec1=#{prec1} mode=#{mode} y=#{y} r=#{r} y_lower=#{y_lower} y_upper=#{y_upper}"
          end
        end
      end

      mode = MODE_LOOKUP[[mode.major, MINOR_UP]] if (mode.minor == MINOR_EVEN || mode.minor == MINOR_ODD || mode.minor == MINOR_DOWN || mode.minor == MINOR_FLOOR) && r.positive?
      y.round_to_scale(prec, mode)

    end
  end

  #
  # calculate cbrt with remainder uncached
  #
  def self.cbrt_raw(x, new_scale1, rounding_mode)
    old_scale = (new_scale1 * 3)
    x = x.round_to_scale(old_scale, rounding_mode)
    root, rem = LongMath.cbrtb_with_remainder(x.int_val)
    y = LongDecimal(root, new_scale1)
    r = LongDecimal(rem, old_scale)
    [y, r]
  end

  #
  # calculate the natural logarithm function of x to the given precision as
  # LongDecimal.
  #
  # down?
  def self.log(x, prec, mode = LongMath.standard_mode)
    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    log_internal(x, prec, mode)
  end

  #
  # internal functionality of log.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing log.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def self.log_internal(x, prec = nil, final_mode = LongMath.standard_mode, iprec = nil, mode = LongMath.standard_imode, cache_result = true)
    raise TypeError, "x=#{x.inspect} must not be positive" unless x.positive?

    if prec.nil?
      if x.is_a? LongDecimalBase
        prec = x.scale
      else
        raise ArgumentError,
              "precision must be supplied either as precision of x=#{x} or explicitely"
      end
    end
    prec = check_is_prec(prec, 'prec')

    final_mode = LongMath.standard_mode if final_mode.nil?
    check_is_mode(final_mode, 'final_mode')
    check_is_mode(mode, 'mode')

    iprec = ((prec + 12) * 1.20).round if iprec.nil?
    iprec = prec if iprec < prec
    iprec = check_is_prec(iprec, 'iprec')
    x = x.to_ld(iprec, mode) unless x.is_a? LongDecimal
    return LongDecimal.zero!(prec) if x.one?

    cache_key = get_cache_key('log', x, mode, [2, 3, 5, 10])
    y = get_cached(cache_key, x, iprec)
    if y.nil?
      y = log_raw(x, prec, iprec, mode)
      set_cached(cache_key, y) if cache_result
    end

    y.round_to_scale(prec, final_mode)
  end

  #
  # calculate log with all digits used internally.
  # result needs to be rounded in order to ensure that all digits that
  # are provided are correct.
  #
  def self.log_raw(x, _prec, iprec, mode)
    # we have to rely on iprec being at least 10
    raise TypeError, "iprec=#{iprec} out of range" unless (iprec.is_a? Integer) && iprec >= 10 && iprec <= MAX_32BIT_FIXNUM

    dprec = iprec - 1

    # result is stored in y
    y = 0
    # sign of result
    s = 1
    # make sure x is >= 1
    mode1 = mode
    if x < 1
      mode1 = mode1.minverse
      x = (1 / x).round_to_scale(iprec, mode1)
      s = -1
    end

    # number that are beyond the usual range of Float need to be
    # handled specially to reduce to something expressable as Float
    exp_keys = [MAX_EXP_ABLE.to_i, 100, 10, 1]
    exp_keys.each do |exp_key|
      exp_val = exp(exp_key, iprec)
      while x > exp_val
        x = (x / exp_val).round_to_scale(iprec, mode1)
        if s.negative?
          y -= exp_key
        else
          y += exp_key
        end
      end
    end

    factor = 1
    sprec  = (iprec * 1.5).round
    delta  = LongDecimal(1, (iprec.to_f**0.45).round)
    while (x - 1).abs > delta
      x       = LongMath.sqrt(x, sprec, mode1)
      factor *= 2
    end

    ss = 1
    mode2 = mode1.ainverse
    if x < 1
      mode2 = mode2.ainverse
      x = (1 / x).round_to_scale(iprec, mode2)
      ss = -1
    end

    sum = 0
    z   = 1 - x
    i   = 1
    p   = 1.to_ld
    d   = 1.to_ld
    until p.abs.round_to_scale(dprec, LongDecimal::ROUND_DOWN).zero?
      p = (p * z).round_to_scale(iprec, mode2)
      d = (p / i).round_to_scale(iprec, mode2)
      i += 1
      sum += d

    end
    sum *= ss

    y -= ((s * factor) * sum).round_to_scale(iprec, mode.ainverse)
    y
  end

  #
  # calculate the base 10 logarithm of x to the given precision as
  # LongDecimal.
  #
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
  #
  # down?
  def self.log10(x, prec, mode = LongMath.standard_mode)
    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    iprec = prec + 6
    x = x.to_ld(iprec, mode) unless x.is_a? LongDecimal
    return LongDecimal.zero!(prec) if x.one?

    id = x.int_digits10
    xx = x.move_point_left(id)
    lnxx = log_internal(xx, iprec, mode)
    ln10 = log_internal(10, iprec, mode)
    id + (lnxx / ln10).round_to_scale(prec, mode)
  end

  #
  # calculate the base 2 logarithm of x to the given precision as
  # LongDecimal.
  #
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
  #
  def self.log2(x, prec, mode = LongMath.standard_mode)
    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    iprec = prec + 6
    x = x.to_ld(iprec, mode) unless x.is_a? LongDecimal
    return LongDecimal.zero!(prec) if x.one?

    id = x.int_digits2
    xx = (x / (1 << id)).round_to_scale(x.scale + id)
    lnxx = log_internal(xx, iprec, mode)
    ln2  = log_internal(2.to_ld, iprec, mode)
    id + (lnxx / ln2).round_to_scale(prec, mode)
  end

  #
  # calculate the natural logarithm of x as floating point number,
  # even if x cannot reasonably be expressed as Float.
  #
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
  #
  def self.log_f(x)
    raise TypeError, "x=#{x.inspect} must not be positive" unless x.positive?

    unless x.is_a? LongDecimal
      x_rounded = x.to_ld(18, LongDecimalRoundingMode::ROUND_HALF_UP)
      if x_rounded.one?
        # x rounds to 1, if we cut of the last digits?
        # near 1 the derivative of log(x) is approximately 1, so we can assume log_f(x) ~ x-1
        return x - 1
      else
        x = x_rounded
      end
    end
    y = 0
    while x > LongMath::MAX_FLOATABLE
      y += LOG_1E100
      x  = x.move_point_left(100)
    end
    while x < LongMath::MIN_FLOATABLE
      y -= LOG_1E100
      x  = x.move_point_right(100)
    end
    x_f = x.to_f
    y  += Math.log(x_f)
    y
  end

  # logarithms of integers to base 2
  LOGARR = [nil, \
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
            8.0].freeze

  def self.log2int(x)
    raise TypeError, "x=#{x.inspect} must be Integer" unless x.is_a? Integer
    raise ArgumentError, "x=#{x} < 0" if x <= 0

    s = x.size
    l = [(8 * s) - 36, 0].max

    xx = x >> l
    while xx >= 256
      l += 1
      xx = xx >> 1
    end
    yy = LOGARR[xx]
    l + yy
  end

  #
  # calc the power of x with exponent y to the given precision as
  # LongDecimal.  Only supports values of y such that the result still
  # fits into a float
  #
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
  #
  def self.power(x, y, prec, mode = LongMath.standard_mode)
    raise TypeError, "x=#{x} must be numeric" unless x.is_a? Numeric
    raise TypeError, "y=#{y} must be numeric" unless y.is_a? Numeric
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "y=#{y.inspect} must not be greater #{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE

    if y.negative? && x.zero?
      raise TypeError,
            "y=#{y.inspect} must not be negative if base is zero}"
    end
    raise TypeError, "x=#{x.inspect} must not negative" unless x >= 0

    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    # puts "LongMath.power(x=#{x} y=#{y} prec=#{prec} mode=#{mode})"

    # handle the special cases where base or exponent are 0 or 1 explicitely
    if y.zero?
      return LongDecimal.one!(prec)
    elsif x.zero?
      return LongDecimal.zero!(prec)
    elsif y.one?
      return x.to_ld(prec, mode)
    elsif x.one?
      return LongDecimal.one!(prec)
    end

    # could be result with our precision
    # x ** y <= 10**-s/2  <=> y * log(x) <= -s log(10) - log(2)

    iprec, iprec_x, iprec_y, logx_y_f = calc_iprec_for_power(x, y, prec)
    # puts "x=#{x} y=#{y} prec=#{prec} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y} logx_y_f=#{logx_y_f}: checking x < 1 && y > 0 || x > 1 && y < 0=#{x < 1 && y > 0 || x > 1 && y < 0}"
    $stdout.flush
    if ((x < 1 && y.positive?) || (x > 1 && y.negative?)) && (logx_y_f <= (- prec * LOG10) - LOG2)
      # puts "checking if zero logx_y_f=#{logx_y_f} <= #{- prec * LOG10 - LOG2}"
      return LongDecimal.zero!(prec)
    end

    x = x.to_ld(iprec_x, mode) unless (x.is_a? LongDecimalBase) || (x.is_a? Integer)
    y = y.to_ld(iprec_y, mode) unless (y.is_a? LongDecimalBase) || (y.is_a? Integer)

    # try shortcut if exponent is an integer
    y = y.to_i if (y.is_a? LongDecimalBase) && y.is_int?
    unless y.is_a? Integer
      y2 = y * 2
      y2 = y2.to_i if (y2.is_a? LongDecimalBase) && y2.is_int?
      if y2.is_a? Integer
        x = LongMath.sqrt(x, 2 * iprec_x, mode)
        y = y2
      end
    end
    if y.is_a? Integer
      x = x.to_ld(iprec_x) unless x.is_a? LongDecimal
      z = LongMath.ipower(x, y, 2 * iprec, mode)
      return z.to_ld(prec, mode)
    end

    # it can be assumed that the exponent is not an integer, so it should
    # be converted into LongDecimal
    y = y.to_ld(iprec_y, mode) unless y.is_a? LongDecimal

    # if x < 1 && y < 0 then
    # working with x < 1 should be improved, less precision needed
    if x < 1
      # since we do not allow x < 0 and we have handled x = 0 already,
      # we can be sure that x is no integer, so it has been converted
      # if necessary to LongDecimalBase
      y = -y
      x = (1 / x).round_to_scale(iprec_x * 2, mode)
      iprec, iprec_x, iprec_y, logx_y_f = calc_iprec_for_power(x, y, prec)
      # puts "x=#{x} y=#{y} prec=#{prec} iprec=#{iprec} iprec_x=#{iprec_x} iprec_y=#{iprec_y} logx_y_f=#{logx_y_f}: checking x < 1 && y > 0 || x > 1 && y < 0=#{x < 1 && y > 0 || x > 1 && y < 0}"
      $stdout.flush
      if ((x < 1 && y.positive?) || (x > 1 && y.negative?)) && (logx_y_f <= (- prec * LOG10) - LOG2)
        # puts "checking if zero logx_y_f=#{logx_y_f} <= #{- prec * LOG10 - LOG2}"
        return LongDecimal.zero!(prec)
      end
    end

    # exponent is split in two parts, an integer part and a
    # LongDecimal with absolute value <= 0.5
    y0 = y.round_to_scale(0, LongMath.standard_imode).to_i
    x0 = x
    point_shift = 0
    # puts "x0=#{x0} y0=#{y0}"
    while x0 > LongMath::MAX_FLOATABLE
      x0 = x0.move_point_left(100)
      point_shift += 100
    end
    iprec2 = 2 * (iprec + point_shift)
    iprec3 = [iprec2, LongMath.prec_limit - 24].min
    # puts "x0=#{x0} y0=#{y0} point_shift=#{point_shift} iprec=#{iprec} iprec2=#{iprec2} iprec3=#{iprec3}"
    z0 = LongMath.ipower(x0, y0, iprec3, mode)
    if point_shift.positive?
      z0 = z0.to_ld(2 * (iprec + point_shift)) unless z0.is_a? LongDecimal
      z0 = z0.move_point_right(point_shift * y0)
    end
    y1 = y - y0
    prec_extra = 0
    prec_extra = (y0 * Math.log10(x.to_f).abs).ceil if y0.positive?
    # z1 = LongMath.power_internal(x, y1, prec+prec_extra , mode)
    z1 = LongMath.power_internal(x, y1, prec + prec_extra + 4, mode)
    z  = z0 * z1
    # puts("x=#{x} y=#{y} z=#{z} y not int")
    z.to_ld(prec, mode)
  end

  #
  # internal functionality to calculate the y-th power of x assuming
  # that y is an integer
  # prec is a hint on how much internal precision is needed at most
  # final rounding is left to the caller
  #
  def self.ipower(x, y, prec, mode)
    t0 = Time.now
    raise TypeError, "base x=#{x} must be numeric" unless x.is_a? Numeric
    raise TypeError, "exponent y=#{y} must be integer" unless y.is_a? Integer
    raise TypeError, "base x=#{x.inspect} must not be greater MAX_FLOATABLE=#{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "exponent y=#{y.inspect} must not be greater MAX_FLOATABLE=#{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE

    prec = check_is_prec(prec, 'prec')
    check_is_mode(mode, 'mode')
    # puts "LongMath.ipower(x=#{x} y=#{y} prec=#{prec} mode=#{mode})"

    if y.zero?
      1
    elsif !(x.is_a? LongDecimalBase) || x.scale * y.abs <= prec
      # puts "x=#{x} y=#{y} using **"
      x**y
    elsif y.negative?
      l = Math.log10(x.abs.to_f)
      prec += (2 * l).ceil if l.positive?
      # return (1/LongMath.ipower(x, -y, prec + 2, mode)).round_to_scale(prec, mode)
      xi = 1 / x
      # puts "x=#{x} y=#{y} prec=#{prec} using (1/x)**y xi=#{xi}"
      xr = xi.round_to_scale(prec + 6, mode)
      LongMath.ipower(xr, -y, prec, mode)
    else
      # y > 0
      # puts "x=#{x} y=#{y} regular"
      cnt = 0
      z = x
      y0 = y
      x0 = x
      loop do
        cnt + +
        y -= 1
        break if y.zero?

        while (y & 0x01).zero?

          cnt + +
          y = y >> 1
          x = (x * x)
          x = x.round_to_scale(prec + 4, mode) if x.is_a? LongDecimalBase
          if cnt > 1000
            # puts("ipower x=#{x} y=#{y} cnt=#{cnt} z=#{z} t=#{Time.now - t0}")
            cnt = 0
          end

        end
        z *= x
        if z.is_a? LongDecimalBase
          z = z.round_to_scale(prec + 3, mode)
          break if z.zero?
        end
      end
      # puts "z=#{z} rounding prec=#{prec}"
      z.round_to_scale(prec, mode)
      # puts "rounded -> z=#{z}"

    end
  end

  #
  # internal functionality of exp.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing exp.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def self.power_internal(x, y, prec = nil, final_mode = LongMath.standard_mode, iprec = nil, mode = LongMath.standard_imode)
    if prec.nil?
      if (x.is_a? LongDecimalBase) && (y.is_a? LongDecimalBase)
        prec = [x.scale, y.scale].max
      elsif x.is_a? LongDecimalBase
        prec = x.scale
      elsif y.is_a? LongDecimalBase
        prec = y.scale
      else
        raise ArgumentError,
              "precision must be supplied either as precision of x=#{x} or explicitely"
      end
    end
    prec = check_is_prec(prec, 'prec')

    final_mode = LongMath.standard_mode if final_mode.nil?
    check_is_mode(final_mode, 'final_mode')
    check_is_mode(mode, 'mode')

    if y.zero?
      return LongDecimal.one!(prec)
    elsif x.zero?
      return LongDecimal.zero!(prec)
    end

    iprec, iprec_x, iprec_y = calc_iprec_for_power(x, y, prec) if iprec.nil?
    unless x.is_a? LongDecimal
      # x = x.to_ld(iprec, mode)
      x = x.to_ld(iprec_x, mode)
    end
    unless y.is_a? LongDecimal
      # y = y.to_ld(iprec, mode)
      y = y.to_ld(iprec_y, mode)
    end

    # logx = log(x, iprec, mode)
    logx = log(x, iprec + 20, mode)
    logx_y = logx * y
    # xy = exp_internal(logx_y, prec + 1, mode)
    # xy = exp_internal(logx_y, prec + 4, mode)
    xy = exp_internal(logx_y, prec + 3, mode)
    xy.round_to_scale(prec, final_mode)
  end

  # helper for means
  def self.sign_check_for_mean(allow_different_signs, *args)
    raise ArgumentError, 'cannot calculate mean of empty array' if args.empty?

    first = args[0]
    has_neg = false
    has_pos = false
    has_zero = false
    all_same = true
    result_sign = 0
    args.each do |x|
      raise ArgumentError, "cannot calculate mean of a non-numeric array #{args.inspect}" unless x.is_a? Numeric
      raise ArgumentError, "mean not supported for complex numbers args=#{args.inspect}" if x.is_a? Complex

      all_same = false if all_same && x != first
      sign = x.sgn
      if sign.negative?
        has_neg = true
        result_sign = sign
      elsif sign.positive?
        has_pos = true
        result_sign = sign
      else
        has_zero = true
      end
      if has_neg && has_pos && !allow_different_signs
        raise ArgumentError,
              "signs of parameters have to match for quadratic mean args=#{args.inspect}"
      end
    end
    [result_sign, all_same, has_neg, has_zero, has_pos]
  end

  # arithmetic mean
  def self.arithmetic_mean(new_scale, rounding_mode, *args)
    raise ArgumentError, 'cannot calculate average of empty array' if args.empty?

    sum = args.inject(LongDecimal.zero!(((1.5 * new_scale) + 25).to_i)) do |psum, x|
      psum + x
    end
    raw_result = if sum.is_a? Integer
                   Rational(sum, args.size)
                 else
                   sum / args.size
                 end
    raw_result.to_ld(new_scale, rounding_mode)
    # puts "sum=#{sum} args.size=#{args.size} raw_result=#{raw_result} result=#{result} new_scale=#{new_scale} rounding_mode=#{rounding_mode}"
  end

  # arithmetic mean with LongDecimalQuot as result (experimental)
  # parameters arguments for which arithmetic mean is calculated
  # result is exact if parameters are Integer, LongDecimal, LongDecimalQuot or Rational
  def self.arithmetic_mean_ldq(*args)
    raise ArgumentError, 'cannot calculate average of empty array' if args.empty?

    sum = args.inject(LongDecimalQuot(0, 0)) do |psum, x|
      psum + x
    end
    sum / args.size
  end

  class << LongMath
    alias average arithmetic_mean
  end

  # geometric mean
  def self.geometric_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    return args[0].to_ld(new_scale, rounding_mode) if all_same
    return LongDecimal.zero!(new_scale) if has_zero

    prod = args.inject(LongDecimal.one!(new_scale + 20)) do |pprod, x|
      pprod * x.abs
    end
    result = nil
    n = args.size
    result = if [0, 1].include?(n)
               prod.to_ld(new_scale, rounding_mode)
             elsif n == 2
               LongMath.sqrt(prod, new_scale, rounding_mode)
             elsif n == 3
               LongMath.cbrt(prod, new_scale, rounding_mode)
             else
               LongMath.power(prod, Rational(1, args.size), new_scale, rounding_mode)
             end
    result = -result if has_neg
    result
  end

  # harmonic mean
  def self.harmonic_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    return args[0].to_ld(new_scale, rounding_mode) if all_same

    if has_zero
      raise ArgumentError,
            "cannot calculate harmonic mean of argument list containing zero #{args.inspect}"
    end

    sum = args.inject(LongDecimal.zero!) do |psum, x|
      psum + if x.is_a? Integer
               Rational(1, x)
             else
               LongDecimal.one!(new_scale + 1) / x
             end
    end
    raw_result = args.size / sum
    raw_result.to_ld(new_scale, rounding_mode)
  end

  # harmonic mean with LongDecimalQuot as result (experimental)
  # parameters arguments for which arithmetic mean is calculated
  # result is exact if parameters are Integer, LongDecimal, LongDecimalQuot or Rational
  def self.harmonic_mean_ldq(*args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    return LongDecimalQuot(args) if all_same

    if has_zero
      raise ArgumentError,
            "cannot calculate harmonic mean of argument list containing zero #{args.inspect}"
    end

    sum = args.inject(LongDecimalQuot(0, 0)) do |psum, x|
      psum + if x.is_a? Integer
               Rational(1, x)
             else
               1 / x
             end
    end
    args.size / sum
  end

  # arithmetic-geometric mean (AGM)
  def self.arithmetic_geometric_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    return args[0].to_ld(new_scale, rounding_mode) if all_same

    prec = ((new_scale * 1.1) + 20).to_i
    x = arithmetic_mean(prec, rounding_mode, *args)
    y = geometric_mean(prec, rounding_mode, *args)
    delta = 3 * x.unit
    while (x - y).abs >= delta
      xn = arithmetic_mean(prec, rounding_mode, x, y)
      yn = geometric_mean(prec, rounding_mode, x, y)
      x = xn
      y = yn
    end
    x.round_to_scale(new_scale, rounding_mode)
  end

  # harmonic-geometric mean (HGM)
  def self.harmonic_geometric_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    return args[0].to_ld(new_scale, rounding_mode) if all_same

    prec = ((new_scale * 1.1) + 20).to_i
    x = harmonic_mean(prec, rounding_mode, *args)
    y = geometric_mean(prec, rounding_mode, *args)
    delta = 3 * x.unit
    while (x - y).abs >= delta
      xn = harmonic_mean(prec, rounding_mode, x, y)
      yn = geometric_mean(prec, rounding_mode, x, y)
      x = xn
      y = yn
    end
    x.round_to_scale(new_scale, rounding_mode)
  end

  # quadratic mean
  def self.quadratic_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    return args[0].to_ld(new_scale, rounding_mode) if all_same

    sum = args.inject(LongDecimal.zero!) do |psum, x|
      x = x.to_ld((2 * new_scale) + 20) if !(x.is_a? LongDecimalBase) && !(x.is_a? Rational)
      psum + (x * x)
    end
    quot = if sum.is_a? Integer
             Rational(sum, args.size)
           else
             sum / args.size
           end
    result = LongMath.sqrt(quot, new_scale, rounding_mode)
    result = -result if has_neg
    result
  end

  # cubic mean
  def self.cubic_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(false, *args)
    return args[0].to_ld(new_scale, rounding_mode) if all_same

    sum = args.inject(LongDecimal.zero!) do |psum, x|
      raise ArgumentError, "cubic mean not supported for complex numbers args=#{args.inspect}" if x.is_a? Complex

      x = x.to_ld((2 * new_scale) + 20) if !(x.is_a? LongDecimalBase) && !(x.is_a? Rational)
      psum + (x**3)
    end
    quot = if sum.is_a? Integer
             Rational(sum, args.size)
           else
             sum / args.size
           end
    LongMath.cbrt(quot, new_scale, rounding_mode)
  end

  # helper class for round_sum
  class RawElement
    include LongDecimalRoundingMode

    def initialize(element, new_scale, rounding_mode = ROUND_FLOOR)
      @element = element
      @rounded = element.to_ld(new_scale, rounding_mode)
      @delta   = @element - @rounded
    end

    def add(epsilon)
      @rounded += epsilon
    end

    attr_reader :element, :rounded, :delta

    def <=>(other)
      delta <=> other.delta
    end
  end

  # round elements in such a way that round(new_scale, rounding_mode_sum, sum(elements)) = sum(elements_rounded)
  # HAARE_NIEMEYER
  #  (experimental)
  def self.round_sum_hm(new_scale, rounding_mode_sum, *elements)
    return elements if elements.empty?

    raw_sum = elements.inject(0) do |psum, x|
      psum + x
    end
    sum = raw_sum.to_ld(new_scale, rounding_mode_sum)
    raw_elements = elements.map do |element|
      RawElement.new(element, new_scale)
    end
    raw_elements_sum = raw_elements.inject(0) do |psum, element|
      psum + element.rounded
    end
    delta = sum - raw_elements_sum
    epsilon = LongDecimal(1, new_scale)
    raw_elements_sorted = raw_elements.sort.reverse
    n = (delta / epsilon).to_ld(0, ROUND_HALF_EVEN).to_i
    puts "delta=#{delta} epsilon=#{epsilon} n=#{n} sum=#{sum} raw_sum=#{raw_sum}"
    n.times do |i|
      raw_elements_sorted[i].add(epsilon)
    end
    result = raw_elements.map(&:rounded)
  end

  # round elements in such a way that round(new_scale, rounding_mode, sum(elements)) = sum(elements_rounded)
  # where rounding_mode_set is
  #  (experimental)
  def self.round_sum_divisor(new_scale, rounding_mode_sum, rounding_mode_set, *elements)
    return elements if elements.empty?

    delta = -1
    raw_sum = elements.inject(0) do |psum, x|
      psum + x
    end
    sum = raw_sum.to_ld(new_scale, rounding_mode_sum)
    raw_elements = elements.map do |element|
      RawElement.new(element, new_scale, rounding_mode_set)
    end
    loop do
      raw_elements_sum = raw_elements.inject(0) do |psum, element|
        psum + element.rounded
      end
      delta = sum - raw_elements_sum
      break if delta.zero?

      factor = (1 + (delta / raw_elements_sum))
      puts("delta=#{delta} raw_elements_sum=#{raw_elements_sum} factor=#{factor}")
      raw_elements = raw_elements.map do |element|
        RawElement.new(element.element * factor, new_scale, rounding_mode_set)
      end
    end
    result = raw_elements.map(&:rounded)
  end

  @@standard_mode = ROUND_HALF_UP

  # default to be used as rounding mode when no explicit mode is provided
  def self.standard_mode
    @@standard_mode
  end

  # set default to be used as rounding mode when no explicit mode is provided
  def self.standard_mode=(x)
    LongMath.check_is_mode(x)
    @@standard_mode = x
  end

  @@standard_imode = ROUND_HALF_EVEN

  def self.standard_imode
    @@standard_imode
  end

  def self.standard_imode=(x)
    LongMath.check_is_mode(x)
    @@standard_imode = x
  end

  MAX_FLOATABLE10 = LongMath.npower10(Float::MAX_10_EXP)
  MIN_FLOATABLE   = Float::MIN.to_ld(340, LongMath::ROUND_UP)
  INV_MIN_FLOATABLE = MIN_FLOATABLE.reciprocal.round_to_scale(0, LongMath::ROUND_HALF_UP).to_i
  # numbers >= FLOATABLE_WITHOUT_FRACTION yield the same result when converted to Float, regardless of what follows after the decimal point
  FLOATABLE_WITHOUT_FRACTION = (2 / Float::EPSILON).to_i
  MAX_SIGNIFICANT_FLOATABLE_DIGITS = Float::DIG + 1
end

# end of file long-decimal.rb
