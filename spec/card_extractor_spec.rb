require_relative '../card_extractor'
include RSpec::Matchers

SUPPORT_DIR = File.expand_path("support", File.dirname(__FILE__))
def read_gatherer_page(filename)
  File.open("#{SUPPORT_DIR}/#{filename}", "r") {|f| f.read }
end

describe 'CardExtractor' do
  before :each do
    @url = "http://www.magicihavegathered.com"
    @card_extractor = CardExtractor.new(@url)
  end

  describe '#get_card_details' do
    before :each do
      @response = "<html><head><title>Magic I've Gathered</title></head><body><h1>Magic I've Gathered</h1><p>Dude. It's awesome.</p></body></html>"
      RestClient.stub(:get).and_return(@response)
    end

    it "should scrape all card details from a Gatherer card web page" do
      RestClient.should_receive(:get).with(@url)
      @card_extractor.should_receive(:extract_multiverse_id).with(@url)
      @card_extractor.should_receive(:build_image_url)
      @card_extractor.should_receive(:extract_name).with(@response)
      @card_extractor.should_receive(:extract_mana_cost).with(@response)
      @card_extractor.should_receive(:extract_converted_mana_cost).with(@response)
      @card_extractor.should_receive(:extract_types).with(@response)
      @card_extractor.should_receive(:extract_oracle_text).with(@response)
      @card_extractor.should_receive(:extract_power).with(@response)
      @card_extractor.should_receive(:extract_toughness).with(@response)
      @card_extractor.should_receive(:extract_loyalty).with(@response)
      @card_extractor.should_receive(:extract_color_indicator).with(@response)
      @card_extractor.should_receive(:extract_rarity).with(@response)
      @card_extractor.should_receive(:determine_colors)

      @card_extractor.get_card_details
    end
  end

  describe '#extract_multiverse_id' do
    it "should extract a card's multiverse ID from the Gatherer url for the card" do
      url = "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=201130" # Krimson Kobolds
      @card_extractor.extract_multiverse_id(url).should == '201130'

      url = "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=889" # Forest (Unlimited v1)
      @card_extractor.extract_multiverse_id(url).should == '889'
    end
  end

  describe '#build_image_url' do
    it "should build the card's image from the card's multiverse ID" do
      multiverse_id_krimson_kobolds = '201130' # Krimson Kobolds
      @card_extractor.build_image_url(multiverse_id_krimson_kobolds).should == "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{multiverse_id_krimson_kobolds}&type=card"

      multiverse_id_forest = '889' # Forest (Unlimited v1)
      @card_extractor.build_image_url(multiverse_id_forest).should == "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{multiverse_id_forest}&type=card"
    end
  end

  describe '#extract_name' do
    it "should extract a card's name from a Gatherer card web page" do
      html = read_gatherer_page('devils_play.html')
      @card_extractor.extract_name(html).should == "Devil's Play"

      html = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.extract_name(html).should == "Emrakul, the Aeons Torn"

      html = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_name(html).should == "Kruin Outlaw"

      html = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_name(html).should == "Terror of Kruin Pass"

      html = read_gatherer_page('village_bell-ringer.html')
      @card_extractor.extract_name(html).should == "Village Bell-Ringer"
    end
  end

  describe '#extract_mana_cost' do
    it "should determine a card's mana cost from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_converted_mana_cost' do
    it "should determine a card's converted mana cost from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_types' do
    it "should extract all of a card's types from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_oracle_text' do
    it "should extract a card's oracle text from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_power' do
    it "should extract a creature's power from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_toughness' do
    it "should extract a creature's toughness from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_loyalty' do
    it "should extract a planeswalker's loyalty from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_color_indicator' do
    it "should extract the card's color indicator from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#determine_colors' do
    it "should determine the card's colors from a Gatherer card web page" do
      true.should be_false
    end
  end

  describe '#extract_rarity' do
    it "should extract the card's rarity from a Gatherer card web page" do
      true.should be_false
    end
  end
end
