# encoding: utf-8

require 'spec_helper'

describe MTGExtractor::CardExtractor do
  before :each do
    @url = "http://gatherer.wizards.com?multiverseid=0"
    @card_extractor = MTGExtractor::CardExtractor.new(@url)
  end

  describe '#extract_multiverse_id' do
    it "should extract a card's multiverse ID from the Gatherer url for the card" do
      url = "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=201130" # Krimson Kobolds
      @card_extractor.extract_multiverse_id(url).should == '201130'

      url = "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=889" # Forest (Unlimited v1)
      @card_extractor.extract_multiverse_id(url).should == '889'
    end
  end

  describe '#get_card_details' do
    before :each do
      response = "<html><head><title>Magic I've Gathered</title></head><body><h1>Magic I've Gathered</h1><p>Dude. It's awesome.</p></body></html>"
      RestClient.stub(:get).and_return(response)
    end

    it "should scrape all card details from a Gatherer card web page" do
      RestClient.should_receive(:get).with(@url)
      @card_extractor.should_receive(:build_image_url)
      @card_extractor.should_receive(:extract_name)
      @card_extractor.should_receive(:extract_mana_cost)
      @card_extractor.should_receive(:extract_converted_mana_cost)
      @card_extractor.should_receive(:extract_types)
      @card_extractor.should_receive(:extract_oracle_text)
      @card_extractor.should_receive(:extract_power)
      @card_extractor.should_receive(:extract_toughness)
      @card_extractor.should_receive(:extract_loyalty)
      @card_extractor.should_receive(:extract_rarity)
      @card_extractor.should_receive(:determine_colors)
      @card_extractor.should_receive(:extract_transformed_multiverse_id)
      @card_extractor.should_receive(:extract_artist)
      @card_extractor.should_receive(:extract_expansion_symbol_url)

      @card_extractor.get_card_details
    end
  end

  describe '#build_image_url' do
    it "should build the card's image from the card's multiverse ID" do
      multiverse_id_krimson_kobolds = '201130' # Krimson Kobolds
      @card_extractor.card_details['multiverse_id'] = multiverse_id_krimson_kobolds
      @card_extractor.build_image_url.should == "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{multiverse_id_krimson_kobolds}&type=card"

      multiverse_id_forest = '889' # Forest (Unlimited v1)
      @card_extractor.card_details['multiverse_id'] = multiverse_id_forest
      @card_extractor.build_image_url.should == "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{multiverse_id_forest}&type=card"
    end
  end

  describe '#extract_name' do
    it "should extract a card's name from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('devils_play.html')
      @card_extractor.extract_name.should == "Devil's Play"

      @card_extractor.card_details['page_html'] = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.extract_name.should == "Emrakul, the Aeons Torn"

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_fire.html')
      @card_extractor.extract_name.should == "Fire // Ice"

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.extract_name.should == "Fire // Ice"

      @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_name.should == "Kruin Outlaw"

      @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_name.should == "Terror of Kruin Pass"

      @card_extractor.card_details['page_html'] = read_gatherer_page('village_bell-ringer.html')
      @card_extractor.extract_name.should == "Village Bell-Ringer"
    end
  end

  describe '#multipart_card?' do
    it "should determine whether a card is a multi-part card" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('evil_twin.html')
      @card_extractor.multipart_card?.should be_false

      @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.multipart_card?.should be_false

      @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.multipart_card?.should be_false

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_fire.html')
      @card_extractor.multipart_card?.should be_true

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.multipart_card?.should be_true
    end
  end

  describe '#extract_mana_cost' do
    context 'normal card' do
      it "should determine a card's mana cost from a Gatherer card web page" do
        @card_extractor.card_details['page_html'] = read_gatherer_page('eldrazi_conscription.html')
        @card_extractor.extract_mana_cost.should == '{8}'

        @card_extractor.card_details['page_html'] = read_gatherer_page('forest.html')
        @card_extractor.extract_mana_cost.should be_nil
      end
    end

    context 'multi-part card' do
      it "should determine a card's mana cost from a Gatherer card web page" do
        @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_fire.html')
        @card_extractor.extract_mana_cost.should == '{1}{R}'

        @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_ice.html')
        @card_extractor.extract_mana_cost.should == '{1}{U}'
      end
    end

    context 'double-sided card' do
      it "should determine a card's mana cost from a Gatherer card web page" do
        @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
        @card_extractor.extract_mana_cost.should == '{1}{R}{R}'

        @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
        @card_extractor.extract_mana_cost.should be_nil
      end
    end
  end

  describe '#convert_mana_cost' do
    it "should convert mana cost html into a textual representation" do
      html = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.convert_mana_cost(html).should == '{1}{BR}{BR}{BR}'

      html = read_gatherer_page('blazing_torch.html')
      @card_extractor.convert_mana_cost(html).should == '{1}'

      html = read_gatherer_page('callow_jushi.html')
      @card_extractor.convert_mana_cost(html).should == '{1}{U}{U}'

      html = read_gatherer_page('cover_of_winter.html')
      @card_extractor.convert_mana_cost(html).should == '{2}{W}'

      html = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.convert_mana_cost(html).should == '{0}'

      html = read_gatherer_page('devils_play.html')
      @card_extractor.convert_mana_cost(html).should == '{X}{R}'

      html = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.convert_mana_cost(html).should == '{1}{G}{U}'

      html = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.convert_mana_cost(html).should == '{15}'

      html = read_gatherer_page('forest.html')
      @card_extractor.convert_mana_cost(html).should be_nil

      html = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.convert_mana_cost(html).should == '{1}{B}{B}'

      html = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.convert_mana_cost(html).should == '{4}{RP}{RP}'
    end
  end

  describe '#extract_converted_mana_cost' do
    context 'normal card' do
      it "should determine a card's converted mana cost from a Gatherer card web page" do
        @card_extractor.card_details['page_html'] = read_gatherer_page('eldrazi_conscription.html')
        @card_extractor.extract_converted_mana_cost.should == '8'

        @card_extractor.card_details['page_html'] = read_gatherer_page('forest.html')
        @card_extractor.extract_converted_mana_cost.should be_nil
      end
    end

    context 'multi-part card' do
      it "should determine a card's converted mana cost from a Gatherer card web page" do
        @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_fire.html')
        @card_extractor.extract_converted_mana_cost.should == '2'

        @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_ice.html')
        @card_extractor.extract_converted_mana_cost.should == '2'
      end
    end

    context 'double-sided card' do
      it "should determine a card's mana cost from a Gatherer card web page" do
        @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
        @card_extractor.extract_converted_mana_cost.should == '3'

        @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
        @card_extractor.extract_converted_mana_cost.should be_nil
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
      @card_extractor.card_details['page_html'] = read_gatherer_page('ancient_grudge.html')
      @card_extractor.extract_types.should == ['Instant']

      @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_types.should == ['Creature', 'Human', 'Rogue', 'Werewolf']

      @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_types.should == ['Creature', 'Werewolf']

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.extract_types.should == ['Instant']

      @card_extractor.card_details['page_html'] = read_gatherer_page('forest.html')
      @card_extractor.extract_types.should == ['Basic', 'Land', 'Forest']

      @card_extractor.card_details['page_html'] = read_gatherer_page('gavony_township.html')
      @card_extractor.extract_types.should == ['Land']

      @card_extractor.card_details['page_html'] = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.extract_types.should == ['Legendary', 'Creature', 'Elf', 'Rogue']

      @card_extractor.card_details['page_html'] = read_gatherer_page('eldrazi_conscription.html')
      @card_extractor.extract_types.should == ['Tribal', 'Enchantment', 'Eldrazi', 'Aura']

      @card_extractor.card_details['page_html'] = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_types.should == ['Planeswalker', 'Liliana']

      @card_extractor.card_details['page_html'] = read_gatherer_page('urzas_mine.html')
      @card_extractor.extract_types.should == ['Land', "Urza’s", 'Mine']
    end
  end

  describe '#extract_oracle_text' do
    it "should extract a card's oracle text from a Gatherer card web page" do
      @card_extractor.card_details['multiverse_id'] = '234429'
      @card_extractor.card_details['page_html'] = read_gatherer_page("fortress_crab.html")
      @card_extractor.extract_oracle_text.should == ""

      @card_extractor.card_details['multiverse_id'] = '888'
      @card_extractor.card_details['page_html'] = read_gatherer_page("forest.html")
      @card_extractor.extract_oracle_text.should == "G"

      @card_extractor.card_details['multiverse_id'] = '235600'
      @card_extractor.card_details['page_html'] = read_gatherer_page("ancient_grudge.html")
      @card_extractor.extract_oracle_text.should == "Destroy target artifact.\n\nFlashback {G} (You may cast this card from your graveyard for its flashback cost. Then exile it.)"

      @card_extractor.card_details['multiverse_id'] = '121158'
      @card_extractor.card_details['page_html'] = read_gatherer_page("arctic_flats.html")
      @card_extractor.extract_oracle_text.should == "Arctic Flats enters the battlefield tapped.\n\n{tap}: Add {G} or {W} to your mana pool."

      @card_extractor.card_details['multiverse_id'] = '146065'
      @card_extractor.card_details['page_html'] = read_gatherer_page("ashenmoor_liege.html")
      @card_extractor.extract_oracle_text.should == "Other black creatures you control get +1/+1.\n\nOther red creatures you control get +1/+1.\n\nWhenever Ashenmoor Liege becomes the target of a spell or ability an opponent controls, that player loses 4 life."

      @card_extractor.card_details['multiverse_id'] = '221284'
      @card_extractor.card_details['page_html'] = read_gatherer_page("blazing_torch.html")
      @card_extractor.extract_oracle_text.should == "Equipped creature can't be blocked by Vampires or Zombies.\n\nEquipped creature has \"{tap}, Sacrifice Blazing Torch: Blazing Torch deals 2 damage to target creature or player.\"\n\nEquip {1} ({1}: Attach to target creature you control. Equip only as a sorcery.)"

      @card_extractor.card_details['multiverse_id'] = '74489'
      @card_extractor.card_details['page_html'] = read_gatherer_page("callow_jushi.html")
      @card_extractor.extract_oracle_text.should == "Whenever you cast a Spirit or Arcane spell, you may put a ki counter on Callow Jushi.\n\nAt the beginning of the end step, if there are two or more ki counters on Callow Jushi, you may flip it.\n\n----\n\nJaraku the Interloper\n\nLegendary Creature — Spirit\n\n3/4\n\nRemove a ki counter from Jaraku the Interloper: Counter target spell unless its controller pays {2}."

      @card_extractor.card_details['multiverse_id'] = '121140'
      @card_extractor.card_details['page_html'] = read_gatherer_page("cover_of_winter.html")
      @card_extractor.extract_oracle_text.should == "Cumulative upkeep {snow} (At the beginning of your upkeep, put an age counter on this permanent, then sacrifice it unless you pay its upkeep cost for each age counter on it. {snow} can be paid with one mana from a snow permanent.)\n\nIf a creature would deal combat damage to you and/or one or more creatures you control, prevent X of that damage, where X is the number of age counters on Cover of Winter.\n\n{snow}: Put an age counter on Cover of Winter."

      @card_extractor.card_details['multiverse_id'] = '201130'
      @card_extractor.card_details['page_html'] = read_gatherer_page("crimson_kobolds.html")
      @card_extractor.extract_oracle_text.should == ""

      @card_extractor.card_details['multiverse_id'] = '247419'
      @card_extractor.card_details['page_html'] = read_gatherer_page("devils_play.html")
      @card_extractor.extract_oracle_text.should == "Devil's Play deals X damage to target creature or player.\n\nFlashback {X}{R}{R}{R} (You may cast this card from your graveyard for its flashback cost. Then exile it.)"

      @card_extractor.card_details['multiverse_id'] = '338443'
      @card_extractor.card_details['page_html'] = read_gatherer_page("edric_spymaster_of_trest.html")
      @card_extractor.extract_oracle_text.should == "Whenever a creature deals combat damage to one of your opponents, its controller may draw a card."

      @card_extractor.card_details['multiverse_id'] = '244740'
      @card_extractor.card_details['page_html'] = read_gatherer_page("elbrus_the_binding_blade.html")
      @card_extractor.extract_oracle_text.should == "Equipped creature gets +1/+0.\n\nWhen equipped creature deals combat damage to a player, unattach Elbrus, the Binding Blade, then transform it.\n\nEquip {1}"

      @card_extractor.card_details['multiverse_id'] = '244738'
      @card_extractor.card_details['page_html'] = read_gatherer_page("withengar_unbound.html")
      @card_extractor.extract_oracle_text.should == "Flying, intimidate, trample\n\nWhenever a player loses the game, put thirteen +1/+1 counters on Withengar Unbound."

      @card_extractor.card_details['multiverse_id'] = '193492'
      @card_extractor.card_details['page_html'] = read_gatherer_page("eldrazi_conscription.html")
      @card_extractor.extract_oracle_text.should == "Enchant creature\n\nEnchanted creature gets +10/+10 and has trample and annihilator 2. (Whenever it attacks, defending player sacrifices two permanents.)"

      @card_extractor.card_details['multiverse_id'] = '193452'
      @card_extractor.card_details['page_html'] = read_gatherer_page("emrakul_the_aeons_torn.html")
      @card_extractor.extract_oracle_text.should == "Emrakul, the Aeons Torn can't be countered.\n\nWhen you cast Emrakul, take an extra turn after this one.\n\nFlying, protection from colored spells, annihilator 6\n\nWhen Emrakul is put into a graveyard from anywhere, its owner shuffles his or her graveyard into his or her library."

      @card_extractor.card_details['multiverse_id'] = '87599'
      @card_extractor.card_details['page_html'] = read_gatherer_page("erayo_soratami_ascendant.html")
      @card_extractor.extract_oracle_text.should == "Flying\n\nWhenever the fourth spell of a turn is cast, flip Erayo, Soratami Ascendant.\n\n----\n\nErayo's Essence\n\nLegendary Enchantment\n\n1 / 1\n\nWhenever an opponent casts a spell for the first time in a turn, counter that spell."

      @card_extractor.card_details['multiverse_id'] = '87599'
      @card_extractor.card_details['page_html'] = read_gatherer_page("erayo_essence.html")
      @card_extractor.extract_oracle_text.should == "Flying\n\nWhenever the fourth spell of a turn is cast, flip Erayo, Soratami Ascendant.\n\n----\n\nErayo's Essence\n\nLegendary Enchantment\n\n1 / 1\n\nWhenever an opponent casts a spell for the first time in a turn, counter that spell."

      @card_extractor.card_details['multiverse_id'] = '229965'
      @card_extractor.card_details['page_html'] = read_gatherer_page("evil_twin.html")
      @card_extractor.extract_oracle_text.should == "You may have Evil Twin enter the battlefield as a copy of any creature on the battlefield except it gains \"{U}{B}, {tap}: Destroy target creature with the same name as this creature.\""

      @card_extractor.card_details['multiverse_id'] = '259270'
      @card_extractor.card_details['page_html'] = read_gatherer_page("fire-field_ogre.html")
      @card_extractor.extract_oracle_text.should == "First strike\n\nUnearth {U}{B}{R} ({U}{B}{R}: Return this card from your graveyard to the battlefield. It gains haste. Exile it at the beginning of the next end step or if it would leave the battlefield. Unearth only as a sorcery.)"

      @card_extractor.card_details['multiverse_id'] = '292753'
      @card_extractor.card_details['page_html'] = read_gatherer_page("fire_ice_fire.html")
      @card_extractor.extract_oracle_text.should == "Fire deals 2 damage divided as you choose among one or two target creatures and/or players."

      @card_extractor.card_details['multiverse_id'] = '292753'
      @card_extractor.card_details['page_html'] = read_gatherer_page("fire_ice_ice.html")
      @card_extractor.extract_oracle_text.should == "Tap target permanent.\n\nDraw a card."

      @card_extractor.card_details['multiverse_id'] = '233242'
      @card_extractor.card_details['page_html'] = read_gatherer_page("gavony_township.html")
      @card_extractor.extract_oracle_text.should == "{tap}: Add {1} to your mana pool.\n\n{2}{G}{W}, {tap}: Put a +1/+1 counter on each creature you control."

      @card_extractor.card_details['multiverse_id'] = '230792'
      @card_extractor.card_details['page_html'] = read_gatherer_page("grimoire_of_the_dead.html")
      @card_extractor.extract_oracle_text.should == "{1}, {tap}, Discard a card: Put a study counter on Grimoire of the Dead.\n\n{tap}, Remove three study counters from Grimoire of the Dead and sacrifice it: Put all creature cards from all graveyards onto the battlefield under your control. They're black Zombies in addition to their other colors and types."

      @card_extractor.card_details['multiverse_id'] = '244678'
      @card_extractor.card_details['page_html'] = read_gatherer_page("heartless_summoning.html")
      @card_extractor.extract_oracle_text.should == "Creature spells you cast cost {2} less to cast.\n\nCreatures you control get -1/-1."

      @card_extractor.card_details['multiverse_id'] = '241988'
      @card_extractor.card_details['page_html'] = read_gatherer_page("hinterland_harbor.html")
      @card_extractor.extract_oracle_text.should == "Hinterland Harbor enters the battlefield tapped unless you control a Forest or an Island.\n\n{tap}: Add {G} or {U} to your mana pool."

      @card_extractor.card_details['multiverse_id'] = '227084'
      @card_extractor.card_details['page_html'] = read_gatherer_page("kruin_outlaw.html")
      @card_extractor.extract_oracle_text.should == "First strike\n\nAt the beginning of each upkeep, if no spells were cast last turn, transform Kruin Outlaw."

      @card_extractor.card_details['multiverse_id'] = '227090'
      @card_extractor.card_details['page_html'] = read_gatherer_page("terror_of_kruin_pass.html")
      @card_extractor.extract_oracle_text.should == "Double strike\n\nEach Werewolf you control can't be blocked except by two or more creatures.\n\nAt the beginning of each upkeep, if a player cast two or more spells last turn, transform Terror of Kruin Pass."

      @card_extractor.card_details['multiverse_id'] = '235597'
      @card_extractor.card_details['page_html'] = read_gatherer_page("liliana_of_the_veil.html")
      @card_extractor.extract_oracle_text.should == "+1: Each player discards a card.\n\n-2: Target player sacrifices a creature.\n\n-6: Separate all permanents target player controls into two piles. That player sacrifices all permanents in the pile of his or her choice."

      @card_extractor.card_details['multiverse_id'] = '201207'
      @card_extractor.card_details['page_html'] = read_gatherer_page("living_plane.html")
      @card_extractor.extract_oracle_text.should == "All lands are 1/1 creatures that are still lands."

      @card_extractor.card_details['multiverse_id'] = '221892'
      @card_extractor.card_details['page_html'] = read_gatherer_page("llanowar_elves.html")
      @card_extractor.extract_oracle_text.should == "{tap}: Add {G} to your mana pool."

      @card_extractor.card_details['multiverse_id'] = '233051'
      @card_extractor.card_details['page_html'] = read_gatherer_page("moltensteel_dragon.html")
      @card_extractor.extract_oracle_text.should == "({RP} can be paid with either {R} or 2 life.)\n\nFlying\n\n{RP}: Moltensteel Dragon gets +1/+0 until end of turn."

      @card_extractor.card_details['multiverse_id'] = '220387'
      @card_extractor.card_details['page_html'] = read_gatherer_page("skeletal_grimace.html")
      @card_extractor.extract_oracle_text.should == "Enchant creature\n\nEnchanted creature gets +1/+1 and has \"{B}: Regenerate this creature.\""

      @card_extractor.card_details['multiverse_id'] = '222923'
      @card_extractor.card_details['page_html'] = read_gatherer_page("village_bell-ringer.html")
      @card_extractor.extract_oracle_text.should == "Flash (You may cast this spell any time you could cast an instant.)\n\nWhen Village Bell-Ringer enters the battlefield, untap all creatures you control."
    end
  end

  describe '#extract_power' do
    it "should extract a creature's power from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_power.should == "4"

      @card_extractor.card_details['page_html'] = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_power.should == "0"

      @card_extractor.card_details['page_html'] = read_gatherer_page('devils_play.html')
      @card_extractor.extract_power.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.extract_power.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.extract_power.should == "4"

      @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_power.should == "2"

      @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_power.should == "3"

      @card_extractor.card_details['page_html'] = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_power.should be_nil
    end
  end

  describe '#extract_toughness' do
    it "should extract a creature's toughness from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_toughness.should == "1"

      @card_extractor.card_details['page_html'] = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_toughness.should == "1"

      @card_extractor.card_details['page_html'] = read_gatherer_page('devils_play.html')
      @card_extractor.extract_toughness.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.extract_toughness.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.extract_toughness.should == "4"

      @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_toughness.should == "2"

      @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_toughness.should == "3"

      @card_extractor.card_details['page_html'] = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_toughness.should be_nil
    end
  end

  describe '#extract_loyalty' do
    it "should extract a planeswalker's loyalty from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_loyalty.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('liliana_of_the_veil.html')
      @card_extractor.extract_loyalty.should == "3"
    end
  end

  describe '#extract_color_indicator' do
    it "should extract the card's color indicator from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_color_indicator.should == "Red"

      @card_extractor.card_details['page_html'] = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.extract_color_indicator.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_color_indicator.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.extract_color_indicator.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.extract_color_indicator.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('elbrus_the_binding_blade.html')
      @card_extractor.extract_color_indicator.should be_nil

      @card_extractor.card_details['page_html'] = read_gatherer_page('withengar_unbound.html')
      @card_extractor.extract_color_indicator.should == "Black"
    end
  end

  describe '#determine_colors' do
    it "should determine the card's colors from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('blazing_torch.html')
      @card_extractor.determine_colors.should == ""

      @card_extractor.card_details['page_html'] = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.determine_colors.should == "R"

      @card_extractor.card_details['page_html'] = read_gatherer_page('edric_spymaster_of_trest.html')
      @card_extractor.determine_colors.should == "GU"

      @card_extractor.card_details['page_html'] = read_gatherer_page('emrakul_the_aeons_torn.html')
      @card_extractor.determine_colors.should == "" 

      @card_extractor.card_details['page_html'] = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.determine_colors.should == ""

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_fire.html')
      @card_extractor.determine_colors.should == "R"

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.determine_colors.should == "U"

      @card_extractor.card_details['page_html'] = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.determine_colors.should == "BR"

      @card_extractor.card_details['page_html'] = read_gatherer_page('moltensteel_dragon.html')
      @card_extractor.determine_colors.should == "R"
    end
  end

  describe '#extract_rarity' do
    it "should extract the card's rarity from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_rarity.should == "Rare"

      @card_extractor.card_details['page_html'] = read_gatherer_page('crimson_kobolds.html')
      @card_extractor.extract_rarity.should == "Common"

      @card_extractor.card_details['page_html'] = read_gatherer_page('devils_play.html')
      @card_extractor.extract_rarity.should == "Rare"

      @card_extractor.card_details['page_html'] = read_gatherer_page('hinterland_harbor.html')
      @card_extractor.extract_rarity.should == "Rare"

      @card_extractor.card_details['page_html'] = read_gatherer_page('elbrus_the_binding_blade.html')
      @card_extractor.extract_rarity.should == "Mythic Rare"

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire-field_ogre.html')
      @card_extractor.extract_rarity.should == "Uncommon"

      @card_extractor.card_details['page_html'] = read_gatherer_page('forest.html')
      @card_extractor.extract_rarity.should == "Basic Land"
    end
  end

  describe '#extract_transformed_multiverse_id' do
    it "should extract the card's transformed multiverse id from a Gatherer card web page" do
      @card_extractor.card_details['multiverse_id'] = '245247'
      @card_extractor.card_details['page_html'] = read_gatherer_page('forest.html')
      @card_extractor.extract_transformed_multiverse_id.should be_nil

      @card_extractor.card_details['multiverse_id'] = '227084'
      @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_transformed_multiverse_id.should == '227090'

      @card_extractor.card_details['multiverse_id'] = '227090'
      @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_transformed_multiverse_id.should == '227084'
    end
  end

  describe '#extract_artist' do
    it "should extract the card's artist from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('forest.html')
      @card_extractor.extract_artist.should == "James Paick"

      @card_extractor.card_details['page_html'] = read_gatherer_page('kruin_outlaw.html')
      @card_extractor.extract_artist.should == "David Rapoza"

      @card_extractor.card_details['page_html'] = read_gatherer_page('terror_of_kruin_pass.html')
      @card_extractor.extract_artist.should == "David Rapoza"

      @card_extractor.card_details['page_html'] = read_gatherer_page('elbrus_the_binding_blade.html')
      @card_extractor.extract_artist.should == "Eric Deschamps"
    end
  end

  describe '#extract_expansion_symbol_url' do
    it "should extract the url to a card's expansion symbol from a Gatherer card web page" do
      @card_extractor.card_details['page_html'] = read_gatherer_page('llanowar_elves.html')
      @card_extractor.extract_expansion_symbol_url.should == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=2U&size=small&rarity=C'

      @card_extractor.card_details['page_html'] = read_gatherer_page('ashenmoor_liege.html')
      @card_extractor.extract_expansion_symbol_url.should == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=SHM&size=small&rarity=R'

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_fire.html')
      @card_extractor.extract_expansion_symbol_url.should == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=AP&size=small&rarity=U'

      @card_extractor.card_details['page_html'] = read_gatherer_page('fire_ice_ice.html')
      @card_extractor.extract_expansion_symbol_url.should == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=AP&size=small&rarity=U'

      @card_extractor.card_details['page_html'] = read_gatherer_page('elbrus_the_binding_blade.html')
      @card_extractor.extract_expansion_symbol_url.should == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=DKA&size=small&rarity=M'

      @card_extractor.card_details['page_html'] = read_gatherer_page('withengar_unbound.html')
      @card_extractor.extract_expansion_symbol_url.should == 'http://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=DKA&size=small&rarity=M'
    end
  end
end
