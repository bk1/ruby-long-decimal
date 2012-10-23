#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdecimal-extra.rb,v 1.1 2007/08/19 19:25:59 bk1 Exp $
# CVS-Label: $Name: ALPHA_01_03 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "runit/testcase"
require "runit/cui/testrunner"
require "runit/testsuite"

load "lib/long-decimal.rb"
load "lib/long-decimal-extra.rb"
load "test/testlongdeclib.rb"

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimalExtra_class < RUNIT::TestCase
  include TestLongDecHelper

  @RCS_ID='-$Id: testlongdecimal-extra.rb,v 1.1 2007/08/19 19:25:59 bk1 Exp $-'

  #
  # test exp2 of LongMath
  #
  def test_exp2
    10.times do |i|
      n = (i*i+i)/2
      x = LongDecimal(n, 3*i)+LongMath.pi(20)
      check_exp2_floated(x, n)

      y  = LongMath.exp2(x, n)
      yy = LongMath.exp2(x, n + 5)
      assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
      z  = LongMath.power(2, x, n)
      assert_equal(z, y, "exp2 x=#{x} y=#{y} z=#{z} i=#{i} n=#{n}")
    end

    # random tests that have failed previously
    check_exp2_floated(LongDecimal("-0.00147492625237084606064197462823289474038138852346725504592707365251736299180323394082648207114993022483949313246714392730651107673327728615912046468517225938833913598854936005"), 20)

  end

  #
  # test the calculation of the exponential function where result is
  # near zero
  #
  def test_exp2_near_zero

    x = LongDecimal(1, 100)
    y = LongMath.log2(x, 100)
    z = check_exp2_floated(y, 100)
    assert_equal(x, z, "must be equal")
    z = check_exp2_floated(y, 99)
    assert(z.zero?, "must be zero")
    z = check_exp2_floated(y * 100, 99)
    assert(z.zero?, "must be zero")

  end

  #
  # test exp10 of LongMath
  #
  def test_exp10
    10.times do |i|
      n  = (i*i+i)/2
      x  = LongDecimal(n, 3*i)+LongMath.pi(20)
      check_exp10_floated(x, n)

      y  = LongMath.exp10(x, n)
      yy = LongMath.exp10(x, n + 5)
      assert_equal(yy.round_to_scale(y.scale, LongDecimal::ROUND_HALF_DOWN), y, "x=#{x} y=#{y} yy=#{yy}")
      z  = LongMath.power(10, x, n)
      assert_equal(z, y, "exp10 x=#{x} y=#{y} z=#{z} i=#{i} n=#{n}")
    end
  end

  #
  # test the calculation of the exponential function where result is
  # near zero
  #
  def test_exp10_near_zero

    x = LongDecimal(1, 100)
    y = LongMath.log10(x, 100)
    z = check_exp10_floated(y, 100)
    assert_equal(x, z, "must be equal")
    z = check_exp10_floated(y, 99)
    assert(z.zero?, "must be zero")
    z = check_exp10_floated(y * 100, 99)
    assert(z.zero?, "must be zero")

  end

  #
  # test LongMath.power for bases that can be expressed as integer
  #
  def test_lm_power_xint

    xx = LongMath.log(3, 40)
    pi = LongMath.pi(40)
    sq = LongMath.sqrt(5, 40)

    check_power_xint(2, 700.01, 10)
    check_power_xint(2, 100.001, 10)
    check_power_xint(2, 1.000000001, 10)
    check_power_xint(2, 0.01, 10)
    check_power_xint(2, 1e-10, 10)
    check_power_xint(2, 1e-90, 10)
    check_power_xint(2, 0, 10)
    check_power_xint(2, -1.000000001, 10)
    check_power_xint(2, -100.001, 10)
    check_power_xint(2, -700.01, 10)
    check_power_xint(2, xx, 10)
    check_power_xint(2, pi, 10)
    check_power_xint(2, sq, 10)

    check_power_xint(10, 308.01, 10)
    check_power_xint(10, 100.001, 10)
    check_power_xint(10, 1.000000001, 10)
    check_power_xint(10, 0.01, 10)
    check_power_xint(10, 1e-10, 10)
    check_power_xint(10, 1e-90, 10)
    check_power_xint(10, 0, 10)
    check_power_xint(10, -1.000000001, 10)
    check_power_xint(10, -100.001, 10)
    check_power_xint(10, -308.01, 10)
    check_power_xint(10, xx, 10)
    check_power_xint(10, pi, 10)
    check_power_xint(10, sq, 10)

    check_power_xint(2, 700.01, 100)
    check_power_xint(2, 100.001, 100)
    check_power_xint(2, 1.000000001, 100)
    check_power_xint(2, 0.01, 100)
    check_power_xint(2, 1e-10, 100)
    check_power_xint(2, 1e-90, 100)
    check_power_xint(2, 0, 100)
    check_power_xint(2, -1.000000001, 100)
    check_power_xint(2, -100.001, 100)
    check_power_xint(2, -700.01, 100)
    check_power_xint(2, xx, 100)
    check_power_xint(2, pi, 100)
    check_power_xint(2, sq, 100)

    check_power_xint(10, 308.01, 100)
    check_power_xint(10, 100.001, 100)
    check_power_xint(10, 1.000000001, 100)
    check_power_xint(10, 0.01, 100)
    check_power_xint(10, 1e-10, 100)
    check_power_xint(10, 1e-90, 100)
    check_power_xint(10, 0, 100)
    check_power_xint(10, -1.000000001, 100)
    check_power_xint(10, -100.001, 100)
    check_power_xint(10, -308.01, 100)
    check_power_xint(10, xx, 100)
    check_power_xint(10, pi, 100)
    check_power_xint(10, sq, 100)

    check_power_xint(2, 700.01, 40)
    check_power_xint(2, 100.001, 40)
    check_power_xint(2, 1.000000001, 40)
    check_power_xint(2, 0.01, 40)
    check_power_xint(2, 1e-10, 40)
    check_power_xint(2, 1e-90, 40)
    check_power_xint(2, 0, 40)
    check_power_xint(2, -1.000000001, 40)
    check_power_xint(2, -100.001, 40)
    check_power_xint(2, -700.01, 40)
    check_power_xint(2, xx, 40)
    check_power_xint(2, pi, 40)
    check_power_xint(2, sq, 40)

    check_power_xint(10, 308.01, 40)
    check_power_xint(10, 100.001, 40)
    check_power_xint(10, 1.000000001, 40)
    check_power_xint(10, 0.01, 40)
    check_power_xint(10, 1e-10, 40)
    check_power_xint(10, 1e-90, 40)
    check_power_xint(10, 0, 40)
    check_power_xint(10, -1.000000001, 40)
    check_power_xint(10, -100.001, 40)
    check_power_xint(10, -308.01, 40)
    check_power_xint(10, xx, 40)
    check_power_xint(10, pi, 40)
    check_power_xint(10, sq, 40)

  end

  #
  # test LongMath.power for bases that can be expressed as integer
  #
  def test_lm_power_yint

    xx = LongMath.log(3, 40)
    pi = LongMath.pi(40)
    sq = LongMath.sqrt(5, 40)

    check_power_yint(xx, 400, 10)
    check_power_yint(xx, 100, 10)
    check_power_yint(xx, 1, 10)
    check_power_yint(xx, 0, 10)
    check_power_yint(xx, -1, 10)
    check_power_yint(xx, -100, 10)
    check_power_yint(xx, -400, 10)

    check_power_yint(pi, 400, 10)
    check_power_yint(pi, 100, 10)
    check_power_yint(pi, 1, 10)
    check_power_yint(pi, 0, 10)
    check_power_yint(pi, -1, 10)
    check_power_yint(pi, -100, 10)
    check_power_yint(pi, -400, 10)

    check_power_yint(sq, 400, 10)
    check_power_yint(sq, 100, 10)
    check_power_yint(sq, 1, 10)
    check_power_yint(sq, 0, 10)
    check_power_yint(sq, -1, 10)
    check_power_yint(sq, -100, 10)
    check_power_yint(sq, -400, 10)

    check_power_yint(xx, 400, 100)
    check_power_yint(xx, 100, 100)
    check_power_yint(xx, 1, 100)
    check_power_yint(xx, 0, 100)
    check_power_yint(xx, -1, 100)
    check_power_yint(xx, -100, 100)
    check_power_yint(xx, -400, 100)

    check_power_yint(pi, 400, 100)
    check_power_yint(pi, 100, 100)
    check_power_yint(pi, 1, 100)
    check_power_yint(pi, 0, 100)
    check_power_yint(pi, -1, 100)
    check_power_yint(pi, -100, 100)
    check_power_yint(pi, -400, 100)

    check_power_yint(sq, 400, 100)
    check_power_yint(sq, 100, 100)
    check_power_yint(sq, 1, 100)
    check_power_yint(sq, 0, 100)
    check_power_yint(sq, -1, 100)
    check_power_yint(sq, -100, 100)
    check_power_yint(sq, -400, 100)

    check_power_yint(xx, 400, 40)
    check_power_yint(xx, 100, 40)
    check_power_yint(xx, 1, 40)
    check_power_yint(xx, 0, 40)
    check_power_yint(xx, -1, 40)
    check_power_yint(xx, -100, 40)
    check_power_yint(xx, -400, 40)

    check_power_yint(pi, 400, 40)
    check_power_yint(pi, 100, 40)
    check_power_yint(pi, 1, 40)
    check_power_yint(pi, 0, 40)
    check_power_yint(pi, -1, 40)
    check_power_yint(pi, -100, 40)
    check_power_yint(pi, -400, 40)

    check_power_yint(sq, 400, 40)
    check_power_yint(sq, 100, 40)
    check_power_yint(sq, 1, 40)
    check_power_yint(sq, 0, 40)
    check_power_yint(sq, -1, 40)
    check_power_yint(sq, -100, 40)
    check_power_yint(sq, -400, 40)

  end

  #
  # test LongMath.power for bases that can be expressed as integer
  #
  def test_lm_power_yhalfint

    xx = LongMath.log(3, 40)
    pi = LongMath.pi(40)
    sq = LongMath.sqrt(5, 40)

    check_power_yhalfint(xx, 801, 10)
    check_power_yhalfint(xx, 799, 10)
    check_power_yhalfint(xx, 201, 10)
    check_power_yhalfint(xx, 3, 10)
    check_power_yhalfint(xx, 1, 10)
    check_power_yhalfint(xx, -1, 10)
    check_power_yhalfint(xx, -201, 10)
    check_power_yhalfint(xx, -799, 10)
    check_power_yhalfint(xx, -801, 10)

    check_power_yhalfint(pi, 801, 10)
    check_power_yhalfint(pi, 799, 10)
    check_power_yhalfint(pi, 201, 10)
    check_power_yhalfint(pi, 3, 10)
    check_power_yhalfint(pi, 1, 10)
    check_power_yhalfint(pi, -1, 10)
    check_power_yhalfint(pi, -201, 10)
    check_power_yhalfint(pi, -799, 10)
    check_power_yhalfint(pi, -801, 10)

    check_power_yhalfint(sq, 801, 10)
    check_power_yhalfint(sq, 799, 10)
    check_power_yhalfint(sq, 201, 10)
    check_power_yhalfint(sq, 3, 10)
    check_power_yhalfint(sq, 1, 10)
    check_power_yhalfint(sq, -1, 10)
    check_power_yhalfint(sq, -201, 10)
    check_power_yhalfint(sq, -799, 10)
    check_power_yhalfint(sq, -801, 10)

    check_power_yhalfint(xx, 801, 40)
    check_power_yhalfint(xx, 799, 40)
    check_power_yhalfint(xx, 201, 40)
    check_power_yhalfint(xx, 3, 40)
    check_power_yhalfint(xx, 1, 40)
    check_power_yhalfint(xx, -1, 40)
    check_power_yhalfint(xx, -201, 40)
    check_power_yhalfint(xx, -799, 40)
    check_power_yhalfint(xx, -801, 40)

    check_power_yhalfint(pi, 801, 40)
    check_power_yhalfint(pi, 799, 40)
    check_power_yhalfint(pi, 201, 40)
    check_power_yhalfint(pi, 3, 40)
    check_power_yhalfint(pi, 1, 40)
    check_power_yhalfint(pi, -1, 40)
    check_power_yhalfint(pi, -201, 40)
    check_power_yhalfint(pi, -799, 40)
    check_power_yhalfint(pi, -801, 40)

    check_power_yhalfint(sq, 801, 40)
    check_power_yhalfint(sq, 799, 40)
    check_power_yhalfint(sq, 201, 40)
    check_power_yhalfint(sq, 3, 40)
    check_power_yhalfint(sq, 1, 40)
    check_power_yhalfint(sq, -1, 40)
    check_power_yhalfint(sq, -201, 40)
    check_power_yhalfint(sq, -799, 40)
    check_power_yhalfint(sq, -801, 40)

  end

  #
  # test LongMath.power with non-LongDecimal arguments
  #
  def test_non_ld_power
    xi = 77
    yi = 88
    zi = LongMath.power(xi, yi, 35)
    wi = (LongMath.log(zi, 40) / LongMath.log(xi, 40)).round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert(wi.is_int?, "wi=#{wi} not int (zi=#{zi})")
    assert_equal(yi, wi.to_i, "zi=#{zi} wi=#{wi}")
    zj = LongMath.power_internal(xi, yi, 35)
    assert_equal(zi, zj, "internal power should yield the same result zi=#{zi} zj=#{zj}")

    xf = 77.0
    yf = 88.0
    zf = LongMath.power(xf, yf, 35)
    wf = (LongMath.log(zf, 40) / LongMath.log(xf, 40)).round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert(wf.is_int?, "wf=#{wf} not int (zf=#{zf} wi=#{wi} zi=#{zi}")
    assert_equal(yf, wf.to_i, "yf=#{yf} wf=#{yf}")

    xr = Rational(224, 225)
    yr = Rational(168, 169)
    zr = LongMath.power(xr, yr, 35)
    wr = (LongMath.log(zr, 40) / LongMath.log(xr, 40)).round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert((yr-wr).abs <= wr.unit, "wr-yr")
  end

  #
  # test the calculation of the power-function of LongMath
  #
  def test_lm_power
    check_power_floated(1.001, 1.001, 10)
    check_power_floated(1.001, 2.001, 10)
    check_power_floated(2.001, 1.001, 10)
    check_power_floated(2.001, 2.001, 10)
    check_power_floated(100.001, 10.001, 10)
    check_power_floated(10.001, 100.001, 10)
    check_power_floated(10.001, 100.001, 100)
    check_power_floated(1e-20, 1.01, 19)
    check_power_floated(1.01, 1e-20, 19)
    check_power_floated(1e-20, 1.01, 20)
    check_power_floated(1.01, 1e-20, 20)
    check_power_floated(1e-20, 1.01, 21)
    check_power_floated(1.01, 1e-20, 21)
    puts "done (1.01, 1e-20, 21)"

    check_power_floated(1.001, -1.001, 10)
    check_power_floated(1.001, -2.001, 10)
    check_power_floated(2.001, -1.001, 10)
    check_power_floated(2.001, -2.001, 10)
    check_power_floated(100.001, -10.001, 10)
    check_power_floated(10.001, -100.001, 10)
    check_power_floated(1e-20, -1.01, 19)
    check_power_floated(1.01, -1e-20, 19)
    check_power_floated(1e-20, -1.01, 20)
    check_power_floated(1.01, -1e-20, 20)
    check_power_floated(1e-20, -1.01, 21)
    check_power_floated(1.01, -1e-20, 21)
    puts "done (1.01, -1e-20, 21)"

    # random tests that have failed
    check_power_floated(LongDecimal("0.000000000077517987624900000000000000000000000000000000000000000000000000000000000000000000000000000014809051260000000000000000000000000000000000000000000000000000000000000000000000000000000000707281"),
                        LongDecimal("26.627053911388694974442854299008649887946027550330988420533923061901183724914978160564862753777080769340"),
                        29)
    puts "a"
    check_power_floated(LongDecimal("1.000000000000000151000000000000000000000000000000000000000000000000000000000000057800000000205"),
                        LongDecimal("-680.0000000000000000000013100000000000000000000000000000000000000165000000000000000000234"),
                        26)
    puts "b"
    check_power_floated(LongDecimal("1.0000000000000000000000000000000000000000000068000000000853000000000926"),
                        LongDecimal("-536.000000000086100000000000000000000000000019200000000000000000000000000000000000000000000000166"),
                        49)
    puts "c"
    check_power_floated(LongDecimal("1.0000000000000000049000000000002090000000000447"),
                        LongDecimal("-328.00000000000000000000000000000000567000000000000000026600000000000000000000000679"),
                        24)
    puts "d"
    check_power_floated(LongDecimal("1.0000000000000000000003580000000000000000000000376238"),
                        LongDecimal("-359.0000000003910721000000000000000000000000000000000000000000000000000000000000000000000000479"),
                        39)
    puts "e"
    check_power_floated(LongDecimal("1.000000000000000000000032000000001500000000000000000000439"),
                        LongDecimal("-252.00000000000000025500000000000176907"),
                        39)
    puts "f"
    check_power_floated(LongDecimal("1.0000000000000008590000521000000000000621"),
                        LongDecimal("-135.0000000000000000000000000000000000000000000000000000000074400000000000000000000000000321"),
                        50)
    puts "g"
    check_power_floated(LongDecimal("1.000000000000000151000000000000000000000000000000000000000000000000000000000000057800000000205"),
                        LongDecimal("-680.0000000000000000000013100000000000000000000000000000000000000165000000000000000000234"),
                        26)
    puts "h"
    check_power_floated(LongDecimal("1.02350000000000000000000356000000000000000000000000000000000000000000000000000000000104"),
                        LongDecimal("-971.0000000000000000055400000000000000000000000000000000000000000000000000040900000000000000000000000603"),
                        45)
    puts "i"
    check_power_floated(LongDecimal("1.0023800000000000000000000000000000000000000000000000000000000000265000000000000000000000000000000453"),
                        LongDecimal("-277.000000000000000000000000000000000000000000000000000000000000113000000000000000000041400000294"),
                        22)
    puts "j"
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003422250001093950095910422515315300670761"),
                        LongDecimal("-0.99999999999999999999999999999999999999999999999999997909999999999999999999999999667999957000000000000000065521500000000000000000000020816402696099999999999997719321110428280027729999999129874367303020000000000071412895105695789681563000036363932570289984431712381817869482773696988055442648559706239710901091550702341077381290973316336980640165855210736680"),
                        46)
    puts "k"
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000049273899694369"),
                        LongDecimal("-0.99999999999999999999999999999999999999988899963450000000000000000000000000000001847988671170038537499999999999999999999658146648184996349480690906250000000000066400422857493760370353798820585648437488207957808220483456569835670219978619056054192244103752969215743872596800486621906638928959243058783356441503226136251748249991020724187893339868"),
                        40)
    puts "l"
    check_power_floated(LongDecimal("0.0000000000000000000000000000003868840000000000000000000328416000000000000000000006969600000000000000000000000000000059338800000000000000000002518560000000000000000000000000000000000000000000000000000000227529"),
                        LongDecimal("-0.999999999999999999999999999999999999999999999999999998264999999999999999999999999999616741000000000000000004515337500000000000000000000001994863094999999999999986943149282831191620999999999993077825060350000000000033980453035745280148525000000024019946927993617107497210600671335038418031107762499920991889855598841096454678838495791189026426859181655270271342"),
                        31)
    puts "m"
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000435600000000000000000000000000000000000000000000000006204000000075240000000000000000000000000000000000000022090000000535800000003249"),
                        LongDecimal("-4.50377349099168904759987513420506734335755704389619751192197520413005925604849718759451665302464588879636922713303481423460050066204079523260315868192642742903330525895063299416"),
                        20)
    puts "n"
    check_power_floated(LongDecimal("0.0000000000000000000000000000700720943029391693947940220429504569709269190190365416713568"),
                        LongDecimal("-6.633249580710799698229865473341373367854177091179010213018664944871230"),
                        7)
    puts "o"
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000816700000697"),
                        LongDecimal("-0.58685446009389671361502347417840375586854460093896713614906034406753510106019528753113359342280707917300359276157963863070992095386428055722936293804476401957909668625460628698383384886591034139"),
                        36)
    puts "p"
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000046500000000000015087"),
                        LongDecimal("-1.0000000037300000000000000000000000000000000000000000003924"),
                        3)
    puts "q"
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000002450257484405715360000000000000000097614149083200000000000000000000000972196"),
                        LongDecimal("-1.00000008600000184900000000000000000000000000000000000000012640000543520000000000000000000013300000571900000000000000399424000000000000000000000000000840560000000000000000000000000000442225"),
                        3)
    puts "r"
    check_power_floated(LongDecimal("0.00000000000000000000000000000000000000000000000000000000000000000000367236000000000000000093202800000000000000005914074196000000000000000058905400000000000000000000146689"),
                        LongDecimal("-1.000000000008800000000019360000000062800000000276320250000000001100000985960000000000007850000000000000015625"),
                        4)
    puts "s"
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000000000000000000000000000000000002777290000000006513720000000003819240000000000000000000000000000100340800000000117667200000000000000000000000000000000000000000000906304"),
                        LongDecimal("-0.5773502691896257645091447198050641552797247036332110311421498194545129249630222981047763195372146430879281215100223411775138874331819083544781222838698051829302865547075365868655847179043571799566074987574406310154782766513220296853158689786573196010629608653145605201822170964422894732870490642190250948498852022304300879727510280657218553"),
                        23)
    puts "s"
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000000000007350000295000915"),
                        LongDecimal("-1.000002193000861"),
                        2)
    puts "u"
    check_power_floated(LongDecimal("0.0000000086862400000000000000015172960006039360000000662596000527472000104976"),
                        LongDecimal("-0.999999999999999999999999999999999999999999999999999999999997169999999999996784999999999687000000000000000000000000000012013350000000027295350000002672874337500003018885000000146896669625999999845508318999984783776699499965759759873248317316431267825611053489338193758007138415641516991908731376997678345955102618540146326218008264916981179817214058767402196571"),
                        11)
    puts "v"
    check_power_floated(LongDecimal("0.00000000000000000000000000624000383000000000000000000000000000000000000000000000358"),
                        LongDecimal("-1.0000004600000000000000000000000000000004210"),
                        3)
    puts "w"
    check_power_floated(LongDecimal("0.00000000006236994468492015585972291475115698519825552824875948893004062366348813472156776148562881057978611940708477498267201430163921921918813918304834563518614088250202460271818014152969"),
                        LongDecimal("-21.81742422927144044215775880732087497227530694228658299334049542576403906256739064739549866577137008231569804502022381108724983114382624747999460445291671084230968250529511708947428208082234"),
                        6)
    puts "x"
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000000035600000000928000000000000000450"),
                        LongDecimal("-0.70821529745042492917661444999959874487397062785764977666003279651340417551441776107007487983685090756343178115766012078677210548592741818458068450268168492334992979756923"),
                        13)
    puts "y"
    check_power_floated(LongDecimal("0.0000000000000000000000000000025900000000000000000000000000000000000000000022100000000000000000032"),
                        LongDecimal("-0.999943403203378688766215832183174473300891276419706031790088430934495839737458766990116492"),
                        4)
    puts "z"
    check_power_floated(LongDecimal("0.002658925294303146195800785280451092866235470739838791730450519159432915"),
                        LongDecimal("-87.0000000000000008330000000000000000000000000000000000000000000000000000000000000000000000000092046"),
                        90)
    puts "a"
    check_power_floated(LongDecimal("0.0014814814814814814812905349794238683127818125285779606767229367555739725854802645575188374989810195213530274617178142875856830586369415448003164084698537116523550097"),
                        LongDecimal("-52.0000000000000000000000000000000000000000683000000000000000000238000000000228"),
                        25)
    puts "b"
    check_power_floated(LongDecimal("0.00000000000000000000047400000000000000000084700000892"),
                        LongDecimal("-17.000000001310000000000000000000000000000000000000000000000000002800000000000000217"),
                        56)
    puts "c"
    check_power_floated(LongDecimal("0.00000000000000000000005110000000000000000004800000000000000000000000000000163"),
                        LongDecimal("-37.000000009170000000000000000000000000000000000000000000000000000000000000055800048"),
                        21)
    puts "d"
    check_power_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000000000000000002450257484405715360000000000000000097614149083200000000000000000000000972196"),
                        LongDecimal("-1.00000008600000184900000000000000000000000000000000000000012640000543520000000000000000000013300000571900000000000000399424000000000000000000000000000840560000000000000000000000000000442225"),
                        3)
    puts "e"
    check_power_floated(LongDecimal("0.999999999999983820000000000052544300000001372125483999980457478288050051600649560171986452284020178492146835403829341250837967306416835643061512149984415283328897050537606939603101940467080257495289168053434691062993302374332577706782680685214083677104079828206433042861334386773091111658939537092356816922764138900649581031721453211835260155666851398044388924204855221543729490461274063089475188763279119570"),
                        LongDecimal("80321932.89024988628926432624765785135567744505377819122460049392916097399960142838065367057138986526363804"),
                        40)
    puts "f"
    check_power_floated(LongDecimal("0.999999999999999999999999999999998351999999999999983020000000000002036927999998210041974559999999997978335404004424810825925120045592892314014072707890311225042124730264194167337496376801852022987153782535008598977724682635285958668331865904517437818865287190004735483899633845078360662820274644903126498781970492928578903950"),
                        LongDecimal("24449877750611246943765281173.594132029339853300733454400081300326994697544849684064538112517261374573394648075725881734888526076256999828217542217625441301525934675012853453406806380262764050867999"),
                        5)
    puts "g"
    check_power_floated(LongDecimal("0.999999999999999862599981980000014159073713922242243328677707050386499779178242565766291900177208859765599761583988066205590104341111429059119646260524293805643133602429678974677397380813589741657940554009198199034562447106122960905140273768835224006261013069576237942279008951360618433986"),
                        LongDecimal("10266940451745.37987679671457905534956086166404546967839388790271998098584221166751699838745542116653920000125768690393028114699714286512441385099525"),
                        14)
    puts "h"
    check_power_floated(LongDecimal("0.999999999999999981500000000000000256687499999999996834187500000000036604706930449997823687754750325053502286291757658419972795166437108241085949094447949893401640711985948839881287077716265593625727522425306777978451009970778400655052736724232660803755458234164496101454557290134193942433026948513566480800350007916601440691706219670728270104113540"),
                        LongDecimal("41380294430118397.455148144857963343847598908617723236165122243380531570432704458595232182042029429597565318650987561380534985825811466980798564531839364855305381553585381037046185516421336524897364607404185776449463"),
                        26)
    puts "i"
    check_power_floated(LongDecimal("0.000000000000000000000000000000000000046500000000000015087"),
                        LongDecimal("-1.0000000037300000000000000000000000000000000000000000003924"),
                        23)

  end

  #
  # test the calculation of the base-10-logarithm function
  #
  def test_log10
    check_log10_floated(10**2000, 30)
    check_log10_floated(100, 30)
    check_log10_floated(1, 30)
    check_log10_floated(0.01, 30)
    check_log10_floated(1e-10, 30)
    check_log10_floated(1e-90, 30)
    check_log10_floated(1e-300, 30)
    check_log10_floated(LongDecimal(1, 2000), 30)

    check_log10_exact(10**2000, 2000, 30)
    check_log10_exact(10**0, 0, 30)
    check_log10_exact(10**1, 1, 30)
    check_log10_exact(10**10, 10, 30)

    # random tests that have failed
    check_log10_floated(LongDecimal("587.00000000000000000095700000000000000000000000000000000000000000000000000000000000000000000001206"), 21)
    check_log10_floated(LongDecimal("543.0000002480000900000000000000000000000000000000000000000000000000000000000000000000847"), 2)
    check_log10_floated(LongDecimal("180.0000000000000000003570000000000000000000000000000000000000000000000577000000000000000000000000000637"), 2)
    check_log10_floated(LongDecimal("0.0000000000000000000000000000000000000000180000000063000000000000000000000000000000000025"), 74)
    check_log10_floated(LongDecimal("0.0000000000000000000000000006200000000000000000000000000000000000000000000000007940000015"), 74)
    check_log10_floated(LongDecimal("0.00000000000000000000000000000000000000000032900000000000000000000233000000000000000000000000000000254"), 10)
    check_log10_floated(LongDecimal("0.00000000000000000000000233000000094800000000000000000000000000000000000000000000000000000000000000682"), 100)
    check_log10_floated(LongDecimal("0.000000000000000000000000000000000000097000000041500000000000000000784"), 97)
    check_log10_floated(LongDecimal("185.000025300000000000000006320000000000000000000000000000737"), 27)
    check_log10_floated(LongDecimal("0.00000000000000000000000000000302000000000000000000000000000000000000000000000000000000060673"), 100)
    check_log10_floated(LongDecimal("442.000000000000045300000000000000000000000000000000000000000000000000000000000000000000000721000000000752"), 97)
    check_log10_floated(LongDecimal("0.001030927835051546391752577284408545010096715910298651428936221023301883588097777204212461151695109779555577162172"), 62)

  end

  #
  # test the calculation of the base-10-logarithm function
  #
  def test_log2
    check_log2_floated(10**2000, 30)
    check_log2_floated(2**2000, 30)
    check_log2_floated(100, 30)
    check_log2_floated(1, 30)
    check_log2_floated(0.01, 30)
    check_log2_floated(1e-10, 30)
    check_log2_floated(1e-90, 30)
    check_log2_floated(1e-300, 30)
    check_log2_floated(LongDecimal(1, 2000), 30)

    check_log2_exact(2**2000, 2000, 30)
    check_log2_exact(2**0, 0, 30)
    check_log2_exact(2**1, 1, 30)
    check_log2_exact(2**10, 10, 30)

    # random tests that have failed
    check_log2_floated(LongDecimal("341.00000739000000000000000000000000000000000000000000000000000000000000171"), 3)
    check_log2_floated(LongDecimal("504.00000000000000000000000000000000000000000000000000000000000000000000000000000000000327400000000000828"), 1)
    check_log2_floated(LongDecimal("0.0033222591362126245847176079734219269102990032888157967351353737817463383406363175903135730345286354858609181999523961456225622835123748782987926188031081"), 48)
    check_log2_floated(LongDecimal("0.000802000000000000000000197000000000000000000000302"), 84)
    check_log2_floated(LongDecimal("0.00000000000000000000000000000000000000000000000000000000000000000000000452000000000069480"), 3)
    check_log2_floated(LongDecimal("0.0000000000000000000000000000000000000000000000000000930000000000000000000000000983000000000000300"), 61)
    check_log2_floated(LongDecimal("0.000000000000000000000000000000000000000000000000000000000086000133000000000000000000000000947"), 106)
    check_log2_floated(LongDecimal("0.00000000000000000000000000000276000000000000000000000000000000000008560000000000000000000000000000161"), 81)

  end

  #
  # test the calculation of the base-x-logarithm of sqrt(x)
  #
  def test_log_2_10_of_sqrt
    # n = 125
    n = 30
    m = 5
    x2  = LongMath.sqrt(2, n)
    x10 = LongMath.sqrt(10, n)

    (2*m).times do |i|
      check_log2_floated(x2, n+m-i)
      check_log10_floated(x10, n+m-i)
    end

    y2  = check_log2_floated(x2, n)
    assert((y2*2).one?, "xe=#{x2} ye=#{y2}")
    y10 = check_log10_floated(x10, n)
    assert((y10*2).one?, "xe=#{x10} ye=#{y10}")

  end

end

RUNIT::CUI::TestRunner.run(TestLongDecimalExtra_class.suite)

# end of file testlongdecimal.rb
