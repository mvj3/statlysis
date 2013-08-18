# encoding: UTF-8

module Statlysis
  class Timely < Count
    def setup_stat_model
      cron.stat_table_name = Utils.normalise_name [cron.class.name.split("::")[-1], cron.multiple_dataset.name, cron.source_where_array.join, cron.time_unit[0]]
      raise "mysql only support table_name in 64 characters, the size of '#{cron.stat_table_name}' is #{cron.stat_table_name.to_s.size}. please set cron.stat_table_name when you create a Cron instance" if cron.stat_table_name.to_s.size > 64

      if not Statlysis.sequel.table_exists?(cron.stat_table_name)
        Statlysis.sequel.transaction do
          Statlysis.sequel.create_table cron.stat_table_name, DefaultTableOpts do
            DateTime :t # alias for :time
          end

          # TODO Add cron.source_where_array before count_columns
          count_columns = [:timely_c, :totally_c] # alias for :count
          count_columns.each {|w| Statlysis.sequel.add_column cron.stat_table_name, w, Integer }
          index_column_names = [:t] + count_columns
          index_column_names_name = index_column_names.join("_")
          index_column_names_name = index_column_names_name[-63..-1] if index_column_names_name.size > 64

          # Fix there should be uniq index name between tables
          # `SQLite3::SQLException: index t_timely_c_totally_c already exists (Sequel::DatabaseError)`
          if not Statlysis.config.is_skip_database_index
            Statlysis.sequel.add_index cron.stat_table_name, index_column_names, :name => index_column_names_name
          end
        end
      end

      n = cron.stat_table_name.to_s.singularize.camelize
      cron.stat_model = class_eval <<-MODEL, __FILE__, __LINE__+1
        class ::#{n} < Sequel::Model;
          self.set_dataset :#{cron.stat_table_name}
        end
        #{n}
      MODEL

      # add sum columns
      sum_column_to_result_columns_hash.each do |_sum_col, _result_cols|
        _result_cols.each do |_result_col|
          if not cron.stat_model.columns.include?(_result_col)
            # convert to Interger type in view if needed
            Statlysis.sequel.add_column cron.stat_table_name, _result_col, Float
          end
        end
      end

      cron.stat_model
    end

    def output
      @output ||= (cron.time_range.map do |time|
        _hash = {:t => time, :timely_c => 0, :totally_c => 0}
        sum_column_to_result_columns_hash.each do |_sum_col, _result_cols|
          _result_cols.each do |_result_col|
            _hash[_result_col] = 0.0
          end
        end

        # support multiple data sources
        _first_source = nil
        cron.multiple_dataset.sources.each do |s|
          _t = DateTime1970
          _t = is_time_column_integer? ? _t.to_i : _t

          _scope_one = s.where(unit_range_query(time))
          # TODO cache pre-result
          _scope_all = s.where(unit_range_query(time, _t))

          # 1. count
          _hash[:timely_c]  += _scope_one.count
          _hash[:totally_c] += _scope_all.count

          # 2. sum
          sum_column_to_result_columns_hash.each do |_sum_col, _result_cols|
            _hash[_result_cols[0]] = _scope_one.map(&_sum_col).reduce(:+).to_f
            _hash[_result_cols[1]] = _scope_all.map(&_sum_col).reduce(:+).to_f
          end

          _first_source ||= s.where(unit_range_query(time))
        end
        logger.info "#{time.in_time_zone(cron.time_zone)} multiple_dataset:#{cron.multiple_dataset.name} _first_source:#{_first_source.inspect} timely_c:#{_hash[:timely_c]} totally_c:#{_hash[:totally_c]}" if ENV['DEBUG']

        _hash
      end.select {|r1| r1.except(:t).values.reject {|r2| r2.zero? }.any? })
    end

    private
    def sum_column_to_result_columns_hash
      cron.sum_columns.inject({}) do |h, _col|
        [:timely, :totally].each do |_pre|
          h[_col] ||= []
          h[_col] << Utils.normalise_name([_pre, _col, 's']).to_sym
        end
        h
      end
    end

  end
end
