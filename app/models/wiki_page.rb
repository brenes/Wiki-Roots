require 'wikipedia'

class WikiPage < ActiveRecord::Base
  has_ancestry



  # For tracing we must search for the end of the road or a loop
  def trace
    
    path = WikiPath.new
    
    page = self

    wikipage = Wikipedia.find(title)

    # If page has a parent we must stop (we can fetch the cached path or it's a loop)
    # If there's no page... we reached the end of the road
    while !page.blank? and page.parent_id.blank? 
      
      path.pages << page
          
      # We must get rid of infoboxes, metadata and Image and FIle links before we get the link title
      first_link_title = wikipage.content.gsub("\n", "").gsub(/\{\{[^\}]*\}\}/, "").gsub("[[Image:", "").gsub("[[File:", "").match(/\[\[[^\]]*\]\]/)[0]
      first_link_title = first_link_title.split("|").first.gsub("]", "").gsub("[", "") unless first_link_title.nil?


      if first_link_title.nil?
        page.update_attributes :is_root => true
        page = nil
      else

        wikipage = Wikipedia.find(first_link_title)

        parent_page = WikiPage.find_by_title(first_link_title)
        parent_page ||= WikiPage.create :url => "", :title => first_link_title, :fetched_at => Time.now

        page.update_attributes :parent_id => parent_page.id


        page = parent_page        
      end
    end

    unless page.blank?
      path.pages << page
      unless page.parent_id.blank?
        
        parent_pos = path.pages.index page.parent
        # If parent is not in the path then we have a cached path
        if parent_pos.nil?
          path.pages.concat(page.ancestors.reverse)
        else # If parent is in the path then we have a loop

          # remove pages from path
          roots = path.pages.slice! parent_pos, path.pages.length - parent_pos

          # create a tree

          # we remove the parent page to every root and indicate it's a root
          roots.each do |root|
            root.update_attributes :is_root => true, :parent_id => nil
          end

        end

      end
    end

    path

  end

end
