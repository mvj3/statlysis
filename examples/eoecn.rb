# encoding: UTF-8

Statlysis.setup do
  set_database :statlysis
  update_time_columns :t
  set_tablename_default_pre :st

  # 统计网站总体每日访问量
  @log_model = IS_DEVELOP ? EoeLogTest : EoeLog
  hourly @log_model, :time_column => :t
  daily  @log_model, :time_column => :t
  # 统计登陆和非登陆用户访问量
  daily  @log_model.where(:ui => 0), :time_column => :t
  daily  @log_model.where(:ui => {"$ne" => 0}), :time_column => :t

  # 统计各个子网站每日访问量
  daily  @log_model.where(:do => {"$in" => [DOMAINS_HASH[:blog], DOMAINS_HASH[:my]]}), :time_column => :t
  [:www, :code, :skill, :book, :edu, :news, :wiki, :salon, :android].each do |site|
    daily  @log_model.where(:do => DOMAINS_HASH[site]), :time_column => :t
  end

  # 统计各个数据模型在不同条件下每天的变化量
  daily CodeGist
  [BlogPost, NewsNews, WikiPage].each do |model|
    daily model.where("create_time > 0"), :time_column => :create_time
    daily model.where("update_time > 0"), :time_column => :update_time
  end

  daily CommonComment.where("is_delete = 0"), :time_column => :create_time
  daily CommonComment.where(:model => 'blog').where("is_delete = 0"), :time_column => :create_time
  daily CommonComment.where(:model => 'code').where("is_delete = 0"), :time_column => :create_time

  daily CommonMember.where("regdate > 0"), :time_column => :regdate

end
