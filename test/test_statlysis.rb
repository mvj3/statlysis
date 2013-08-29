# encoding: UTF-8

require 'helper'

class TestStatlysis < Test::Unit::TestCase
  def setup
    @old_datetime = Time.zone.parse("20130105")
  end

  def test_setup_count_stat_table
    eval("class CodeGist < ActiveRecord::Base; end")
    t = Statlysis::Timely.new CodeGist.where(:user_id => 470700), :time_column => :created_at, :time_unit => :day
    t.setup_stat_model
    is_created = Statlysis.sequel.table_exists?(t.stat_table_name)
    Statlysis.sequel.drop_table t.stat_table_name

    assert(is_created, "统计表#{t.stat_table_name}没有成功创建")
  end

  def test_setup_lastest_visits_stat_table
    tn = 'st_blog_lastest_visits_tests'
    lv = Statlysis::LastestVisits.new EoeLog, :stat_table_name => tn, :test => true, :default_time => @old_datetime
    h = Statlysis::Utils.setup_pattern_table_and_model tn
    lv.stat_model = h[:model]
    is_sequel_model = lv.stat_model.respond_to?(:count)
    Statlysis.sequel.drop_table tn

    assert(is_sequel_model, "统计表#{lv.stat_table_name}没有成功创建")
  end

end
