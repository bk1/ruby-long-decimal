#
# long-decimal.rb -- Arbitrary precision decimals with fixed decimal point
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2009
#
# This class contains the basic functionality for working with LongDecimal
# additional functionality, mostly transcendental functions,
# may be found in long-decimal-extra.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/lib/long-decimal.rb,v 1.87 2011/01/30 20:01:40 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "complex"
require "rational"
require "bigdecimal"

# require "bigdecimal/math"

BYTE_SIZE_OF_ONE = 1.size

#
# define rounding modes to be used for LongDecimal
# this serves the purpose of an "enum" in C/C++/Java
#
module LongDecimalRoundingMode

  private

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
  # for major modes that are completely defined by themselves and do not need to rely on minor modes for the boundary stuff
  MINOR_UNUSED = RoundingMinorMode.new(:MINOR_UNUSED, "")

  private

  ALL_MINOR = [ MINOR_UP, MINOR_DOWN, MINOR_CEILING, MINOR_FLOOR, MINOR_EVEN ]
  # puts(ALL_MINOR)
  # puts

  NO_MINOR = [ MINOR_UNUSED ]

  # which mode is to be used instead when we do an multiplicative inversion?
  MUL_INVERSE_MINOR_MODE = {
    MINOR_UNUSED  =>   MINOR_UNUSED,
    MINOR_UP      =>   MINOR_DOWN,
    MINOR_DOWN    =>   MINOR_UP,
    MINOR_CEILING =>   MINOR_FLOOR,
    MINOR_FLOOR   =>   MINOR_CEILING,
    MINOR_EVEN    =>   MINOR_EVEN,
  }

  # which mode is to be used instead when we do an additive inversion?
  ADD_INVERSE_MINOR_MODE = {
    MINOR_UNUSED  =>   MINOR_UNUSED,
    MINOR_UP      =>   MINOR_UP,
    MINOR_DOWN    =>   MINOR_DOWN,
    MINOR_CEILING =>   MINOR_FLOOR,
    MINOR_FLOOR   =>   MINOR_CEILING,
    MINOR_EVEN    =>   MINOR_EVEN,
  }

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

  private

  ALL_MAJOR_MODES = [  MAJOR_UP, MAJOR_DOWN, MAJOR_CEILING, MAJOR_FLOOR, MAJOR_UNNECESSARY, MAJOR_HALF, MAJOR_GEOMETRIC, MAJOR_HARMONIC, MAJOR_QUADRATIC, MAJOR_CUBIC ]

  # puts("ALL_MAJOR_MODES:")
  # puts(ALL_MAJOR_MODES)
  # puts

  MUL_INVERSE_MAJOR_MODE = {
    MAJOR_UP           =>   MAJOR_DOWN,
    MAJOR_DOWN         =>   MAJOR_UP,
    MAJOR_CEILING      =>   MAJOR_FLOOR,
    MAJOR_FLOOR        =>   MAJOR_CEILING,
    MAJOR_HALF         =>   MAJOR_HALF,
    MAJOR_UNNECESSARY  =>   MAJOR_UNNECESSARY
  }

  # which mode is to be used instead when we do an additive inversion?
  ADD_INVERSE_MAJOR_MODE = {
    MAJOR_UP           =>   MAJOR_UP,
    MAJOR_DOWN         =>   MAJOR_DOWN,
    MAJOR_CEILING      =>   MAJOR_FLOOR,
    MAJOR_FLOOR        =>   MAJOR_CEILING,
    MAJOR_HALF         =>   MAJOR_HALF,
    MAJOR_UNNECESSARY  =>   MAJOR_UNNECESSARY
  }

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
    def <=>(o)
      if o.respond_to?:num
        self.num <=> o.num
      elsif o.kind_of? Numeric
        self.num <=> o
      else
        puts("stack=#{caller.join("\n")}")
        raise TypeError, "o=#{o.inspect} must be numeric or RoundingMode";
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

    # internal use
    # no special checks included
    # we assume: lower <= unrounded <= upper
    # we assume: sign = sgn(unrounded)
    def pick_value(unrounded, sign, lower, upper, even)
      if (sign == 0 || major == MAJOR_UNNECESSARY)
        if (lower == unrounded)
          return lower
        elsif (upper == unrounded)
          return upper
        end
      end
      if (major == MAJOR_UP && sign > 0)
        return upper
      elsif (major == MAJOR_UP && sign < 0)
        return lower
      elsif (major == MAJOR_DOWN && sign > 0)
        return lower
      elsif (major == MAJOR_DOWN && sign < 0)
        return upper
      elsif (major == MAJOR_CEILING)
        return upper
      elsif (major == MAJOR_FLOOR)
        return lower
      elsif (major == MAJOR_UNNECESSARY)
        rails ArgumentError, "rounding #{name} of unrounded=#{unrounded} (sign=#{sign}) is not applicable for lower=#{lower} and upper=#{upper}"
      end
      on_boundary = false
      if (major == MAJOR_HALF)
        d = unrounded - lower <=> upper - unrounded
        if (d < 0)
          # unrounded is below half
          return lower
        elsif (d > 0)
          # unrounded is below half
          return upper
        else
          on_boundary = true
        end
      elsif (major == MAJOR_GEOMETRIC)
        prod = lower * upper
        if (prod < 0)
          raise ArgumentError, "geometric rounding #{name} of unrounded=#{unrounded} (sign=#{sign}) is not applicable for lower=#{lower} and upper=#{upper} with different signs"
        elsif (prod == 0)
          # lower or upper is 0
          # we only round 0 to 0
          if (sign == 0)
            raise ArgumentError, "geometric rounding #{name} of unrounded=#{unrounded} (sign=#{sign}) is not applicable for lower=#{lower} and upper=#{upper} with 0 cannot be decided"
          elsif (sign < 0)
            return lower
          else
            return upper
          end
        end
        # now prod > 0
        square = unrounded * unrounded
        d = square <=> prod
        if (d < 0)
          # |unrounded| < sqrt(lower*upper)
          if (sign < 0)
            # lower < unrounded < upper < 0
            return upper
          else
            # (sign > 0)
            return lower
          end
        elsif (d > 0)
          # |unrounded| > sqrt(lower*upper)
          if (sign < 0)
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
      elsif (major == MAJOR_HARMONIC)
        prod = lower * upper
        if (prod < 0)
          raise ArgumentError, "harmonic rounding #{name} of unrounded=#{unrounded} is not applicable for lower=#{lower} and upper=#{upper} with different signs"
        elsif (prod == 0)
          # lower or upper is 0
          # we only round 0 to 0
          if (sign == 0)
            raise ArgumentError, "harmonic rounding #{name} of unrounded=#{unrounded} is not applicable for lower=#{lower} and upper=#{upper} with 0 cannot be decided"
          elsif (sign < 0)
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
        rhs = 2*prod
        d = lhs <=> rhs
        if (sign < 0)
          # lower + upper < 0
          d = -d
        end
        if (d < 0)
          # unrounded < 2*upper*lower/(upper+lower)
          return lower
        elsif (d > 0)
          # unrounded > 2*upper*lower/(upper+lower)
          return upper
        else
          # (d == 0)
          on_boundary = true
        end
      elsif (major == MAJOR_QUADRATIC)
        square = unrounded * unrounded
        lhs = 2 * square
        rhs = lower * lower + upper * upper
        d = lhs <=> rhs
        if (sign < 0)
          # lower <= unrounded <= upper <= 0
          # lower^2 >= unrounded >= upper^2 >= 0
          d = -d
        end
        if (d < 0)
          # unrounded < sqrt(...)
          return lower
        elsif (d > 0)
          # unrounded > sqrt(...)
          return upper
        else
          # (d == 0)
          on_boundary = true
        end
      elsif (major == MAJOR_CUBIC)
        cube = unrounded * unrounded * unrounded
        lhs = 2 * cube
        rhs = lower * lower * lower + upper * upper * upper
        d = lhs <=> rhs
        if (d < 0)
          # unrounded < x_cubic(lower, upper)
          return lower
        elsif (d > 0)
          # unrounded > x_cubic(lower, upper)
          return upper
        else
          # (d == 0)
          on_boundary = true
        end
      else
        raise ArgumentError, "unsupported rounding mode (#{name}: major=#{major})"
      end
      if (! on_boundary)
        raise ArgumentError, "rounding #{name} of unrounded=#{unrounded} failed for lower=#{lower} and upper=#{upper}: not on boundary"
      end
      if (minor == MINOR_UP)
        return ROUND_UP.pick_value(unrounded, sign, lower, upper, even)
      elsif (minor == MINOR_DOWN)
        return ROUND_DOWN.pick_value(unrounded, sign, lower, upper, even)
      elsif (minor == MINOR_CEILING)
        return ROUND_CEILING.pick_value(unrounded, sign, lower, upper, even)
      elsif (minor == MINOR_FLOOR)
        return ROUND_FLOOR.pick_value(unrounded, sign, lower, upper, even)
      elsif (minor == MINOR_UNUSED)
        raise ArgumentError, "rounding #{name} of unrounded=#{unrounded} failed for lower=#{lower} and upper=#{upper}: on boundary but no applicable minor mode"
      elsif (minor == MINOR_EVEN)
        return even
      else
        raise ArgumentError, "rounding #{name} of unrounded=#{unrounded} failed for lower=#{lower} and upper=#{upper}: on boundary but no applicable minor mode"
      end
    end

    def hash
      num
    end

    def to_long_s
      "RM(#{name} major=#{major.name} minor=#{minor.name} num=#{num})"
    end

    def to_s
      "#{name}"
    end

  end

  MODE_LOOKUP = {}
  
  rounding_mode_counter = 0

  public

  ALL_ROUNDING_MODES = []

  MUL_INVERSE_MODE = {}

  ADD_INVERSE_MODE = {}


  ALL_MAJOR_MODES.each do |majm|
    majm_str = majm.part.to_s
    majm.minor.each do |minm|
      minm_str = minm.part.to_s
      const_str = "ROUND_" + majm_str + minm_str
      class_eval("#{const_str} = RoundingModeClass.new(:#{const_str}, #{majm.name}, #{minm.name}, rounding_mode_counter)")
      class_eval("#{const_str}.freeze")
      rounding_mode_counter += 1
      class_eval("ALL_ROUNDING_MODES.push(#{const_str})")
      class_eval("MODE_LOOKUP[[#{majm.name}, #{minm.name}]] = #{const_str}")
    end
  end

  ALL_ROUNDING_MODES.freeze
  # puts(ALL_ROUNDING_MODES)
  MODE_LOOKUP.freeze
  # puts(MODE_LOOKUP)

  ALL_ROUNDING_MODES.each do |rm|
    majm = rm.major
    minm = rm.minor
    mul_inv = MODE_LOOKUP[[ MUL_INVERSE_MAJOR_MODE[majm], MUL_INVERSE_MINOR_MODE[minm]]]
    MUL_INVERSE_MODE[rm] = mul_inv
    add_inv = MODE_LOOKUP[[ ADD_INVERSE_MAJOR_MODE[majm], ADD_INVERSE_MINOR_MODE[minm]]]
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
    def <=>(o)
      if o.respond_to?:num
        self.num <=> o.num
      elsif o.kind_of? Numeric
        self.num <=> o
      else
        puts("stack=#{caller.join("\n")}")
        raise TypeError, "o=#{o.inspect} must be numeric or ZeroRoundingMode";
      end
    end

    def hash
      num
    end

    def to_long_s
      "ZM(#{name} num=#{num})"
    end

    def to_s
      "#{name}"
    end

  end

  #
  # rounding modes as constants
  #
  ZERO_ROUND_TO_PLUS                 = ZeroRoundingModeClass.new(:ZERO_ROUND_TO_PLUS, 0)
  ZERO_ROUND_TO_MINUS                = ZeroRoundingModeClass.new(:ZERO_ROUND_TO_MINUS, 1)
  ZERO_ROUND_TO_CLOSEST_PREFER_PLUS  = ZeroRoundingModeClass.new(:ZERO_ROUND_TO_CLOSEST_PREFER_PLUS, 2)
  ZERO_ROUND_TO_CLOSEST_PREFER_MINUS = ZeroRoundingModeClass.new(:ZERO_ROUND_TO_CLOSEST_PREFER_MINUS, 3)
  ZERO_ROUND_UNNECESSARY             = ZeroRoundingModeClass.new(:ZERO_ROUND_UNNECESSARY, 4)

  ALL_ZERO_MODES = [ LongDecimalRoundingMode::ZERO_ROUND_TO_PLUS,\
      LongDecimalRoundingMode::ZERO_ROUND_TO_MINUS,\
      LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_PLUS,\
      LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_MINUS,\
      LongDecimalRoundingMode::ZERO_ROUND_UNNECESSARY ];

end # LongDecimalRoundingMode

# JRuby has a bug to be fixed in version > 1.2 that implies results of
# 0 for multiplications of two Fixnums neither of which is 0 in some
# cases.  This code fixes the bug for the purposes of long-decimal.
if (RUBY_PLATFORM == 'java')

  if (JRUBY_VERSION.match /^[01]\.[012]/)
    class Fixnum

      alias :mul :*

      # fix multiplication
      def *(y)
        if (self == 0 || y == 0)
          return self.mul(y)
        elsif (y.kind_of? Fixnum)
          x = self
          s = 0
          while (x & 0xff == 0)
            x >>= 8
            s += 8
          end
          while (y & 0xff == 0)
            y >>= 8
            s += 8
          end
          return x.mul(y) << s
        else
          return self.mul(y)
        end
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

  alias :signum :sgn
  alias :sign   :sgn

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

    raise TypeError, "remainders must be Array" unless remainders_param.kind_of? Array
    raise TypeError, "remainders must be non-empty Array" unless remainders_param.length > 0
    raise TypeError, "modulus #{modulus.inspect} must be integer" unless modulus.kind_of? Integer
    raise TypeError, "modulus #{modulus.inspect} must be >= 2" unless modulus >= 2
    raise TypeError, "rounding_mode #{rounding_mode.inspect} must be legal rounding rounding_mode" unless rounding_mode.kind_of? LongDecimalRoundingMode::RoundingModeClass
    raise TypeError, "#{rounding_mode} is not applicable here" if rounding_mode.minor == LongDecimalRoundingMode::MINOR_EVEN
    raise TypeError, "zero_rounding_mode #{zero_rounding_mode.inspect} must be legal zero_rounding zero_rounding_mode" unless zero_rounding_mode.kind_of? LongDecimalRoundingMode::ZeroRoundingModeClass

    remainders = remainders_param.clone
    r_self     = self % modulus
    r_self_00  = r_self
    remainders = remainders.collect do |r|
      raise TypeError, "remainders must be integral numbers" unless r.kind_of? Integer
      r % modulus
    end
    remainders.sort!.uniq!
    r_first = remainders[0]
    r_last  = remainders[-1]
    r_first_again = r_first + modulus
    remainders.push r_first_again
    if (r_self < r_first) then
      r_self += modulus
    end
    r_lower = -1
    r_upper = -1
    remainders.each_index do |i|
      r = remainders[i]
      if (r == r_self) then
        return self
      elsif (r < r_self) then
        r_lower = r
      elsif (r > r_self) then
        r_upper  = r
        break
      end
    end
    if (r_lower < 0) 
      raise ArgumentError, "self=#{self} r_self=#{r_self} r_lower=#{r_lower} r_upper=#{r_upper}"
    end
    if (r_upper < 0) 
      raise ArgumentError, "self=#{self} r_self=#{r_self} r_lower=#{r_lower} r_upper=#{r_upper}"
    end
    lower = self - (r_self - r_lower)
    upper = self + (r_upper - r_self)
    # puts "round_to_allowed_remainders(remainders_param=#{remainders_param} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}) remainders=#{remainders} lower=#{lower} upper=#{upper} r_lower=#{r_lower} r_upper=#{r_upper} r_self=#{r_self}"

    unless (lower < self && self < upper)
      raise ArgumentError, "self=#{self} not in (#{lower}, #{upper}) with r_self=#{r_self} r_lower=#{r_lower} r_upper=#{r_upper}"
    end
    if (rounding_mode == LongDecimalRoundingMode::ROUND_UNNECESSARY) then
      raise ArgumentError, "mode ROUND_UNNECESSARY not applicable, self=#{self.to_s} is in open interval (#{lower}, #{upper})"
    end

    if (rounding_mode == LongDecimalRoundingMode::ROUND_FLOOR) then
      if (lower.nil?)
        raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
      end
      return lower
    elsif (rounding_mode == LongDecimalRoundingMode::ROUND_CEILING) then
      if (upper.nil?)
        raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
      end
      return upper
    end

    sign_self = self.sgn
    if (sign_self == 0) then
      if (rounding_mode == LongDecimalRoundingMode::ROUND_UP \
          || rounding_mode == LongDecimalRoundingMode::ROUND_DOWN \
          || rounding_mode.major == LongDecimalRoundingMode::MAJOR_GEOMETRIC \
          || rounding_mode.major == LongDecimalRoundingMode::MAJOR_HARMONIC \
          || rounding_mode.major == LongDecimalRoundingMode::MAJOR_QUADRATIC \
          || lower == -upper && (rounding_mode.minor == LongDecimalRoundingMode::MINOR_UP || rounding_mode.minor == LongDecimalRoundingMode::MINOR_DOWN))
        if (zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_UNNECESSARY) then
          raise ArgumentError, "self=#{self.to_s} is 0 in open interval (#{lower}, #{upper}) and cannot be resolved with ZERO_ROUND_UNNECESSARY (rounding_mode=#{rounding_mode} modulus=#{modulus} remainders=#{remainders}"
        elsif (zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_PLUS \
               || zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_MINUS) then
          diff = lower.abs <=> upper.abs
          if (diff < 0) then
            if (lower.nil?)
              raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
            end
            return lower
          elsif (diff > 0) then
            if (upper.nil?)
              raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
            end
            return upper
          elsif (zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_PLUS) then
            if (upper.nil?)
              raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
            end
            return upper
          elsif (zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_CLOSEST_PREFER_MINUS) then
            if (lower.nil?)
              raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
            end
            return lower
          else
            raise ArgumentError, "this case can never happen: zero_rounding_mode=#{zero_rounding_mode}"
          end
        elsif (zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_PLUS) then
          if (upper.nil?)
            raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
          end
          return upper
        elsif (zero_rounding_mode == LongDecimalRoundingMode::ZERO_ROUND_TO_MINUS) then
          if (lower.nil?)
            raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
          end
          return lower
        else
          raise ArgumentError, "this case can never happen: zero_rounding_mode=#{zero_rounding_mode}"
        end
      end
    end

    # for geometric and harmonic never round across 0
    if (rounding_mode.major == LongDecimalRoundingMode::MAJOR_GEOMETRIC || rounding_mode.major == LongDecimalRoundingMode::MAJOR_HARMONIC || rounding_mode.major == LongDecimalRoundingMode::MAJOR_QUADRATIC)
      if (sign_self > 0 && lower < 0)
        if (upper.nil?)
          raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
        end
        return upper
      elsif (sign_self < 0 && upper > 0)
        if (lower.nil?)
          raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
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
    if (pick.nil?)
      raise ArgumentError, "remainders=#{remainders} modulus=#{modulus} rounding_mode=#{rounding_mode} zero_rounding_mode=#{zero_rounding_mode}"
    end
    return pick
  end
end

#
# common base class for LongDecimal and LongDecimalQuot
#
class LongDecimalBase < Numeric
  @@RCS_ID='-$Id: long-decimal.rb,v 1.87 2011/01/30 20:01:40 bk1 Exp $-'

  # allow easy check if running with version 1.9
  RUNNING_19 = RUBY_VERSION.match /^1\.9/

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
    sx = self.scale
    dx = self.sint_digits10
    new_scale = [ 0, 2 * dx + sx - 2].max
    result = 1 / self
    result.scale = new_scale
    result
  end

  alias :inverse :reciprocal

  #
  # square of absolute value
  # happens to be the square
  #
  alias :abs2 :square

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

  private

  #
  # helper method for round_to_scale
  #
  def round_to_scale_helper(dividend, divisor, new_scale, mode)

    sign_quot = dividend <=> 0
    if sign_quot == 0 then
      # finish zero without long calculations at once
      return LongDecimal(0, new_scale)
    end

    divisor   = divisor
    quot, rem = dividend.divmod(divisor)
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
    raise ArgumentError, "signs do not match self=#{self.to_s} f=#{factor} dividend=#{dividend} divisor=#{divisor} quot=#{quot} rem=#{rem}" if sign_rem <= 0

    if (sign_quot < 0) then
      # handle negative sign of self
      rem -= divisor
      quot += 1
      sign_rem = rem <=> 0
      raise ArgumentError, "signs do not match self=#{self.to_s} f=#{factor} dividend=#{dividend} divisor=#{divisor} quot=#{quot} rem=#{rem}" if sign_rem >= 0
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
      half    = (abs_rem << 1) <=> divisor
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

  end

end # class LongDecimalBase

#
# class for holding fixed point long decimal numbers
# these can be considered as a pair of two integer.  One contains the
# digits and the other one the position of the decimal point.
#
class LongDecimal < LongDecimalBase
  @@RCS_ID='-$Id: long-decimal.rb,v 1.87 2011/01/30 20:01:40 bk1 Exp $-'

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
    new(LongMath.npower10(s), s)
  end


  #
  # creates a LongDecimal representing two with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.two!(s = 0)
    new(2*LongMath.npower10(s), s)
  end


  #
  # creates a LongDecimal representing ten with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.ten!(s = 0)
    new(LongMath.npower10(s+1), s)
  end

  #
  # creates a LongDecimal representing 1/2 with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.half!(s = 1)
    new(5 * LongMath.npower10(s-1), s)
  end


  #
  # creates a LongDecimal representing minus one with the given number of
  # digits after the decimal point (scale=s)
  #
  def LongDecimal.minus_one!(s = 0)
    new(-1*LongMath.npower10(s), s)
  end


  #
  # creates a LongDecimal representing a power of ten with the given
  # exponent e and with the given number of digits after the decimal
  # point (scale=s)
  #
  def LongDecimal.power_of_ten!(e, s = 0)
    LongMath.check_is_int(e, "e")
    raise TypeError, "negative 1st arg \"#{e.inspect}\""    if e < 0
    new(LongMath.npower10(s+e), s)
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
    raise TypeError, "non numeric 1st arg \"#{x.inspect}\"" if ! (x.kind_of? Numeric) && ! (x.kind_of? String)
    # we could maybe even work with complex number, if their imaginary part is zero.
    # but this is not so important to deal with, so we raise an error anyway.
    raise TypeError, "complex numbers not supported \"#{x.inspect}\"" if x.kind_of? Complex

    # handle some obvious errors with optional second parameter, if present
    LongMath.check_is_prec(s, "scale", :raise_error)
#    raise TypeError, "non integer 2nd arg \"#{s.inspect}\"" if ! s.kind_of? Integer
#    raise TypeError, "negative 2nd arg \"#{s.inspect}\""    if s < 0

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
      int_val = (x * LongMath.npower10(iscale2+iscale)).to_i

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
      num_str = num_str.gsub(/\s/, "")
      num_str.gsub!(/_/, "")

      # handle sign
      num_str.gsub!(/^\+/, "")
      negative = false
      if num_str.gsub!(/^-/, "") then
        negative = true
      end

      # split in parts before and after decimal point
      num_arr = num_str.split(/\./)
      if num_arr.length > 2 then
        raise TypeError, "1st arg contains more than one . \"#{num_str.inspect}\""
      end
      num_int  = num_arr[0]
      num_rem  = num_arr[1]
      num_frac = nil
      num_exp  = nil
      unless num_rem.nil? then
        num_arr  = num_rem.split(/[Ee]/)
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
      f = LongMath.npower10(d.abs)
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

    new_scale = LongMath.check_is_prec(new_scale)
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.kind_of? RoundingModeClass
    if @scale == new_scale then
      self
    else
      diff   = new_scale - scale
      factor = LongMath.npower10(diff.abs)
      if (diff > 0) then
        # we become more precise, no rounding issues
        new_int_val = int_val * factor
        return LongDecimal(new_int_val, new_scale)
      else
        return round_to_scale_helper(int_val, factor, new_scale, mode)
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

    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "remainders must be Array" unless remainders.kind_of? Array
    raise TypeError, "remainders must be non-empty Array" unless remainders.length > 0
    raise TypeError, "modulus #{modulus.inspect} must be integer" unless modulus.kind_of? Integer
    raise TypeError, "modulus #{modulus.inspect} must be >= 2" unless modulus >= 2
    raise TypeError, "rounding_mode #{rounding_mode.inspect} must be legal rounding rounding_mode" unless rounding_mode.kind_of? RoundingModeClass
    raise TypeError, "ROUND_HALF_EVEN is not applicable here" if rounding_mode == LongDecimalRoundingMode::ROUND_HALF_EVEN
    raise TypeError, "zero_rounding_mode #{zero_rounding_mode.inspect} must be legal zero_rounding zero_rounding_mode" unless zero_rounding_mode.kind_of? ZeroRoundingModeClass

    if @scale < new_scale then
      expanded = self.round_to_scale(new_scale, rounding_mode)
      return expanded.round_to_allowed_remainders(new_scale, remainders, modulus, rounding_mode, zero_rounding_mode)
    elsif @scale > new_scale
      factor = LongMath.npower10(@scale - new_scale)
      remainders = remainders.collect do |r|
        r * factor
      end
      modulus *= factor
    end

    int_val_2 = @int_val.round_to_allowed_remainders(remainders, modulus, rounding_mode, zero_rounding_mode)
    self_2 = LongDecimal.new(int_val_2, @scale)

    result = self_2.round_to_scale(new_scale, rounding_mode)
    return result
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
      quot    = (self.move_point_right(scale) * base ** shown_scale) / LongMath.npower10(scale)
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
  # to_f has to consider the following cases:
  # if 10**scale or int_val > MAX_FLOATABLE, divide by an adequate power of 10 to reach the ranges, where the conversion below works.
  # if 10**scale and int_val both < MAX_FLOATABLE, use lookup for float-representation 1/10**scale -> int_val.to_f * (1/10**scale)
  # special care has to be taken for the "border cases".
  #
  def to_f

    # result 0.0 if int_val == 0
    if (int_val == 0)
      # t1
      # puts "t1 #{self.to_s}=#{self.inspect} -> 0.0"
      return 0.0
    end

    if (scale == 0)
      if (int_val.abs <= LongMath::MAX_FLOATABLE)
        y = int_val.to_f
        # t2
        # puts "t2 #{self.to_s}=#{self.inspect} -> #{y}"
        return y
      elsif int_val < 0
        # t13
        # puts "t13 #{self.to_s}=#{self.inspect} -> -Infinity"
        return -1.0/0.0
      elsif int_val > 0
        # t14
        # puts "t13 #{self.to_s}=#{self.inspect} -> Infinity"
        return 1.0/0.0
      end
    end

    # negative: can be handled by doing to_f of the absolute value and negating the result.
    if (self < 0) then
      y = -(-self).to_f
      # t3
      # puts "t3 #{self.to_s}=#{self.inspect} -> #{y}"
      return y
    end

    # handle the usual case first, avoiding expensive calculations
    if (int_val <= LongMath::MAX_FLOATABLE && scale <= Float::MAX_10_EXP)
      y = to_f_simple(int_val, scale)
      # t4
      # puts "t4 #{self.to_s}=#{self.inspect} -> #{y}"
      return y
    end

    divisor = denominator

    # result NaN if int_val > MAX_FLOATABLE * 10**scale
    # handle overflow: raise exception
    if (int_val > divisor * LongMath::MAX_FLOATABLE) then
      # t5
      # puts "t5 #{self.to_s}=#{self.inspect} -> Infinity"
      return 1/0.0 # Infinity
    end

    # result 0.0 if int_val * MAX_FLOATABLE < 10**scale
    # handle underflow: return 0.0
    if (int_val * LongMath::INV_MIN_FLOATABLE * 20 < divisor) then
      # t6
      # puts "t6 #{self.to_s}=#{self.inspect} -> 0.0"
      p = int_val * LongMath::INV_MIN_FLOATABLE * 20
      d = divisor
      n = int_val
      return 0.0
    end

    if int_val <= LongMath::MAX_FLOATABLE then
      # the case divisor <= LongMath::MAX_FLOATABLE has been dealt with above already.
      # ==> denominator > LongMath::MAX_FLOATABLE is true
      # the case self < LongMath::MIN_FLOATABLE has been handed above
      # int_val beeing < LongMath::MAX_FLOATABLE we know that qe < 2 * Float::MAX_10_EXP
      y = int_val.to_f
      s = scale
      while (s > 0)
        qe = [ s, Float::MAX_10_EXP ].min
        q  = LongMath.neg_float_npower10(qe)
        y *= q
        if (y == 0.0)
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

    if (cmp == 0)
      # t10
      # puts "t10 #{self.to_s}=#{self.inspect} -> 1.0"
      return 1.0
    elsif (cmp > 0)
      # self > 1, retain MAX_SIGNIFICANT_FLOATABLE_DIGITS
      rounded_ld = round_to_scale(LongMath::MAX_SIGNIFICANT_FLOATABLE_DIGITS, ROUND_HALF_UP)
      # self >= LongMath::FLOATABLE_WITHOUT_FRACTION > self > 1, scale = 16,
      y = to_f_simple(rounded_ld.int_val, rounded_ld.scale)
      # t11
      # puts "t11 #{self.to_s}=#{self.inspect} #{rounded_ld.to_s}=#{rounded_ld.inspect} -> #{y}"
      return y
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
      y = to_f_simple(rounded_ld.int_val, rounded_ld.scale)
      # t12
      # puts "t12 #{self.to_s}=#{self.inspect} #{rounded_ld.to_s}=#{rounded_ld.inspect} sd=#{sd} #{self <=> 1} -> #{y}"
      return y
    end
  end

  private

  # private helper method for to_f
  def to_f_simple(int_val, scale)
    if (scale > Float::MAX_10_EXP - 10)
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
    if (prec.nil?)
      return self
    else
      return round_to_scale(prec, mode)
    end
  end

  #
  # convert self into BigDecimal
  #
  def to_bd
    # this operation is probably not used so heavily, so we can live with a
    # string as an intermediate step.
    BigDecimal(self.to_s)
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
  alias :numerator :int_val

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

    n = ((int_part.size - BYTE_SIZE_OF_ONE) << 3) + 1
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
      factor   = LongMath.npower10(exponent)
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

  alias :next :succ

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
      new_scale = s.scale + o.scale
      prod      = s.int_val * o.int_val
      if (new_scale > LongMath.prec_limit)
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
        LongDecimalQuot(Rational(LongMath.npower10(new_scale), int_val ** abs_other), new_scale)
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
      LongDecimal(int_val * LongMath.npower10(n-scale), 0)
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
      # s, o = other.coerce(self.to_f)
      if (RUNNING_19)
        s, o = other.coerce(self)
        # puts "complex coerce 19: #{self}, #{other} -> #{s}, #{o}"
        return o, s
      else
        s, o = other.coerce(Complex(self, 0))
        # puts "complex coerce 18/J: #{self}, #{other} -> #{s}, #{o}"
        return o, s
      end
      # s, o = other.coerce(Complex(self.to_f, 0))
      # return o, s

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
    scale == 0 || int_val % LongMath.npower10(scale) == 0
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

  alias :signum :sgn
  alias :sign   :sgn

  #
  # comparison of self with other for equality
  # takes into account the values expressed by self and other and the
  # equality of the number of digits.
  #
  def eql?(other)
    (other.kind_of? LongDecimal) && (self <=> other) == 0 && self.scale == other.scale
  end

  #
  # comparison of self with other for equality
  # takes into account the values expressed by self
  #
  def ==(other)
    # (other.kind_of? LongDecimal) && (self <=> other) == 0 && self.scale == other.scale
    if (other.kind_of? LongDecimal)
      scale_diff = self.scale - other.scale
      if (scale_diff == 0)
        return self.int_val == other.int_val
      elsif (scale_diff < 0)
        return self.int_val * LongMath.npower10(-scale_diff) == other.int_val
      else
        return self.int_val == other.int_val * LongMath.npower10(scale_diff)
      end
    elsif other.kind_of? Integer
      return self.int_val == other * LongMath.npower10(scale)
    elsif other.kind_of? Numeric
      return (self <=> other).zero?
    else
      return false
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

  @@RCS_ID='-$Id: long-decimal.rb,v 1.87 2011/01/30 20:01:40 bk1 Exp $-'

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
    if ((first.kind_of? Rational) || (first.kind_of? LongDecimalQuot) || (first.kind_of? Integer)) && (second.kind_of? Integer) then
      LongMath.check_is_prec(second)
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
      # used for the result, which can be more than new_scale.
      sx = first.scale
      sy = second.scale
      dx = first.sint_digits10
      dy = second.sint_digits10
      new_scale = [ 0, 2 * dy + sx + sy - [ dx + sx, dy + sy ].max - 3].max

      first, second = first.anti_equalize_scale(second)
      if (second.zero?)
        raise ZeroDivisionError, "second=#{second.inspect} must not be zero. (first=#{first.inspect})"
      end
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
  alias :abs2 :square

  #
  # convert LongDecimalQuot to LongDecimal with the given precision
  # and the given rounding mode
  #
  def round_to_scale(new_scale = @scale, mode = ROUND_UNNECESSARY)

    raise TypeError, "new_scale #{new_scale.inspect} must be integer" unless new_scale.kind_of? Integer
    raise TypeError, "new_scale #{new_scale.inspect} must be >= 0" unless new_scale >= 0
    raise TypeError, "mode #{mode.inspect} must be legal rounding mode" unless mode.kind_of? RoundingModeClass

    factor    = LongMath.npower10(new_scale)
    prod      = numerator * factor
    raise TypeError, "numerator=#{numerator} must be integer" unless numerator.kind_of? Integer
    raise TypeError, "denominator=#{denominator}=#{denominator.inspect} must be integer" unless denominator.kind_of? Integer
    raise TypeError, "factor=#{factor} (new_scale=#{new_scale}) must be integer" unless factor.kind_of? Integer
    raise TypeError, "prod=#{prod} must be integer" unless prod.kind_of? Integer
    return round_to_scale_helper(prod, denominator, new_scale, mode)

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
      s, o = other.coerce(self.to_bd(scale + 10))
      return o, s

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
  def eql?(other)
    (other.kind_of? LongDecimalQuot) && (self <=> other) == 0 && self.scale == other.scale
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
    if other.kind_of? Numeric
      (self <=> other) == 0
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
  alias :signum :sgn
  alias :sign   :sgn

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
  def to_ld(prec = nil, mode = LongMath.standard_mode)
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

  def sgn
    raw_sign = self <=> 0
    if (raw_sign < 0)
      -1
    elsif (raw_sign == 0)
      0
    else
      +1
    end
  end

end # Numeric

class Complex

  alias :cdiv :/

  # fix problems with complex division depending on Ruby version
  if (RUBY_VERSION.match /^1\.8/)
    #
    # Division by real or complex number for Ruby 1.8
    #
    def / (other)
      if other.kind_of?(Complex)
        p = self*other.conjugate
        d = other.abs2
        r = p.real/d
        i = p.image/d
        Complex(r, i)
      elsif Complex.generic?(other)
        Complex(@real/other, @image/other)
      elsif other.kind_of? BigDecimal
        Complex(@real/other, @image/other)
      else
        x, y = other.coerce(self)
        x/y
      end
    end
  else
    #
    # Division by real or complex number for Ruby 1.9
    #
    def / (other)
      if other.kind_of?(Complex)
        p = self*other.conjugate
        d = other.abs2
        r = nil
        i = nil
        if (d.kind_of? Integer) && (p.real.kind_of? Integer)
          r = Rational(p.real, d)
        else
          r = p.real/d
        end
        if (d.kind_of? Integer) && (p.image.kind_of? Integer)
          i = Rational(p.image, d)
        else
          i = p.image/d
        end
        Complex(r, i)
      elsif Complex.generic?(other)
        r = nil
        i = nil
        if (other.kind_of? Integer) && (real.kind_of? Integer)
          r = Rational(real, other)
        else
          r = real/other
        end
        if (other.kind_of? Integer) && (image.kind_of? Integer)
          i = Rational(image, other)
        else
          i = image/other
        end
        Complex(r, i)
      elsif other.kind_of? BigDecimal
        Complex(real/other, image/other)
      else
        x, y = other.coerce(self)
        x/y
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
    if (prec.nil?)
      return LongDecimal(self)
    else
      l = LongDecimalQuot(self, prec)
      return l.round_to_scale(prec, mode)
    end
  end

  # retain original to_f under different name
  alias :to_f_orig :to_f

  FLOAT_MAX_I         = Float::MAX.to_i
  FLOAT_SIGNIFICANT_I = 2**56

  unless (RUBY_VERSION.match /^1\.9/)

    # fix eql? for Ruby 1.8
    def eql?(other)
      (other.kind_of? Rational) && self.numerator == other.numerator && self.denominator == other.denominator
    end

    # improved to_f, works better where numerator and denominator are integers beyond the range of float, but their Quotient is still expressable as Float
    def to_f
      num = numerator
      den = denominator
      # puts("num=#{num} den=#{den}")
      sign = num <=> 0
      # puts("num=#{num} den=#{den} sign=#{sign}")
      if (sign.zero?)
        return 0.0
      elsif sign < 0
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
        num = (num + den/2) / den
        return (sign * num).to_f
      elsif den >= FLOAT_MAX_I
        den = (den + num/2) / num
        if (den >= FLOAT_MAX_I)
          return 0.0
        else
          return sign/den.to_f
        end
      else
        return sign * (num.to_f / den.to_f)
      end
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

  MAX_FLOATABLE   = Float::MAX.to_i
  MAX_FLOATABLE2  = MAX_FLOATABLE / 2
  # moved to bottom because of dependencies
  # MAX_FLOATABLE10 = 10.0 ** Float::MAX_10_EXP
  MAX_EXP_ABLE    = 709
  # moved to the bottom because of dependencies
  # MIN_FLOATABLE   = Float::MIN.to_ld(340, LongMath::ROUND_UP)

  # some arbritrary limit, so we do not exhaust too much memory.
  MAX_PREC        = 2097161 # largest integral number n such that 10**n can be calculated in Ruby.
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

  private

  # POWERS_BIG_BASE = 10**POWERS_MED_EXP_LIMIT: calculate on demand
  def LongMath.powers_big_base
    npower10_cached(POWERS_MED_EXP_LIMIT)
  end

  # powers of powers_big_base
  def LongMath.npower_of_big_base(n1)
    power = @@powers_of_big_base[n1]
    if (power.nil?)
      power = powers_big_base ** n1
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

  #
  # lookup the upper limit for scale of LongDecimal
  #
  def LongMath.prec_limit
    @@prec_limit ||= LongMath::DEFAULT_MAX_PREC
  end

  #
  # lookup the rule for handling errors with overflow of LongDecimal scale
  #
  def LongMath.prec_overflow_handling
    @@prec_overflow_handling ||= :raise_error
  end

  #
  # set the rule for handling errors with overflow of LongDecimal scale
  # possible values are:
  # :raise_error  : immediately raise an error
  # :use_max      : tacitely reduce scale to the maximum allowed value
  # :warn_use_max : print a warning and reduce scale to the max allowed
  #
  def LongMath.prec_overflow_handling=(poh)
    unless (poh == :raise_error || poh == :use_max || poh == :warn_use_max)
      raise ArgumentError, "poh=#{poh} no accepted value"
    end
    @@prec_overflow_handling = poh
  end

  #
  # get the rule for handling errors with overflow of LongDecimal scale
  # possible values are:
  # :raise_error  : immediately raise an error
  # :use_max      : tacitely reduce scale to the maximum allowed value
  # :warn_use_max : print a warning and reduce scale to the max allowed
  #
 def LongMath.prec_limit=(l = LongMath::DEFAULT_MAX_PREC)
    LongMath.check_is_int(l)
    raise ArgumentError, "#{l} must be >= #{Float::MAX_10_EXP}"  unless l >= Float::MAX_10_EXP
    raise ArgumentError, "#{l} must be <= #{LongMath::MAX_PREC}" unless l <= LongMath::MAX_PREC
    @@prec_limit = l
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
  # optimize calculation of power of 10 by non-negative integer,
  # because it is essential to LongDecimal to us it very often.
  # n is the exponent (must be >= 0 and Integer)
  #
  def LongMath.npower10(n)
    check_is_prec(n, "n", :raise_error, MAX_PREC)
    n0 = n & POWERS_MED_EXP_MASK
    n1 = n >> POWERS_MED_EXP_PARAM
    p  = npower10_cached(n0)
    if (n1 > 0) then
      # puts "n0=#{n0} n1=#{n1}"
      p1 = npower_of_big_base(n1)
      # puts "n0=#{n0} n1=#{n1} p1"
      p *= p1
      # puts "n0=#{n0} n1=#{n1} p"
    end
    return p
  end

  private

  #
  # helper method for npower10
  # only for internal use
  #
  def LongMath.npower10_cached(n)
    p = @@small_powers_of_10[n]
    if (p.nil?)
      n0 = n &  POWERS_SMALL_EXP_MASK
      n1 = n >> POWERS_SMALL_EXP_PARAM
      p = npower10_cached_small(n0)
      if (n1 > 0)
        p *= npower10_cached_small(POWERS_SMALL_EXP_LIMIT) ** n1
      end
      @@small_powers_of_10[n] = p
    end
    p
  end

  #
  # helper method for npower10
  # only for internal use
  #
  def LongMath.npower10_cached_small(n)
    p = @@small_powers_of_10[n]
    if (p.nil?)
      p = 10 ** n
      @@small_powers_of_10[n] = p
    end
    p
  end

  public

  #
  # helper method for npower10
  # only for internal use
  #
  def LongMath.neg_float_npower10(n)
    if (n > MAX_NEG_10_EXP)
      return 0.0
    end
    p = @@negative_powers_of_10_f[n]
    if (p.nil?)
      #p = 0.1 ** n
      p = "1e-#{n}".to_f # 0.1 ** n
      @@negative_powers_of_10_f[n] = p
    end
    p
  end

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
  def LongMath.check_is_prec(prec, name="prec", error_handling = nil, pl = prec_limit)
    raise TypeError, "#{name}=#{prec.inspect} must be Fixnum" unless prec.kind_of? Integer
    raise ArgumentError, "#{name}=#{prec.inspect} must be >= 0" unless prec >= 0
    unless (prec.kind_of? Fixnum) && prec <= pl
      poh = LongMath.prec_overflow_handling
      if poh == :raise_error || error_handling == :raise_error
        raise ArgumentError, "#{name}=#{prec.inspect} must be <= #{pl}"
      elsif poh == :warn_use_max
        warn "WARNING: #{name}=#{prec} too big => reduced to #{pl}"
        prec = pl
      elsif poh == :use_max
        prec = pl
      else
        raise ArgumentError, "unsupported value for prec_overflow_handling=#{poh} found #{name}=#{prec} > #{pl}"
      end
    end
    prec
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
  # y**2&nbsp;<=&nbsp;x&nbsp;<&nbsp;(y+1)**2
  #
  def LongMath.sqrtb(x)
    a = sqrtb_with_remainder(x)
    a[0]
  end

  #
  # calculate an integer s&nbsp;>=&nbsp;0 and a remainder r&nbsp;>=&nbsp;0 such that
  # x&nbsp;=&nbsp;s**2&nbsp;+&nbsp;r and s**2&nbsp;<=&nbsp;x&nbsp;<&nbsp;(s+1)**2
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
  # y**2&nbsp;<=&nbsp;x&nbsp;<&nbsp;(y+1)**2
  #
  def LongMath.sqrtw(x, n = 16)
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
  def LongMath.sqrtw_with_remainder(x, n = 16)
    check_is_int(x, "x")
    check_is_int(n, "n")

    n2 = n << 1
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
  # calculate the cubic root of an integer x using bitwise algorithm
  # the result is rounded to an integer y such that
  # y**3&nbsp;<=&nbsp;x&nbsp;<&nbsp;(y+1)**3
  #
  def LongMath.cbrtb(x)
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
  def LongMath.cbrtb_with_remainder(x)
    check_is_int(x, "x")

    s = (x <=> 0)
    if (s == 0) then
      return [0, 0]
    elsif (s < 0)
      a = cbrtb_with_remainder(-x)
      return [ -a[0], -a[1]]
    end

    # split into groups of three bits
    xwords = split_to_words(x, 3)
    xi = xwords[0] - 1
    yi = 1

    1.upto(xwords.length-1) do |i|
      xi = (xi << 3) + xwords[i]
      d0 = 6 * yi * (2 * yi + 1) + 1
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
        e = (Math.log(Float::MAX) / Math.log(prime_number)).floor
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
  def LongMath.pi(prec, final_mode = LongMath.standard_mode, iprec = nil, mode = nil, cache_result = true) # DOWN?

    prec = check_is_prec(prec, "prec")
    if (mode.nil?)
      mode  = LongMath.standard_mode
    end
    check_is_mode(final_mode, "final_mode")
    check_is_mode(mode, "mode")

    # calculate internal precision
    if (iprec.nil?)
      iprec = 5*(prec+1)
    end
    iprec = check_is_prec(iprec, "iprec")
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
  def LongMath.exp(x, prec, mode = LongMath.standard_mode) # down?
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_EXP_ABLE}" unless x <= MAX_EXP_ABLE
    prec = check_is_prec(prec, "prec")
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
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
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
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
  #
  def LongMath.exp10(x, prec, mode = LongMath.standard_mode) # down?
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
    iprec = [ iprec, prec ].max
    if (x_was_neg)
      iprec += 2
    end
    iprec = check_is_prec(iprec, "iprec")
    iprec
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
  def LongMath.exp_internal(x, prec = nil, final_mode = LongMath.standard_mode, j = nil, k = nil, iprec = nil, mode = LongMath.standard_imode, cache_result = true) # down?

    if (prec.nil?) then
      if (x.kind_of? LongDecimalBase)
        prec = x.scale
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

    # if the result would come out to zero anyway, cut the work
    xi = x.to_i
    if (xi < -LongMath::MAX_FLOATABLE) || xi + 1 < -prec * LOG10 - LOG2 then
      # the result is 1/4 of the smallest positive number that can be expressed with the given precision.
      # this is rounded according to the final rounding mode, yielding 0.00000...00 or 0.00000...01.
      return LongDecimal(25, prec+2).round_to_scale(prec, final_mode)
    end

    # if x is negative, do the calculation with -x and take 1/exp(-x) as the final result later.
    x_was_neg = false
    if (x < 0) then
      x = -x
      x_was_neg = true
    end

    # calculate j and k if they are not given.
    if j.nil? || k.nil? then
      s1 = (prec * LOG10 / LOG2) ** (1.0/3.0)
      if (j.nil?) then
        j = s1.round
      end
      if (k.nil?) then
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

    # calculate iprec if it is not given.
    if (iprec.nil?) then
      iprec = calc_iprec_for_exp(x, prec, x_was_neg)
    end
    iprec = check_is_prec(iprec, "iprec")

    # we only cache exp(1), exp(10), exp(100), exp(MAX_EXP_ABLE.to_i), otherwise cache_key is returned as nil.
    cache_key = get_cache_key("exp", x, mode, [1, 10, 100, MAX_EXP_ABLE.to_i])
    y_k = get_cached(cache_key, x, iprec)

    # if the cache did not yield our result, calculate it.
    if (y_k.nil?) then
      y_k = exp_raw(x, prec, j, k, iprec, mode)

      # keep result around for exp(1), exp(10), exp(100), exp(MAX_EXP_ABLE.to_i)
      set_cached(cache_key, y_k) if (cache_result)
    end

    # take 1/exp(-x) as result, if x was negative.
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
  def LongMath.exp_raw(x, prec, j, k, iprec, mode)
    dprec = [ (iprec*0.9).round, prec ].max

    # convert to LongDecimal, if necessary:
    unless (x.kind_of? LongDecimal)
      x = x.to_ld(iprec, mode)
    end

    # we use this x_k in the Taylor row:
    x_k = (x / (1 << k)).round_to_scale(iprec, mode)
    # x_k ** j
    x_j = (x_k ** j).round_to_scale(iprec, mode)
    # vector with j entries
    s = [ LongDecimal(0) ] * j
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
        break if (t.zero?)
      end
      # multiply t by x_k**j.  Detect when we can stop, if summands are zero or irrelevant for final result.
      break if (t.zero?)
      t = (t * x_j).round_to_scale(iprec, mode)
      break if (t.zero?)
      tr = t.round_to_scale(dprec, LongDecimal::ROUND_DOWN).abs
      break if (t.zero?)
      tu = t.unit
      break if (tr <= tu && last_t <= tu)
      last_t = tr
    end

    # calculate result exp(x_k)
    x_i = 1
    y_k = LongDecimal(0)
    j.times do |i|
      if (i > 0) then
        x_i = (x_i * x_k).round_to_scale(iprec, mode)
      end
      y_k += (s[i] * x_i).round_to_scale(iprec, mode)
    end

    # square exp(x_k) k times to get exp(x):
    k.times do |i|
      y_k = y_k.square.round_to_scale(iprec, mode)
    end

    y_k
  end # exp_raw

  public

  #
  # calculate approximation of sqrt of a LongDecimal.
  #
  def LongMath.sqrt(x, prec, mode = LongMath.standard_mode) # down
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
    prec = check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    unless (x.kind_of? LongDecimal)
      x = x.to_ld(2 * (prec+1), mode)
    end
    prec1 = prec
    unless (with_rem) then
      prec1 += 1
    end
    cache_key = nil
    y_arr = nil
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
  # calculate approximation of cbrt of a LongDecimal.
  #
  def LongMath.cbrt(x, prec, mode = LongMath.standard_mode) # down
    LongMath.cbrt_internal(x, prec, mode, false)
  end

  #
  # calculate approximation of cbrt of a LongDecimal with remainder
  #
  def LongMath.cbrt_with_remainder(x, prec)
    LongMath.cbrt_internal(x, prec, ROUND_DOWN, true)
  end

  private

  #
  # internal helper method for calculationg cbrt and cbrt_with_remainder
  #
  def LongMath.cbrt_internal(x, prec, mode, with_rem, cache_result = true)
    prec = check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    unless (x.kind_of? LongDecimal)
      x = x.to_ld(3 * (prec+1), mode)
    end
    prec1 = prec
    unless (with_rem) then
      prec1 += 1
    end
    cache_key = nil
    y_arr = nil
    unless (with_rem)
      cache_key = get_cache_key("cbrt", x, mode, [2, 3, 5, 6, 7, 8, 10])
      y_arr = get_cached(cache_key, x, prec)
    end
    if (y_arr.nil?) then
      y_arr = cbrt_raw(x, prec1, mode)
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
  # calculate cbrt with remainder uncached
  #
  def LongMath.cbrt_raw(x, new_scale1, rounding_mode)
    old_scale  = (new_scale1 * 3)
    x = x.round_to_scale(old_scale, rounding_mode)
    root, rem = LongMath.cbrtb_with_remainder(x.int_val)
    y = LongDecimal(root, new_scale1)
    r = LongDecimal(rem, old_scale)
    return [y, r]
  end

  public

  #
  # calculate the natural logarithm function of x to the given precision as
  # LongDecimal.
  #
  def LongMath.log(x, prec, mode = LongMath.standard_mode) # down?
    prec = check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    log_internal(x, prec, mode)
  end

  #
  # internal functionality of log.  exposes some more parameters, that
  # should usually be set to defaut values, in order to allow better testing.
  # do not actually call this method unless you are testing log.
  # create a bug report, if the default settings for the parameters do
  # not work correctly
  #
  def LongMath.log_internal(x, prec = nil, final_mode = LongMath.standard_mode, iprec = nil, mode = LongMath.standard_imode, cache_result = true)

    raise TypeError, "x=#{x.inspect} must not be positive" unless x > 0
    if (prec.nil?) then
      if (x.kind_of? LongDecimalBase)
        prec = x.scale
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

    if (iprec.nil?) then
      iprec = ((prec+12)*1.20).round
    end
    if (iprec < prec) then
      iprec = prec
    end
    iprec = check_is_prec(iprec, "iprec")
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

    # we have to rely on iprec being at least 10
    raise TypeError, "iprec=#{iprec} out of range" unless (iprec.kind_of? Fixnum) && iprec >= 10

    dprec = iprec - 1

    # result is stored in y
    y = 0
    # sign of result
    s = 1
    # make sure x is >= 1
    mode1 = mode
    if (x < 1) then
      mode1 = mode1.minverse
      x = (1 / x).round_to_scale(iprec, mode1)
      s = -1
    end

    # number that are beyond the usual range of Float need to be
    # handled specially to reduce to something expressable as Float
    exp_keys = [ MAX_EXP_ABLE.to_i, 100, 10, 1 ]
    exp_keys.each do |exp_key|
      exp_val = exp(exp_key, iprec)
      while (x > exp_val) do
        x = (x / exp_val).round_to_scale(iprec, mode1)
        if (s < 0) then
          y -= exp_key
        else
          y += exp_key
        end
      end
    end

    factor = 1
    sprec  = (iprec * 1.5).round
    delta  = LongDecimal(1, (iprec.to_f**0.45).round)
    while (x - 1).abs > delta do
      x       = LongMath.sqrt(x, sprec, mode1)
      factor *= 2
    end

    ss = 1
    mode2 = mode1.ainverse
    if (x < 1)
      mode2 = mode2.ainverse
      x  = (1 / x).round_to_scale(iprec, mode2)
      ss = -1
    end

    sum = 0
    z   = 1 - x
    i   = 1
    p   = 1.to_ld
    d   = 1.to_ld
    until p.abs.round_to_scale(dprec, LongDecimal::ROUND_DOWN).zero? do
      p = (p * z).round_to_scale(iprec, mode2)
      d = (p / i).round_to_scale(iprec, mode2)
      i += 1
      sum += d

    end
    sum *= ss

    y -= ((s * factor) * sum).round_to_scale(iprec, mode.ainverse)
    return y
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
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
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
  # Warning: this is a transcendental function that aims at producing
  # results to the given precision, but minor inaccuracies of the
  # result have to be expected under some circumstances, being off by
  # one even more often.
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
  def LongMath.power(x, y, prec, mode = LongMath.standard_mode)

    raise TypeError, "x=#{x} must be numeric" unless x.kind_of? Numeric
    raise TypeError, "y=#{y} must be numeric" unless y.kind_of? Numeric
    raise TypeError, "x=#{x.inspect} must not be greater #{MAX_FLOATABLE}" unless x.abs <= MAX_FLOATABLE
    raise TypeError, "y=#{y.inspect} must not be greater #{MAX_FLOATABLE}" unless y.abs <= MAX_FLOATABLE
    raise TypeError, "y=#{y.inspect} must not be negative if base is zero}" if y < 0 && x.zero?
    raise TypeError, "x=#{x.inspect} must not negative" unless x >= 0
    prec = check_is_prec(prec, "prec")
    check_is_mode(mode, "mode")
    # puts "LongMath.power(x=#{x} y=#{y} prec=#{prec} mode=#{mode})"

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
    # puts "x0=#{x0} y0=#{y0}"
    while x0 > LongMath::MAX_FLOATABLE
      x0 = x0.move_point_left(100)
      point_shift += 100
    end
    iprec2 = 2 * (iprec + point_shift)
    iprec3 = [ iprec2, LongMath.prec_limit() - 24 ].min
    # puts "x0=#{x0} y0=#{y0} point_shift=#{point_shift} iprec=#{iprec} iprec2=#{iprec2} iprec3=#{iprec3}"
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
    # puts "LongMath.ipower(x=#{x} y=#{y} prec=#{prec} mode=#{mode})"

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
            # puts("ipower x=#{x} y=#{y} cnt=#{cnt} z=#{z} t=#{Time.now - t0}")
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
      # puts "z=#{z} rounding prec=#{prec}"
      z = z.round_to_scale(prec, mode)
      # puts "rounded -> z=#{z}"
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

  # helper for means
  def LongMath.sign_check_for_mean(allow_different_signs, *args)
    if (args.empty?)
      raise ArgumentError, "cannot calculate mean of empty array"
    end
    first = args[0]
    has_neg = false
    has_pos = false
    has_zero = false
    all_same = true
    result_sign = 0
    args.each do |x|
      if (! (x.kind_of? Numeric))
        raise ArgumentError, "cannot calculate mean of a non-numeric array #{args.inspect}"
      end
      if (x.kind_of? Complex)
        raise ArgumentError, "mean not supported for complex numbers args=#{args.inspect}"
      end
      if (all_same && x != first)
        all_same = false
      end
      sign = x.sgn
      if (sign < 0)
        has_neg = true
        result_sign = sign
      elsif (sign > 0)
        has_pos = true
        result_sign = sign
      else
        has_zero = true
      end
      if (has_neg && has_pos && !allow_different_signs)
        raise ArgumentError, "signs of parameters have to match for quadratic mean args=#{args.inspect}"
      end
    end
    return result_sign, all_same, has_neg, has_zero, has_pos
  end

  public

  # arithmetic mean
  def LongMath.arithmetic_mean(new_scale, rounding_mode, *args)
    if (args.empty?)
      raise ArgumentError, "cannot calculate average of empty array"
    end
    sum = args.inject(0) do |psum,x| 
      psum + x
    end
    raw_result = if (sum.kind_of? Integer)
        Rational(sum, args.size)
    else
        sum / args.size
    end
    result = raw_result.to_ld(new_scale, rounding_mode)
    return result
  end

  class << LongMath
    alias_method :average, :arithmetic_mean
  end

  # geometric mean
  def LongMath.geometric_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    if (all_same)
      return args[0].to_ld(new_scale, rounding_mode)
    end
    if (has_zero)
      return LongDecimal.zero!(new_scale)
    end
    prod = args.inject(1) do |pprod,x| 
      pprod * x.abs
    end
    result = nil
    n = args.size
    if (n == 0 || n == 1)
      result = prod.to_ld(new_scale, rounding_mode)
    elsif (n == 2)
      result = LongMath.sqrt(prod, new_scale, rounding_mode)
    elsif (n == 3) 
      result = LongMath.cbrt(prod, new_scale, rounding_mode)
    else
      result = LongMath.power(prod, Rational(1, args.size), new_scale, rounding_mode)
    end
    if (has_neg)
      result = -result
    end
    return result
  end

  # harmonic mean
  def LongMath.harmonic_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    if (all_same)
      return args[0].to_ld(new_scale, rounding_mode)
    end
    if (has_zero)
      raise ArgumentError, "cannot calculate harmonic mean of argument list containing zero #{args.inspect}"
    end
    sum = args.inject(0) do |psum, x| 
      psum + if (x.kind_of? Integer)
               Rational(1, x)
             else
               1/x
             end
    end
    raw_result = args.size / sum
    result = raw_result.to_ld(new_scale, rounding_mode)
    return result
  end

  # quadratic mean
  def LongMath.quadratic_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(true, *args)
    if (all_same)
      return args[0].to_ld(new_scale, rounding_mode)
    end
    sum = args.inject(0) do |psum, x| 
      psum + x*x
    end
    quot = if (sum.kind_of? Integer)
             Rational(sum, args.size)
           else
             sum / args.size
           end
    result = LongMath.sqrt(quot, new_scale, rounding_mode)
    if (has_neg)
      result = -result
    end
    return result
  end

  # cubic mean
  def LongMath.cubic_mean(new_scale, rounding_mode, *args)
    result_sign, all_same, has_neg, has_zero, has_pos = sign_check_for_mean(false, *args)
    if (all_same)
      return args[0].to_ld(new_scale, rounding_mode)
    end
    sum = args.inject(0) do |psum, x| 
      if (x.kind_of? Complex)
        raise ArgumentError, "cubic mean not supported for complex numbers args=#{args.inspect}"
      end
      psum + x*x*x
    end
    quot = if (sum.kind_of? Integer)
             Rational(sum, args.size)
           else
             sum / args.size
           end
    result = LongMath.cbrt(quot, new_scale, rounding_mode)
    return result
  end

  @@standard_mode = ROUND_HALF_UP

  # default to be used as rounding mode when no explicit mode is provided
  def LongMath.standard_mode
    @@standard_mode
  end

  # set default to be used as rounding mode when no explicit mode is provided
  def LongMath.standard_mode=(x)
    LongMath.check_is_mode(x)
    @@standard_mode = x
  end

  @@standard_imode = ROUND_HALF_EVEN

  def LongMath.standard_imode
    @@standard_imode
  end

  def LongMath.standard_imode=(x)
    LongMath.check_is_mode(x)
    @@standard_imode = x
  end

  MAX_FLOATABLE10 = LongMath.npower10(Float::MAX_10_EXP)
  MIN_FLOATABLE   = Float::MIN.to_ld(340, LongMath::ROUND_UP)
  INV_MIN_FLOATABLE = MIN_FLOATABLE.reciprocal.round_to_scale(0, LongMath::ROUND_HALF_UP).to_i
  # numbers >= FLOATABLE_WITHOUT_FRACTION yield the same result when converted to Float, regardless of what follows after the decimal point
  FLOATABLE_WITHOUT_FRACTION = (2 / Float::EPSILON).to_i
  MAX_SIGNIFICANT_FLOATABLE_DIGITS = Float::DIG + 1


end # LongMath

# end of file long-decimal.rb
