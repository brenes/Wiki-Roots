module ApplicationHelper

  def url_to_wikipedia path
    "#{Settings["wikipedia_domain"]}#{path}"
  end

end
