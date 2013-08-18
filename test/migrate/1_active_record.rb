class CreateActiveRecord < ActiveRecord::Migration
  create_table :code_gists do |t|
    t.string  :description
    t.integer :user_id
    t.timestamps
    t.string :author
    t.integer :fav_count
  end
end
