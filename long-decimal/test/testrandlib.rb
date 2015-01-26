#!/usr/bin/env ruby
#
# testrandlib.rb -- library for random tests for long-decimal.rb and long-decimal-extra.rb
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2009
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testrandlib.rb,v 1.10 2011/02/03 00:22:39 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "rubygems"
# require "crypt/ISAAC"
require "crypt-isaac"

#
# test class for LongDecimal and LongDecimalQuot
#
module TestRandomHelper

  @RCS_ID='-$Id: testrandlib.rb,v 1.10 2011/02/03 00:22:39 bk1 Exp $-'

  @@r1 = Crypt::ISAAC.new
  @@r2 = Crypt::ISAAC.new
  @@r3 = Crypt::ISAAC.new
  @@r4 = Crypt::ISAAC.new

  def arr_with_sq(arr)
    result = arr.map do |x|
      if (x >= 0) then
        r = LongMath.sqrt(x, x.scale, LongMath::ROUND_HALF_UP)
        [ r, x, r*x, x.square ]
      else
        x
      end
    end
    result.flatten
  end

  def arr_with_neg(arr)
    arr.map { |x| [x, -x] }.flatten
  end

  def arr_with_inv(arr)
    result = arr.map do |x|
      if (x.zero? || x.one?) then
        x
      else
        [x, x.inverse.to_ld(x.scale*2)]
      end
    end
    result.flatten
  end

  #
  # get random numbers in an array
  # xb is between 0 and 1000
  # xm is between 1 and 2
  # xs is between 0 and 1
  # all three are LongDecimal and have the same digits after the decimal point
  # out of these an array of up to 36 values is formed and returned as a[0]
  # are found by adding sqrt and square of of these to the array, if >= 0
  # adding the reciprocal of each non-zero entry of this array to array
  # and adding negated value of each entry to the array, then sorting
  # array and removing duplicates
  # a[1] is an integer between 0 and 120 used as precision for exp
  # a[2] is an integer between 1 and 121 used as precision for log
  # a[3] is an integer between 0 and 120+(x.scale)/2 used as precision for sqrt
  # a[4] is an integer between 0 and 60 used as precision for power
  #
  def random_arr
    x0 = @@r1.rand(1000)
    x1 = @@r2.rand(1000)
    x2 = @@r2.rand(100)+3
    x3 = @@r3.rand(1000)
    x4 = @@r3.rand(100)+4
    x5 = @@r4.rand(1000)
    x6 = @@r4.rand(100)+5
    xs = LongDecimal(x1, x2) + LongDecimal(x3, x4) + LongDecimal(x5, x6)
    xt = (xs / LongMath.pi(xs.scale)).to_ld(xs.scale*2)
    xu = 1 + xs
    xv = 1 + xt
    xw = 2 + xs
    xe = LongMath.exp(1, xs.scale) + xs
    xp = LongMath.pi(xs.scale) + xs
    xn = 10 + xs
    xb = x0 + xs
    xg = LongMath::MAX_EXP_ABLE - xs
    xh = LongMath::MAX_EXP_ABLE + xs
    eprec = @@r1.rand(120)
    lprec = eprec+1
    sprec = eprec+((xb.scale+1)>>1)
    pprec = lprec >> 1
    arr1 = [ xt, xs, xu, xv, xw, xe, xp, xn, xb, xg, xh ]
#     f    = LongDecimal("0.25")
#     arr2 = (0..8).map do |j|
#       ff = f*j
#       [ ff + xs, ff**5 + xs ]
#     end
#     arr3 = [ arr1, arr2 ].flatten
    arr  = arr_with_neg(arr_with_inv(arr_with_sq(arr1))).sort.uniq
    return [ arr, eprec, lprec, sprec, pprec, xb.scale ]
  end

end

# end of file testrandlib.rb
