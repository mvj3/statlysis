# encoding: UTF-8

module Statlysis
  TimeUnits = %w[hour day week month year]
  DateTime1970 = Time.zone.parse("19700101").in_time_zone
  TimeUnitToTableSuffixHash = (TimeUnits + [false]).inject({}) {|_h, _i| _h[_i] = (_i ? _i[0] : 'a'); _h }

  DefaultTableOpts = {:charset => "utf8", :collate => "utf8_general_ci", :engine => "MyISAM"}

  DefaultNotImplementWrongMessage = "Not implement yet, please config it by subclass".freeze
end
