class CreateLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :links do |t|
      t.belongs_to :path, foreign_key: true
      t.string :name
    end
  end
end
