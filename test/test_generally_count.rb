# encoding: UTF-8
# NOTE 以下统计数据依赖code_gists测试数据。

require 'helper'

class TestGenerallyCount < Test::Unit::TestCase
  def setup
    @output = Statlysis.daily['code_gist'].first.output
  end

  def test_timely
    o = @output.map {|i| i[:timely_c] }
    assert o.uniq.count > 20
  end

  def test_totally
    assert_equal @output[-1][:totally_favcount_s].to_i, CodeGist.all.map(&:fav_count).reduce(:+)
  end

end
