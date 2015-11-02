Statlysis [![Build Status](https://travis-ci.org/mvj3/statlysis.png)](https://travis-ci.org/mvj3/statlysis) [![Documentation badges](http://inch-ci.org/github/mvj3/statlysis.svg?branch=master)](https://inch-ci.org/github/mvj3/statlysis)
===============================================
Statistic and analysis in Ruby DSL, just as simple as SQL operations in ActiveRecord.

Usage
-----------------------------------------------
见下面的 [成功案例](#成功案例) 的配置文件 和 [手把手操作示例](http://mvj3.github.io/statlysis/showterm.html) 。

项目来由，理念，和使用说明
-----------------------------------------------
该项目起因是为eoe.cn做一套统计后台，而其构思来自于2012上半年做 [Android优亿市场数据采集分析系统](http://mvj3.github.io/2012/11/01/android_eoemarket_data_collect_and_analysis_system_summary/) 时的一些经验和心得，在2013年上半年完成了架构和大部分代码，支持ActiveRecord和Mongoid两个ORM。下半年在阳光书屋加上了对Mongoid的MapReduce支持。

针对一般互联网网站的统计需求，都是把Google Analysis等分析网站的一段Javascript脚本放到网页底部，然后就可以看到网站每日详细的访问情况了。但是针对内部数据需求，比如每日注册用户量，这个一般就不可能开放给第三方去统计了，所以这就是statlysis的存在意义。

做过数据分析的人都知道其中的坑，比如有些是直接拿SQL跨多个表Join统计，每次有数据需求均执行一次完整的查询，随着数据量的增大，性能问题可想而知。

下面介绍如何用statlysis进行统计分析：

#### 是否要 ETL(Extract, Transform, Load) 数据清洗
statlysis认为数据源一定要被ETL为简单几个维度的单层数据集，因为用户最后能看到和理解的也就是两三维的分析图表而已，所以从用户理解出发。

这里也需要注意如果当该数据表是可以直接支持统计分析的，但是数据量大，那么得加上相关索引，或者导入到另外的单表里(在ORM里可以在`after_save`等hooks里操作)再加索引。

#### 流程
1. 分析数据统计需求，画出包含对应维度的图表。
2. ETL，参照 #是否要 ETL(Extract, Transform, Load) 数据清洗#
3. 在 `Statlysis.setup { }` 代码块里配置出页面需要的数据，注意得是单表的，类似没有跨表JOIN的SQL查询。
4. 跑统计分析，比如 `Statlysis.daily.run`。此过程可以用cron定时来驱动，或者`after_save`等数据更新来驱动。
5. 编写用于数据需求人员查看的HTML页面，其中统计数据可以用`Statlysis.daily['code_gists'].first.stat_model`或`TimelyCodegist`来直接查询。

#### 尽量采用MongoDB来作为统计数据源
MongoDB作为NoSQL数据库，它是为 **单collection** 里读写 **单个记录的整体** 而优化设计的，并支持MapReduce并发来加快统计过程。

成功案例
-----------------------------------------------
* eoe.cn各子网站的页面访问统计，和包含多个条件的数据库表每日数据统计，详情见 [示例配置文件](https://github.com/mvj3/statlysis/blob/master/examples/eoecn.rb) ，按日期维度分。
* 阳光书屋的学习提高班的关于做题情况的统计分析，详情见 [示例配置文件](https://github.com/mvj3/statlysis/blob/master/examples/sunshinelibrary.rb) ，按班级维度分。

Features
-----------------------------------------------
1. 支持Mongoid和ActiveRecord两种ORM，其中Mongoid以MapReduce方式统计，ActiveRecord基于纯SQL操作。
2. 对统计结果进行SQL索引，以支持高效访问。
3. 支持单行DSL配置，链式风格。
4. 支持跨表统计，需结构相同，表名按日期分割。
5. 依据统计需求自动配置统计结果的存储表，并支持条件查询，返回ORM统计表。
6. 支持任意维度统计，其中时间维度可选。
7. 单次统计里支持多个GroupConcat字段。
8. 支持最近统计的时间。
9. 支持以整数类型存储的时间字段，以兼容PHP社区的特别约定。

Statistic Process
-----------------------------------------------
1. Delete invalid statistic data, e.g. data in tomorrow
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


TODO
-----------------------------------------------
* Admin interface
* statistic query api in Ruby and HTTP
* Interacting with Javascript charting library, e.g. Highcharts, D3.


Copyright
-----------------------------------------------
MIT. David Chen at eoe.cn, sunshine-library .
