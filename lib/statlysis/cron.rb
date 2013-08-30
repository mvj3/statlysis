# encoding: UTF-8

module Statlysis
  class Cron
    attr_reader :multiple_dataset, :source_type, :time_column, :time_unit, :time_zone
    include Common

    def initialize s, opts = {}
      # setup data type related
      @source_type = ({Utils.is_activerecord?(s) => :activerecord, Utils.is_mongoid?(s) => :mongoid}.detect {|k, v| k } || {})[1] || :unknown

      @time_column      = opts[:time_column]
      @time_unit        = opts[:time_unit]
      @time_zone        = opts[:time_zone] || Statlysis.default_time_zone || Time.zone || Time.now.utc_offset

      # insert source as a dataset
      @multiple_dataset = (s.is_a?(ActiveRecordDataset) ? s : ActiveRecordDataset.new(cron).add_source(s)) if is_activerecord?
      @multiple_dataset = (s.is_a?(MongoidDataset) ? s : MongoidDataset.new(cron).add_source(s)) if is_mongoid?
      @multiple_dataset.instance_variable_set("@cron", cron) if is_orm? && @multiple_dataset.cron.nil?

      @stat_table_name = opts[:stat_table_name] if opts[:stat_table_name]

      cron
    end
    def output; raise DefaultNotImplementWrongMessage end
    def reoutput; @output = nil; output end
    def setup_stat_model; raise DefaultNotImplementWrongMessage end
    def run; raise  DefaultNotImplementWrongMessage end
    def is_activerecord?; @source_type == :activerecord; end
    def is_mongoid?; @source_type == :mongoid; end
    def is_orm?; [:activerecord, :mongoid].include?(@source_type); end
    def _source; cron.multiple_dataset.sources.first end

    def source_where_array
      # TODO follow index seq
      a = _source.where("").where_values.map do |equality|
        # use full keyvalue index name
        equality.is_a?(String) ? equality.to_sym : "#{equality.operand1.name}#{equality.operand2}"
      end if is_activerecord?
      a = _source.all.selector.reject {|k, v| k == 't' } if is_mongoid?
      a.map {|s1| s1.to_s.split(//).select {|s2| s2.match(/[a-z0-9]/i) }.join }.sort.map(&:to_sym)
    end

    # automode
    # or
    # specify TIME_RANGE and TIME_UNIT in shell to run
    def time_range
      return TimeSeries.parse(ENV['TIME_RANGE'], :unit => (ENV['TIME_UNIT'] || 'day'), :zone => cron.time_zone) if ENV['TIME_RANGE']
      # 选择开始时间。取出统计表的最后时间，和数据表的最先时间对比，哪个在后就选择哪个
      begin_day = DateTime.now.beginning_of_day
      st_timebegin = (a = cron.stat_model.order(:t).where("t >= ?", begin_day.yesterday).first) ? a[:t] : nil

      # TODO support multiple log
      cron.stat_model.where("t >= ?", begin_day.tomorrow).delete # 明天的数据没出来肯定统计不了
      timebegin = (multiple_dataset.first_time != DateTime1970) ? multiple_dataset.first_time : (DateTime.now - 1.second)
      timebegin = Time.at(timebegin) if is_time_column_integer?
      timebegin = (st_timebegin > timebegin) ? st_timebegin : timebegin if st_timebegin

      timeend = DateTime.now
      logger.info "#{multiple_dataset.name}'s range #{timebegin..timeend}"
      # 把统计表的最后时间点也包含进去重新计算下
      TimeSeries.parse(timebegin..timeend, :unit => cron.time_unit)
    end

    protected

    # 兼容采用整数类型作时间字段
    def is_time_column_integer?
      if is_activerecord?
        _source.columns_hash[cron.time_column.to_s].type == :integer
      else
        false
      end
    end
    def time_column?; !!@time_column end

  end

end


require 'statlysis/cron/timely'
require 'statlysis/cron/top'
