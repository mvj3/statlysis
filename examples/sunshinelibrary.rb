# encoding: UTF-8

Statlysis.setup do
  set_database :local_statistic

  daily UserRecord.where(item_type: "activity")

  # 表关系 subject <= chapter <= lesson <= activity <= problem
  #        room和[user, duration]等绑定

  # ********
  # **列表**
  # ********
  # 查询条件:     [chapter]
  # 章节课时分析: room, lesson, level{5}, group_concat(user), count
  # 推断其他字段: [lesson] => [chapter]
  %w[not_done bad good1 good3 good5].each do |level|
    always ETL::LessonLog.where(:level => level),
           :group_by_columns => [
             {:column_name => :room, :type => :string},
             {:column_name => :lesson, :type => :string}
           ],
           :group_concat_columns => [:user]
  end

  # ********
  # **详情**
  # ********
  # 查询条件:     [activity]
  # Activity分析: room, problem, answer, group_concat(user, duration), count
  # 推断其他字段: [problem] => [activity, lesson]
  always ETL::ProblemLog,
         :group_by_columns => [
           {:column_name => :room, :type => :string},
           {:column_name => :problem, :type => :string},
           # statlysis.gem use column_name to create table name, so that's why no_index option exists
           {:column_name => :answer, :type => :string, :no_index => true}
         ],
         :group_concat_columns => [:user, :duration]

end
