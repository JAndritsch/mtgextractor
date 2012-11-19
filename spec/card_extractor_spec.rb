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

      html = read_gatherer_page('fire_ice_fire.html')
      @card_extractor.extract_name(html).should == "Fire // Ice"

      html = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.extract_name(html).should == "Fire // Ice"

      html = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_name(html).should == "Kruin Outlaw"

      html = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_name(html).should == "Terror of Kruin Pass"

      html = read_gatherer_page('village_bell-ringer.html')
      @card_extractor.extract_name(html).should == "Village Bell-Ringer"
    end
  end

  describe '#multipart_card?' do
    it "should determine whether a card is a multi-part card" do
      html = read_gatherer_page('evil_twin.html')
      @card_extractor.multipart_card?(html).should be_false

      html = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.multipart_card?(html).should be_false

      html = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.multipart_card?(html).should be_false

      html = read_gatherer_page('fire_ice_fire.html')
      @card_extractor.multipart_card?(html).should be_true

      html = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.multipart_card?(html).should be_true
    end
  end

  describe '#extract_mana_cost' do
    before :each do
      @card_extractor.stub(:extract_name)
      @card_extractor.stub(:convert_mana_cost)
    end

    context 'normal card' do
      it "should determine a card's mana cost from a Gatherer card web page" do
        html = read_gatherer_page('eldrazi_conscription.html')
        @card_extractor.should_receive(:extract_name).with(html)
        @card_extractor.should_receive(:convert_mana_cost)
        @card_extractor.extract_mana_cost(html)

        html = read_gatherer_page('forest.html')
        @card_extractor.should_receive(:extract_name).with(html)
        @card_extractor.should_not_receive(:convert_mana_cost)
        @card_extractor.extract_mana_cost(html)
      end
    end

    context 'multi-part card' do
      it "should determine a card's mana cost from a Gatherer card web page" do
        html = read_gatherer_page('fire_ice_fire.html')
        @card_extractor.should_not_receive(:extract_name).with(html)
        @card_extractor.should_receive(:convert_mana_cost)
        @card_extractor.extract_mana_cost(html)

        html = read_gatherer_page('fire_ice_ice.html')
        @card_extractor.should_not_receive(:extract_name).with(html)
        @card_extractor.should_receive(:convert_mana_cost)
        @card_extractor.extract_mana_cost(html)
      end
    end

    context 'double-sided card' do
      # NOTE: Using a regex to simulate grabbing the correct mana cost section
      # on a double-sided card's Gatherer page.
      it "should determine a card's mana cost from a Gatherer card web page" do
        name = 'Kruin Outlaw'
        html = read_gatherer_page('kruin_outlaw.html')
        card_section_regex = /(Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Types:)/m
        card_section = html.match(card_section_regex)[1]

        @card_extractor.should_receive(:extract_name).with(card_section)
        @card_extractor.should_receive(:convert_mana_cost)
        @card_extractor.extract_mana_cost(card_section)

        name = 'Terror of Kruin Pass'
        html = read_gatherer_page('terror_of_kruin_pass.html')
        card_section_regex = /(Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Types:)/m
        card_section = html.match(card_section_regex)[1]

        @card_extractor.should_receive(:extract_name).with(card_section)
        @card_extractor.should_not_receive(:convert_mana_cost)
        @card_extractor.extract_mana_cost(card_section)
      end
    end
  end

  describe '#convert_mana_cost' do
    it "should convert mana cost html into a textual representation" do
      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.convert_mana_cost(html).should == ["1", "BR", "BR", "BR"]

      html = read_gatherer_page('blazing_torch.html')
      @card_extractor.convert_mana_cost(html).should == ["1"]

      html = read_gatherer_page('callow_jushi.html')
      @card_extractor.convert_mana_cost(html).should == ["1", "U", "U"]

      html = read_gatherer_page('cover_of_winter.html')
      @card_extractor.convert_mana_cost(html).should == ["2", "W"]

      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.convert_mana_cost(html).should == ["0"]

      html = read_gatherer_page('devils_play.html')
      @card_extractor.convert_mana_cost(html).should == ["X", "R"]

      html = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.convert_mana_cost(html).should == ["1", "G", "U"]

      html = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.convert_mana_cost(html).should == ["15"]

      html = read_gatherer_page('forest.html')
      @card_extractor.convert_mana_cost(html).should be_nil

      html = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.convert_mana_cost(html).should == ["1", "B", "B"]

      html = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.convert_mana_cost(html).should == ["4", "RP", "RP"]
    end
  end

  describe '#extract_converted_mana_cost' do
    before :each do
      @card_extractor.stub(:extract_name)
      @card_extractor.stub(:convert_converted_mana_cost)
    end

    context 'normal card' do
      it "should determine a card's converted mana cost from a Gatherer card web page" do
        html = read_gatherer_page('eldrazi_conscription.html')
        @card_extractor.should_receive(:extract_name).with(html)
        @card_extractor.should_receive(:convert_converted_mana_cost)
        @card_extractor.extract_converted_mana_cost(html)

        html = read_gatherer_page('forest.html')
        @card_extractor.should_receive(:extract_name).with(html)
        @card_extractor.should_not_receive(:convert_converted_mana_cost)
        @card_extractor.extract_converted_mana_cost(html)
      end
    end

    context 'multi-part card' do
      it "should determine a card's converted mana cost from a Gatherer card web page" do
        html = read_gatherer_page('fire_ice_fire.html')
        @card_extractor.should_not_receive(:extract_name).with(html)
        @card_extractor.should_receive(:convert_converted_mana_cost)
        @card_extractor.extract_converted_mana_cost(html)

        html = read_gatherer_page('fire_ice_ice.html')
        @card_extractor.should_not_receive(:extract_name).with(html)
        @card_extractor.should_receive(:convert_converted_mana_cost)
        @card_extractor.extract_converted_mana_cost(html)
      end
    end

    context 'double-sided card' do
      # NOTE: Using a regex to simulate grabbing the correct mana cost section
      # on a double-sided card's Gatherer page.
      it "should determine a card's mana cost from a Gatherer card web page" do
        name = 'Kruin Outlaw'
        html = read_gatherer_page('kruin_outlaw.html')
        card_section_regex = /(Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Types:)/m
        card_section = html.match(card_section_regex)[1]

        @card_extractor.should_receive(:extract_name).with(card_section)
        @card_extractor.should_receive(:convert_converted_mana_cost)
        @card_extractor.extract_converted_mana_cost(card_section)

        name = 'Terror of Kruin Pass'
        html = read_gatherer_page('terror_of_kruin_pass.html')
        card_section_regex = /(Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Types:)/m
        card_section = html.match(card_section_regex)[1]

        @card_extractor.should_receive(:extract_name).with(card_section)
        @card_extractor.should_not_receive(:convert_converted_mana_cost)
        @card_extractor.extract_converted_mana_cost(card_section)
      end
    end
  end

  describe '#convert_converted_mana_cost' do
    it "should convert converted mana cost html into a textual representation" do
      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.convert_converted_mana_cost(html).should == "4"

      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.convert_converted_mana_cost(html).should == "0"

      html = read_gatherer_page('devils_play.html')
      @card_extractor.convert_converted_mana_cost(html).should == "1"

      html = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.convert_converted_mana_cost(html).should == "0"

      html = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.convert_converted_mana_cost(html).should == "6"
    end
  end

  describe '#extract_types' do
    it "should extract all of a card's types from a Gatherer card web page" do
      html = read_gatherer_page('ancient_grudge.html')
      @card_extractor.extract_types(html).should == "Instant"
      # TODO: Break returned type string into individual pieces?
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
      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_power(html).should == "4"

      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_power(html).should == "0"

      html = read_gatherer_page('devils_play.html')
      @card_extractor.extract_power(html).should be_nil

      html = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.extract_power(html).should be_nil

      html = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.extract_power(html).should == "4"
    end
  end

  describe '#extract_toughness' do
    it "should extract a creature's toughness from a Gatherer card web page" do
      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_toughness(html).should == "1"

      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_toughness(html).should == "1"

      html = read_gatherer_page('devils_play.html')
      @card_extractor.extract_toughness(html).should be_nil

      html = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.extract_toughness(html).should be_nil

      html = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.extract_toughness(html).should == "4"
    end
  end

  describe '#extract_loyalty' do
    it "should extract a planeswalker's loyalty from a Gatherer card web page" do
      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_loyalty(html).should be_nil

      html = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_loyalty(html).should == "3"
    end
  end

  describe '#extract_color_indicator' do
    it "should extract the card's color indicator from a Gatherer card web page" do
      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_color_indicator(html).should == "Red"

      html = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.extract_color_indicator(html).should be_nil
    end
  end

  describe '#determine_colors' do
    it "should determine the card's colors from a Gatherer card web page" do
      @card_extractor.determine_colors('mana_cost' => ["1", "W", "R"]).should =~ ["W", "R"]
      @card_extractor.determine_colors('mana_cost' => ["0"]).should == ["colorless"]
      @card_extractor.determine_colors('mana_cost' => ["1"], 'color_indicator' => 'Red').should == ["R"]
    end
  end

  describe '#extract_rarity' do
    it "should extract the card's rarity from a Gatherer card web page" do
      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_rarity(html).should == "Rare"

      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_rarity(html).should == "Common"

      html = read_gatherer_page('devils_play.html')
      @card_extractor.extract_rarity(html).should == "Rare"

      html = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.extract_rarity(html).should == "Rare"

      html = read_gatherer_page('forest.html')
      @card_extractor.extract_rarity(html).should == "Basic Land"
    end
  end
end
