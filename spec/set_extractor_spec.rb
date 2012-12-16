# encoding: utf-8

require 'spec_helper'

describe MTGExtractor::SetExtractor do

  describe "initialize" do
    let (:extractor) { MTGExtractor::SetExtractor }
    it "should accept a set name and have two attributes" do
      extractor.new("Apocalypse").should respond_to(:url)
      extractor.new("Apocalypse").should respond_to(:name)
    end
    it "should set the name to the name passed in" do
      extractor.new("Apocalypse").name.should == "Apocalypse"
    end
    it "should build the URL to the Gatherer page for that set" do
      dark_ascension_url = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?output=checklist&set=[%22Dark%20Ascension%22]'
      extractor.new("Dark Ascension").url.should == dark_ascension_url
    end
  end

  describe "#get_card_urls" do
    let (:extractor) { MTGExtractor::SetExtractor.new("Dark Ascension") }
    let (:page_html) { read_gatherer_page("dark_ascension.html") }
    before do 
      RestClient.stub(:get).and_return(page_html)
    end
    it "should make a request to get the page html for that set" do
      RestClient.should_receive(:get).with(extractor.url)
      extractor.get_card_urls
    end
    it "should extract the individual card urls from the returned html" do
      extractor.should_receive(:extract_card_urls).with(page_html)
      extractor.get_card_urls
    end
  end

  describe "#extract_card_urls" do
    let (:extractor) { MTGExtractor::SetExtractor.new("Dark Ascension") }
    let (:page_html) { read_gatherer_page("dark_ascension.html") }
    let (:dark_ascension_count) { 171 }
    it "should return an array of card urls for every card in that set" do
      extractor.extract_card_urls(page_html).count.should == dark_ascension_count
    end
  end

  describe "self.get_all_sets" do
    # Note: This test is using a cached version of Gatherer's home page, so it's likely
    # that this data will be outdated sometime soon. Regardless, the concepts are the same.
    let (:extractor) { MTGExtractor::SetExtractor }
    let (:page_html) { read_gatherer_page("gatherer_home_page.html") }
    let (:gatherer_home_page) { 'http://gatherer.wizards.com/Pages/Default.aspx' }
    let (:total_sets) { 114 }
    before do 
      RestClient.stub(:get).and_return(page_html)
    end
    it "should request to get the page html for the gatherer home page" do
      RestClient.should_receive(:get).with(gatherer_home_page)
      extractor.get_all_sets
    end
    it "should return an alphabetically sorted array of all sets available" do
      all_sets = extractor.get_all_sets
      all_sets.first.should == "Alara Reborn"
      all_sets.last.should == "Zendikar"
      all_sets.count.should == total_sets
    end
  end

end
