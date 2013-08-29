# encoding: UTF-8

module Statlysis
  class Timely


    def multiple_dimensions_output
      self.send "multiple_dimensions_output_with#{cron.time_column ? '' : 'out'}_time_column"
    end

    private
    def multiple_dimensions_output_with_time_column
      cron.time_range.map do |time|
      end
    end

    def multiple_dimensions_output_without_time_column
    end


  end
end
 
