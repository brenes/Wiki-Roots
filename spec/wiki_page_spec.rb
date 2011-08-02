require "spec_helper.rb"

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr/'
  c.stub_with :webmock 
end

describe WikiPage do
    
  it "should trace its own path" do

    VCR.use_cassette('wikipages') do

      page = WikiPage.create! :title => 'List of characters on Scrubs'
      lambda {  page.trace }.should_not raise_error(NoMethodError)
    end

  end

  describe "when tracing a page" do
   
     it "should create a tree" do

      VCR.use_cassette('wikipages') do

        page = WikiPage.create! :title => 'List of characters on Scrubs'
        path = page.trace      
        assert WikiTree.count == 1
        assert_equal WikiTree.first.pages.count, path.pages.count
        assert_equal WikiTree.first.roots.count, path.pages.select{|p| p.is_root}.count

      end

    end

    it "should not follow the 'Image:' or 'File:' links" do

      # 'American English' has an 'Image:' link first which we must not follow
      # If we follow it it will crush
      VCR.use_cassette('wikipages') do

        page = WikiPage.create! :title => 'American English'
        path = page.trace 
        assert path.pages.select{|p| p.title.starts_with?("Image:") or p.title.starts_with?("File:") }.blank?


      end

    end

    it "should mark the last pages as roots" do

      root_pages = ["old persian cuneiform script", "cuneiform"]

      VCR.use_cassette('wikipages') do

        page = WikiPage.create! :title => 'American English'
        page.trace

        root_pages.each do |root_title|
          page = WikiPage.find_by_title(root_title)
          assert !(page.blank?) && page.is_root
        end
      end

    end
  end

end