# encoding: UTF-8

module Statlysis
  class Clock
    attr_accessor :clock
    include Common

    # feature is a string
    def initialize feature, default_time = nil
      # init table & model
      cron.stat_table_name = [Statlysis.tablename_default_pre, 'clocks'].compact.join("_")
      unless Statlysis.sequel.table_exists?(cron.stat_table_name)
        Statlysis.sequel.create_table cron.stat_table_name, DefaultTableOpts.merge(:engine => "InnoDB") do
          primary_key :id
          String      :feature
          DateTime    :t
          index       :feature, :unique => true
        end
      end
      h = Utils.setup_pattern_table_and_model cron.stat_table_name
      cron.stat_model = h[:model]

      # init default_time
      default_time ||= DateTime.now
      cron.clock = cron.stat_model.find_or_create(:feature => feature)
      cron.clock.update :t => default_time if cron.current.nil?
      cron
    end

    def update time = DateTime.now
      time = DateTime.now if time == DateTime1970
      return false if time && (time < cron.current)
      cron.clock.update :t => time
    end

    # ensure the time is newest
    def current; cron.stat_model.find(id: clock.id).t end

  end

end
