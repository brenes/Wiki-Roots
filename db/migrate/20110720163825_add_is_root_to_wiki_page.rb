class AddIsRootToWikiPage < ActiveRecord::Migration
  def change
    add_column :wiki_pages, :is_root, :boolean, :default => false
  end
end
