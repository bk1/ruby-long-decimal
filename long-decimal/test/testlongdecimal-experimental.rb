#!/usr/bin/env ruby
#
# testlongdecimal.rb -- runit test for long-decimal.rb
#
# (C) Karl Brodowsky (IT Sky Consulting GmbH) 2006-2015
#
# TAG:       $TAG pre-v1.00.03$
# CVS-ID:    $Header: /var/cvs/long-decimal/long-decimal/test/testlongdecimal-extra.rb,v 1.19 2009/05/07 20:21:43 bk1 Exp $
# CVS-Label: $Name:  $
# Author:    $Author: bk1 $ (Karl Brodowsky)
#

$test_type = nil
if ((RUBY_VERSION.match /^1\./) || (RUBY_VERSION.match /^2\.0/)) then
  require 'test/unit'
  $test_type = :v20
else
  require 'minitest/autorun'
  require 'test/unit/assertions'
  include Test::Unit::Assertions
  $test_type = :v21
end

load "lib/long-decimal.rb"
load "lib/long-decimal-extra.rb"
load "test/testlongdeclib.rb"

if ($test_type == :v20)
  class UnitTest < Test::Unit::TestCase
  end
else
  class UnitTest < MiniTest::Test
  end
end

#
# test class for LongDecimal and LongDecimalQuot
#
class TestLongDecimalExperimental_class < UnitTest
  include TestLongDecHelper
  include LongDecimalRoundingMode

  MAX_FLOAT_I = (Float::MAX).to_i

  def test_to_f2
    x = 1
    t1sum = 0
    t2sum = 0
    t3sum = 0
    t4sum = 0
    t5sum = 0
    t6sum = 0
    bad_1 = []
    bad_2 = []
    bad_3 = []
    bad_4 = []
    bad_5 = []
    bad_6 = []

    660.times do |i|
      print ":"
      $stdout.flush
      s = i >> 1
      l = LongDecimal(x, s)
      o = LongDecimal.one!(s)
      q = l / o
      f0 = if (x < MAX_FLOAT_I)
             x.to_f * "1e-#{s}".to_f
           else
             (x / 10**s).to_f
           end
      t0 = Time.new
      f1 = l.to_g
      t1 = Time.new
      f2 = l.to_f  # t2 # t9
      t2 = Time.new
      f3 = l.to_r.to_f
      t3 = Time.new
      f4 = q.to_f
      t4 = Time.new
      f5 = l.to_s.to_f
      t5 = Time.new
      f6 = q.to_r.to_f
      t6 = Time.new
      t6 -= t5
      t5 -= t4
      t4 -= t3
      t3 -= t2
      t2 -= t1
      t1 -= t0
      t1sum += t1
      t2sum += t2
      t3sum += t3
      t4sum += t4
      t5sum += t5
      t6sum += t6

      li = Math.log(i+1)
      lli = Math.log(li+1)
      sum = (f1+f2+f3+f4+f5+f6)
      delta = sum * lli * lli / 2**55
      delta2 = sum * li * lli ** 4 / 2**55
      assert_equal_float(f0, f1, delta2, "f1 i=#{i} x=#{x} d=#{f1-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f2, delta, "f2 i=#{i} x=#{x} d=#{f2-f0} li=#{li} lli=#{lli} delta=#{delta}")
      assert_equal_float(f0, f3, delta2, "f3 i=#{i} x=#{x} d=#{f3-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f4, delta2, "f4 i=#{i} x=#{x} d=#{f4-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f5, delta2, "f5 i=#{i} x=#{x} d=#{f5-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f6, delta2, "f6 i=#{i} x=#{x} d=#{f6-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      bad_1 << i if (f0 - f1).abs != 0
      bad_2 << i if (f0 - f2).abs != 0
      bad_3 << i if (f0 - f3).abs != 0
      bad_4 << i if (f0 - f4).abs != 0
      bad_5 << i if (f0 - f5).abs != 0
      bad_6 << i if (f0 - f6).abs != 0
      fs = sprintf("f1=%20.18e f2=%20.18e f3=%20.18e f4=%20.18e f5=%20.18e f6=%20.18e", f1, f2, f3, f4, f5, f6)
      assert_equal_float(f1, f2, delta2, "f1/f2 i=#{i} x=#{x} d=#{f1-f2} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f1, f3, delta, "f1/f3 i=#{i} x=#{x} d=#{f1-f3} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f2, f3, delta2, "f2/f3 i=#{i} x=#{x} d=#{f2-f3} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f1, f5, delta, "f1/f2 i=#{i} x=#{x} d=#{f1-f2} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f2, f5, delta2, "f1/f3 i=#{i} x=#{x} d=#{f1-f3} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f3, f5, delta, "f2/f3 i=#{i} x=#{x} d=#{f2-f3} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f4, f6, delta, "f4/f6 i=#{i} x=#{x} d=#{f4-f6} lli=#{lli} delta=#{delta} #{fs}")
      x *= 9
    end
    puts
    puts "t1sum=#{t1sum} t2sum=#{t2sum} t3sum=#{t3sum} t4sum=#{t4sum} t5sum=#{t5sum} t6sum=#{t6sum}"
    # puts "bad_1=#{bad_1.inspect} bad_2=#{bad_2.inspect} bad_3=#{bad_3.inspect} bad_4=#{bad_4.inspect} bad_5=#{bad_5.inspect} bad_6=#{bad_6.inspect}"
    puts "bad_count_1=#{bad_1.size} bad_count_2=#{bad_2.size} bad_count_3=#{bad_3.size} bad_count_4=#{bad_4.size} bad_count_5=#{bad_5.size} bad_count_6=#{bad_6.size}"
  end

  def test_to_f3
    x = 1
    t1sum = 0
    t2sum = 0
    t3sum = 0
    t4sum = 0
    t5sum = 0
    t6sum = 0
    bad_1 = []
    bad_2 = []
    bad_3 = []
    bad_4 = []
    bad_5 = []
    bad_6 = []

    c = 10**500

    660.times do |i|
      print ":"
      $stdout.flush
      s = i >> 1
      l = LongDecimal(x * c, s + 500)
      o = LongDecimal.one!(s)
      q = l / o
      f0 = if (x < MAX_FLOAT_I)
             x.to_f * "1e-#{s}".to_f
           else
             (x / 10**s).to_f
           end
      t0 = Time.new
      f1 = l.to_f  # t10 # t11
      t1 = Time.new
      f2 = l.to_g
      t2 = Time.new
      f3 = l.to_r.to_f
      t3 = Time.new
      f4 = q.to_f
      t4 = Time.new
      f5 = l.to_s.to_f
      t5 = Time.new
      f6 = q.to_r.to_f
      t6 = Time.new
      t6 -= t5
      t5 -= t4
      t4 -= t3
      t3 -= t2
      t2 -= t1
      t1 -= t0
      t1sum += t1
      t2sum += t2
      t3sum += t3
      t4sum += t4
      t5sum += t5
      t6sum += t6

      li = Math.log(i+1)
      lli = Math.log(li+1)
      sum = (f1+f2+f3+f4+f5+f6)
      delta = sum * lli ** 4 / 2**45
      delta2 = sum * li ** 2 * lli ** 4 / 2**45
      assert_equal_float(f0, f1, delta2, "f1 i=#{i} x=#{x} d=#{f1-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f2, delta2, "f2 i=#{i} x=#{x} d=#{f2-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f3, delta2, "f3 i=#{i} x=#{x} d=#{f3-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f4, delta2, "f4 i=#{i} x=#{x} d=#{f4-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f5, delta2, "f5 i=#{i} x=#{x} d=#{f5-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      assert_equal_float(f0, f6, delta2, "f6 i=#{i} x=#{x} d=#{f6-f0} li=#{li} lli=#{lli} delta2=#{delta2}")
      bad_1 << i if (f0 - f1).abs != 0
      bad_2 << i if (f0 - f2).abs != 0
      bad_3 << i if (f0 - f3).abs != 0
      bad_4 << i if (f0 - f4).abs != 0
      bad_5 << i if (f0 - f5).abs != 0
      bad_6 << i if (f0 - f6).abs != 0
      fs = sprintf("f1=%20.18e f2=%20.18e f3=%20.18e f4=%20.18e f5=%20.18e f6=%20.18e", f1, f2, f3, f4, f5, f6)
      assert_equal_float(f1, f2, delta2, "f1/f2 i=#{i} x=#{x} d=#{f1-f2} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f1, f3, delta, "f1/f3 i=#{i} x=#{x} d=#{f1-f3} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f2, f3, delta2, "f2/f3 i=#{i} x=#{x} d=#{f2-f3} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f1, f5, delta, "f1/f2 i=#{i} x=#{x} d=#{f1-f2} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f2, f5, delta2, "f1/f3 i=#{i} x=#{x} d=#{f1-f3} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f3, f5, delta, "f2/f3 i=#{i} x=#{x} d=#{f2-f3} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f4, f6, delta, "f4/f6 i=#{i} x=#{x} d=#{f4-f6} lli=#{lli} delta=#{delta} #{fs}")
      x *= 9
    end
    puts
    puts "t1sum=#{t1sum} t2sum=#{t2sum} t3sum=#{t3sum} t4sum=#{t4sum} t5sum=#{t5sum} t6sum=#{t6sum}"
    # puts "bad_1=#{bad_1.inspect} bad_2=#{bad_2.inspect} bad_3=#{bad_3.inspect} bad_4=#{bad_4.inspect} bad_5=#{bad_5.inspect} bad_6=#{bad_6.inspect}"
    puts "bad_count_1=#{bad_1.size} bad_count_2=#{bad_2.size} bad_count_3=#{bad_3.size} bad_count_4=#{bad_4.size} bad_count_5=#{bad_5.size} bad_count_6=#{bad_6.size}"
    l = LongDecimal.zero!(0)
  end


  def test_to_f4
    x = 1
    t1sum = 0
    t2sum = 0
    t3sum = 0
    t4sum = 0
    t5sum = 0
    t6sum = 0
    bad_1 = []
    bad_2 = []
    bad_3 = []
    bad_4 = []
    bad_5 = []
    bad_6 = []

    ff = "1e-300".to_f

    660.times do |i|
      print ":"
      $stdout.flush
      s = i >> 1
      l = LongDecimal(x, s + 300)
      o = LongDecimal.one!(s)
      q = l / o
      f0 = if (x < MAX_FLOAT_I)
             x.to_f * "1e-#{s}".to_f() * ff
           else
             (x / 10 ** s).to_f() * ff
           end
      t0 = Time.new
      f1 = l.to_f       # t4 # t8
      t1 = Time.new
      f2 = l.to_g
      t2 = Time.new
      f3 = l.to_r.to_f
      t3 = Time.new
      f4 = q.to_f
      t4 = Time.new
      f5 = l.to_s.to_f
      t5 = Time.new
      f6 = q.to_r.to_f
      t6 = Time.new
      t6 -= t5
      t5 -= t4
      t4 -= t3
      t3 -= t2
      t2 -= t1
      t1 -= t0
      t1sum += t1
      t2sum += t2
      t3sum += t3
      t4sum += t4
      t5sum += t5
      t6sum += t6

      li = Math.log(i+1) + 1
      lli = Math.log(li+1) + 1
      sum = (f1+f2+f3+f4+f5+f6)
      delta = sum * lli ** 4 / 2**45
      delta2 = sum * li ** 2 * lli ** 4 / 2**45
      assert_equal_float(f0, f1, delta2, "f1=#{f1} i=#{i} x=#{x} l=#{l.to_s} d=#{f1-f0} delta2=#{delta2} li=#{li} lli=#{lli}")
      assert_equal_float(f0, f2, delta2, "f2=#{f2} i=#{i} x=#{x} l=#{l.to_s} d=#{f2-f0} delta2=#{delta2} li=#{li} lli=#{lli}")
      assert_equal_float(f0, f3, delta2, "f3=#{f3} i=#{i} x=#{x} l=#{l.to_s} d=#{f3-f0} delta2=#{delta2} li=#{li} lli=#{lli}")
      assert_equal_float(f0, f4, delta2, "f4=#{f4} i=#{i} x=#{x} l=#{l.to_s} d=#{f4-f0} delta2=#{delta2} li=#{li} lli=#{lli}")
      assert_equal_float(f0, f5, delta2, "f5=#{f5} i=#{i} x=#{x} l=#{l.to_s} d=#{f5-f0} delta2=#{delta2} li=#{li} lli=#{lli}")
      assert_equal_float(f0, f6, delta2, "f6=#{f6} i=#{i} x=#{x} l=#{l.to_s} d=#{f6-f0} delta2=#{delta2} li=#{li} lli=#{lli}")
      bad_1 << i if (f0 - f1).abs != 0
      bad_2 << i if (f0 - f2).abs != 0
      bad_3 << i if (f0 - f3).abs != 0
      bad_4 << i if (f0 - f4).abs != 0
      bad_5 << i if (f0 - f5).abs != 0
      bad_6 << i if (f0 - f6).abs != 0
      fs = sprintf("f1=%20.18e f2=%20.18e f3=%20.18e f4=%20.18e f5=%20.18e f6=%20.18e", f1, f2, f3, f4, f5, f6)
      assert_equal_float(f1, f2, delta2, "f1/f2 i=#{i} x=#{x} d=#{f1-f2} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f1, f3, delta, "f1/f3 i=#{i} x=#{x} d=#{f1-f3} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f2, f3, delta2, "f2/f3 i=#{i} x=#{x} d=#{f2-f3} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f1, f5, delta, "f1/f2 i=#{i} x=#{x} d=#{f1-f2} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f2, f5, delta2, "f1/f3 i=#{i} x=#{x} d=#{f1-f3} lli=#{lli} delta2=#{delta2} #{fs}")
      assert_equal_float(f3, f5, delta, "f2/f3 i=#{i} x=#{x} d=#{f2-f3} lli=#{lli} delta=#{delta} #{fs}")
      assert_equal_float(f4, f6, delta, "f4/f6 i=#{i} x=#{x} d=#{f4-f6} lli=#{lli} delta=#{delta} #{fs}")
      x *= 9
    end
    puts
    puts "t1sum=#{t1sum} t2sum=#{t2sum} t3sum=#{t3sum} t4sum=#{t4sum} t5sum=#{t5sum} t6sum=#{t6sum}"
    # puts "bad_1=#{bad_1.inspect} bad_2=#{bad_2.inspect} bad_3=#{bad_3.inspect} bad_4=#{bad_4.inspect} bad_5=#{bad_5.inspect} bad_6=#{bad_6.inspect}"
    puts "bad_count_1=#{bad_1.size} bad_count_2=#{bad_2.size} bad_count_3=#{bad_3.size} bad_count_4=#{bad_4.size} bad_count_5=#{bad_5.size} bad_count_6=#{bad_6.size}"
    l = LongDecimal.zero!(0)
  end
end
