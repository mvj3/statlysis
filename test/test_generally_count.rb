# encoding: UTF-8
# NOTE 以下统计数据依赖code_gists测试数据。

require 'helper'

class TestGenerallyCount < Test::Unit::TestCase
  def setup
    @output = Statlysis.daily['code_gist'].first.output
  end

  def test_timely
    o = @output.map {|i| i[:timely_c] }
    r = (o - [5,11,0,1,8,2,3,4,16,10,26,13,7,9,20,15,30,33,14,6,12,17,19,59,65,84,62,114,69,52,61,67,154,70]).reject(&:zero?).blank?
    assert r
  end

  def test_totally
    o = @output.map {|i| i[:totally_c] }
    r = (o - [5,16,17,25,27,30,34,36,37,53,55,56,57,59,60,64,66,67,68,70,71,73,74,75,80,90,116,129,136,145,165,185,200,230,234,235,236,237,270,273,274,288,299,304,305,312,327,337,345,359,374,380,392,418,435,446,452,463,466,473,493,506,512,520,525,545,549,553,558,577,636,701,785,805,867,981,1050,1102,1163,1230,1384,1454,1455,1457,1458]).reject(&:zero?).blank?
    assert r
    assert_equal @output[-1][:totally_favcount_s].to_i, CodeGist.all.map(&:fav_count).reduce(:+)
  end

end 
