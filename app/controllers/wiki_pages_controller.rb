class WikiPagesController < ApplicationController

  def create

     wikipedia_page = Wikipedia.find(params[:wiki_page][:title])

     wiki_page = WikiPage.find_or_create_by_title wikipedia_page.title

     if wiki_page.fetched_at.nil? or (wiki_page.fetched_at  < 7.days.ago.to_date)
       wiki_page.trace
     end

     redirect_to wiki_trees_path
  end
end
