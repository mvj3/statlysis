# encoding: UTF-8

module Statlysis
  module Javascript
    class MultiDimensionalCount
      attr_reader :map_func, :reduce_func

      def initialize *fields
        fields = :_id if fields.blank?
        emit_key = case fields
        when Array
          emit_key = fields.map {|dc| "#{dc}: this.#{dc}" }.join(", ")
          emit_key = "{#{emit_key}}"
        when Symbol, String
          "this.#{fields}"
        else
          raise "Please assign symbol, string, or array of them"
        end

        @map_func = "function() {
          emit (#{emit_key}, {count: 1});
        }"

        @reduce_func = "function(key, values) {
          var count = 0;

          values.forEach(function(v) {
            count += v['count'];
          });

          return {count: count};
        }"

        self
      end

    end
  end
end
