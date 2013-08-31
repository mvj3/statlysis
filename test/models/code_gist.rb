# encoding: UTF-8

class CodeGist < ActiveRecord::Base

end


class CodeGistMongoid
  include Mongoid::Document
  include Mongoid::Timestamps
  field :id,          :type => Integer
  field :description, :type => String
  field :user_id,     :type => Integer
  field :author,      :type => String
  field :fav_count,   :type => Integer
end
