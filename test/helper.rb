require File.join(ENV['HOME'], 'utils/ruby/irb') rescue nil
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.dirname(__FILE__) # test dirs
require 'pry-debugger'

# load mongoid setup
require 'mongoid'
Mongoid.load!(File.expand_path("../config/mongoid.yml", __FILE__), :production)
Mongoid.default_session.collections.select {|c| c.name !~ /system/ }.each(&:drop) # delete lastest data

require 'statlysis'

# load rails
def Rails.root; Pathname.new(File.expand_path('../.', __FILE__)) end
def Rails.env; 'development' end
require 'sqlite3'

# load ActiveRecord setup
Statlysis.set_database ":memory:"
Statlysis.config.is_skip_database_index = true
ActiveRecord::Base.establish_connection(Statlysis.config.database_opts.merge("adapter" => "sqlite3"))
Dir[File.expand_path("../migrate/*.rb", __FILE__).to_s].each { |f| require f }
Dir[File.expand_path("../models/*.rb", __FILE__).to_s].each { |f| require f }

# load basic test data
# copied from http://stackoverflow.com/questions/4410794/ruby-on-rails-import-data-from-a-csv-file/4410880#4410880
require 'csv'
csv = CSV.parse(File.read(File.expand_path('../data/code_gists_20130724.csv', __FILE__)), :headers => true) # data from code.eoe.cn
csv.each do |row|
  _h = row.to_hash.merge(:fav_count => rand(5).to_i)
  CodeGist.create! _h
  _h[:category_id] = rand(10).to_i + 1
  CodeGistMongoid.create! _h
end


Statlysis.setup do
  hourly EoeLog, :time_column => :t

  daily  CodeGist, :sum_columns => [:fav_count], :group_concat_columns => [:user_id]
  always CodeGistMongoid, :group_by_columns => [{:column_name => :author, :type => :string}], :group_concat_columns => [:user_id]
  always CodeGistMongoid, :group_by_columns => [{:column_name => :author, :type => :string}, {:column_name => :category_id, :type => :integer}], :group_concat_columns => [:user_id]

  [EoeLog,
   EoeLog.where(:do => 3),
   Mongoid[/multiple_log_2013[0-9]{4}/],
   Mongoid[/multiple_log_2013[0-9]{4}/].where(:ui => {"$ne" => 0})
  ].each do |s|
    daily s, :time_column => :t
  end
  cron1 = Statlysis.daily['mul'][1]
  cron2 = Statlysis.daily['cod'][0]
  cron3 = Statlysis.always['code']['mongoid'][0]
  (require 'pry-debugger';binding.pry) if ENV['DEBUG']

end
