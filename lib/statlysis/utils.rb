# encoding: UTF-8

module Statlysis
  module Utils
    class << self
      def is_activerecord?(data); data.is_a?(ActiveRecordDataset) || !!((data.respond_to?(:included_modules) ? data.included_modules : []).index(ActiveRecord::Store)) end
      def is_mongoid?(data); data.is_a?(MongoidDataset) || !!((data.respond_to?(:included_modules) ? data.included_modules : []).index(Mongoid::Document)) end
      def name(data)
        return :collection_name if Utils.is_mongoid?(data)
        return :table_name      if Utils.is_activerecord?(data)
      end

      def setup_pattern_table_and_model tn
        # ensure statlysis table
        tn = tn.pluralize
        if not Statlysis.sequel.table_exists?(tn)
          Statlysis.sequel.create_table tn, DefaultTableOpts.merge(:engine => "InnoDB") do
            primary_key :id
            String :pattern
            index  :pattern
          end
          Statlysis.sequel.add_column tn, :result, String, :text => true
        end

        # generate a statlysis kv model
        str = tn.to_s.singularize.camelize
        class_eval <<-MODEL, __FILE__, __LINE__ + 1
          class ::#{str} < Sequel::Model;
            self.set_dataset :#{tn}
            def self.[] item_id
              JSON.parse(find_or_create(:pattern => item_id).result) rescue []
            end
          end;
        MODEL
        {:table => tn, :model => str.constantize}
      end

      def normalise_name name
        Array(name).map {|s| s.to_s.gsub('_','') }.reject {|s| s.blank? }.join('_').downcase
      end

      def sha1_name name; Digest::SHA1.hexdigest Array(name).map(&:to_s).join end

    end
  end
end
