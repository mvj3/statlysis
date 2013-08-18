# encoding: UTF-8

module Statlysis
  class Count < Cron
    attr_reader :sum_columns

    def initialize source, opts = {}
      super
      Statlysis.check_set_database
      @sum_columns = opts[:sum_columns] || []
      cron.setup_stat_model
      cron
    end

    # 设置数据源，并保存结果入数据库
    def run
      (logger.info("#{cron.multiple_dataset.name} have no result!"); return false) if cron.output.blank?
      # delete first in range
      @output = cron.output
      unless @output.any?
        logger.info "没有数据"; return
      end
      num_i = 0; num_add = 999
      Statlysis.sequel.transaction do
        cron.stat_model.where("t >= ? AND t <= ?", cron.output[0][:t], cron.output[-1][:t]).delete
        while !(_a = @output[num_i..(num_i+num_add)]).blank? do
          # batch insert all
          cron.stat_model.multi_insert _a
          num_i += (num_add + 1)
        end
      end

      return self
    end


    protected
    def unit_range_query time, time_begin = nil
      # time begin and end
      tb = time
      te = (time+1.send(cron.time_unit)-1.second)
      tb, te = tb.to_i, te.to_i if is_time_column_integer?
      tb = time_begin || tb
      return ["#{cron.time_column} >= ? AND #{cron.time_column} < ?", tb, te] if is_activerecord?
      return {cron.time_column => {"$gte" => tb.utc, "$lt" => te.utc}} if is_mongoid? # .utc  [fix undefined method `__bson_dump__' for Sun, 16 Dec 2012 16:00:00 +0000:DateTime]
    end

  end

end


require 'statlysis/cron/count/timely'
require 'statlysis/cron/count/dimensions'
