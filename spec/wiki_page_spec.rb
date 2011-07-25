require "spec_helper.rb"

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr/'
  c.stub_with :webmock 
end

describe WikiPage do
    
  it "should trace its own path" do

    VCR.use_cassette('wikipages') do

      WebMock.disable_net_connect!(:net_http_connect_on_start => true)

      page = WikiPage.create! :title => 'List of characters on Scrubs'
      path = page.trace      
    end

  end

  it "should not follow the 'Image:' or 'File:' links" do

    # 'American English' has an 'Image:' link first which we must not follow
    # If we follow it it will crush
    VCR.use_cassette('wikipages') do

      WebMock.disable_net_connect!(:net_http_connect_on_start => true)

      page = WikiPage.create! :title => 'American English'
      lambda {  page.trace }.should_not raise_error(NoMethodError)

    end

  end

  it "should mark the last pages as roots" do

    root_pages = ["old persian cuneiform script", "cuneiform"]

    VCR.use_cassette('wikipages') do

      WebMock.disable_net_connect!(:net_http_connect_on_start => true)

      page = WikiPage.create! :title => 'American English'
      page.trace

      root_pages.each do |root_title|
        page = WikiPage.find_by_title(root_title)
        assert !(page.blank?) && page.is_root
      end
    end

  end

end