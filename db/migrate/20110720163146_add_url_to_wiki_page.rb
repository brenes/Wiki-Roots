class AddUrlToWikiPage < ActiveRecord::Migration
  def change
    add_column :wiki_pages, :url, :string
  end
end
