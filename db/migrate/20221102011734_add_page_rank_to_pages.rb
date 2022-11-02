class AddPageRankToPages < ActiveRecord::Migration[7.0]
  def change
    add_column :pages, :page_rank, :float
  end
end
