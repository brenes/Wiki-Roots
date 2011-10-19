require "spec_helper.rb"

VCR.config do |c|
  c.cassette_library_dir = "#{::Rails.root}/spec/vcr/"
  c.stub_with :webmock 
  
end

describe WikiPage do
    
  it "should trace its own path" do

    VCR.use_cassette('wikipages', :record => :new_episodes) do

      page = WikiPage.create! :title => 'List of characters on Scrubs'
      lambda {  page.trace }.should_not raise_error(NoMethodError)
    end

  end

  describe "when tracing a page" do
   
     it "should create a tree" do

      VCR.use_cassette('wikipages', :record => :new_episodes) do
        

        assert_equal WikiPage.count, 0

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
      VCR.use_cassette('wikipages', :record => :new_episodes) do

        page = WikiPage.create! :title => 'American English'
        path = page.trace 
        assert path.pages.select{|p| p.title.starts_with?("Image:") or p.title.starts_with?("File:") }.blank?


      end

    end

    it "should not follow the 'wikt:' links" do

      # 'Hanzi' has a 'wikt:' link first which we must not follow
      # If we follow it it will crush
      VCR.use_cassette('wikipages', :record => :new_episodes) do

        page = WikiPage.create! :title => 'Hanzi'
        lambda {  page.trace }.should_not raise_error(NoMethodError)


      end

    end

    it "should not follow links on Infoboxes when they include some {{}} characters" do

      # "The Royal Anthem of Jordan" page has in its infobox some info between {{}}. This breaks
      # current way of handling infoboxes
      VCR.use_cassette('wikipages', :record => :new_episodes) do

        page = WikiPage.create! :title => "The Royal Anthem of Jordan"
        path = page.trace 
        assert path.pages[1].title != "Abdul Monem Al-Refai"

      end

    end

    it "should not follow the links inside images" do

      # 'Classics' has a link to Homero in an image (Bust of Homero)
      # at the beginning of the article which must not be detected as 
      # the first link on the wikipedia page
      VCR.use_cassette('wikipages', :record => :new_episodes) do

        page = WikiPage.create! :title => 'Classics'
        path = page.trace 
        assert_not_equal path.pages[1].title, "Homer"

      end

    end

    it "should mark the last pages as roots" do
      root_pages = ["Indo-European languages", "language family", "language", "human", "taxonomy", "science", "knowledge", "fact", "Latin", "Italic language"]

      VCR.use_cassette('wikipages', :record => :new_episodes) do

        page = WikiPage.create! :title => 'American English'
        page.trace

        root_pages.each do |root_title|
          page = WikiPage.find_by_title(root_title)
          assert !(page.blank?) && page.is_root, "Page is #{page.inspect}"
        end
      end

    end
  end

  describe "when tracing two pages" do
   
     it "should only create a tree if they share the tree" do

      VCR.use_cassette('wikipages', :record => :new_episodes) do
        
        page = WikiPage.create! :title => 'Cheers'
        first_path = page.trace

        assert_equal WikiTree.count, 1

        page = WikiPage.create! :title => 'Frasier'
        second_path = page.trace

        first_path.pages.select{|p| p.is_root}.each do |page|
          assert second_path.pages.include?(page), "Some root on the first path is not in the second path (and they should share roots). If this tests is failing we should search for another example on pages sharing roots"
        end
        
        assert_equal WikiTree.count, 1, "A Tree has been created when tracing the second page (and it shouldn't)"
      end

    end

    it "should only create a tree if they share the root" do

      VCR.use_cassette('wikipages', :record => :new_episodes) do
        
        page = WikiPage.create! :title => 'Cheers'
        first_path = page.trace

        assert_equal WikiTree.count, 1

        page = WikiPage.create! :title => 'Oviedo'
        second_path = page.trace

        first_path.pages.select{|p| p.is_root}.each do |page|
          assert second_path.pages.include?(page), "Some root on the first path is not in the second path (and they should share roots). If this tests is failing we should search for another example on pages sharing roots"
        end
        
        assert_equal WikiTree.count, 1, "A Tree has been created when tracing the second page (and it shouldn't)"
      end

    end

  end

end