Statlysis
===============================================
Statistical & Analysis in Ruby DSL

Usage
-----------------------------------------------
### setup

```ruby
Statlysis.setup do
  set_database :statlysis

  daily CodeGist
  hourly EoeLog, :time_column => :t # support custom time_column

  [EoeLog,
   EoeLog.where(:ui => 0), # support query scope
   EoeLog.where(:ui => {"$ne" => 0}),
   Mongoid[/eoe_logs_[0-9]+$/].where(:ui => {"$ne" => 0}), # support collection name regexp
   EoeLog.where(:do => {"$in" => [DOMAINS_HASH[:blog], DOMAINS_HASH[:my]]}),
  ].each do |s|
    daily s, :time_column => :t
  end
end
```

### access

```ruby
Statlysis.daily # => return daily crons
Statlysis.daily.run # => run daily crons
Statlysis.daily[/name_regexp/] # => return matched daily crons
```

### process

```irb
[23] pry(#<Statlysis::Configuration>)> Statlysis.daily['multi'].first
```

Features
-----------------------------------------------
* Support time column that stored as integer.

TODO
-----------------------------------------------
* Admin interface
* statistical query api in Ruby and HTTP
* Interacting with Javascript charting library, e.g. Highcharts, D3.


Statistical Process
-----------------------------------------------
1. Delete invalid statistical data, e.g. data in tomorrow
2. Count data within the specified time by the dimensions
3. Delete overlapping data, and insert new data


FAQ
-----------------------------------------------
Q: Why use Sequel instead of ActiveRecord?

A: When initialize an ORM object, ActiveRecord is 3 times slower than Sequel, and we just need the basic operations, including read, write, enumerate, etc. See more details in [Quick dive into Ruby ORM object initialization](http://merbist.com/2012/02/23/quick-dive-into-ruby-orm-object-initialization/) .


Q: Why do you recommend using multiple collections to store logs rather than a single collection, or a capped collection?

A: MongoDB can effectively reuse space freed by removing entire collections without leading to data fragmentation, see details at http://docs.mongodb.org/manual/use-cases/storing-log-data/#multiple-collections-single-database


Q: In Mongodb, why use MapReduce instead of Aggregation?

A: The result of aggregation pipeline is a document and is subject to the BSON Document size limit, which is currently 16 megabytes, see more details at http://docs.mongodb.org/manual/core/aggregation-pipeline/#pipeline


Copyright
-----------------------------------------------
MIT. David Chen at eoe.cn, sunshine-library .

Related
-----------------------------------------------
### Projects
* https://github.com/paulasmuth/fnordmetric FnordMetric is a redis/ruby-based realtime Event-Tracking app
* https://github.com/thirtysixthspan/descriptive_statistics adds methods to the Enumerable module to allow easy calculation of basic descriptive statistics for a set of data
* https://github.com/tmcw/simple-statistics simple statistics for javascript in node and the browser
* https://github.com/clbustos/statsample/  A suite for basic and advanced statistics on Ruby. 
* https://github.com/SciRuby/sciruby Tools for scientific computation in Ruby/Rails

### Articles
* http://www.slideshare.net/WombatNation/logging-app-behavior-to-mongo-db

### Event collector
* https://github.com/fluent
* https://github.com/logstash/logstash

### Admin interface
* http://three.kibana.org/ browser based analytics and search interface to Logstash and other timestamped data sets stored in ElasticSearch.


### ETL
* https://github.com/activewarehouse/activewarehouse-etl/ 
* http://jisraelsen.github.io/drudgery/ ruby ETL DSL, support csv, sqlite3, ActiveRecord, without support time range
* https://github.com/square/ETL Simply encapsulates the SQL procedures


