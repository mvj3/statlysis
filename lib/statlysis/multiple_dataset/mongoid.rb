# encoding: UTF-8

require 'mongoid'

# http://mongoid.org/en/origin/index.html
# Origin provides a DSL to mix in to any object to give it the ability to build MongoDB queries easily. It was extracted from Mongoid in an attempt to allow others to leverage the DSL in their own applications without needing a mapper.
require 'origin'

module Statlysis
  class MongoidDataset < MultipleDataset
    # Notice: Origin::Queryable overwrite MongoidDataset#initialize
    class Query; include Origin::Queryable end

    # delegate mongoid query to @sources
    # see document at http://rubydoc.info/github/mongoid/origin/Origin/Queryable & http://rubydoc.info/github/mongoid/origin/Origin/Forwardable
    attr_reader :criteria
    def method_missing m, *args, &blk
      @criteria ||= Query.new
      if (Origin::Selectable.forwardables + Origin::Optional.forwardables).include?(m)
        @criteria = @criteria.__send__(m, *args, &blk)
        @sources = @sources.map {|s| s.__send__(m, *args, &blk) }
        return self # support method chain
      else
        super
      end
    end

    def set_regexp regexp
      super

      _collections = Mongoid.default_session.collections.select {|_collection| _collection.name.match(@regexp) }
      mongoid_models = _select_orm(Mongoid::Document)

      _collections.select do |_collection|
        _mongoid_model = mongoid_models.detect {|m| "#{m.collection_name}" === _collection.name }
        raise "Please define Mongoid model for #{_collection}.collection under ::Object namespace!" if _mongoid_model.nil?
        mongoid_models.delete _mongoid_model
        @sources.add _mongoid_model
      end

      _resort_source_order

      return self
    end

    def resort_source_order; @sources = @sources.map {|s| s.asc(cron.time_column) } end

  end

  def Mongoid.[] regexp
    MongoidDataset.new.set_regexp(regexp)
  end

end
