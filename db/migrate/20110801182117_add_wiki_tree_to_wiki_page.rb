class AddWikiTreeToWikiPage < ActiveRecord::Migration
  def change
    add_column :wiki_pages, :wiki_tree_id, :integer
  end
end
