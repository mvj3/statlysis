# encoding: UTF-8
#
# Sequel的操作均需通过Symbol
#
# 删除匹配的统计表
# Statlysis.sequel.tables.select {|i| i.to_s.match(//i) }.each {|i| Statlysis.sequel.drop_table i }

# TODO Statlysis.sequel.tables.map {|t| eval "class ::#{t.to_s.camelize} < ActiveRecord::Base; self.establish_connection Statlysis.database_opts; self.table_name = :#{t}; end; #{t.to_s.camelize}" }

require "active_support/all"
Time.zone ||= Time.now.utc_offset # require activesupport

require "active_support/core_ext"
require 'active_support/core_ext/module/attribute_accessors.rb'
require 'active_record'
require 'activerecord_idnamecache'
%w[yaml sequel mongoid].map(&method(:require))

# Fake a Rails environment
module Rails; end

require 'statlysis/constants'
require 'statlysis/utils'
require 'statlysis/configuration'
require 'statlysis/common'

module Statlysis
  class << self
    def setup &blk
      raise "Need to setup proc" if not blk

      logger.info "Start to setup Statlysis" if ENV['DEBUG']
      time_log do
        self.config.instance_exec(&blk)
      end
    end

    def time_log text = nil
      t = Time.now
      logger.info text if text
      yield if block_given?
      logger.info "Time spend #{(Time.now - t).round(2)} seconds." if ENV['DEBUG']
      logger.info "-" * 42 if ENV['DEBUG']
    end

    # delagate config methods to Configuration
    def config; Configuration.instance end
    require 'active_support/core_ext/module/delegation.rb'
    Configuration::DelegateMethods.each do |sym|
      delegate sym, :to => :config
    end

    attr_accessor :logger
    Statlysis.logger ||= Logger.new($stdout)

    def source_to_database_type; @_source_to_database_type ||= {} end

    # 代理访问 各个时间类型的 crons
    def daily; CronSet.new(Statlysis.config.day_crons) end
    def hourly; CronSet.new(Statlysis.config.hour_crons) end
    def always; CronSet.new(Statlysis.config.always_crons) end

  end

end

require 'statlysis/timeseries'
require 'statlysis/map_reduce'
require 'statlysis/clock'
require 'statlysis/rake'
require 'statlysis/cron'
require 'statlysis/cron_set'
require 'statlysis/similar'
require 'statlysis/multiple_dataset'

module Statlysis
  require 'short_inspect'
  ShortInspect.apply_to Cron, MultipleDataset
  ShortInspect.apply_minimal_to ActiveRecord::Relation # lazy load
end


# load rake tasks
module Statlysis
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../statlysis/rake.rb', __FILE__)
    end
  end
end if defined? Rails::Railtie
