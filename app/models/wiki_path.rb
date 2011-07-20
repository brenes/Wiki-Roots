class WikiPath
  attr_reader :pages

  def initialize
    @pages = []
  end

  def distance 
    @pages.length - 1
  end

end