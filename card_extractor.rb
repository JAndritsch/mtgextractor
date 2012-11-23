# encoding: utf-8

require 'restclient'

# Scrapes a Gatherer card details page and extracts card info
# Issues:
#
#   It can't read oracle texts that follow the pattern "Words {image}". It is only
#   currently set up to handle "{image}: Words".
#
#   NOTE: Cards that "flip" (e.g., Akki Lavarunner, Kitsune Mystic, 
#   Callow Jushi) are not handled consistently in Gatherer. We will not try to
#   improve upon this tragedy; some things will therefore remain unsearchable.
#

class CardExtractor
  
  attr_accessor :url

  def initialize(url)
    @url = url
  end

  def get_card_details
    response = RestClient.get(@url)
    card_details = {}
    card_details['gatherer_url']     = @url
    card_details['multiverse_id']    = extract_multiverse_id(@url)
    card_details['image_url']        = build_image_url(card_details['multiverse_id'])

    card_details['expansion']        = extract_expansion(response)
    card_details['name']             = extract_name(response)
    card_details['mana_cost']        = extract_mana_cost(response)
    card_details['converted_cost']   = extract_converted_mana_cost(response)
    card_details['types']            = extract_types(response)
    card_details['oracle_text']      = extract_oracle_text(response)
    card_details['power']            = extract_power(response)
    card_details['toughness']        = extract_toughness(response)
    card_details['loyalty']          = extract_loyalty(response)
    card_details['rarity']           = extract_rarity(response)
    card_details['colors']           = determine_colors(response)
    card_details['transformed_id']   = extract_transformed_multiverse_id(response)

    card_details
  end

  def extract_multiverse_id(url)
    url.match(/multiverseid=(\d+)/)[1]
  end

  def build_image_url(id)
    "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{id}&type=card"
  end

  def extract_expansion(html)
    expansion_regex = /<div id="[^"]+?_currentSetSymbol">.+?<a href="\/Pages\/Search\/Default.aspx\?action=advanced&amp;set=[^"]+">([^<]+)/m
    html.match(expansion_regex)[1]
  end

  def extract_name(html)
    match_data = /<span id="ctl00_ctl00_ctl00_MainContent_SubContent_SubContentHeader_subtitleDisplay"[^>]*>([^<]+)/
    html.match(match_data)[1]
  end

  def multipart_card?(html)
    html.match(/This is one part of the multi-part card/) != nil
  end

  def extract_mana_cost(html)
    # Gatherer displays both sides of double-sided cards (e.g., Kruin Outlaw
    # and Terror of Kruin Pass) on the same page, yet the "back" side of such,
    # cards doesn't have a mana cost. Thus, we must associate the mana cost
    # block with the actual block on the page associated with the "front" side,
    # of the card. We do this by finding the name of the card in the summary
    # display section on the Gatherer page.
    #
    # However, Gatherer displays multi-part cards (e.g., Fire // Ice) with each
    # "mini-card" on its own page, named by that specific mini-card. (I.e., Fire
    # gets its own page, and Ice gets its own page.) So the Gatherer name for
    # the card is inaccurate for this purpose.
    #
    # Solution: identify multi-part cards, and pull the mana cost out simply for
    # these cards, because there will be only one mana cost block on the page.
    # All other cards, allow for the possibility that it's a double-sided card.
    if multipart_card?(html)
      mana_cost = convert_mana_cost(html)
    else
      name = extract_name(html)
      mana_cost_group_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Mana Cost:.+?<div[^>]*>(.+?)<\/div>/m
      mana_cost_group = html.match(mana_cost_group_regex)
      mana_cost = mana_cost_group ? convert_mana_cost(mana_cost_group[1]) : nil
    end
    mana_cost
  end

  def convert_mana_cost(html)
    mana_cost_regex = /<img src="\/Handlers\/Image\.ashx\?size=medium&amp;name=([a-zA-Z0-9]+)&amp/
    match = html.scan(mana_cost_regex).flatten
    match.length > 0 ? match : nil
  end

  def extract_converted_mana_cost(html)
    # See remarks for #extract_mana_cost, above. Similar processing with respect
    # to double-sided cards is necessary here as well.
    if multipart_card?(html)
      cmc = convert_converted_mana_cost(html)
    else
      name = extract_name(html)
      cmc_group_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Converted Mana Cost:<\/div>\s+<div[^>]*>[^<]+/m
      cmc_group = html.match(cmc_group_regex)
      cmc = cmc_group ? convert_converted_mana_cost(cmc_group[0]) : nil
    end
    cmc
  end

  def convert_converted_mana_cost(html)
    cmc_regex = /Converted Mana Cost:<\/div>\s+<div[^>]*>\s+(\d+)/
    match = html.match(cmc_regex)
    match ? match[1] : "0"
  end

  def extract_types(html)
    html = html.force_encoding("utf-8")
    if multipart_card?(html)
      card_types_regex = /Types:<\/div>\s+<div class="value">\s+([a-zA-Z\s-—]+)<\/div>/
    else
      name = extract_name(html)
      card_types_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Types:<\/div>\s+<div class="value">\s+([a-zA-Z\s-—]+)<\/div>)/m
    end
    card_types = html.match(card_types_regex)[1]
    if card_types
      card_types.split("—").collect {|type| type.strip.split(/\s+/)}.flatten
    else
      card_types
    end
  end

  def extract_oracle_text(html)
    match_data = /<div class="cardtextbox">(?:<img src="\/Handlers\/Image\.ashx\?size=small&amp;name=\w+&amp;type=symbol" alt="\w+" align="absbottom" \/>)*:*([^>]+)<\/div>/
    match = html.scan(match_data).flatten
    match.length > 0 ? match.join("\n") : ""
  end

  def extract_printed_text(html)
    # TODO
  end

  def extract_power(html)
    name = extract_name(html)
    creature_power_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?P\/T:<\/div>\s+<div class="value">\s+(\d+) \/ \d+)/m
    match = html.match(creature_power_regex)
    match ? match[1] : nil
  end

  def extract_toughness(html)
    name = extract_name(html)
    creature_toughness_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?P\/T:<\/div>\s+<div class="value">\s+\d+ \/ (\d+))/m
    match = html.match(creature_toughness_regex)
    match ? match[1] : nil
  end

  def extract_loyalty(html)
    match_data = /Loyalty:<\/div>\s+<div class="value">\s+(\w+)<\/div>/
    match = html.match(match_data)
    match ? match[1] : nil
  end

  def extract_color_indicator(html)
    match_data = /Color Indicator:<\/div>\s+<div[^>]*>\s+(\w+)/
    match = html.match(match_data)
    match ? match[1] : nil
  end

  def determine_colors(html)
    indicator_to_color = {
      "Red"   => "R",
      "Blue"  => "U",
      "Green" => "G",
      "White" => "W",
      "Black" => "B"
    }

    mana_cost = extract_mana_cost(html)
    match = mana_cost.join("").scan(/[ubrgw]/i) if mana_cost

    indicator = extract_color_indicator(html)
    if indicator
      card_colors = [indicator_to_color[indicator]]
    elsif match && match.length > 0
      card_colors = match.flatten.uniq
    else
      card_colors = ['colorless']
    end
    card_colors
  end

  def extract_rarity(html)
    match_data = /Rarity:<\/div>\s+<div class="value">\s+<span class=["']\w+["']>([\w\s]*)/
    match = html.match(match_data)[1]
  end

  def extract_transformed_multiverse_id(html)
    # Get the multiverse id of the transformed card, if one exists
    card_multiverse_id = extract_multiverse_id(html)
    multiverse_id_regex = /<img src="\.\.\/\.\.\/Handlers\/Image\.ashx\?multiverseid=(\d+)&amp;type=card/
    multiverse_ids_on_page = html.scan(multiverse_id_regex).flatten.uniq
    (multiverse_ids_on_page - [card_multiverse_id]).first
  end

end
