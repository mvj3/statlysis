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
                          i['_id'].inject({}) do |_h, _i|
                            _h[_i[0].to_sym] = _i[1]
                            _h
                          end.merge(
                            :c => i['value']['count']
                          )
                        end
      end
      array

      # TODO support sum_columns
      # support group_concat_columns
    end


  end
end
