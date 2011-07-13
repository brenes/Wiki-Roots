class WikiPath
  attr_reader :pages

  def initialize
    @pages = []
  end

  def distance 
    @pages.length - 1
  end

  def self.trace url
    path = WikiPath.new

    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    
    html_page = agent.get(url)

    title = html_page.at('#firstHeading').text().downcase

    page = WikiPage.find_by_title(title)

    unless page.blank?
      path.pages << page
      path.pages.concat(page.ancestors.reverse)
        return path
    end

    page ||= WikiPage.create :title => title, :fetched_at => Time.now

    path.pages << page

    while  title != 'philosophy'

      # click_first_link
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

      raise "Oops! seems that \"#{page_title}\" has no links" if first_link.nil?

      html_page = html_page.links_with(:href => /#{first_link[1]}/).first.click

      title = html_page.at('#firstHeading').text().downcase

      
      parent_page = WikiPage.find_by_title(title)

      unless parent_page.blank?
        page.update_attributes :parent_id => parent_page.id
        path.pages << parent_page
        path.pages.concat(parent_page.ancestors.reverse)
        return path
      end

      parent_page ||= WikiPage.create :title => title, :fetched_at => Time.now
      page.update_attributes :parent_id => parent_page.id

      page = parent_page
            
      path.pages << page
    end

    path

  end

  private

  def click_first_link

  end

end