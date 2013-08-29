# encoding: UTF-8

module Statlysis
  class Timely


    # one dimension **must** have `time_column`, or there's nothing to do
    def one_dimension_output
      cron.time_range.map do |time|
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

          # 3. group_concat
          _other_json = {}
          _other_json[:group_concat_columns] ||= {}
          cron.group_concat_columns.each do |_group_concat_column|
            _other_json[:group_concat_columns][_group_concat_column] = _scope_one.map(&_group_concat_column).uniq
          end
          _hash[:other_json] = _other_json.to_json

          _first_source ||= s.where(unit_range_query(time))
        end
        logger.info "#{time.in_time_zone(cron.time_zone)} multiple_dataset:#{cron.multiple_dataset.name} _first_source:#{_first_source.inspect} timely_c:#{_hash[:timely_c]} totally_c:#{_hash[:totally_c]}" if ENV['DEBUG']

        _hash
      end.select {|r1| r1.except(:t, :other_json).values.reject {|r2| r2.zero? }.any? }
    end


  end
end
