class CreatePages < ActiveRecord::Migration[7.0]
  def change
    create_table :pages do |t|
      t.belongs_to :host, foreign_key: true
      t.string :name
      t.string :title
    end
  end
end
