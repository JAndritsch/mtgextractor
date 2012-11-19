# encoding: utf-8

require 'restclient'

# Scrapes a Gatherer card details page and extracts card info
# Issues:
#
#   Can't handle double-faced cards quite yet. It currently treats them as separate
#   cards, but includes both sides' oracle texts. There's also no link between
#   the sides.
#
#   It can't read oracle texts that follow the pattern "Words {image}". It is only
#   currently set up to handle "{image}: Words".
class CardExtractor
  
  attr_accessor :url

  def initialize(url)
    @url = url
  end

  def get_card_details
    response = RestClient.get(@url)
    card_details = {}
    card_details['gatherer_url'] = @url
    card_details['multiverse_id'] = extract_multiverse_id(@url)
    card_details['image_url'] = build_image_url(card_details['multiverse_id'])

    card_details['name'] = extract_name(response) 
    card_details['mana_cost'] = extract_mana_cost(response) 
    card_details['converted_cost'] = extract_converted_mana_cost(response) 
    card_details['types'] = extract_types(response) 
    card_details['oracle_text'] = extract_oracle_text(response) 
    card_details['power'] = extract_power(response) 
    card_details['toughness'] = extract_toughness(response) 
    card_details['loyalty'] = extract_loyalty(response) 
    card_details['color_indicator'] = extract_color_indicator(response)
    card_details['rarity'] = extract_rarity(response) 
    card_details['colors'] = determine_colors(card_details)
    card_details
  end

  def extract_multiverse_id(url)
    url.match(/multiverseid=(\d+)/)[1]
  end

  def build_image_url(id)
    "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{id}&type=card"
  end

  def extract_name(html)
    match_data = /<span id="ctl00_ctl00_ctl00_MainContent_SubContent_SubContentHeader_subtitleDisplay"[^>]*>([^<]+)/
    html.match(match_data)[1]
  end

  def extract_mana_cost(html)
    match_data = /<img src="\/Handlers\/Image\.ashx\?size=medium&amp;name=([a-zA-Z0-9]+)&amp/
    match = html.scan(match_data).flatten
    match.length > 0 ? match : nil
  end

  def extract_converted_mana_cost(html)
    match_data = /Converted Mana Cost:<\/div>\s+<div class="value">\s+(\d+)/
    match = html.match(match_data)
    match ? match[1] : 0
  end

  def extract_types(html)
    html = html.force_encoding("utf-8")
    match_data = /Types:<\/div>\s+<div class="value">\s+([a-zA-Z\s-—]+)<\/div>/
    html.match(match_data)[1]
  end

  def extract_oracle_text(html)
    match_data = /<div class="cardtextbox">(?:<img src="\/Handlers\/Image\.ashx\?size=small&amp;name=\w+&amp;type=symbol" alt="\w+" align="absbottom" \/>)*:*([^>]+)<\/div>/
    match = html.scan(match_data).flatten
    match.length > 0 ? match.join("\n") : ""
  end

  def extract_power(html)
    match_data = /P\/T:<\/div>\s+<div class="value">\s+(\d+) \/ \d+/
    match = html.match(match_data)
    match ? match[1] : nil
  end

  def extract_toughness(html)
    match_data = /P\/T:<\/div>\s+<div class="value">\s+\d+ \/ (\d+)/
    match = html.match(match_data)
    match ? match[1] : nil
  end

  def extract_loyalty(html)
    match_data = /Loyalty:<\/div>\s+<div class="value">\s+(\w+)<\/div>/
    match = html.match(match_data)
    match ? match[1] : nil
  end

  def extract_color_indicator(html)
    match_data = /Color Indicator:<\/div>\s+<div class="value">\s+(\w+)/
    match = html.match(match_data)
    match ? match[1] : nil
  end

  def determine_colors(card_details)
    indicator_to_color = {
      "Red"   => "R",
      "Blue"  => "U",
      "Green" => "G",
      "White" => "W",
      "Black" => "B"
    }

    mana_cost = card_details['mana_cost']
    match = mana_cost.join("").scan(/[ubrgw]/i) if mana_cost

    indicator = card_details['color_indicator']
    if indicator
      card_colors = [indicator_to_color[indicator]]
    elsif match.length > 0
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

end
