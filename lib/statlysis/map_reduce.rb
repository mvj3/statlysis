# encoding: utf-8

require 'statlysis/javascript/count'

module Statlysis
  class MapReduce
    attr_reader :mongoid_scope, :mapreduce_javascript
    attr_accessor :mr_collection, :results
    attr_accessor :is_use_inline, :identify
    def initialize mongoid_scope, mapreduce_javascript
      mr.mongoid_scope = mongoid_scope
      mr.mapreduce_javascript = mapreduce_javascript
      mr.is_use_inline = true
      mr.identify = Time.now.strftime("%m%d_%H%M%S")
      mr
    end

    def run
      # TODO collection for large
      mr.results = Results.new mr.mongoid_scope.map_reduce(mapreduce_javascript.map_func, mapreduce_javascript.reduce_func).out(:replace => out_collection_name)
      self
    end

    def output
      mr.results.output
    end

    def out_collection_name; "mr_#{mr.mongoid_scope.collection_name}_#{mr.identify}" end
    def mr; self end
  end

end
