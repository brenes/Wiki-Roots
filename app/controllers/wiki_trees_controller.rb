class WikiTreesController < ApplicationController

  def index
    @wiki_trees = WikiTree.all
  end

  def show
    @wiki_tree = WikiTree.find params[:id]
  end
  
end
