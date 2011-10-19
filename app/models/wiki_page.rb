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

    tree = nil

    wikipage = Wikipedia.find(title)

    page.update_attributes :fetched_at => Time.now

    # If page has a parent or is root we must stop (we can fetch the cached path or it's a loop)
    # If there's no page... we reached the end of the road
    while page.parent_id.blank? and !page.is_root
      
      path.pages << page

      first_link_title = wikipage.content
      first_link_title.gsub!("\n", "")
      # We must get rid of infoboxes, metadata and Image and FIle links before we get the link title
      first_link_title.gsub!(%r{(?<re>\{\{(?:(?> [^\{\}]+ )|\g<re>)*\}\})}x, "")

      # We get the whole [[ ... ]] fragments even when they have recursive [[...]] blocks 
      # and then must get the first which doesn't point to a File, Image...
      first_link_title = first_link_title.scan(%r{(?<re>\[\[(?:(?> [^\[\]]+ )|\g<re>)*\]\])}x).flatten.detect{|m| !m.match(/^\[\[[^\]\|].*:/)}
      first_link_title = first_link_title.split("|").first.gsub("]", "").gsub("[", "") unless first_link_title.nil?

      if first_link_title.nil?
        page.update_attributes :is_root => true
        page = nil
      else
        wikipage = Wikipedia.find(first_link_title)

        parent_page = WikiPage.find_by_title(first_link_title)
        parent_page ||= WikiPage.create :url => "", :title => first_link_title, :fetched_at => Time.now, :is_root => false

        page.parent = parent_page
        page.save

        page = parent_page        
      end
    end

    parent_pos = path.pages.index(page.parent) unless page.parent.nil?

    # If parent is not in the path then we have a cached path
    # and the current tree is parent's tree
    if !page.parent.nil? and parent_pos.nil?
   
      path.pages.concat(page.ancestors.reverse)
 
      # I don't understand why page.tree does not work :S
      tree =  WikiTree.find(page.parent.wiki_tree_id)

      path.pages.concat(tree.roots).uniq!
    elsif page.is_root
      
      # I don't understand why page.tree does not work :S
      tree =  WikiTree.find(page.wiki_tree_id.inspect)
      # If page is a root then we should add all the other roots to the path and 
      # the current tree is the root's tree
      path.pages.concat(tree.roots).uniq!

    else
      # If parent is in the path then we have a loop
      # we must get the roots 
      roots = path.pages.slice parent_pos-1, path.pages.length - (parent_pos - 1)

      # create a tree
      tree = WikiTree.create :name => roots.map(&:title).join(" - ")      
      # remove the parent page to every root and indicate it's a root
      roots.reverse.each do |root|
        root.is_root = true
        root.parent_id = nil
        root.save!
      end

    end


    # and now we assign every page to the tree
    path.pages.each do |page|
      page.wiki_tree_id = tree.id
      page.save!
    end


    path

  end

end
