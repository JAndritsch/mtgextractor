# encoding: utf-8

require 'spec_helper'

describe MTGExtractor::CardExtractor do
  before :each do
    @url = "http://www.magicihavegathered.com"
    @card_extractor = MTGExtractor::CardExtractor.new(@url)
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
      @card_extractor.should_receive(:extract_rarity).with(@response)
      @card_extractor.should_receive(:determine_colors).with(@response)
      @card_extractor.should_receive(:extract_transformed_multiverse_id).with(@response)

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
      @card_extractor.extract_types(html).should == ['Instant']

      html = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_types(html).should == ['Creature', 'Human', 'Rogue', 'Werewolf']

      html = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_types(html).should == ['Creature', 'Werewolf']

      html = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.extract_types(html).should == ['Instant']

      html = read_gatherer_page('forest.html')
      @card_extractor.extract_types(html).should == ['Basic', 'Land', 'Forest']

      html = read_gatherer_page('gavony_township.html')
      @card_extractor.extract_types(html).should == ['Land']

      html = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.extract_types(html).should == ['Legendary', 'Creature', 'Elf', 'Rogue']

      html = read_gatherer_page('eldrazi_conscription.html')
      @card_extractor.extract_types(html).should == ['Tribal', 'Enchantment', 'Eldrazi', 'Aura']

      html = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_types(html).should == ['Planeswalker', 'Liliana']

      html = read_gatherer_page('urzas_mine.html')
      @card_extractor.extract_types(html).should == ['Land', "Urza’s", 'Mine']
    end
  end

  describe '#extract_oracle_text' do
    it "should extract a card's oracle text from a Gatherer card web page" do
      html = read_gatherer_page("fortress_crab.html")
      @card_extractor.extract_oracle_text(html).should == ""

      html = read_gatherer_page("forest.html")
      @card_extractor.extract_oracle_text(html).should == "G"

      html = read_gatherer_page("ancient_grudge.html")
      @card_extractor.extract_oracle_text(html).should == "Destroy target artifact.\n\nFlashback {G} (You may cast this card from your graveyard for its flashback cost. Then exile it.)"

      html = read_gatherer_page("arctic_flats.html")
      @card_extractor.extract_oracle_text(html).should == "Arctic Flats enters the battlefield tapped.\n\n{tap}: Add {G} or {W} to your mana pool."

      html = read_gatherer_page("ashenmoor_liege.html")
      @card_extractor.extract_oracle_text(html).should == "Other black creatures you control get +1/+1.\n\nOther red creatures you control get +1/+1.\n\nWhenever Ashenmoor Liege becomes the target of a spell or ability an opponent controls, that player loses 4 life."

      html = read_gatherer_page("blazing_torch.html")
      @card_extractor.extract_oracle_text(html).should == "Equipped creature can't be blocked by Vampires or Zombies.\n\nEquipped creature has \"{tap}, Sacrifice Blazing Torch: Blazing Torch deals 2 damage to target creature or player.\"\n\nEquip {1} ({1}: Attach to target creature you control. Equip only as a sorcery.)"

      html = read_gatherer_page("callow_jushi.html")
      @card_extractor.extract_oracle_text(html).should == "Whenever you cast a Spirit or Arcane spell, you may put a ki counter on Callow Jushi.\n\nAt the beginning of the end step, if there are two or more ki counters on Callow Jushi, you may flip it.\n\n----\n\nJaraku the Interloper\n\nLegendary Creature — Spirit\n\n3/4\n\nRemove a ki counter from Jaraku the Interloper: Counter target spell unless its controller pays {2}."

      html = read_gatherer_page("cover_of_winter.html")
      @card_extractor.extract_oracle_text(html).should == "Cumulative upkeep {snow} (At the beginning of your upkeep, put an age counter on this permanent, then sacrifice it unless you pay its upkeep cost for each age counter on it. {snow} can be paid with one mana from a snow permanent.)\n\nIf a creature would deal combat damage to you and/or one or more creatures you control, prevent X of that damage, where X is the number of age counters on Cover of Winter.\n\n{snow}: Put an age counter on Cover of Winter."

      html = read_gatherer_page("crimson_kobolds.html")
      @card_extractor.extract_oracle_text(html).should == ""

      html = read_gatherer_page("devils_play.html")
      @card_extractor.extract_oracle_text(html).should == "Devil's Play deals X damage to target creature or player.\n\nFlashback {X}{R}{R}{R} (You may cast this card from your graveyard for its flashback cost. Then exile it.)"

      html = read_gatherer_page("edric_spymaster_of_trest.html")
      @card_extractor.extract_oracle_text(html).should == "Whenever a creature deals combat damage to one of your opponents, its controller may draw a card."

      html = read_gatherer_page("elbrus_the_binding_blade.html")
      @card_extractor.extract_oracle_text(html).should == "Equipped creature gets +1/+0.\n\nWhen equipped creature deals combat damage to a player, unattach Elbrus, the Binding Blade, then transform it.\n\nEquip {1}"

      html = read_gatherer_page("withengar_unbound.html")
      @card_extractor.extract_oracle_text(html).should == "Flying, intimidate, trample\n\nWhenever a player loses the game, put thirteen +1/+1 counters on Withengar Unbound."

      html = read_gatherer_page("eldrazi_conscription.html")
      @card_extractor.extract_oracle_text(html).should == "Enchant creature\n\nEnchanted creature gets +10/+10 and has trample and annihilator 2. (Whenever it attacks, defending player sacrifices two permanents.)"

      html = read_gatherer_page("emrakul_the_aeons_torn.html")
      @card_extractor.extract_oracle_text(html).should == "Emrakul, the Aeons Torn can't be countered.\n\nWhen you cast Emrakul, take an extra turn after this one.\n\nFlying, protection from colored spells, annihilator 6\n\nWhen Emrakul is put into a graveyard from anywhere, its owner shuffles his or her graveyard into his or her library."

      html = read_gatherer_page("erayo_soratami_ascendant.html")
      @card_extractor.extract_oracle_text(html).should == "Flying\n\nWhenever the fourth spell of a turn is cast, flip Erayo, Soratami Ascendant.\n\n----\n\nErayo's Essence\n\nLegendary Enchantment\n\n1 / 1\n\nWhenever an opponent casts a spell for the first time in a turn, counter that spell."

      html = read_gatherer_page("erayo_essence.html")
      @card_extractor.extract_oracle_text(html).should == "Flying\n\nWhenever the fourth spell of a turn is cast, flip Erayo, Soratami Ascendant.\n\n----\n\nErayo's Essence\n\nLegendary Enchantment\n\n1 / 1\n\nWhenever an opponent casts a spell for the first time in a turn, counter that spell."

      html = read_gatherer_page("evil_twin.html")
      @card_extractor.extract_oracle_text(html).should == "You may have Evil Twin enter the battlefield as a copy of any creature on the battlefield except it gains \"{U}{B}, {tap}: Destroy target creature with the same name as this creature.\""

      html = read_gatherer_page("fire-field_ogre.html")
      @card_extractor.extract_oracle_text(html).should == "First strike\n\nUnearth {U}{B}{R} ({U}{B}{R}: Return this card from your graveyard to the battlefield. It gains haste. Exile it at the beginning of the next end step or if it would leave the battlefield. Unearth only as a sorcery.)"

      html = read_gatherer_page("fire_ice_fire.html")
      @card_extractor.extract_oracle_text(html).should == "Fire deals 2 damage divided as you choose among one or two target creatures and/or players."

      html = read_gatherer_page("fire_ice_ice.html")
      @card_extractor.extract_oracle_text(html).should == "Tap target permanent.\n\nDraw a card."

      html = read_gatherer_page("gavony_township.html")
      @card_extractor.extract_oracle_text(html).should == "{tap}: Add {1} to your mana pool.\n\n{2}{G}{W}, {tap}: Put a +1/+1 counter on each creature you control."

      html = read_gatherer_page("grimoire_of_the_dead.html")
      @card_extractor.extract_oracle_text(html).should == "{1}, {tap}, Discard a card: Put a study counter on Grimoire of the Dead.\n\n{tap}, Remove three study counters from Grimoire of the Dead and sacrifice it: Put all creature cards from all graveyards onto the battlefield under your control. They're black Zombies in addition to their other colors and types."

      html = read_gatherer_page("heartless_summoning.html")
      @card_extractor.extract_oracle_text(html).should == "Creature spells you cast cost {2} less to cast.\n\nCreatures you control get -1/-1."

      html = read_gatherer_page("hinterland_harbor.html")
      @card_extractor.extract_oracle_text(html).should == "Hinterland Harbor enters the battlefield tapped unless you control a Forest or an Island.\n\n{tap}: Add {G} or {U} to your mana pool."

      html = read_gatherer_page("kruin_outlaw.html")
      @card_extractor.extract_oracle_text(html).should == "First strike\n\nAt the beginning of each upkeep, if no spells were cast last turn, transform Kruin Outlaw."

      html = read_gatherer_page("terror_of_kruin_pass.html")
      @card_extractor.extract_oracle_text(html).should == "Double strike\n\nEach Werewolf you control can't be blocked except by two or more creatures.\n\nAt the beginning of each upkeep, if a player cast two or more spells last turn, transform Terror of Kruin Pass."

      html = read_gatherer_page("liliana_of_the_veil.html")
      @card_extractor.extract_oracle_text(html).should == "+1: Each player discards a card.\n\n-2: Target player sacrifices a creature.\n\n-6: Separate all permanents target player controls into two piles. That player sacrifices all permanents in the pile of his or her choice."

      html = read_gatherer_page("living_plane.html")
      @card_extractor.extract_oracle_text(html).should == "All lands are 1/1 creatures that are still lands."

      html = read_gatherer_page("llanowar_elves.html")
      @card_extractor.extract_oracle_text(html).should == "{tap}: Add {G} to your mana pool."

      html = read_gatherer_page("moltensteel_dragon.html")
      @card_extractor.extract_oracle_text(html).should == "({RP} can be paid with either {R} or 2 life.)\n\nFlying\n\n{RP}: Moltensteel Dragon gets +1/+0 until end of turn."

      html = read_gatherer_page("skeletal_grimace.html")
      @card_extractor.extract_oracle_text(html).should == "Enchant creature\n\nEnchanted creature gets +1/+1 and has \"{B}: Regenerate this creature.\""

      html = read_gatherer_page("village_bell-ringer.html")
      @card_extractor.extract_oracle_text(html).should == "Flash (You may cast this spell any time you could cast an instant.)\n\nWhen Village Bell-Ringer enters the battlefield, untap all creatures you control."
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

      html = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_power(html).should == "2"

      html = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_power(html).should == "3"

      html = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_power(html).should be_nil
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

      html = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_toughness(html).should == "2"

      html = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_toughness(html).should == "3"

      html = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_toughness(html).should be_nil
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

      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_color_indicator(html).should be_nil

      html = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.extract_color_indicator(html).should be_nil

      html = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.extract_color_indicator(html).should be_nil

      html = read_gatherer_page('elbrus_the_binding_blade.html')
      @card_extractor.extract_color_indicator(html).should be_nil

      html = read_gatherer_page('withengar_unbound.html')
      @card_extractor.extract_color_indicator(html).should == "Black"
    end
  end

  describe '#determine_colors' do
    it "should determine the card's colors from a Gatherer card web page" do
      html = read_gatherer_page('blazing_torch.html')
      @card_extractor.determine_colors(html).should == ""

      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.determine_colors(html).should == "R"

      html = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.determine_colors(html).should == "GU"

      html = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.determine_colors(html).should == "" 

      html = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.determine_colors(html).should == ""

      html = read_gatherer_page('fire_ice_fire.html')
      @card_extractor.determine_colors(html).should == "R"

      html = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.determine_colors(html).should == "U"

      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.determine_colors(html).should == "BR"

      html = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.determine_colors(html).should == "R"
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

      html = read_gatherer_page('elbrus_the_binding_blade.html')
      @card_extractor.extract_rarity(html).should == "Mythic Rare"

      html = read_gatherer_page('fire-field_ogre.html')
      @card_extractor.extract_rarity(html).should == "Uncommon"

      html = read_gatherer_page('forest.html')
      @card_extractor.extract_rarity(html).should == "Basic Land"
    end
  end

  describe '#extract_transformed_multiverse_id' do
    it "should extract the card's transformed multiverse id from a Gatherer card web page" do
      html = read_gatherer_page('forest.html')
      @card_extractor.extract_transformed_multiverse_id(html).should be_nil

      html = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_transformed_multiverse_id(html).should == '227090'

      html = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_transformed_multiverse_id(html).should == '227084'
    end
  end

  describe '#extract_artist' do
    it "should extract the card's artist from a Gatherer card web page" do
      html = read_gatherer_page('forest.html')
      @card_extractor.extract_artist(html).should_not be_nil
    end

  end
  
end
