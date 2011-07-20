class WikiPage < ActiveRecord::Base
  has_ancestry



  # For tracing we must search for the end of the road or a loop
  def trace
    
    path = WikiPath.new
    
    page = self

    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'

    # If page has a parent we must stop (we can fetch the cached path or it's a loop)
    # If there's no page... we reached the end of the road
    while !page.blank? and page.parent_id.blank? 
      
      path.pages << page
    
      html_page ||= agent.get(url)

      first_link = nil
    
      # div#bodyContent is where wikipedia shows article's content
      # The starting text is direct child of div#bodyContent. This way we avoid <p> inside TOCs and other texts.
      # We also avoid Disambiguation and other wikipedia texts, (which all of them contains links in italics) because
      # they are in <div> instead of <p>
      html_page.search('#bodyContent > p').each do |p|
        
        # Links between parens should not be clicked
        # I tried using a regex with lookbehind to know if a link has an opening parenthesis before, but ruby doesn't
        # support them, so I will just remove all text between parens...
        text = p.to_html.gsub(/\((?:.*?)\)/, '').gsub(/<i>(?:.*?)<\/i>/, '')

        # ...and then get the first link.
        first_link = text.match(/<a(?:.*?)href\=\"[^#](.*?)\"(?:.*?)\/a>/)
        break unless first_link.nil?
      end

      if first_link.nil?
        page.update_attributes :is_root => true
        page = nil
      else
        html_page = html_page.links_with(:href => /#{first_link[1]}/).first.click

        title = html_page.at('#firstHeading').text().downcase

        parent_page = WikiPage.find_by_title(title)
        parent_page ||= WikiPage.create :url => html_page.uri, :title => title, :fetched_at => Time.now

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
