class CreateWikiTrees < ActiveRecord::Migration
  def change
    create_table :wiki_trees do |t|
      t.string :name

      t.timestamps
    end
  end
end
