# encoding: UTF-8

require 'helper'

class TestMapReduce < Test::Unit::TestCase
  def setup
  end

  def test_multiple_dimensions_output_without_time_column
    before_time = DateTime.now
    cron = Statlysis.always['mongoid']['code'][0]
    assert_equal cron.time_column, false
    assert_equal cron.time_unit, false
    assert_equal cron.stat_table_name, 'timely_codegistmongoids_author_a'

    cron.run

    # 测试更新最后执行时间的时钟
    # TODO 可能移到其他地方
    assert((cron.clock.current - before_time) >= 0) # compact with fake time

    assert_equal cron.output.detect {|h| h[:author] == 'mvj3' }[:c].to_i, cron.multiple_dataset.sources.first.where(:author => 'mvj3').count
  end


end
