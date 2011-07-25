require "spec_helper.rb"

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr/'
  c.stub_with :webmock 
end

describe WikiPage do
    
  it "should trace its own path" do

    VCR.use_cassette('wikipages') do

      WebMock.allow_net_connect!(:net_http_connect_on_start => true)

      page = WikiPage.create! :title => 'List of characters on Scrubs'
      path = page.trace      
    end

  end

  it "should not follow the 'Image:' or 'File:' links" do

    # 'American English' has an 'Image:' link first which we must not follow
    # If we follow it it will crush
    VCR.use_cassette('wikipages') do

      WebMock.allow_net_connect!(:net_http_connect_on_start => true)

      page = WikiPage.create! :title => 'American English'
      lambda {  page.trace }.should_not raise_error(NoMethodError)

    end

  end

end