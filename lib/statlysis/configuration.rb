# encoding: UTF-8
#
# see original implementation at http://mvj3.github.io/2013/04/17/statlysis-analysis-design-solve-two-problems-lazy-loading-and-scope/
#

require 'singleton'

module Statlysis
  class Configuration
    include Singleton

    # variables
    attr_accessor :sequel, :default_time_columns, :default_time_zone, :database_opts, :tablename_default_pre
    attr_accessor :is_skip_database_index
    (TimeUnits + %W[always] + [:realtime, :similar, :hotest]).each do |unit|
      sym = "#{unit}_crons"; attr_accessor sym; self.instance.send "#{sym}=", []
    end
    self.instance.send "tablename_default_pre=", "st"
    self.instance.send "is_skip_database_index=", false

    # 会在自动拼接统计数据库表名时去除这些时间字段
    def update_time_columns *columns
      self.default_time_columns ||= [:created_at, :updated_at]
      columns.each {|column| self.default_time_columns.push column }
      self.default_time_columns = self.default_time_columns.uniq
    end

    def set_database sym_or_hash
      self.database_opts = if sym_or_hash.is_a? Symbol
        YAML.load_file(Rails.root.join("config/database.yml"))[sym_or_hash.to_s]
      elsif Hash
        sym_or_hash
      else
        raise "Statlysis#set_database only support symbol or hash params"
      end

      # sqlite dont support regular creating database in mysql style
      self.sequel = if (self.database_opts['adapter'].match(/sqlite/) && self.database_opts['database'].match(/\A:memory:\Z/)) # only for test envrionment
        Sequel.sqlite
      else
        # create database, copied from http://stackoverflow.com/a/14435522/595618
        require 'mysql2'
        mysql2_client = Mysql2::Client.new(self.database_opts.except('database'))
        mysql2_client.query("CREATE DATABASE IF NOT EXISTS #{self.database_opts['database']}")
        Sequel.connect(self.database_opts)
      end

      # 初始化键值model
      ["#{self.tablename_default_pre}_single_kvs", "#{self.tablename_default_pre}_single_kv_histories"].each do |tn|
        Utils.setup_pattern_table_and_model tn
      end

      return self
    end

    def set_default_time_zone zone; self.default_time_zone = zone; return self; end
    def set_tablename_default_pre str; self.tablename_default_pre = str.to_s; return self end
    def check_set_database; raise "Please setup database first" if sequel.nil?  end

    def daily  source, opts = {}; timely source, {:time_unit => :day }.merge(opts) end
    def hourly source, opts = {}; timely source, {:time_unit => :hour}.merge(opts) end
    def always source, opts = {}; timely source, {:time_unit => false}.merge(opts) end # IMPORTANT set :time_unit to false

    # the real requirement is to compute lastest items group by special pattens, like user_id, url prefix, ...
    def lastest_visits source, opts
      self.check_set_database
      opts.reverse_merge! :time_column => :created_at
      self.realtime_crons.push LastestVisits.new(source, opts)
    end

    # TODO 为什么一层proc的话会直接执行的
    def hotest_items key, id_to_score_and_time_hash = {}
      _p = proc { if block_given?
        (proc do
          id_to_score_and_time_hash = Hash.new
          yield id_to_score_and_time_hash
          id_to_score_and_time_hash
        end)
      else
        (proc { id_to_score_and_time_hash })
      end}

      self.hotest_crons.push HotestItems.new(key, _p)
    end

    # TODO support mongoid
    def similar_items model_name, id_to_text_hash = {}
      _p = if block_given?
        (proc do
          id_to_text_hash = Hash.new {|hash, key| hash[key] = "" }
          yield id_to_text_hash
          id_to_text_hash
        end)
      else
        (proc { id_to_text_hash })
      end

      self.similar_crons.push Similar.new(model_name, _p)
    end


    private
    def timely source, opts
      self.check_set_database

      opts.reverse_merge! :time_column => :created_at,
                          :time_unit => :day,
                          :sum_columns => [],
                          :group_by_columns => [],
                          :group_concat_columns => []

      opts.each {|k, v| opts[k] = v.map(&:to_sym) if k.to_s.match(/_columns/) } # Sequel use symbol as column names

      # e.g. convert [:user_id] to [{:column_name => :user_id, :type => :integer}]
      if (opts[:group_by_columns].first || {})[:type].blank?
        opts[:group_by_columns] = opts[:group_by_columns].map {|i| {:column_name => i, :type => :integer} }
      end

      t = Timely.new source, opts
      self.send("#{opts[:time_unit] || 'always'}_crons").push t
    end

  end
end
