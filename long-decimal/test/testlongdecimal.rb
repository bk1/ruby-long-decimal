#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdecimal.rb,v 1.32 2006/04/07 22:26:08 bk1 Exp $
# CVS-Label: $Name: PRE_ALPHA_0_22 $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

require "runit/testcase"
require "runit/cui/testrunner"
require "runit/testsuite"

# load "lib/long-decimal.rb"
load "test/testlongdeclib.rb"

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimal_class < RUNIT::TestCase
  include TestLongDecHelper

  @RCS_ID='-$Id: testlongdecimal.rb,v 1.32 2006/04/07 22:26:08 bk1 Exp $-'

  #
  # test split_to_words and merge_from_words
  #
  def test_split_merge_words
    check_split_merge_words(0, 1, 1)
    check_split_merge_words(0, 10, 1)
    check_split_merge_words(0, 100, 1)
    check_split_merge_words(0, 1000, 1)
    check_split_merge_words(-1, 1, 1)
    check_split_merge_words(-1, 10, 1)
    check_split_merge_words(-1, 100, 1)
    check_split_merge_words(-1, 1000, 1)
    check_split_merge_words(1, 1, 1)
    check_split_merge_words(1, 10, 1)
    check_split_merge_words(1, 100, 1)
    check_split_merge_words(1, 1000, 1)
    check_split_merge_words(10, 1, 4)
    check_split_merge_words(10, 10, 1)
    check_split_merge_words(10, 100, 1)
    check_split_merge_words(10, 1000, 1)
    x = 10**12 # 10**12 = 1000**4 < 2**40
    check_split_merge_words(x, 1, 40)
    check_split_merge_words(x, 10, 4)
    check_split_merge_words(x, 100, 1)
    check_split_merge_words(x, 1000, 1)
    x = 2**40
    check_split_merge_words(x, 1, 41)
    check_split_merge_words(x, 10, 5)
    check_split_merge_words(x, 100, 1)
    check_split_merge_words(x, 1000, 1)
  end

  #
  # test the calculation of the exponential function
  #
  def test_exp
    xx = LongMath.log(10.to_ld, 10)*100
    check_exp_floated(700, 10)
    check_exp_floated(100, 10)
    check_exp_floated(1, 10)
    check_exp_floated(0.01, 10)
    check_exp_floated(1e-10, 10)
    check_exp_floated(1e-90, 10)
    check_exp_floated(0, 10)
    check_exp_floated(-1, 10)
    check_exp_floated(-100, 10)
    check_exp_floated(-700, 10)
    check_exp_floated(xx, 10)
    check_exp_floated(-xx, 10)

    check_exp_floated(700, 100)
    check_exp_floated(100, 100)
    check_exp_floated(1, 100)
    check_exp_floated(0.01, 100)
    check_exp_floated(1e-10, 100)
    check_exp_floated(1e-90, 100)
    check_exp_floated(0, 100)
    check_exp_floated(-1, 100)
    check_exp_floated(-100, 100)
    check_exp_floated(-700, 100)
    check_exp_floated(xx, 100)
    check_exp_floated(-xx, 100)

    # random tests that have failed previously
    check_exp_floated(LongDecimal("0.0000000000000000000000000050000000000000000000000000000000000000000000000000000000000000017066"), 25)
    check_exp_floated(LongDecimal("0.00000000000000000000000000000000000000000000000000000000000000570000000004000000000000050"), 86)
  end

  #
  # test the calculation of the exponential function with precision 0
  #
  def test_exp_int

    xx = LongMath.log(10, 10)*100
    pi = LongMath.pi(10)
    sq = LongMath.sqrt(5, 20)

    check_exp_int(0)

    check_exp_int(700.1)
    check_exp_int(700)
    check_exp_int(100.01)
    check_exp_int(100)
    check_exp_int(1.001)
    check_exp_int(1)
    check_exp_int(0.01)
    check_exp_int(1e-10)
    check_exp_int(1e-90)
    check_exp_int(xx)
    check_exp_int(pi)
    check_exp_int(sq)

    check_exp_int(-700.1)
    check_exp_int(-700)
    check_exp_int(-100.01)
    check_exp_int(-100)
    check_exp_int(-1.001)
    check_exp_int(-1)
    check_exp_int(-0.01)
    check_exp_int(-1e-10)
    check_exp_int(-1e-90)
    check_exp_int(-xx)
    check_exp_int(-pi)
    check_exp_int(-sq)

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
  # test LongMath.exp with non-LongDecimal arguments
  #
  def test_non_ld_exp
    xi = 77
    yi = LongMath.exp(xi, 30)
    zi = LongMath.log(yi, 30)
    assert(zi.is_int?, "zi")
    assert_equal(xi, zi.to_i, "zi")

    xf = 77.0
    yf = LongMath.exp(xf, 30)
    zf = LongMath.log(yf, 30)
    assert(zf.is_int?, "zf")
    assert_equal(xf, zf.to_f, "zf")
    assert_equal(yi, yf, "i-f")

    xr = Rational(224, 225)
    yr = LongMath.exp(xr, 30)
    zr = LongMath.log(yr, 30)
    assert((zr-xr).abs <= zr.unit, "zr-xr")
  end

  #
  # test LongMath.log with non-LongDecimal arguments
  #
  def test_non_ld_log
    xi = 77
    yi = LongMath.log(xi, 35)
    zi = LongMath.exp(yi, 30)
    assert(zi.is_int?, "zi=#{zi}")
    assert_equal(xi, zi.to_i, "zi")

    xf = 77.0
    yf = LongMath.log(xf, 35)
    zf = LongMath.exp(yf, 30)
    assert(zf.is_int?, "zf=#{zf}")
    assert_equal(xf, zf.to_f, "zf")
    assert_equal(yi, yf, "i-f")

    xr = Rational(224, 225)
    yr = LongMath.log(xr, 35)
    zr = LongMath.exp(yr, 30)
    assert((zr-xr).abs <= zr.unit, "zr-xr zr=#{zr}")
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
  # test the calculation of the logarithm function
  #
  def test_log

    check_log_floated(10**2000, 10)
    check_log_floated(100, 10)
    check_log_floated(1, 10)
    check_log_floated(0.01, 10)
    check_log_floated(1e-10, 10)
    check_log_floated(1e-90, 10)
    check_log_floated(1e-300, 10)
    check_log_floated(LongDecimal(1, 2000), 10)

    check_log_floated(2, 50)
    check_log_floated(1.01, 50)
    check_log_floated(1+1e-10, 50, 1e7)
    check_log_floated(1.to_ld(90).succ, 100, 1e9, 1e-90)
    check_log_floated(1.to_ld(300).succ, 400, 1e9,1e-300)

    check_log_floated(2, 50)
    check_log_floated(0.99, 50)
    check_log_floated(1-1e-10, 50, 1e7)
    check_log_floated(1.to_ld(90).pred, 100, 1e9, 1e-90)
    check_log_floated(1.to_ld(300).pred, 400, 1e9, 1e-300)

    check_log_floated(10**2000, 100)
    check_log_floated(100, 100)
    check_log_floated(1, 100)
    check_log_floated(0.01, 100)
    check_log_floated(1e-10, 100)
    check_log_floated(1e-90, 100)
    check_log_floated(1e-300, 100)
    check_log_floated(LongDecimal(1, 2000), 100)

    # random tests that have failed
    check_log_floated(LongDecimal("666.000000000000000000000000000000000091600000000531000000000000000000000000000000000000000000831"), 1)
    check_log_floated(LongDecimal("333.000000000000000000000000919000000000000000000000000000000000001240000000000198"), 91)
    check_log_floated(LongDecimal("695.000000000000000000000000000000000000016169000000000000000572"), 10)
    check_log_floated(LongDecimal("553.00000000526000000000000000000000000000000000000000000000000298000000000000000079"), 1)
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
  end



  #
  # test calculation of pi
  #
  def test_pi
    s  = "3.14159265358979323846264338327950288419716939937510"
    s +=   "58209749445923078164062862089986280348253421170679"
    s +=   "82148086513282306647093844609550582231725359408128"
    s +=   "48111745028410270193852110555964462294895493038196"
    s +=   "44288109756659334461284756482337867831652712019091"
    s +=   "45648566923460348610454326648213393607260249141273"
    s +=   "72458700660631558817488152092096282925409171536436"
    s +=   "78925903600113305305488204665213841469519415116094"
    s +=   "33057270365759591953092186117381932611793105118548"
    s +=   "07446237996274956735188575272489122793818301194912"
    s +=   "98336733624406566430860213949463952247371907021798"
    s +=   "60943702770539217176293176752384674818467669405132"
    s +=   "00056812714526356082778577134275778960917363717872"
    s +=   "14684409012249534301465495853710507922796892589235"
    s +=   "42019956112129021960864034418159813629774771309960"
    s +=   "51870721134999999837297804995105973173281609631859"
    s +=   "50244594553469083026425223082533446850352619311881"
    s +=   "71010003137838752886587533208381420617177669147303"
    s +=   "59825349042875546873115956286388235378759375195778"
    s +=   "18577805321712268066130019278766111959092164201989"
    s +=   "38095257201065485863278865936153381827968230301952"
    s +=   "03530185296899577362259941389124972177528347913151"
    s +=   "55748572424541506959508295331168617278558890750983"
    s +=   "81754637464939319255060400927701671139009848824012"
    s +=   "85836160356370766010471018194295559619894676783744"
    s +=   "94482553797747268471040475346462080466842590694912"
    s +=   "93313677028989152104752162056966024058038150193511"
    s +=   "25338243003558764024749647326391419927260426992279"
    s +=   "67823547816360093417216412199245863150302861829745"
    s +=   "55706749838505494588586926995690927210797509302955"
    s +=   "32116534498720275596023648066549911988183479775356"
    s +=   "63698074265425278625518184175746728909777727938000"
    s +=   "81647060016145249192173217214772350141441973568548"
    s +=   "16136115735255213347574184946843852332390739414333"
    s +=   "45477624168625189835694855620992192221842725502542"
    s +=   "56887671790494601653466804988627232791786085784383"
    s +=   "82796797668145410095388378636095068006422512520511"
    s +=   "73929848960841284886269456042419652850222106611863"
    s +=   "06744278622039194945047123713786960956364371917287"
    s +=   "46776465757396241389086583264599581339047802759010"

    l = LongDecimal(s)
    pi = LongMath.pi 200
    assert_equal(l.round_to_scale(200, LongMath::ROUND_HALF_EVEN), pi, "200 digits")
    pi = LongMath.pi 201
    assert_equal(l.round_to_scale(201, LongMath::ROUND_HALF_EVEN), pi, "201 digits")
    pi = LongMath.pi 199
    assert_equal(l.round_to_scale(199, LongMath::ROUND_HALF_EVEN), pi, "199 digits")
    pi = LongMath.pi 201
    assert_equal(l.round_to_scale(201, LongMath::ROUND_HALF_EVEN), pi, "201 digits")
  end

  #
  # test method sqrtb for calculating sqrt of short integers
  #
  def test_int_sqrtb
    assert_equal(Complex(0,1), LongMath.sqrtb(-1), "sqrt(-1)=i")
    1024.times do |x|
      check_sqrtb(x, " loop x=#{x}")
    end
    512.times do |i|
      x1 = i*i
      y = check_sqrtb(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtb(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtb(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtb(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtb(x1-1, " 2**i-1 i=#{i}")
        check_sqrtb(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtb(x1, " 3*2**i i=#{i}")
      check_sqrtb(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtb(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method sqrtb for calculating sqrt of long integers
  #
  def test_int_sqrtw
    assert_equal(Complex(0,1), LongMath.sqrtw(-1), "sqrt(-1)=i")
    1024.times do |x|
      check_sqrtw(x, " loop x=#{x}")
    end
    1024.times do |i|
      x1 = i*i
      y = check_sqrtw(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtw(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtw(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtw(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtw(x1-1, " 2**i-1 i=#{i}")
        check_sqrtw(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtw(x1, " 3*2**i i=#{i}")
      check_sqrtw(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtw(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method sqrtb_with_remainder for calculating sqrt _with_remainderof short integers
  #
  def test_int_sqrtb_with_remainder
    10.times do |x|
      check_sqrtb_with_remainder(x, " loop x=#{x}")
    end
    100.times do |i|
      x = 10*i + 10
      check_sqrtb_with_remainder(x, " loop x=#{x}")
    end
    50.times do |j|
      i = 10 * j
      x1 = i * i
      y = check_sqrtb_with_remainder(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtb_with_remainder(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtb_with_remainder(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtb_with_remainder(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtb_with_remainder(x1-1, " 2**i-1 i=#{i}")
        check_sqrtb_with_remainder(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtb_with_remainder(x1, " 3*2**i i=#{i}")
      check_sqrtb_with_remainder(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtb_with_remainder(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test method sqrtb_with_remainder for calculating sqrt _with_remainderof long integers
  #
  def test_int_sqrtw_with_remainder
    10.times do |x|
      check_sqrtw_with_remainder(x, " loop x=#{x}")
    end
    100.times do |j|
      x = 10 * j + 10
      check_sqrtw_with_remainder(x, " loop x=#{x}")
    end
    100.times do |j|
      i = 10*j
      x1 = i*i
      y = check_sqrtw_with_remainder(x1, " i*i i=#{i}")
      assert_equal(i, y, "i=#{i} y=#{y}")
      if (i > 0) then
        x2 = x1 + 1
        y = check_sqrtw_with_remainder(x2, " i*i+1 i=#{i}")
        assert_equal(i, y, "i=#{i} y=#{y}")
        x0 = x1 - 1
        y = check_sqrtw_with_remainder(x0, " i*i-1 i=#{i}")
        assert_equal(i-1, y, "i=#{i} y=#{y}")
      end

      x1 = 1 << i
      y = check_sqrtw_with_remainder(x1, " 2**i i=#{i}")
      if (i[0] == 0)
        assert_equal(1 << (i>>1), y, "2^(i/2) i=#{i} y=#{y}")
      end
      if (i > 0) then
        check_sqrtw_with_remainder(x1-1, " 2**i-1 i=#{i}")
        check_sqrtw_with_remainder(x1+1, " 2**i+1 i=#{i}")
      end

      x1 = 3 << i
      check_sqrtw_with_remainder(x1, " 3*2**i i=#{i}")
      check_sqrtw_with_remainder(x1-1, " 3*2**i-1 i=#{i}")
      check_sqrtw_with_remainder(x1+1, " 3*2**i+1 i=#{i}")
    end
  end

  #
  # test gcd_with_high_power
  #
  def test_gcd_with_high_power
    n = 224
    assert_equal(32, LongMath.gcd_with_high_power(n, 2), "2-part of 224 is 32")
    assert_equal(7, LongMath.gcd_with_high_power(n, 7), "7-part of 224 is 7")
    assert_equal(1, LongMath.gcd_with_high_power(n, 3), "3-part of 224 is 1")
  end

  #
  # test multiplicity_of_factor for integers
  #
  def test_multiplicity_of_factor
    n = 224
    assert_equal(5, LongMath.multiplicity_of_factor(n, 2), "ny_2(224) is 5")
    assert_equal(1, LongMath.multiplicity_of_factor(n, 7), "ny_7(224) is 1")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 3), "ny_3(224) is 0")
  end

  #
  # test multiplicity_of_factor for rationals
  #
  def test_rat_multiplicity_of_factor
    n = Rational(224, 225)
    assert_equal(5, LongMath.multiplicity_of_factor(n, 2), "ny_2(n) is 5")
    assert_equal(1, LongMath.multiplicity_of_factor(n, 7), "ny_7(n) is 1")
    assert_equal(-2, LongMath.multiplicity_of_factor(n, 3), "ny_3(n) is -2")
    assert_equal(-2, LongMath.multiplicity_of_factor(n, 5), "ny_5(n) is -2")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 11), "ny_11(n) is 0")
  end

  #
  # test multiplicity_of_factor for rationals with numerator and
  # denominator exceeding Float
  #
  def test_rat_long_multiplicity_of_factor
    n = Rational(224*(10**600+1), 225*(5**800))
    assert_equal(5, LongMath.multiplicity_of_factor(n, 2), "ny_2(n) is 5")
    assert_equal(1, LongMath.multiplicity_of_factor(n, 7), "ny_7(n) is 1")
    assert_equal(-2, LongMath.multiplicity_of_factor(n, 3), "ny_3(n) is -2")
    assert_equal(-802, LongMath.multiplicity_of_factor(n, 5), "ny_5(n) is -2")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 11), "ny_11(n) is 0")
  end

  #
  # test multiplicity_of_factor for LongDecimal
  #
  def test_ld_multiplicity_of_factor
    # 0.729
    n = LongDecimal(729, 3)
    assert_equal(-3, LongMath.multiplicity_of_factor(n, 2), "ny_2(n) is -3")
    assert_equal(6, LongMath.multiplicity_of_factor(n, 3), "ny_3(n) is 6")
    assert_equal(-3, LongMath.multiplicity_of_factor(n, 5), "ny_5(n) is -3")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 7), "ny_7(n) is 0")
    assert_equal(0, LongMath.multiplicity_of_factor(n, 11), "ny_11(n) is 0")
  end

  #
  # test creation of 0 with given number of digits after the decimal point
  #
  def test_zero_init
    l = LongDecimal.zero!(224)
    assert_equal(l.to_r, 0, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 1 with given number of digits after the decimal point
  #
  def test_one_init
    l = LongDecimal.one!(224)
    assert_equal(l.to_r, 1, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 2 with given number of digits after the decimal point
  #
  def test_two_init
    l = LongDecimal.two!(224)
    assert_equal(l.to_r, 2, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 10 with given number of digits after the decimal point
  #
  def test_ten_init
    l = LongDecimal.ten!(224)
    assert_equal(l.to_r, 10, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of -1 with given number of digits after the decimal point
  #
  def test_minus_one_init
    l = LongDecimal.minus_one!(224)
    assert_equal(l.to_r, -1, "to_r")
    assert_equal(l.scale, 224, "scale")
  end

  #
  # test creation of 10**e with given number of digits after the decimal point
  #
  def test_power_of_ten_init
    20.times do |e|
      l = LongDecimal.power_of_ten!(e, 224)
      assert_equal(l.to_r, 10**e, "to_r e=#{e}")
      assert_equal(l.scale, 224, "scale")
    end
  end

  #
  # test construction of LongDecimal from Integer
  #
  def test_int_init
    i = 224
    l = LongDecimal(i)
    assert_equal(i, l.to_i, "no loss of information for integers allowed")
    assert_equal(l, i.to_ld(0), "to_ld")
    i = -333
    l = LongDecimal(i)
    assert_equal(i, l.to_i, "no loss of information for integers allowed")
    assert_equal(l, i.to_ld(0), "to_ld")
    i = 1000000000000000000000000000000000000000000000000
    l = LongDecimal(i)
    assert_equal(i, l.to_i, "no loss of information for integers allowed")
    assert_equal(l, i.to_ld(0), "to_ld")
    i = 19
    l = LongDecimal(i, 1)
    assert_equal(1, l.to_i, "loss of information 1.9->1")
    assert_equal(LongDecimal(190, 1), i.to_ld(1))
  end

  #
  # test construction from Rational
  #
  def test_rat_init
    r = Rational(227, 100)
    l = LongDecimal(r)
    assert_equal(r, l.to_r, "no loss of information for rationals with denominator power of 10 allowed l=#{l.inspect}")
    assert_equal(l, r.to_ld, "to_ld")
    l = LongDecimal(r, 3)
    assert_equal(r, l.to_r * 1000, "scaling for rationals")
    assert_equal(l, (r/1000).to_ld(5), "to_ld")
    r = Rational(224, 225)
    l = LongDecimal(r)
    assert((r - l.to_r).to_f.abs < 0.01, "difference of #{r.inspect} and #{l.inspect} must be less 0.01 but is #{(r - l.to_r).to_f.abs}")
    assert_equal(l, r.to_ld, "to_ld")
  end

  #
  # test construction from Float
  #
  def test_float_init
    s = "5.32"
    l = LongDecimal(s)
    assert_equal(s, l.to_s, "l=#{l.inspect}")
    assert_equal(l, s.to_f.to_ld, "to_ld")
    f = 2.24
    l = LongDecimal(f)
    assert_equal(f.to_s, l.to_s, "l=#{l.inspect} f=#{f.inspect}")
    assert_equal(l, f.to_ld, "to_ld")
    f = 2.71E-4
    l = LongDecimal(f)
    assert_equal("0.000271", l.to_s, "l=#{l.inspect} f=#{f.inspect}")
    assert_equal(l, f.to_ld, "to_ld")
    f = 224.225
    l = LongDecimal(f, 4)
    assert_equal("0.0224225", l.to_s, "l=#{l.inspect} f=#{f.inspect}")
    assert_equal(l, (f/10000).to_ld(7), "to_ld")
  end

  #
  # test construction from BigDecimal
  #
  def test_bd_init
    b = BigDecimal("5.32")
    l = LongDecimal(b)
    assert_equal(b, l.to_bd, "l=#{l.inspect}")
    assert_equal(l, b.to_ld, "to_ld")
    b = BigDecimal("2.24")
    l = LongDecimal(b)
    assert((b.to_f - l.to_f).abs < 1e-9, "l=#{l.inspect} b=#{b.inspect}")
    assert_equal(l, b.to_ld, "to_ld")
    b = BigDecimal("2.71E-4")
    l = LongDecimal(b)
    assert_equal("0.000271", l.to_s, "l=#{l.inspect} b=#{b.inspect}")
    assert_equal(l, b.to_ld, "to_ld")
    b = BigDecimal("224.225")
    l = LongDecimal(b, 4)
    assert_equal("0.0224225", l.to_s, "l=#{l.inspect} b=#{b.inspect}")
    assert_equal(l, (b/10000).to_ld(7), "to_ld")
  end

  #
  # test int_digits2 of LongDecimal
  #
  def test_int_digits2
    assert_equal(0, LongDecimal("0.0000").int_digits2, "0.0000")
    assert_equal(0, LongDecimal("0.9999").int_digits2, "0.9999")
    assert_equal(1, LongDecimal("1.0000").int_digits2, "1.0000")
    assert_equal(1, LongDecimal("1.9999").int_digits2, "1.9999")
    assert_equal(2, LongDecimal("2.0000").int_digits2, "2.0000")
    assert_equal(2, LongDecimal("3.9999").int_digits2, "3.9999")
    assert_equal(3, LongDecimal("4.0000").int_digits2, "4.0000")
    assert_equal(3, LongDecimal("7.9999").int_digits2, "7.9999")
    assert_equal(4, LongDecimal("8.0000").int_digits2, "8.0000")
    assert_equal(4, LongDecimal("15.9999").int_digits2, "15.9999")

    assert_equal(0, LongDecimal("-0.0000").int_digits2, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").int_digits2, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").int_digits2, "-1.0000")
    assert_equal(1, LongDecimal("-1.9999").int_digits2, "-1.9999")
    assert_equal(2, LongDecimal("-2.0000").int_digits2, "-2.0000")
    assert_equal(2, LongDecimal("-3.9999").int_digits2, "-3.9999")
    assert_equal(3, LongDecimal("-4.0000").int_digits2, "-4.0000")
    assert_equal(3, LongDecimal("-7.9999").int_digits2, "-7.9999")
  end

  #
  # test int_digits10 of LongDecimal
  #
  def test_int_digits10
    assert_equal(0, LongDecimal("0.0000").int_digits10, "0.0000")
    assert_equal(0, LongDecimal("0.0009").int_digits10, "0.0009")
    assert_equal(0, LongDecimal("0.0099").int_digits10, "0.0099")
    assert_equal(0, LongDecimal("0.0999").int_digits10, "0.0999")
    assert_equal(0, LongDecimal("0.9999").int_digits10, "0.9999")
    assert_equal(1, LongDecimal("1.0000").int_digits10, "1.0000")
    assert_equal(1, LongDecimal("9.9999").int_digits10, "9.9999")
    assert_equal(2, LongDecimal("10.0000").int_digits10, "10.0000")
    assert_equal(2, LongDecimal("99.9999").int_digits10, "99.9999")
    assert_equal(3, LongDecimal("100.0000").int_digits10, "100.0000")
    assert_equal(3, LongDecimal("999.9999").int_digits10, "999.9999")

    assert_equal(0, LongDecimal("-0.0000").int_digits10, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").int_digits10, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").int_digits10, "-1.0000")
    assert_equal(1, LongDecimal("-9.9999").int_digits10, "-9.9999")
    assert_equal(2, LongDecimal("-10.0000").int_digits10, "-10.0000")
    assert_equal(2, LongDecimal("-99.9999").int_digits10, "-99.9999")
    assert_equal(3, LongDecimal("-100.0000").int_digits10, "-100.0000")
    assert_equal(3, LongDecimal("-999.9999").int_digits10, "-999.9999")
    x = 1234.to_ld
    assert_equal(4, x.int_digits10, "1234")
    assert_equal(4, x.int_digits10, "1234")
    x = 1234.to_ld(10)
    assert_equal(4, x.int_digits10, "1234")
    assert_equal(4, x.int_digits10, "1234")
  end

  #
  # test sint_digits10 of LongDecimal
  #
  def test_sint_digits10
    assert_equal(-4, LongDecimal("0.0000").sint_digits10, "0.0000")
    assert_equal(-3, LongDecimal("0.0009").sint_digits10, "0.0009")
    assert_equal(-2, LongDecimal("0.0099").sint_digits10, "0.0099")
    assert_equal(-1, LongDecimal("0.0999").sint_digits10, "0.0999")
    assert_equal(0, LongDecimal("0.9999").sint_digits10, "0.9999")
    assert_equal(1, LongDecimal("1.0000").sint_digits10, "1.0000")
    assert_equal(1, LongDecimal("9.9999").sint_digits10, "9.9999")
    assert_equal(2, LongDecimal("10.0000").sint_digits10, "10.0000")
    assert_equal(2, LongDecimal("99.9999").sint_digits10, "99.9999")
    assert_equal(3, LongDecimal("100.0000").sint_digits10, "100.0000")
    assert_equal(3, LongDecimal("999.9999").sint_digits10, "999.9999")

    assert_equal(-4, LongDecimal("-0.0000").sint_digits10, "-0.0000")
    assert_equal(0, LongDecimal("-0.9999").sint_digits10, "-0.9999")
    assert_equal(1, LongDecimal("-1.0000").sint_digits10, "-1.0000")
    assert_equal(1, LongDecimal("-9.9999").sint_digits10, "-9.9999")
    assert_equal(2, LongDecimal("-10.0000").sint_digits10, "-10.0000")
    assert_equal(2, LongDecimal("-99.9999").sint_digits10, "-99.9999")
    assert_equal(3, LongDecimal("-100.0000").sint_digits10, "-100.0000")
    assert_equal(3, LongDecimal("-999.9999").sint_digits10, "-999.9999")
    x = 1234.to_ld
    assert_equal(4, x.sint_digits10, "1234")
    assert_equal(4, x.sint_digits10, "1234")
    x = 1234.to_ld(10)
    assert_equal(4, x.sint_digits10, "1234")
    assert_equal(4, x.sint_digits10, "1234")
  end

  #
  # test int_digits10 of LongMath
  #
  def test_lm_int_digits10
    assert_equal(0, LongMath.int_digits10(0), "0")
    assert_equal(1, LongMath.int_digits10(1), "1")
    assert_equal(1, LongMath.int_digits10(9), "9")
    assert_equal(2, LongMath.int_digits10(10), "10")
    assert_equal(2, LongMath.int_digits10(11), "11")
    assert_equal(2, LongMath.int_digits10(98), "98")
    assert_equal(2, LongMath.int_digits10(99), "99")
    assert_equal(3, LongMath.int_digits10(100), "100")
    assert_equal(3, LongMath.int_digits10(999), "999")
    assert_equal(4, LongMath.int_digits10(1000), "1000")
    assert_equal(4, LongMath.int_digits10(9999), "9999")
  end

  #
  # test round_trailing_zeros of LongDecimal
  #
  def test_round_trailing_zeros
    x = LongDecimal.one!(100)
    y = x.round_trailing_zeros
    z = LongDecimal.one!(0)
    assert_equal(y, z, "1 w/o trailing")
    x = LongDecimal(22400, 5)
    y = x.round_trailing_zeros
    z = LongDecimal(224, 3)
    assert_equal(y, z, "2.24 w/o trailing")
    x = LongDecimal(123456, 3)
    y = x.round_trailing_zeros
    assert_equal(y, x, "1234.56 w/o trailing")
  end

  #
  # test rounding of LongDecimal with ROUND_UP
  #
  def test_round_to_scale_up
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_UP)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_DOWN
  #
  def test_round_to_scale_down
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_DOWN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_CEILING
  #
  def test_round_to_scale_ceiling
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_CEILING)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_FLOOR
  #
  def test_round_to_scale_floor
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_FLOOR)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_UP
  #
  def test_round_to_scale_half_up
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_DOWN
  #
  def test_round_to_scale_half_down
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_HALF_EVEN
  #
  def test_round_to_scale_half_even
    l = LongDecimal("2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.35")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.4", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.20")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.20", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.21")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.21", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.25")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.25", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.35")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.4", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.35", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("-2.29")
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-2.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_equal("-2.29", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding with ROUND_UNNECESSARY
  #
  def test_round_to_scale_unnecessary
    l = LongDecimal("2.24")
    r = l.round_to_scale(4, LongDecimal::ROUND_UNNECESSARY)
    assert_equal("2.2400", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimal("2.2400")
    r = l.round_to_scale(2, LongDecimal::ROUND_UNNECESSARY)
    assert_equal("2.24", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    begin
      l = LongDecimal("2.24")
      r = l.round_to_scale(1, LongDecimal::ROUND_UNNECESSARY)
      assert_fail("should not have succeeded l=#{l.inspect} r=#{r.inspect}")
    rescue ArgumentError
      # ignored
    end
  end

  #
  # test conversion to String
  #
  def test_to_s
    l = LongDecimal(224, 0)
    assert_equal("224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert_equal("22.4", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert_equal("2.24", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert_equal("0.224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert_equal("0.0224", l.to_s, "l=#{l.inspect}")

    l = LongDecimal(-224, 0)
    assert_equal("-224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 1)
    assert_equal("-22.4", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 2)
    assert_equal("-2.24", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 3)
    assert_equal("-0.224", l.to_s, "l=#{l.inspect}")
    l = LongDecimal(-224, 4)
    assert_equal("-0.0224", l.to_s, "l=#{l.inspect}")
  end

  #
  # test conversion to String with extra parameters
  #
  def test_to_s_with_params
    l = LongDecimal(224, 0)
    s = l.to_s(5)
    assert_equal("224.00000", s, "l=#{l.inspect} 5")
    s = l.to_s(5, LongDecimal::ROUND_UNNECESSARY, 16)
    assert_equal("e0.00000", s, "l=#{l.inspect} 5 ROUND_UNNECESSARY 16")

    l = LongDecimal(224, 1)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("22", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("22.40000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(224, 2)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("2", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("2.24000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(-224, 0)
    s = l.to_s(5)
    assert_equal("-224.00000", s, "l=#{l.inspect} 5")
    s = l.to_s(5, LongDecimal::ROUND_UNNECESSARY, 16)
    assert_equal("-e0.00000", s, "l=#{l.inspect} 5 ROUND_UNNECESSARY 16")

    l = LongDecimal(-224, 1)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("-22", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("-22.40000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("-16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("-16.66666", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")

    l = LongDecimal(-224, 2)
    s = l.to_s(0, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2", s, "l=#{l.inspect} 0 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP)
    assert_equal("-2.24000", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_UP, 16)
    assert_equal("-2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_UP")
    s = l.to_s(5, LongDecimal::ROUND_HALF_DOWN, 16)
    assert_equal("-2.3d70a", s, "l=#{l.inspect} 5 ROUND_HALF_DOWN")
  end

  #
  # test conversion to Rational
  #
  def test_to_r
    l = LongDecimal(224, 0)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert_equal(l, l.to_r.to_ld, "l=#{l.inspect}")
  end

  #
  # test conversion to Float
  #
  def test_to_f
    l = LongDecimal(224, 0)
    assert((l.to_f - 224).abs < 224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert((l.to_f - 22.4).abs < 22.4 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert((l.to_f - 2.24).abs < 2.24 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert((l.to_f - 0.224).abs < 0.224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert((l.to_f - 0.0224).abs < 0.0224 * 0.000001, "l=#{l.inspect}")
  end

  #
  # test to_ld of Numeric
  #
  def test_to_ld
    x = LongDecimal(123, 100)
    y = x.to_ld(20, LongMath::ROUND_UP)
    z = LongDecimal(1, 20)
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(y, z, "x=#{x} y=#{y}")
    y = x.to_ld(20, LongMath::ROUND_HALF_UP)
    z = LongDecimal(0, 20)
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(y, z, "x=#{x} y=#{y}")

    x = 224
    y = x.to_ld(20)
    z = LongDecimal(224*10**20, 20)
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(y, z, "x=#{x} y=#{y}")
  end

  #
  # test conversion to BigDecimal
  #
  def test_to_bd
    l = LongDecimal(224, 0)
    assert((l.to_bd - 224).abs < 224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert((l.to_bd - 22.4).abs < 22.4 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert((l.to_bd - 2.24).abs < 2.24 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert((l.to_bd - 0.224).abs < 0.224 * 0.000001, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert((l.to_bd - 0.0224).abs < 0.0224 * 0.000001, "l=#{l.inspect}")
  end

  #
  # test conversion to Integer
  #
  def test_to_i
    l = LongDecimal(224, 0)
    assert_equal(224, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 1)
    assert_equal(22, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 2)
    assert_equal(2, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 3)
    assert_equal(0, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(224, 4)
    assert_equal(0, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(229, 1)
    assert_equal(22, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(-229, 1)
    assert_equal(-23, l.to_i, "l=#{l.inspect}")
    l = LongDecimal(-221, 1)
    assert_equal(-23, l.to_i, "l=#{l.inspect}")
  end

  #
  # test adjustment of scale which is used as preparation for addition
  # and subtraction
  #
  def test_equalize_scale
    x = LongDecimal(1, 0)
    y = LongDecimal(10, 1)
    assert_equal(0, (x - y).sgn, "difference must be 0")
    assert(! (x == y), "x and y have the same value, but are not equal")
    u, v = x.equalize_scale(y)
    assert_equal(u, v, "u and v must be equal")
    assert_equal(y, v, "y and v must be equal")
    assert_equal(1, u.scale, "scale must be 1")
    y = LongDecimal(200, 2)
    v, u = y.equalize_scale(x)
    assert_equal(2, u.scale, "scale must be 2")
    assert_equal(2, v.scale, "scale must be 2")
    assert_equal(100, u.int_val, "int_val must be 100")
    assert_equal(200, v.int_val, "int_val must be 200")
  end

  #
  # test adjustment of scale which is used as preparation for division
  #
  def test_anti_equalize_scale
    x = LongDecimal(20, 3)
    y = LongDecimal(10, 1)
    u, v = x.anti_equalize_scale(y)
    assert_equal(0, u.scale, "scale must be 0")
    assert_equal(0, v.scale, "scale must be 0")
    assert_equal(20, u.int_val, "int_val must be 20")
    assert_equal(1000, v.int_val, "int_val must be 1000")
  end

  #
  # test unary minus operation (negation)
  #
  def test_negation
    x = LongDecimal(0, 5)
    assert_equal(-x, x, "x and -x are equal for negative x=#{x.inspect}")
    x = LongDecimal(224, 2)
    y = -x
    assert_equal(-1, y.sgn, "sign of y must be -1 y=#{y.inspect}")
    assert_equal(2, y.scale, "scale of y must be 2 y=#{y.inspect}")
    assert_equal(-224, y.int_val, "int_val of y must be -224 y=#{y.inspect}")
  end

  #
  # test addition of LongDecimal
  #
  def test_add
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x + y
    zz = LongDecimal(254, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x + y
    zz = LongDecimal(724, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x + y
    zz = LongDecimal(724, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x + y
    zz = LongDecimalQuot(Rational(293, 75), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x + y
    zz = LongDecimalQuot(Rational(293, 75), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x + y
    zz = Complex(7.24, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test subtraction of LongDecimal
  #
  def test_sub
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x - y
    zz = LongDecimal(194, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimal(-194, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x - y
    zz = LongDecimal(-276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimal(276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x - y
    zz = LongDecimal(-276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimal(276, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x - y
    zz = LongDecimalQuot(Rational(43, 75), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(-43, 75), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x - y
    zz = LongDecimalQuot(Rational(43, 75), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(-43, 75), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x - y
    zz = Complex(-2.76, -3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = Complex(2.76, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test multiplication of LongDecimal
  #
  def test_mul
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    z = x * y
    zz = LongDecimal(224*3, 3)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x * y
    zz = LongDecimal(224*5, 2)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x * y
    zz = LongDecimal(112000, 4)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 300), 4)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 300), 5)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x * y
    zz = Complex(11.20, 6.72)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test division of LongDecimal
  #
  def test_div
    x = LongDecimal(224, 2) # 2.24 dx=1 sx=2

    y = LongDecimal(3, 1)   # 0.3  dy=0 sy=1
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -3 -> use 0
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(30, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                                   # x= 2.24     dx=1 sx=2
    y = LongDecimal(30000000, 8)   # 0.30000000  dy=0 sy=8
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(30, 224), 1)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                            # x= 2.24 dx=1  sx=2
    y = LongDecimal(3, 4)   # 0.0003  dy=-4 sy=4
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -8 -> use 0
    zz = LongDecimalQuot(Rational(22400, 3), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 2
    zz = LongDecimalQuot(Rational(3, 22400), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                             # x= 2.24 dx=1 sx=2
    y = LongDecimal(3333, 2) # 33.33   dy=2 sy=2
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(224, 3333), 1)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(3333, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                              # x= 2.24 dx=1 sx=2
    y = LongDecimal(33333, 2) # 333.33  dy=3 sy=2
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 2
    zz = LongDecimalQuot(Rational(224, 33333), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -2 -> use 0
    zz = LongDecimalQuot(Rational(33333, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                              # x= 2.24 dx=1 sx=2
    y = LongDecimal(33333, 3) # 33.333  dy=2 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(2240, 33333), 1)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(33333, 2240), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                             # x= 2.24 dx=1 sx=2
    y = LongDecimal(3333, 3) # 3.333   dy=1 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(2240, 3333), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(3333, 2240), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

                                  # x= 2.24    dx=1 sx=2
    y = LongDecimal(123456789, 3) # 123456.789 dy=6 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 5
    zz = LongDecimalQuot(Rational(2240, 123456789), 5)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -5 -> use 0
    zz = LongDecimalQuot(Rational(123456789, 2240), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

           # x= 2.24 dx=1 sx=2
    y = 5  #    5    dy=1 sy=0
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -2 -> use 0
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = -2 -> use 0
    zz = LongDecimalQuot(Rational(500, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

              # x= 2.24 dx=1 sx=2
    y = 5.001 #         dy=1 sy=3
    z = x / y
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 0
    zz = LongDecimalQuot(Rational(500, 224), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x / y
    # y is has no scale, use scale of x
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    # y is has no scale, use scale of x
    zz = LongDecimalQuot(Rational(500, 224*3), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x / y
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(500, 224*3), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x / y
    zz = 2.24 / Complex(5, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y / x
    zz = Complex(5 / 2.24, 3 / 2.24)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test square of LongDecimal
  #
  def test_square
    10.times do |i|
      n = (i*i+i)/2
      x = LongDecimal(n, i)
      y = x.square
      z = LongDecimal(n*n, 2*i)
      assert_equal(y, z, "square i=#{i}")
    end
  end

  #
  # test reciprocal of LongDecimal
  #
  def test_reciprocal
    10.times do |i|
      k = 2*i+1
      n = (k*k+k)/2
      x = LongDecimal(n, i)
      y = x.reciprocal
      z = LongDecimalQuot(Rational(10**i, n), [i+2*(Math.log10(n)-i).floor, 0].max)
      assert_equal(z, y, "reciprocal x=#{x} y=#{y} z=#{z} i=#{i} k=#{k} n=#{n}")
    end
  end

  #
  # test power (**) of LongDecimal
  #
  def test_pow

    x = LongDecimal(224, 2)

    y = 0.5
    z = x ** y
    zz = Math.sqrt(2.24)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = 0
    z = x ** y
    zz = LongDecimal(1, 0)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be 1")

    y = 1
    z = x ** y
    zz = x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = 2
    z = x ** y
    zz = LongDecimal(224**2, 4)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = LongDecimal(2, 0)
    z = x ** y
    zz = LongDecimal(224**2, 4)
    assert_kind_of(LongDecimal, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = -1
    z = x ** y
    zz = LongDecimalQuot(Rational(100, 224), 2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = -2
    z = x ** y
    zz = LongDecimalQuot(Rational(10000, 224**2), 4)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = LongDecimal(5, 1)
    z = x ** y
    zz = Math.sqrt(2.24)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = LongDecimal(5, 1)
    z = 9 ** y
    zz = 3.0
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test division with remainder of LongDecimal
  #
  def test_divmod
    x = LongDecimal(224, 2)

    y = LongDecimal(3, 1)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(30, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimal(30000000, 8)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 30), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(30, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimal(3330000000, 8)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 3330), 1)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(3330, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224), 0)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5.001
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 500), 0)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimal, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224), 3)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Rational(5, 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 500), 2)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224*3), 2)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 500), 6)
    assert_val_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(500, 224*3), 3)
    assert_val_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Complex(5, 3)
    begin
      q, r = x.divmod y
      assert_fail "should have created TypeError"
    rescue TypeError
      # ignored, expected
    end
  end

  #
  # test dec, dec!, inc and inc! of LongDecimal
  #
  def test_inc_dec

    x0 = LongDecimal(224, 1)
    x  = LongDecimal(224, 1)
    y  = x.inc
    z  = LongDecimal(234, 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.inc!
    assert_equal(z, x, "z, x")

    x0 = LongDecimal(224, 1)
    x  = LongDecimal(224, 1)
    y  = x.dec
    z  = LongDecimal(214, 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.dec!
    assert_equal(z, x, "z, x")
  end

  #
  # test pred and succ of LongDecimal
  #
  def test_pred_succ
    x0 = LongDecimal(2245, 2)
    x  = LongDecimal(2245, 2)
    ys = x.succ
    assert_equal(x, x0, "x")
    yp = x.pred
    assert_equal(x, x0, "x")
    zs = LongDecimal(2246, 2)
    zp = LongDecimal(2244, 2)
    assert_equal(zs, ys, "succ")
    assert_equal(zp, yp, "pred")
    y  = LongDecimal(2254, 2)
    n  = (x..y).to_a.size
    assert_equal(10, n, "size")
  end

  #
  # test of &-operator of LongDecimal
  #
  def test_logand
    x = LongDecimal(224, 2) # 0x0e0 / 100

    y = LongDecimal(3, 1)   # 0x01e / 100
    z = x & y
    zz = LongDecimal(0, 2)  # 0x000 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y & x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(32, 1)  # 0x140 / 100
    z = x & y
    zz = LongDecimal(64, 2) # 0x040 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y & x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5                    # 0x1f4 / 100
    z = x & y
    zz = LongDecimal(224, 2) # 0x0e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y & x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 1                    # 0x064 / 100
    z = x & y
    zz = LongDecimal(96, 2)  # 0x060 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y & x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 256                  # 0x06400 / 100
    z = x & y
    zz = LongDecimal(0, 2)  # 0x000 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y & x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test of |-operator of LongDecimal
  #
  def test_logior
    x = LongDecimal(224, 2) # 0x0e0 / 100

    y = LongDecimal(3, 1)   # 0x01e / 100
    z = x | y
    zz = LongDecimal(254, 2)  # 0x0fe / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y | x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(32, 1)  # 0x140 / 100
    z = x | y
    zz = LongDecimal(480, 2) # 0x1e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y | x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5                    # 0x1f4 / 100
    z = x | y
    zz = LongDecimal(500, 2) # 0x1f4 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y | x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 1                    # 0x064 / 100
    z = x | y
    zz = LongDecimal(228, 2)  # 0x0e4 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y | x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 256                  # 0x06400 / 100
    z = x | y
    zz = LongDecimal(25824, 2)   # 0x064e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y | x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test of ^-operator of LongDecimal
  #
  def test_logxor
    x = LongDecimal(224, 2) # 0x0e0 / 100

    y = LongDecimal(3, 1)   # 0x01e / 100
    z = x ^ y
    zz = LongDecimal(254, 2)  # 0x0fe / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y ^ x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(32, 1)  # 0x140 / 100
    z = x ^ y
    zz = LongDecimal(416, 2) # 0x1a0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y ^ x
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5                    # 0x1f4 / 100
    z = x ^ y
    zz = LongDecimal(276, 2) # 0x114 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y ^ x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 1                    # 0x064 / 100
    z = x ^ y
    zz = LongDecimal(132, 2)  # 0x084 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y ^ x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")

    y = 256                  # 0x06400 / 100
    z = x ^ y
    zz = LongDecimal(25824, 2)   # 0x064e0 / 100
    assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    # does not coerce
    #     z = y ^ x
    #     assert_kind_of(LongDecimal, z, "z=#{z.inspect}")
    #     assert_equal(zz, z, "z=#{z.inspect}")
  end

  #
  # test of ^-operator of LongDecimal
  #
  def test_lognot
    x = LongDecimal(224, 2) # 0x0e0 / 100
    y = ~x
    z = LongDecimal(-225, 2)
    assert_kind_of(LongDecimal, y, "y=#{y.inspect}")
    assert_equal(z, y, "y=#{y.inspect}")
    x = LongDecimal(0, 2) # 0x00 / 100
    y = ~x
    z = LongDecimal(-1, 2)
    assert_kind_of(LongDecimal, y, "y=#{y.inspect}")
    assert_equal(z, y, "y=#{y.inspect}")
  end

  #
  # test << and >> of LongDecimal
  #
  def test_shift
    n = 12345678901234567890
    x = LongDecimal(n, 9)
    y = x << 5
    yy = LongDecimal(n * 32, 9)
    z = y >> 5
    assert_equal(yy, y, "shift left")
    assert_equal(x, z, "shift left then right")

    y = x >> 5
    yy = LongDecimal(n >> 5, 9)
    z = y << 5
    zz = LongDecimal((n >> 5) << 5, 9)
    assert_equal(yy, y, "shift right")
    assert_equal(zz, z, "shift right then left")
  end

  #
  # test [] access to digits
  #
  def test_bin_digit
    n = 12345678901234567890
    x = LongDecimal(n, 9)
    100.times do |i|
      assert_equal(n[i], x[i], "i=#{i}")
    end
    n = -12345678901234567890
    x = LongDecimal(n, 9)
    100.times do |i|
      assert_equal(n[i], x[i], "i=#{i}")
    end
  end

  #
  # test move_point_left and move_point_right
  #
  def test_move_point
    n = 12345678901234567890
    x = LongDecimal(n, 9)

    y = x.move_point_left(4)
    yy = x.move_point_right(-4)
    assert_equal(y, yy, "left / right 4")
    z = LongDecimal(n, 13)
    assert_equal(y, z, "left 4")
    w = y.move_point_right(4)
    assert_equal(x, w, "left 4 right 4")

    y = x.move_point_left(12)
    yy = x.move_point_right(-12)
    assert_equal(y, yy, "left / right 12")
    z = LongDecimal(n, 21)
    assert_equal(y, z, "left 12")
    w = y.move_point_right(12)
    assert_equal(x, w, "left 12 right 12")

    y = x.move_point_right(4)
    z = LongDecimal(n, 5)
    assert_equal(y, z, "right 4")
    w = y.move_point_left(4)
    ww = y.move_point_right(-4)
    assert_equal(w, ww, "left / right 4")
    assert_equal(x, w, "right 4 left 4")

    y = x.move_point_right(12)
    yy = x.move_point_left(-12)
    assert_equal(y, yy, "left / right 12")
    z = LongDecimal(n * 1000, 0)
    assert_equal(y, z, "left 12")
    w = y.move_point_left(12)
    v = x.round_to_scale(12)
    assert_equal(v, w, "right 12 left 12")

    y = x.move_point_left(12)
    yy = x.move_point_right(-12)
    assert_equal(y, yy, "left / right 12")
    z = LongDecimal(n, 21)
    assert_equal(y, z, "left 12")
    w = y.move_point_right(12)
    assert_equal(x, w, "right 12 left 12")
  end

  #
  # test moving of decimal point of LongDecimal
  #
  def test_move_point2
    x = LongDecimal(224, 2)

    y = x.move_point_left(0)
    assert_equal(x, y, "point not moved")
    y = x.move_point_right(0)
    assert_equal(x, y, "point not moved")

    z = LongDecimal(224, 3)
    y = x.move_point_left(1)
    assert_equal(z, y, "0.224")
    y = x.move_point_right(-1)
    assert_equal(z, y, "0.224")

    z = LongDecimal(224, 1)
    y = x.move_point_left(-1)
    assert_equal(z, y, "22.4")
    y = x.move_point_right(1)
    assert_equal(z, y, "22.4")

    z = LongDecimal(224, 5)
    y = x.move_point_left(3)
    assert_equal(z, y, "0.00224")
    y = x.move_point_right(-3)
    assert_equal(z, y, "0.00224")

    z = LongDecimal(2240, 0)
    y = x.move_point_left(-3)
    assert_equal(z, y, "2240")
    y = x.move_point_right(3)
    assert_equal(z, y, "2240")
  end

  #
  # test sqrt of LongDecimal
  #
  def test_sqrt
    x = LongDecimal.zero!(101)
    y = check_sqrt(x, 120, LongDecimal::ROUND_UNNECESSARY, 0, 0, "zero")
    assert(y.zero?, "sqrt(0)")

    x = LongDecimal.one!(101)
    y = check_sqrt(x, 120, LongDecimal::ROUND_UNNECESSARY, 0, 0, "one")
    assert(y.one?, "sqrt(1)")

    x = LongDecimal.two!(101)
    y0 = check_sqrt(x, 120, LongDecimal::ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, LongDecimal::ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 120, LongDecimal::ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 140, LongDecimal::ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 140, LongDecimal::ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 140, LongDecimal::ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 160, LongDecimal::ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 160, LongDecimal::ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 160, LongDecimal::ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 120, LongDecimal::ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, LongDecimal::ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 120, LongDecimal::ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    y0 = check_sqrt(x, 100, LongDecimal::ROUND_DOWN, 0, 1, "two")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 100, LongDecimal::ROUND_HALF_EVEN, -1, 1, "two")
    y2 = check_sqrt(x, 100, LongDecimal::ROUND_UP, -1, 0, "two")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    x = 3.to_ld
    y0 = check_sqrt(x, 120, LongDecimal::ROUND_DOWN, 0, 1, "three")
    assert(y0.square < x, "y0*y0")
    assert(y0.succ.square > x, "(y0.succ).square")
    y1 = check_sqrt(x, 120, LongDecimal::ROUND_HALF_EVEN, -1, 1, "three")
    y2 = check_sqrt(x, 120, LongDecimal::ROUND_UP, -1, 0, "three")
    assert(y2.pred.square < x, "y2.pred.squre")
    assert(y2.square > x, "y2*y2")
    assert(y0 <= y1, "y0 y1")
    assert(y1 <= y2, "y1 y2")

    x  = 4.to_ld(101)
    y0 = check_sqrt(x, 120, LongDecimal::ROUND_DOWN, 0, 0, "four")
    y1 = check_sqrt(x, 120, LongDecimal::ROUND_HALF_EVEN, 0, 0, "four")
    y2 = check_sqrt(x, 120, LongDecimal::ROUND_UP, 0, 0, "four")
    assert_equal(y0, y1, "y0 y1")
    assert_equal(y1, y2, "y1 y2")
  end

  #
  # test sqrt_with_remainder of LongDecimal
  #
  def test_sqrt_with_remainder
    x = LongDecimal.zero!(101)
    r = check_sqrt_with_remainder(x, 120, "zero")
    assert(r.zero?, "rsqrt(0)")

    x = LongDecimal.one!(101)
    r = check_sqrt_with_remainder(x, 120, "one")
    assert(r.zero?, "rsqrt(1)")

    x = LongDecimal.two!(101)
    check_sqrt_with_remainder(x, 120, "two")
    check_sqrt_with_remainder(x, 140, "two")
    check_sqrt_with_remainder(x, 160, "two")
    check_sqrt_with_remainder(x, 100, "two")

    x = 3.to_ld
    check_sqrt_with_remainder(x, 120, "three")
    check_sqrt_with_remainder(x, 140, "three")
    check_sqrt_with_remainder(x, 160, "three")
    check_sqrt_with_remainder(x, 100, "three")

    x  = 4.to_ld.round_to_scale(101)
    r = check_sqrt_with_remainder(x, 120, "four")
    assert(r.zero?, "rsqrt(4)")

    x = 5.to_ld
    check_sqrt_with_remainder(x, 120, "five")
  end

  #
  # test LongMath.sqrt with non-LongDecimal arguments
  #
  def test_non_ld_sqrt
    xi = 77
    yi = LongMath.sqrt(xi, 31, LongMath::ROUND_HALF_EVEN)
    zi = yi.square.round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert(zi.is_int?, "zi=#{zi.to_s}")
    assert_equal(xi, zi.to_i, "zi")

    xf = 77.0
    yf = LongMath.sqrt(xf, 31, LongMath::ROUND_HALF_EVEN)
    zf = yf.square.round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert(zf.is_int?, "zf")
    assert_equal(xf, zf.to_f, "zf")
    assert_equal(yi, yf, "i-f")

    xr = Rational(224, 227)
    yr = LongMath.sqrt(xr, 31, LongMath::ROUND_HALF_EVEN)
    zr = yr.square.round_to_scale(30, LongMath::ROUND_HALF_EVEN)
    assert((zr-xr).abs <= zr.unit, "zr-xr")
  end

  #
  # test absolute value of LongDecimal
  #
  def test_abs
    x = LongDecimal(-224, 2)
    y = x.abs
    assert_equal(-x, y, "abs of negative")
    x = LongDecimal(224, 2)
    y = x.abs
    assert_equal(x, y, "abs of positive")
    x = LongDecimal(0, 2)
    y = x.abs
    assert_equal(x, y, "abs of zero")
  end

  #
  # test ufo-operator (<=>) of LongDecimal
  #
  def test_ufo
    x = LongDecimal(224, 2)

    z = x <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")
    y = LongDecimal(2240, 3)
    z = y <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3, 1)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

  end

  #
  # test is_int? of LongDecimal
  #
  def test_is_int
    assert(LongDecimal(1, 0).is_int?, "1, 0")
    assert(LongDecimal(90, 1).is_int?, "90, 1")
    assert(LongDecimal(200, 2).is_int?, "200, 2")
    assert(LongDecimal(1000000, 6).is_int?, "1000000, 6")

    assert(! LongDecimal(1, 1).is_int?, "1, 1")
    assert(! LongDecimal(99, 2).is_int?, "99, 2")
    assert(! LongDecimal(200, 3).is_int?, "200, 3")
    assert(! LongDecimal(1000001, 6).is_int?, "1000001, 6")
    assert(! LongDecimal(1000000, 7).is_int?, "1000000, 7")
  end

  #
  # test zero? of LongDecimal
  #
  def test_zero
    assert(LongDecimal(0, 1000).zero?, "0, 1000")
    assert(LongDecimal(0, 0).zero?, "0, 0")
    assert(LongDecimal.zero!(100).zero?, "0, 100")
    assert(! LongDecimal(1, 1000).zero?, "1, 1000")
    assert(! LongDecimal(1, 0).zero?, "1, 0")
    assert(! LongDecimal.one!(100).zero?, "1, 0")
  end

  #
  # test one? of LongDecimal
  #
  def test_one
    assert(LongDecimal(10**1000, 1000).one?, "1, 1000")
    assert(LongDecimal(1, 0).one?, "1, 0")
    assert(LongDecimal.one!(100).one?, "1, 100")
    assert(! LongDecimal(0, 1000).one?, "0, 1000")
    assert(! LongDecimal(2, 1000).one?, "2, 1000")
    assert(! LongDecimal(0, 0).one?, "0, 0")
    assert(! LongDecimal.zero!(100).one?, "0, 0")
    assert(! LongDecimal.two!(100).one?, "2, 0")
  end

  #
  # test sign-method of LongDecimal
  #
  def test_sgn
    x = LongDecimal(0, 5)
    s = x.sgn
    assert_equal(0, s, "must be 0")
    x = LongDecimal(4, 5)
    s = x.sgn
    assert_equal(1, s, "must be 1")
    x = LongDecimal(-3, 5)
    s = x.sgn
    assert_equal(-1, s, "must be -1")
  end

  #
  # test equality-comparison (==) of LongDecimal
  #
  def test_equal
    x = LongDecimal(224, 2)
    y = LongDecimal(2240, 3)
    assert((x <=> y) == 0, "diff is zero")
    assert(x != y, "but not equal")
    assert(! (x == y), "but not equal")
    assert_equal(x, x, "x equals x")
    assert_equal(y, y, "y equals y")
  end

  #
  # test value-equality-comparison (===) of LongDecimal
  #
  def test_val_equal
    x = LongDecimal(224, 2)
    y = LongDecimal(2240, 3)
    assert((x === y), "value equal")
    assert(x != y, "but not equal")
    assert(x === x, "x equals x")
    assert(y === y, "y equals y")
    x = 1.to_ld(100)
    y = 1
    assert((x === y), "value equal")
    assert(x != y, "but not equal")
    assert(x === x, "x equals x")
    assert(y === y, "y equals y")
    x = LongDecimal(123456, 3)
    y = Rational(123456, 1000)
    assert((x === y), "value equal")
    assert(x != y, "but not equal")
    assert(x === x, "x equals x")
    assert(y === y, "y equals y")
  end

  #
  # test .unit() of LongDecimal
  #
  def test_unit
    10.times do |i|
      x = LongDecimal.zero!(i)
      u = x.unit
      v = LongDecimal(1, i)
      assert_equal(u, v, "unit i=#{i}")
      x = i.to_ld(i*i)
      u = x.unit
      v = LongDecimal(1, i*i)
      assert_equal(u, v, "unit i=#{i}")
    end
  end

  #
  # test denominator of LongDecimal
  #
  def test_denominator
    x = LongDecimal("-2.20")
    assert_equal(100, x.denominator, "-2.20")
    x = LongDecimal("2.20")
    assert_equal(100, x.denominator, "2.20")
    x = LongDecimal("2.2400")
    assert_equal(10000, x.denominator, "2.2400")
    x = LongDecimal(-1, 2)
    assert_equal(100, x.denominator, "-1 2")
    x = LongDecimal(-221, 1)
    assert_equal(10, x.denominator, "-221 1")
    x = LongDecimal(-224, 0)
    assert_equal(1, x.denominator, "-224 0")
    x = LongDecimal(-3, 5)
    assert_equal(100000, x.denominator, "-3 5")
    x = LongDecimal(0, 20)
    assert_equal(10**20, x.denominator, "0 20")
    x = LongDecimal(30000000, 8)
    assert_equal(10**8, x.denominator, "30000000 8")
    x = LongDecimal(3330000000, 8)
    assert_equal(10**8, x.denominator, "3330000000 8")

  end

  #
  # test construction of LongDecimalQuot from LongDecimal
  #
  def test_ldq_ld_init
    x = LongDecimal(224, 2) # 2.24  dx=1 sx=2
    y = LongDecimal(225, 3) # 0.225 dy=0 sy=3
    z = LongDecimalQuot(x, y)
    # 2dy+sy+sx-max(dx+sx,dy+sy)-3 = -1 -> use 0
    zz = LongDecimalQuot(Rational(2240, 225), 0)
    assert_equal(zz, z, "2240/225")

    z = LongDecimalQuot(y, x)
    # 2dx+sx+sy-max(dx+sx,dy+sy)-3 = 1
    zz = LongDecimalQuot(Rational(225, 2240), 1)
    assert_equal(zz, z, "225/2240")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_UP
  #
  def test_ldq_round_to_scale_up

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    # 1.0
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_UP)
    assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_DOWN
  #
  def test_ldq_round_to_scale_down

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    # 0.9
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("-0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_CEILING
  #
  def test_ldq_round_to_scale_ceiling

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("-0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_CEILING)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_CEILING)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_FLOOR
  #
  def test_ldq_round_to_scale_floor

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("0.9", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_FLOOR)
    assert_equal("-0.1", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_FLOOR)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_UP
  #
  def test_ldq_round_to_scale_half_up

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_UP)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_UP)
    assert_equal("56.3", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_DOWN
  #
  def test_ldq_round_to_scale_half_down

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_DOWN)
    assert_equal("56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_HALF_EVEN
  #
  def test_ldq_round_to_scale_half_even

    # 0.99555555555555...
    l = LongDecimalQuot(Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(-Rational(224, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("-1.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-224/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 0.00444444444444444
    l = LongDecimalQuot(Rational(1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(-1, 225), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("0.0", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("-1/225[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1000)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    l = LongDecimalQuot(Rational(1, 1), 1)
    r = l.round_to_scale(4, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("1.0000", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.25
    l = LongDecimalQuot(Rational(225, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("56.2", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("225/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
    # 56.75
    l = LongDecimalQuot(Rational(227, 4), 0)
    r = l.round_to_scale(1, LongDecimal::ROUND_HALF_EVEN)
    assert_equal("56.8", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    assert_kind_of(LongDecimal, r, "must be LongDecimal")
    assert_equal("227/4[0]", l.to_s, "l=#{l.inspect} r=#{r.inspect}")
  end

  #
  # test rounding of LongDecimalQuot with ROUND_UNNECESSARY
  #
  def test_ldq_round_to_scale_unnecessary
    l = LongDecimalQuot(Rational(225, 4), 5)
    r = l.round_to_scale(2, LongDecimal::ROUND_UNNECESSARY)
    assert_equal("56.25", r.to_s, "l=#{l.inspect} r=#{r.inspect}")
    begin
      r = l.round_to_scale(1, LongDecimal::ROUND_UNNECESSARY)
      assert_fail("should not have succeeded l=#{l.inspect} r=#{r.inspect}")
    rescue ArgumentError
      # ignored
    end
  end

  #
  # test conversion of LongDecimalQuot to String
  #
  def test_ldq_to_s
    l = LongDecimalQuot(Rational(224, 225), 226)
    assert_equal("224/225[226]", l.to_s, "l=#{l.inspect}")
    l = LongDecimalQuot(Rational(-224, 225), 226)
    assert_equal("-224/225[226]", l.to_s, "l=#{l.inspect}")
  end

  #
  # test conversion of LongDecimalQuot to Rational
  #
  def test_ldq_to_r
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    r = l.to_r
    assert_kind_of(Rational, r, "must be rational")
    assert_equal(rr, r, "must be equal")
    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    r = l.to_r
    assert_kind_of(Rational, r, "must be rational")
    assert_equal(rr, r, "must be equal")
    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    r = l.to_r
    assert_kind_of(Rational, r, "must be rational")
    assert_equal(rr, r, "must be equal")
  end

  #
  # test conversion of LongDecimalQuot to Float
  #
  def test_ldq_to_f
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    f = l.to_f
    ff = rr.to_f
    assert_kind_of(Float, f, "must be float")
    assert_equal(ff, f, "must be equal")
    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    f = l.to_f
    ff = rr.to_f
    assert_kind_of(Float, f, "must be float")
    assert_equal(ff, f, "must be equal")
    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    f = l.to_f
    ff = rr.to_f
    assert_kind_of(Float, f, "must be float")
    assert_equal(ff, f, "must be equal")
  end

  #
  # test conversion to BigDecimal
  #
  def test_ldq_to_bd
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    b = l.to_bd
    bb = BigDecimal(rr.to_f.to_s)
    assert_kind_of(BigDecimal, b, "must be bd")
    assert((b - bb).abs < 0.000001, "l=#{l.inspect}")

    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    b = l.to_bd
    bb = BigDecimal(rr.to_f.to_s)
    assert_kind_of(BigDecimal, b, "must be bd")
    assert((b - bb).abs < 0.000001, "l=#{l.inspect}")

    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    b = l.to_bd
    bb = BigDecimal(rr.to_f.to_s)
    assert_kind_of(BigDecimal, b, "must be bd")
    assert((b - bb).abs < 0.000001, "l=#{l.inspect}")
  end

  #
  # test to_i of LongDecimalQuot
  #
  def test_ldq_to_i
    rr = Rational(224, 225)
    l = LongDecimalQuot(rr, 22)
    i = l.to_i
    ii = rr.to_i
    assert_kind_of(Integer, i, "must be integer")
    assert_equal(ii, i, "must be equal")
    rr = Rational(-224, 225)
    l = LongDecimalQuot(rr, 22)
    i = l.to_i
    ii = rr.to_i
    assert_kind_of(Integer, i, "must be integer")
    assert_equal(ii, i, "must be equal")
    rr = Rational(0, 225)
    l = LongDecimalQuot(rr, 22)
    i = l.to_i
    ii = rr.to_i
    assert_kind_of(Integer, i, "must be integer")
    assert_equal(ii, i, "must be equal")
  end

  #
  # test to_ld of LongDecimalQuot
  #
  def test_ldq_to_ld
    x = LongDecimalQuot(1, 100)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(100, y.scale, "scale is 100")
    assert(y.one?, "must be one")
    x = LongDecimalQuot(Rational(13, 9), 10)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(10, y.scale, "scale is 10")
    assert_equal(LongDecimal("1.4444444444"), y, "1.44...")
    x = LongDecimalQuot(Rational(14, 9), 10)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(10, y.scale, "scale is 10")
    assert_equal(LongDecimal("1.5555555556"), y, "1.55...")
    x = LongDecimalQuot(Rational(7, 20), 1)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(1, y.scale, "scale is 1")
    assert_equal(LongDecimal("0.4"), y, "0.4")
    x = LongDecimalQuot(Rational(7, 2), 1)
    y = x.to_ld
    assert_kind_of(LongDecimal, y, "must be ld")
    assert_equal(1, y.scale, "scale is 1")
    assert_equal(LongDecimal("3.5"), y, "3.5")
  end

  #
  # test negation operator (unary -) of LongDecimalQuot
  #
  def test_ldq_negation
    x = LongDecimalQuot(Rational(0, 2), 3)
    assert_equal(-x, x, "x and -x are equal for negative x=#{x.inspect}")
    x = LongDecimalQuot(Rational(224, 225), 226)
    yy = LongDecimalQuot(Rational(-224, 225), 226)
    y = -x
    assert_equal(-1, y.sgn, "sign of y must be -1 y=#{y.inspect}")
    assert_equal(226, y.scale, "scale of y must be 2 y=#{y.inspect}")
    assert_equal(yy, y, "yy and y must be equal")
  end

  #
  # test addition operator (binary +) of LongDecimalQuot
  #
  def test_ldq_add
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x + y
    zz = LongDecimalQuot(Rational(583, 450), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x + y
    zz = LongDecimalQuot(Rational(1349, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x + y
    zz = LongDecimalQuot(Rational(53969, 9000), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x + y
    zz = LongDecimalQuot(Rational(599, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x + y
    zz = LongDecimalQuot(Rational(599, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x + y
    zz = Complex(5+224.0/225.0, 3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
    z = y + x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test subtraction operator (binary -) of LongDecimalQuot
  #
  def test_ldq_sub
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x - y
    zz = LongDecimalQuot(Rational(313, 450), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(-313, 450), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x - y
    zz = LongDecimalQuot(Rational(-901, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(901, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x - y
    zz = LongDecimalQuot(Rational(-36049, 9000), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(36049, 9000), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x - y
    zz = LongDecimalQuot(Rational(-151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x - y
    zz = LongDecimalQuot(Rational(-151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y - x
    zz = LongDecimalQuot(Rational(151, 225), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x - y
    zz = Complex(224.0/225.0 -5, -3)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
    zz = -zz
    z = y - x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
  end

  #
  # test multiplication operator (*) of LongDecimalQuot
  #
  def test_ldq_mul
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x * y
    zz = LongDecimalQuot(Rational(224*3, 2250), 227)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 225), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x * y
    zz = LongDecimalQuot(Rational(46676, 9375), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 225*3), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x * y
    zz = LongDecimalQuot(Rational(224*5, 225*3), 226+3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y * x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x * y
    zz = Complex(224.0/45.0, 224.0/75.0)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
    z = y * x
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
  end

  #
  # test division operator (/) of LongDecimalQuot
  #
  def test_ldq_div
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    z = x / y
    zz = LongDecimalQuot(Rational(2240, 225*3), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    zz = LongDecimalQuot(Rational(225*3, 2240), 1)
    z = y / x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x / y
    zz = LongDecimalQuot(Rational(224, 225*5), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(225*5, 224), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x / y
    zz = LongDecimalQuot(Rational(8960, 45009), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(45009, 8960), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x / y
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(225*5, 224*3), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x / y
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y / x
    zz = LongDecimalQuot(Rational(225*5, 224*3), 3)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect}")
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Complex(5, 3)
    z = x / y
    zz = Complex(112.0/765.0, -112.0/1275.0)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
    z = y / x
    zz = Complex(1125.0/224.0, 675.0/224.0)
    assert_kind_of(Complex, z, "z=#{z.inspect}")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect} zz=#{zz.inspect}")
  end

  #
  # test power operator (**) of LongDecimalQuot
  #
  def test_ldq_pow

    x = LongDecimalQuot(Rational(224, 225), 226)

    y = 0.5
    z = x ** y
    zz = Math.sqrt(224.0/225.0)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = 0
    z = x ** y
    zz = LongDecimalQuot(Rational(1, 1), 0)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be 1")

    y = 1
    z = x ** y
    zz = x
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = 2
    z = x ** y
    zz = LongDecimalQuot(Rational(224**2, 225**2), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = LongDecimal(2, 0)
    z = x ** y
    zz = LongDecimalQuot(Rational(224**2, 225**2), 226*2)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimal")
    assert_equal(zz, z, "must be self")

    y = -1
    z = x ** y
    zz = LongDecimalQuot(Rational(225, 224), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = -2
    z = x ** y
    zz = LongDecimalQuot(Rational(225**2, 224**2), 226)
    assert_kind_of(LongDecimalQuot, z, "z=#{z.inspect} must be LongDecimalQuot")
    assert_equal(zz, z, "must be inverse")

    y = LongDecimal(5, 1)
    z = x ** y
    zz = Math.sqrt(2.24/2.25)
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")

    y = LongDecimal(5, 1)
    z = 9 ** y
    zz = 3.0
    assert_kind_of(Float, z, "z=#{z.inspect} must be Float")
    assert((zz-z).abs < 1e-9, "z=#{z.inspect}")
  end

  #
  # test divmod of LongDecimalQuot for division with remainder
  #
  def test_ldq_divmod
    x = LongDecimalQuot(Rational(224, 225), 226)

    y = LongDecimal(3, 1)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimalQuot")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*10, 225*3), 226)
    assert_equal(zz, q + r / y, "z=#{(q+r/y).inspect} y=#{y.inspect} q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*3, 224*10), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224, 225*5), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*5, 224), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = 5.001
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(8960, 45009), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(45009, 8960), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Rational(5, 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*5, 224*3), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    q, r = x.divmod y
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < y.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(224*3, 225*5), 226)
    assert_equal(zz, q + r / y, "z=q=#{q.inspect} r=#{r.inspect}")
    q, r = y.divmod x
    assert_kind_of(Integer, q, "q must be integer")
    assert_kind_of(LongDecimalQuot, r, "r must be LongDecimal")
    assert(r.abs < x.abs, "remainder must be less then divisor")
    zz = LongDecimalQuot(Rational(225*5, 224*3), 226*2)
    assert_equal(zz, q + r / x, "z=q=#{q.inspect} r=#{r.inspect}")

    y = Complex(5, 3)
    begin
      q, r = x.divmod y
      assert_fail "should have created TypeError"
    rescue TypeError
      # ignored, expected
    end
  end

  #
  # test dec, dec!, inc and inc! of LongDecimalQuot
  #
  def test_ldq_inc_dec

    x0 = LongDecimalQuot(Rational(224, 225), 1)
    x  = LongDecimalQuot(Rational(224, 225), 1)
    y  = x.inc
    z  = LongDecimalQuot(Rational(449, 225), 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.inc!
    assert_equal(z, x, "z, x")

    x0 = LongDecimalQuot(Rational(224, 225), 1)
    x  = LongDecimalQuot(Rational(224, 225), 1)
    y  = x.dec
    z  = LongDecimalQuot(Rational(-1, 225), 1)
    assert_equal(x, x0, "x")
    assert_equal(z, y, "y, z")
    x.dec!
    assert_equal(z, x, "z, x")
  end

  #
  # test absolute value of LongDecimalQuot
  #
  def test_ldq_abs
    x = LongDecimalQuot(Rational(-224, 225), 226)
    y = x.abs
    assert_equal(-x, y, "abs of negative")
    x = LongDecimalQuot(Rational(224, 225), 226)
    y = x.abs
    assert_equal(x, y, "abs of positive")
    x = LongDecimalQuot(Rational(0, 2), 3)
    y = x.abs
    assert_equal(x, y, "abs of zero")
  end

  #
  # test ufo operator (<=>) of LongDecimalQuot
  #
  def test_ldq_ufo
    x = LongDecimalQuot(Rational(224, 225), 226)

    z = x <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")
    y = LongDecimalQuot(Rational(224, 225), 0)
    z = y <=> x
    zz = 0
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimal(3, 1)
    z = x <=> y
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = 5.001
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = Rational(5, 3)
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

    y = LongDecimalQuot(Rational(5, 3), 3)
    z = x <=> y
    zz = -1
    assert_equal(zz, z, "z=#{z.inspect}")
    z = y <=> x
    zz = 1
    assert_equal(zz, z, "z=#{z.inspect}")

  end

  #
  # test is_int? of LongDecimalQuot
  #
  def test_ldq_is_int
    assert(! LongDecimalQuot(Rational(1, 2), 0).is_int?, "1, 2")
    assert(! LongDecimalQuot(Rational(90, 91), 1).is_int?, "90, 91")
    assert(! LongDecimalQuot(Rational(200, 3), 2).is_int?, "200, 3")
    assert(! LongDecimalQuot(Rational(3333333, 1000000), 6).is_int?, "3333333, 1000000")

    assert(LongDecimalQuot(1, 1).is_int?, "1, 1")
    assert(LongDecimalQuot(99, 2).is_int?, "99, 2")
    assert(LongDecimalQuot(200, 3).is_int?, "200, 3")
    assert(LongDecimalQuot(1000001, 6).is_int?, "1000001, 6")
    assert(LongDecimalQuot(1000000, 7).is_int?, "1000000, 7")
  end

  #
  # test zero? of LongDecimalQuot
  #
  def test_ldq_zero
    assert(LongDecimalQuot(0, 1000).zero?, "0, 1000")
    assert(LongDecimalQuot(0, 0).zero?, "0, 0")
    assert(! LongDecimalQuot(1, 1000).zero?, "1, 1000")
    assert(! LongDecimalQuot(1, 0).zero?, "1, 0")
  end

  #
  # test one? of LongDecimalQuot
  #
  def test_ldq_one
    assert(LongDecimalQuot(1, 1000).one?, "1, 1000")
    assert(LongDecimalQuot(1, 0).one?, "1, 0")
    assert(! LongDecimalQuot(0, 1000).one?, "0, 1000")
    assert(! LongDecimalQuot(2, 1000).one?, "2, 1000")
    assert(! LongDecimalQuot(0, 0).one?, "0, 0")
  end

  #
  # test sign method of LongDecimalQuot
  #
  def test_ldq_sgn
    x = LongDecimalQuot(Rational(0, 5), 1000)
    s = x.sgn
    assert_equal(0, s, "must be 0")
    x = LongDecimalQuot(Rational(4, 5), 6)
    s = x.sgn
    assert_equal(1, s, "must be 1")
    x = LongDecimalQuot(Rational(-3, 5), 7)
    s = x.sgn
    assert_equal(-1, s, "must be -1")
  end

  #
  # test equality operator (==) of LongDecimalQuot
  #
  def test_ldq_equal
    x = LongDecimalQuot(Rational(224, 225), 226)
    y = LongDecimalQuot(Rational(224, 225), 227)
    assert((x <=> y) == 0, "diff is zero")
    assert(x != y, "but not equal")
    assert(! (x == y), "but not equal")
    assert_equal(x, x, "x equals x")
    assert_equal(y, y, "y equals y")
  end

end

RUNIT::CUI::TestRunner.run(TestLongDecimal_class.suite)

# end of file testlongdecimal.rb
