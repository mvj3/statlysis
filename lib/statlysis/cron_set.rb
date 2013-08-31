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
          reg = Regexp.new(pattern.to_s)
          cron.stat_table_name.match(reg) || cron.multiple_dataset.name.to_s.match(reg)
        end)
      end
    end

    def last; self[-1]; end

    def run
      map(&:run)
    end
  end

end
