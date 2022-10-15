class CreateIndices < ActiveRecord::Migration[7.0]
  def change
    create_table :indices do |t|
      t.belongs_to :word
      t.belongs_to :page
      t.integer :frequency
    end
    add_index(:indices, [:word_id, :page_id], unique: true, name: 'word_page_id')
  end
end
