require 'wikipedia'

class WikiPage < ActiveRecord::Base
  has_ancestry

  belongs_to :tree, :class_name => "WikiTree"

  before_save :title_to_downcase

  scope :roots, where("is_root")

  def title_to_downcase
    title.downcase
  end


  # For tracing we must search for the end of the road or a loop
  def trace
    
    path = WikiPath.new
    
    page = self

    wikipage = Wikipedia.find(title)

    page.update_attributes :fetched_at => Time.now

    # If page has a parent we must stop (we can fetch the cached path or it's a loop)
    # If there's no page... we reached the end of the road
    while !page.blank? and page.parent_id.blank? 
      
      path.pages << page
          
      # We must get rid of infoboxes, metadata and Image and FIle links before we get the link title
      first_link_title = wikipage.content.gsub("\n", "").gsub(%r{(?<re>\{\{(?:(?> [^\{\}]+ )|\g<re>)*\}\})}x, "").gsub("[[wikt:", "").gsub("[[Image:", "").gsub("[[File:", "").match(/\[\[[^\]]*\]\]/)[0]
      first_link_title = first_link_title.split("|").first.gsub("]", "").gsub("[", "") unless first_link_title.nil?

      if first_link_title.nil?
        page.update_attributes :is_root => true
        page = nil
      else

        wikipage = Wikipedia.find(first_link_title)

        parent_page = WikiPage.find_by_title(first_link_title)
        parent_page ||= WikiPage.create :url => "", :title => first_link_title, :fetched_at => Time.now

        page.parent = parent_page
        page.save

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
          tree = WikiTree.create :name => roots.map(&:title).join(" - ")

          path.pages.each do |page|
            page.wiki_tree_id = tree.id
            page.save!
          end
          
          # we remove the parent page to every root and indicate it's a root
          roots.reverse.each do |root|
            root.wiki_tree_id = tree.id
            root.is_root = true
            root.parent_id = nil
            root.save
          end

        end

      end
    end

    path

  end

end
