# encoding: UTF-8

module Statlysis
  class Timely


    def multiple_dimensions_output
      self.send "multiple_dimensions_output_with#{cron.time_column ? '' : 'out'}_time_column"
    end

    private
    def multiple_dimensions_output_with_time_column
      cron.time_range.map do |time|
        raise DefaultNotImplementWrongMessage # TODO
      end
    end

    # TODO encapsulate Mongoid MapReduce in collection output mode
    # TODO support large dataset, e.g. a million.
    def multiple_dimensions_output_without_time_column
      mr = Javascript::MultiDimensionalCount.new(cron)

      array = []
      cron.multiple_dataset.sources.each do |_source|
        # _source = _source.time_range # TODO
        array += _source.map_reduce(mr.map_func, mr.reduce_func)
                        .out(inline: 1) # TODO use replace mode
                        .to_a.map do |i|
                          v = i['value']
                          _h = {:c => v['count']}

                          cron.group_by_columns.each do |_group_by_column|
                            _h[_group_by_column[:column_name]] = v[_group_by_column[:column_name].to_s]
                          end

                          _h[:other_json] = {}
                          cron.group_concat_columns.each do |_group_concat_column|
                            _h[:other_json][_group_concat_column] = v["#{_group_concat_column}_values"].inject({}) {|_h2, i2| _h2[i2] ||= 0; _h2[i2] += 1; _h2 }
                          end
                          _h[:other_json] = _h[:other_json].to_json

                          _h
                        end
      end
      array

      # TODO support sum_columns
    end


  end
end
