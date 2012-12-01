# encoding: utf-8


# Scrapes a Gatherer card details page and extracts card info
# Issues:
#
#   It can't read oracle texts that follow the pattern "Words {image}". It is only
#   currently set up to handle "{image}: Words".
#
#   NOTE: Cards that "flip" (e.g., Erayo, Soratami Ascendant, Kitsune Mystic, 
#   Callow Jushi) are not handled consistently in Gatherer. We will not try to
#   improve upon this tragedy; some things will therefore remain unsearchable.
#

module MTGExtractor
  class CardExtractor
    require 'restclient'

    attr_accessor :url

    def initialize(url)
      @url = url
    end

    def get_card_details
      response = RestClient.get(@url).force_encoding("utf-8")
      card_details = {}
      card_details['gatherer_url']         = @url
      card_details['multiverse_id']        = extract_multiverse_id(@url)
      card_details['image_url']            = build_image_url(card_details['multiverse_id'])
      card_details['name']                 = extract_name(response)
      card_details['mana_cost']            = extract_mana_cost(response)
      card_details['converted_cost']       = extract_converted_mana_cost(response)
      card_details['types']                = extract_types(response)
      card_details['oracle_text']          = extract_oracle_text(response)
      card_details['power']                = extract_power(response)
      card_details['toughness']            = extract_toughness(response)
      card_details['loyalty']              = extract_loyalty(response)
      card_details['rarity']               = extract_rarity(response)
      card_details['colors']               = determine_colors(response)
      card_details['transformed_id']       = extract_transformed_multiverse_id(response)

      card_details['page_html']            = response 
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
      # All other cards, allow for the possibility that it's a "flipping" (e.g.,
      # Erayo, Soratami Ascendant) or double-sided (e.g., Kruin Outlaw) card.
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
      if multipart_card?(html)
        card_types_regex = /Types:<\/div>\s+<div[^>]*>\s+([^>]+)<\/div>/
      else
        name = extract_name(html)
        card_types_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{name}.+?Types:<\/div>\s+<div[^>]*>\s+([^>]+)<\/div>)/m
      end
      card_types = html.match(card_types_regex)[1]
      if card_types
        card_types.split("—").collect {|type| type.strip.split(/\s+/)}.flatten
      else
        card_types
      end
    end

    def extract_oracle_text(html)
      # See remarks for #extract_mana_cost, above. Similar processing with respect
      # to double-sided cards is necessary here as well.
      card_html = html.gsub(/<div\s+class="cardtextbox"[^>]*><\/div>/, "")
      oracle_text = ""

      if !multipart_card?(html)
        name = extract_name(html)
        single_card_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{name}(.+?Expansion:)/m
          card_html = html.match(single_card_regex)[1]
      end

      if card_html.match(/Card Text:/)
        if card_html.match(/Flavor Text:/)
          oracle_regex = /Card Text:<\/div>(.+?)Flavor Text:/m
        else
          oracle_regex = /Card Text:<\/div>(.+?)Expansion:/m
        end
        oracle_html = card_html.match(oracle_regex)[1]

        oracle_text_regex = /<div.+?class="cardtextbox"[^>]*>(.+?)<\/div>/
          oracle_text = oracle_html.scan(oracle_text_regex).flatten.join("\n\n")
        oracle_text = oracle_text.gsub(/<\/?[ib]>|<\/div>/, '').strip

        # "flipping" card with side-by-side Gatherer display?
        if !extract_transformed_multiverse_id(html) and 
          html.match(/Card Name:.+Card Name:/m) and
          oracle_text.match(/\bflip\b/)
          # hack together the flipped version of the card html
          # and add it's oracle text to the unflipped oracle text
          flipped_name_regex = /Card Name:.+Card Name:<\/div>\s+<div[^>]*>\s+([^<]+)/m
          flipped_name = html.match(flipped_name_regex)[1]
          more_oracle_text = [flipped_name]

          flipped_card_regex = /Card Name:.+Card Name:(.+?)Expansion:/m
          card_html = html.match(flipped_card_regex)[1]
          name = extract_name(html)
          card_html = "<span id=\"ctl00_ctl00_ctl00_MainContent_SubContent_SubContentHeader_subtitleDisplay\">#{name}</span> <div>Card Name:</div> <div> #{name}#{card_html}"

          more_oracle_text.push(extract_types(card_html).join(' '))

          power = extract_power(card_html)
          if power
            toughness = extract_toughness(card_html)
            more_oracle_text.push("#{power} / #{toughness}")
          end

          flipped_oracle_text = card_html.scan(oracle_text_regex).flatten.join("\n\n")
          flipped_oracle_text = flipped_oracle_text.gsub(/<\/?[ib]>|<\/div>/, '').strip
          more_oracle_text.push(flipped_oracle_text)

          more_oracle_text = more_oracle_text.join("\n\n")
          oracle_text += "\n\n----\n\n#{more_oracle_text}"
        end

        mana_cost_regex = /<img src="\/Handlers\/Image\.ashx\?.*?name=([a-zA-Z0-9]+)[^>]*>/
          oracle_text.gsub!(mana_cost_regex, '{\1}')
      end

      oracle_text
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
      match_data = /Loyalty:<\/div>\s+<div[^>]*>\s+(\w+)<\/div>/
        match = html.match(match_data)
      match ? match[1] : nil
    end

    def extract_color_indicator(html)
      if !multipart_card?(html)
        name = extract_name(html)
        single_card_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{name}(.+?Expansion:)/m
          html = html.match(single_card_regex)[1]
      end

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
        card_colors = indicator_to_color[indicator]
      elsif match && match.length > 0
        card_colors = match.flatten.uniq.join
      else
        card_colors = ''
      end
      card_colors
    end

    def extract_rarity(html)
      match_data = /Rarity:<\/div>\s+<div[^>]*>\s+<span[^>]*>([\w\s]*)/
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

end
