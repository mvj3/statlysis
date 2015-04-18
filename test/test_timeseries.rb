# encoding: UTF-8

# TODO 改进时间，在 travis 上时区不同导致。
require 'helper'

class TestTimeSeries < Test::Unit::TestCase
  include Statlysis

  def setup
    super
    @dt = Time.zone.parse "20121221 +0800"
    @dt1 = Time.zone.parse "20111221 +0800"
    @dt2 = Time.zone.parse "20121221 +0800"
    @old_datetime = Time.zone.parse("20130105")
  end

  def test_parse_datetime
    assert_equal [@dt.day], TimeSeries.parse(@dt).map(&:day), "抽取单个时间没通过"
  end

  def test_parse_special_datetime
    assert_equal 1, TimeSeries.parse(Time.zone.parse('2012122110')).length, "抽取单个时间没通过"
  end

  def test_parse_range_in_hour
    # (@dt2 - @dt1).to_i  == 366
    assert_equal 24, TimeSeries.parse(@dt1..(@dt1+1.day-1.second), :unit => :hour).length, "抽取小时的时间范围没通过"
  end

  def test_parse_range_in_day
    # (@dt2 - @dt1).to_i  == 366
    assert TimeSeries.parse(@dt1..(@dt2-1.second)).length >= 365, "抽取天的时间范围没通过"
  end

  def test_parse_range_in_week
    # (@dt2 - @dt1).to_i / 7.0 == 52.285714285714285
    assert_equal 53, TimeSeries.parse(@dt1..(@dt2-1.second), :unit => :week).length, "抽取周的时间范围没通过"
  end

  def test_parse_range_in_201212_week
    w1 = Time.zone.parse "20121201 +0800"
    w2 = Time.zone.parse "20121231 +0800"
    assert TimeSeries.parse(w1..w2, :unit => :week).length >= 5, "2012十二月应该有六周"
  end

  def test_clock_set_time
    clock = Statlysis::Clock.new "parse_EoeLog", Time.now
    clock.update @old_datetime
    update_old_time = (@old_datetime != clock.current)
    assert(update_old_time, "Can't update old time")
  end

end
