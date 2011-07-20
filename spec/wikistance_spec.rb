require 'wikistance'

valid_url      = 'http://en.wikipedia.org/wiki/List_of_characters_on_Scrubs'
philosophy_url = 'http://en.wikipedia.org/wiki/Philosophy' 


describe WikiStance do
  
  it "should raise error with invalid URL" do
    lambda { WikiStance.new('wadus') }.should raise_error(ArgumentError)
  end
  
  it "should create a valid object with a valid URL" do
    wiki = WikiStance.new(valid_url)
    wiki.should be_instance_of WikiStance
  end

  it "should fetch the title of the page" do
    wiki = WikiStance.new(valid_url)
    wiki.title.should == "List of characters on Scrubs"
  end
  
  it "should have no distance from Philosophy" do
    wiki = WikiStance.new(philosophy_url)
    wiki.trace
    wiki.distance.should == 0
  end
  
  it "should have one of distance from Modern Philosophy" do
    wiki = WikiStance.new('http://en.wikipedia.org/wiki/Modern_philosophy')
    wiki.trace
    wiki.distance.should == 1
  end
  
  it "should have trails for Moder Philosophy" do
    wiki = WikiStance.new('http://en.wikipedia.org/wiki/Modern_philosophy')
    wiki.trace
    wiki.breadcrumbs.should == ['Modern philosophy', 'Philosophy']
  end
  
  # Greek_language comes back to itself becase of links between parens
  it "should not repeat pages" do
    wiki = WikiStance.new('http://en.wikipedia.org/wiki/Greek_language')
    lambda { wiki.trace }.should_not raise_error(RuntimeError)
  end
  
  # Psychologist first link is an anchor to the same page
  it "should avoid #anchor links" do
    wiki = WikiStance.new('http://en.wikipedia.org/wiki/Psychologist')
    wiki.trace.should be_true
    wiki.distance.should == 12
  end
  
end
