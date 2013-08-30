# encoding: UTF-8

class EoeLog
  include Mongoid::Document

  field :ii, :type => Integer, :default => 0 # ip_int, request.remote_ip
  field :do, :type => Integer, :default => 1 # request.domain
  field :fp, :type => String, :default => '' # request.original_fullpath
  field :ui, :type => Integer, :default => 0 # user_id
  field :re, :type => String, :default => '' # refer

  field :t,  :type => DateTime, :default => Statlysis::DateTime1970 # timestamp

  # request.headers['HTTP_USER_AGENT']
  field :br, :type => Integer, :default => 0 # browser name
  field :bv, :type => String, :default => '' # browser version
  field :bo, :type => Integer, :default => 0 # os

  index({t: -1, ui: 1}, {:background => true})
end
EoeLog.create


# Setup a single log that combined by multiple collections
{'07' => 1..31, '08' => 1..12}.map do |month, day_range|
  day_range.map do |day|
    # define model dynamically, e.g. MultipleLog20130729
    date_str = "2013#{month}#{day.to_s.rjust(2, '0')}"
    collection_class_name = "MultipleLog#{date_str}"
    collection_name = collection_class_name.sub("MultipleLog", "multiple_log_")

    # NOTE: Object.const_set(name, Class.new {}) cause failed with error 16256: "Invalid ns [statlysis_mongoid_test.]",
    # and cann't Mongoid.create data
    eval("
      class #{collection_class_name}
        include Mongoid::Document
        self.default_collection_name = #{collection_name.to_json}
        field :t, :type => DateTime
        field :url, :type => String
        index({t: -1}, {:background => true})
      end
    ")

    collection_class = collection_class_name.constantize
    t = Time.zone.parse(date_str)
    values = (1..day).map {|i| (t.to_time+rand(60*60*24-1)).to_datetime }.sort.map {|i| {:t => i, :url => '/' }  }
    collection_class.create values

    collection_class.count
  end
end
