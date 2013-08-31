# encoding: UTF-8

require 'statlysis/cron'

module Statlysis
  class CronSet < Set
    # filter cron_sets by pattern
    def [] pattern = nil
      case pattern
      when Fixnum, Integer # support array idx access
        self.to_a[pattern]
      else
        CronSet.new(select do |cron|
          cron.stat_table_name.match Regexp.new(pattern.to_s)
        end)
      end
    end

    def last; [-1]; end

    def run
      map(&:run)
    end
  end

end
