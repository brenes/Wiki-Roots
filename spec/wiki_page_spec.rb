require "spec_helper.rb"

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr/'
  c.stub_with :webmock 
end

describe WikiPage do
    
  it "should trace its own path" do

    VCR.use_cassette('wikipages') do


  WebMock.allow_net_connect!(:net_http_connect_on_start => true)
      page = WikiPage.create :title => 'List of characters on Scrubs'
      path = page.trace      
      puts path.pages.map(&:title)
    end

  end

end