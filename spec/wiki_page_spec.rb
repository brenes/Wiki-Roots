require "spec_helper.rb"

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr/'
  c.stub_with :webmock 
end

describe WikiPage do
    
  it "should trace its own path" do

    VCR.use_cassette('wikipages') do
      page = WikiPage.create :url => 'http://en.wikipedia.org/wiki/List_of_characters_on_Scrubs'
      path = page.trace      
    end

  end

end