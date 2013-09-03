# encoding: UTF-8

module Statlysis
  class Timely < Cron
    SqlColumns = [:sum_columns, :group_by_columns, :group_concat_columns]
    attr_reader(*SqlColumns)

    def initialize source, opts = {}
      super
      Statlysis.check_set_database
      SqlColumns.each {|sym| instance_variable_set "@#{sym}", (opts[sym] || []) }
      cron.setup_stat_model
      cron
    end

    # 设置数据源，并保存结果入数据库
    def run
      (logger.info("#{cron.multiple_dataset.name} have no result!"); return false) if cron.output.blank?

      raise "cron.output has no Enumerable" if not cron.output.class.included_modules.include? Enumerable

      num_i = 0; num_add = 999
      Statlysis.sequel.transaction do
        # delete first in range
        cron.stat_model.where("t >= ? AND t <= ?", cron.output[0][:t], cron.output[-1][:t]).delete if cron.time_column?

        # TODO partial delete
        cron.stat_model.where("").delete if cron.group_by_columns?

        while !(_a = cron.output[num_i..(num_i+num_add)]).blank? do
          # batch insert all
          cron.stat_model.multi_insert _a
          num_i += (num_add + 1)
        end
      end

      return self
    end


    def setup_stat_model
      cron.stat_table_name = Utils.normalise_name cron.class.name.split("::")[-1], cron.multiple_dataset.name, cron.source_where_array, cron.group_by_columns.map {|i| i[:column_name] }, TimeUnitToTableSuffixHash[cron.time_unit]
      raise "mysql only support table_name in 64 characters, the size of '#{cron.stat_table_name}' is #{cron.stat_table_name.to_s.size}. please set cron.stat_table_name when you create a Cron instance" if cron.stat_table_name.to_s.size > 64

      if not Statlysis.sequel.table_exists?(cron.stat_table_name)
        Statlysis.sequel.transaction do
          Statlysis.sequel.create_table cron.stat_table_name, DefaultTableOpts do
            primary_key :id # Add one column at least in this block to avoid `SQLite3::SQLException: near ")": syntax error (Sequel::DatabaseError)`
          end
          Statlysis.sequel.add_column   cron.stat_table_name, :t, DateTime if cron.time_column? # alias for :time

          # TODO Add cron.source_where_array before count_columns
          if cron.time_column?
            count_columns = [:timely_c, :totally_c] # alias for :count
            count_columns.each {|w| Statlysis.sequel.add_column cron.stat_table_name, w, Integer }
            index_column_names = count_columns
            index_column_names = [:t] + count_columns
          else
            Statlysis.sequel.add_column cron.stat_table_name, :c, Integer # alias for :count
          end

          # Fix there should be uniq index name between tables
          # `SQLite3::SQLException: index t_timely_c_totally_c already exists (Sequel::DatabaseError)`
          if not Statlysis.config.is_skip_database_index
            Statlysis.sequel.add_index cron.stat_table_name,
                                       index_column_names,
                                       :name => Utils.sha1_name(index_column_names.join("_")) # index name length should not larger than 64
          end
        end
      end

      # add sum columns
      remodel
      sum_column_to_result_columns_hash.each do |_sum_col, _result_cols|
        _result_cols.each do |_result_col|
          if not cron.stat_model.columns.include?(_result_col)
            # convert to Interger type in view if needed
            Statlysis.sequel.add_column cron.stat_table_name, _result_col, Float
          end
        end
      end

      # add group_by columns & indexes
      remodel
      if cron.group_by_columns.any?
        cron.group_by_columns.each do |_h|
          if not cron.stat_model.columns.include?(_h[:column_name])
            Statlysis.sequel.add_column cron.stat_table_name, _h[:column_name], _h[:type]
          end
        end
        _group_by_columns_index_name = cron.group_by_columns.map {|i| i[:column_name] }
        _group_by_columns_index_name = _group_by_columns_index_name.unshift :t if cron.time_column?
        Statlysis.sequel.add_index cron.stat_table_name, _group_by_columns_index_name, :name => Utils.sha1_name(_group_by_columns_index_name)
      end

      # add group_concat column
      remodel
      if cron.group_concat_columns.any? && !cron.stat_model.columns.include?(:other_json)
        Statlysis.sequel.add_column cron.stat_table_name, :other_json, :text
      end

      remodel
    end

    def output
      @output ||= (cron.group_by_columns.any? ? multiple_dimensions_output : one_dimension_output)
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

    # e.g. {:fav_count=>[:timely_favcount_s, :totally_favcount_s]}
    def sum_column_to_result_columns_hash
      cron.sum_columns.inject({}) do |h, _col|
        [:timely, :totally].each do |_pre|
          h[_col] ||= []
          h[_col] << Utils.normalise_name(_pre, _col, 's').to_sym
        end
        h
      end
    end

    private
    def remodel
      n = cron.stat_table_name.to_s.singularize.camelize
      cron.stat_model = class_eval <<-MODEL, __FILE__, __LINE__+1
        class ::#{n} < Sequel::Model;
          self.set_dataset :#{cron.stat_table_name}
        end
        #{n}
      MODEL
    end



  end
end


require 'statlysis/cron/timely/one_dimension'
require 'statlysis/cron/timely/multiple_dimensions'
