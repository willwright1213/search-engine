class CreateLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :links, primary_key: [:page_id, :link_to] do |t|
      t.belongs_to :page
      t.integer :link_to
    end
  end
end
