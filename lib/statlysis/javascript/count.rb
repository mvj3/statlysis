# encoding: UTF-8

module Statlysis
  module Javascript
    class MultiDimensionalCount
      attr_reader :map_func, :reduce_func
      attr_reader :cron

      def initialize cron
        @cron = cron

        # setup group_by_columns
        _group_by_columns = :_id if cron.group_by_columns.blank?
        _group_by_columns ||= cron.group_by_columns.map {|i| i[:column_name] }
        emit_key = _group_by_columns.map {|dc| "#{dc}: this.#{dc}" }.join(", ")
        emit_key = "{#{emit_key}}"

        # TODO setup sum_columns
        # default_emit_values_array += cron.sum_columns.map {|_sum_column| "#{_sum_column}: this.#{_sum_column}" }

        # setup group_concat_columns
        # NOTE if only one uniq emit value, then it'll never be appeared in reduce function
        emit_values_init_array = cron.group_concat_columns.map do |_group_concat_column|
          "emit_value.#{_group_concat_column}_values = {};\n" +
          "emit_value.#{_group_concat_column}_values[this.#{_group_concat_column}] = 1;\n"
        end
        emit_values_init_array += (_group_by_columns.map do |_group_by_column|
          "emit_value.#{_group_by_column} = this.#{_group_by_column};\n"
        end)

        @map_func = "function() {
          var emit_value = {count: 1};
          #{emit_values_init_array.join}

          emit (#{emit_key}, emit_value);
        }"

        # sum_init_values = cron.sum_columns.map {|_sum_column| "#{_sum_column} = 0.0" }
        # sum_init_values = "var #{sum_init_values};" if cron.sum_columns.any?

        group_concat_values_init_array = cron.group_concat_columns.map {|_group_concat_column| "reducedObject.#{_group_concat_column}_values = {};" }
        group_concat_values_process_array = cron.group_concat_columns.map do |_group_concat_column|
          "for (var k1 in v['#{_group_concat_column}_values']) {\n" +
          "  reducedObject.#{_group_concat_column}_values[k1] = reducedObject.#{_group_concat_column}_values[k1] || 0;\n" +
          "  reducedObject.#{_group_concat_column}_values[k1] += 1;\n" +
          "};\n"
        end
        group_concat_values_process_array += (_group_by_columns.map do |_group_by_column|
          "reducedObject.#{_group_by_column} = v.#{_group_by_column};\n"
        end)

        # emit value in map func should be the same structure as the
        # return value in reduce func, see more details in
        # http://rickosborne.org/download/SQL-to-MongoDB.pdf and
        # http://docs.mongodb.org/manual/tutorial/perform-incremental-map-reduce/
        @reduce_func = "function(key, values) {
          var reducedObject = key;
          reducedObject.count = 0;
          #{group_concat_values_init_array.join}

          values.forEach(function(v) {
            reducedObject.count += v['count'];
            #{group_concat_values_process_array.join}
          });

          return reducedObject;
        }"

        return self
      end

    end
  end
end
