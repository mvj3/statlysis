Statlysis
===============================================
Statistical and analysis in Ruby DSL, just as simple as SQL operations in ActiveRecord.

成功案例
-----------------------------------------------
* eoe.cn各子网站的页面访问统计，和包含多个条件的数据库表每日数据统计，详情见 [示例配置文件](https://github.com/mvj3/statlysis/blob/master/examples/eoecn.rb) 。
* 阳光书屋的学习提高班的关于做题情况的统计分析，详情见 [示例配置文件](https://github.com/mvj3/statlysis/blob/master/examples/sunshinelibrary.rb) 。

Usage
-----------------------------------------------
见上面的 [成功案例](#成功案例) 的配置文件 和 [手把手操作示例](http://mvj3.github.io/statlysis/showterm.html) 。

Features
-----------------------------------------------
* 支持Mongoid和ActiveRecord两种ORM，其中Mongoid以MapReduce方式统计，ActiveRecord基于纯SQL操作。
* Support time column that stored as integer.


Statistical Process
-----------------------------------------------
1. Delete invalid statistical data, e.g. data in tomorrow
2. Count data within the specified time by the dimensions
3. Delete overlapping data, and insert new data


FAQ
-----------------------------------------------
Q: 为什么要ETL为简单几个维度的单层数据集，以方便statlysis统计？
A: 用户最后能看到和理解的也就是两三维的分析图表而已，从用户理解出发。

Q: Why use Sequel instead of ActiveRecord?

A: When initialize an ORM object, ActiveRecord is 3 times slower than Sequel, and we just need the basic operations, including read, write, enumerate, etc. See more details in [Quick dive into Ruby ORM object initialization](http://merbist.com/2012/02/23/quick-dive-into-ruby-orm-object-initialization/) .


Q: Why do you recommend using multiple collections to store logs rather than a single collection, or a capped collection?

A: MongoDB can effectively reuse space freed by removing entire collections without leading to data fragmentation, see details at http://docs.mongodb.org/manual/use-cases/storing-log-data/#multiple-collections-single-database


Q: In Mongodb, why use MapReduce instead of Aggregation?

A: The result of aggregation pipeline is a document and is subject to the BSON Document size limit, which is currently 16 megabytes, see more details at http://docs.mongodb.org/manual/core/aggregation-pipeline/#pipeline


TODO
-----------------------------------------------
* Admin interface
* statistical query api in Ruby and HTTP
* Interacting with Javascript charting library, e.g. Highcharts, D3.


Copyright
-----------------------------------------------
MIT. David Chen at eoe.cn, sunshine-library .
