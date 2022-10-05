class CreatePaths < ActiveRecord::Migration[7.0]
  def change
    create_table :paths do |t|
      t.belongs_to :host, foreign_key: true
      t.string :name
    end
  end
end
