class AddAncestryToWikipages < ActiveRecord::Migration
  def change
    add_column :wiki_pages, :ancestry, :string
  end
end
