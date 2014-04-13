# encoding: utf-8

# NOTE: Cards that "flip" (e.g., Erayo, Soratami Ascendant, Kitsune Mystic, 
# Callow Jushi) are not handled consistently in Gatherer. We will not try to
# improve upon this tragedy; some things will therefore remain unsearchable.


module MTGExtractor
  class CardExtractor
    require 'restclient'

    if RUBY_PLATFORM == "java"
      require 'java'
    else
      require 'iconv' if RUBY_VERSION < "1.9.0"
    end

    attr_accessor :url, :card_details

    def initialize(url)
      @url = url
      @card_details = {}
      @card_details['gatherer_url']  = url
      @card_details['multiverse_id'] = extract_multiverse_id(url)
    end

    def parse_page
      @card_details['gatherer_image_url'] = build_image_url
      @card_details['name']               = extract_name
      @card_details['mana_cost']          = extract_mana_cost
      @card_details['converted_cost']     = extract_converted_mana_cost
      @card_details['types']              = extract_types
      @card_details['oracle_text']        = extract_oracle_text
      @card_details['flavor_text']        = extract_flavor_text
      @card_details['mark']               = extract_watermark
      @card_details['power']              = extract_power
      @card_details['toughness']          = extract_toughness
      @card_details['loyalty']            = extract_loyalty
      @card_details['rarity']             = extract_rarity
      @card_details['colors']             = determine_colors
      @card_details['transformed_id']     = extract_transformed_multiverse_id
      @card_details['artist']             = extract_artist
      @card_details['set_icon_url']       = extract_expansion_symbol_url

      @card_details
    end
    
    def get_card_details
      response = RestClient.get(url)
      @card_details['page_html']          = convert_to_utf_8(response)

      parse_page
    end
    
    def next_card_details
      namepart=@card_details['page_html'].lines.grep(/ctl00_ctl00_ctl00_MainContent_SubContent_SubContentHeader_subtitleDisplay/)*"\n"
      cardpart=@card_details['page_html'].split("End Card Details Table",2)[1]
      @card_details['page_html']=namepart+"\n"+cardpart
      
      parse_page
    end

    def extract_multiverse_id(url)
      url.match(/multiverseid=(\d+)/)[1]
    end

    def build_image_url
      "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=#{card_details['multiverse_id']}&type=card"
    end

    def extract_name(html=nil)
      match_data = /<span id="ctl00_ctl00_ctl00_MainContent_SubContent_SubContentHeader_subtitleDisplay"[^>]*>([^<]+)/
      page_html = html ? html : card_details['page_html']
      page_html.match(match_data)[1]
    end
    
    def regex_name(n=extract_name)
      n.
        sub("rathi Berserker","(AE|Æ|)rathi Berserker").
        gsub(/ +/,"\s*")
    end

    def multipart_card?
      extract_name.match(/\/\//) != nil
    end

    def extract_mana_cost
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
      if multipart_card?
        mana_cost = convert_mana_cost(card_details['page_html'])
      else
        mana_cost_group_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name}.+?Mana Cost:.+?<div[^>]*>(.+?)<\/div>/mi
        mana_cost_group = card_details['page_html'].match(mana_cost_group_regex)
        mana_cost = mana_cost_group ? convert_mana_cost(mana_cost_group[1]) : nil
      end
      mana_cost
    end

    def convert_mana_cost(html)
      mana_cost_regex = /<img src="\/Handlers\/Image\.ashx\?size=medium&amp;name=([a-zA-Z0-9]+)&amp/
      match = html.scan(mana_cost_regex).flatten
      match.length > 0 ? match.collect {|m| "{#{m}}"}.join('') : nil
    end

    def extract_converted_mana_cost
      # See remarks for #extract_mana_cost, above. Similar processing with respect
      # to double-sided cards is necessary here as well.
      if multipart_card?
        cmc = convert_converted_mana_cost(card_details['page_html'])
      else
        cmc_group_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name}.+?Converted Mana Cost:<\/div>\s+<div[^>]*>[^<]+/mi
        cmc_group = card_details['page_html'].match(cmc_group_regex)
        cmc = cmc_group ? convert_converted_mana_cost(cmc_group[0]) : nil
      end
      cmc
    end

    def convert_converted_mana_cost(html)
      cmc_regex = /Converted Mana Cost:<\/div>\s+<div[^>]*>\s+(\d+)/
      match = html.match(cmc_regex)
      match ? match[1] : "0"
    end

    def extract_types(html=nil)
      page_html = html ? html : card_details['page_html']
      if multipart_card?
        card_types_regex = /Types:<\/div>\s+<div[^>]*>\s+([^>]+)<\/div>/
      else
        name = extract_name(page_html)
        card_types_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name(name)}.+?Types:<\/div>\s+<div[^>]*>\s+([^>]+)<\/div>)/mi
      end
      card_types = page_html.match(card_types_regex)[1]
      if card_types
        card_types.split("—").collect {|type| type.strip.split(/\s+/)}.flatten
      else
        card_types
      end
    end

    def extract_oracle_text
      # See remarks for #extract_mana_cost, above. Similar processing with respect
      # to double-sided cards is necessary here as well.
      card_html = card_details['page_html'].gsub(/<div\s+class="cardtextbox"[^>]*><\/div>/, "")
      oracle_text = ""

      if !multipart_card?
        single_card_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name}(.+?Expansion:)/mi
        card_html = card_html.match(single_card_regex)[1]
      end

      if card_html.match(/Card Text:/)
        if card_html.match(/Flavor Text:/)
          oracle_regex = /Card Text:<\/div>(.+?)Flavor Text:/m
        elsif card_html.match(/Color Indicator:/)
          oracle_regex = /Card Text:<\/div>(.+?)Color Indicator:/m
        elsif card_html.match(/Watermark:/)
          oracle_regex = /Card Text:<\/div>(.+?)Watermark:/m
        elsif card_html.match(/P\/T:/)
          oracle_regex = /Card Text:<\/div>(.+?)P\/T:/m
        else
          oracle_regex = /Card Text:<\/div>(.+?)Expansion:/m
        end
        oracle_html = card_html.match(oracle_regex)[1]

        oracle_text_regex = /<div.+?class=['"]cardtextbox['"][^>]*>(.+?)<\/div>/
        oracle_text = oracle_html.scan(oracle_text_regex).flatten.join("\n\n")
        oracle_text = oracle_text.gsub(/<\/?[ib]>|<\/div>/, '').strip

        # "flipping" card with side-by-side Gatherer display?
        if !extract_transformed_multiverse_id and 
            card_details['page_html'].match(/Card Name:.+Card Name:/m) and
            oracle_text.match(/\bflip\b/)
          # hack together the flipped version of the card html
          # and add it's oracle text to the unflipped oracle text
          flipped_name_regex = /Card Name:.+Card Name:<\/div>\s+<div[^>]*>\s+([^<]+)/m
          flipped_name = card_details['page_html'].match(flipped_name_regex)[1]
          more_oracle_text = [flipped_name]

          flipped_card_regex = /Card Name:.+Card Name:(.+?)Expansion:/m
          card_html = card_details['page_html'].match(flipped_card_regex)[1]
          name = extract_name
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

    def extract_flavor_text
      flavor_text = ""
      card_html = card_details['page_html'].gsub(/<div\s+class="cardtextbox"[^>]*><\/div>/, "")

      if !multipart_card?
        single_card_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name}(.+?Expansion:)/mi
        card_html = card_html.match(single_card_regex)[1]
      end

      if card_html.match(/Flavor Text:/)
        if card_html.match(/Color Indicator:/)
          flavor_regex = /Flavor Text:<\/div>(.+?)Color Indicator:/m
        elsif card_html.match(/Watermark:/)
          flavor_regex = /Flavor Text:<\/div>(.+?)Watermark:/m
        elsif card_html.match(/P\/T:/)
          flavor_regex = /Flavor Text:<\/div>(.+?)P\/T:/m
        else
          flavor_regex = /Flavor Text:<\/div>(.+?)Expansion:/m
        end
        flavor_html = card_html.match(flavor_regex)[1]

        flavor_text_regex = /<div.+?class=['"]cardtextbox['"][^>]*>(.+?)<\/div>/
        flavor_text = flavor_html.scan(flavor_text_regex).flatten.join("\n\n")
        flavor_text = flavor_text.gsub(/<\/?[ib]>|<\/div>/, '').strip
      end

      flavor_text
    end

    def extract_watermark
      watermark_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name}.+?Watermark:<\/div>\s+<div class="value">\s+<div class="cardtextbox">(.+?)<\/div>)/mi
      match = card_details['page_html'].match(watermark_regex)
      match ? match[1].gsub(/<\/?[ib]>|<\/div>/, '').strip : nil
    end

    def extract_power(html=nil)
      page_html = html ? html : card_details['page_html']
      name = extract_name(page_html)
      creature_power_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name(name)}.+?P\/T:<\/div>\s+<div class="value">\s+(\d+) \/ \d+)/mi
      match = page_html.match(creature_power_regex)
      match ? match[1] : nil
    end

    def extract_toughness(html=nil)
      page_html = html ? html : card_details['page_html']
      name = extract_name(page_html)
      creature_toughness_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name(name)}.+?P\/T:<\/div>\s+<div class="value">\s+\d+ \/ (\d+))/mi
      match = page_html.match(creature_toughness_regex)
      match ? match[1] : nil
    end

    def extract_loyalty
      match_data = /Loyalty:<\/div>\s+<div[^>]*>\s+(\w+)<\/div>/
      match = card_details['page_html'].match(match_data)
      match ? match[1] : nil
    end

    def extract_color_indicator
      if !multipart_card?
        single_card_regex = /Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name}(.+?Expansion:)/mi
        html = card_details['page_html'].match(single_card_regex)[1]
      else
        html = card_details['page_html']
      end

      match_data = /Color Indicator:<\/div>\s+<div[^>]*>\s+(\w+)/
      match = html.match(match_data)
      match ? match[1] : nil
    end

    def determine_colors
      indicator_to_color = {
        "Red"   => "R",
        "Blue"  => "U",
        "Green" => "G",
        "White" => "W",
        "Black" => "B"
      }

      mana_cost = extract_mana_cost
      match = mana_cost.scan(/[ubrgw]/i) if mana_cost

      indicator = extract_color_indicator
      if indicator
        card_colors = indicator_to_color[indicator]
      elsif match && match.length > 0
        card_colors = match.flatten.uniq.join
      else
        card_colors = ''
      end
      card_colors
    end

    def extract_rarity
      match_data = /Rarity:<\/div>\s+<div[^>]*>\s+<span[^>]*>([\w\s]*)/
      match = card_details['page_html'].match(match_data)[1]
    end

    def extract_transformed_multiverse_id
      # Get the multiverse id of the transformed card, if one exists
      multiverse_id_regex = /<img src="\.\.\/\.\.\/Handlers\/Image\.ashx\?multiverseid=(\d+)&amp;type=card/
      multiverse_ids_on_page = card_details['page_html'].scan(multiverse_id_regex).flatten.uniq
      (multiverse_ids_on_page - [card_details['multiverse_id']]).first
    end

    def extract_artist
      artist_regex = /(?:Card Name:<\/div>\s+<div[^>]*>\s+#{regex_name}.+?artist=\[%22([^%]+)%22\])/mi
      match = card_details['page_html'].match(artist_regex)
      match ? match[1] : ""
    end

    def extract_expansion_symbol_url
      expansion_regex = /<div id="[^"]+?_currentSetSymbol">.+?<img .*?src="[^?]+\?([^"]+)/m
      qstring = card_details['page_html'].match(expansion_regex)[1].gsub(/&amp;/, "&")
      "http://gatherer.wizards.com/Handlers/Image.ashx?#{qstring}"
    end
    

    private

    # JRuby 1.7 (with MRI 1.9) or just MRI 1.9 can just use String#force_encoding
    # JRuby 1.6 (with MRI 1.8.7) will use the Java method of conversion
    # MRI (no JRuby) 1.8.7 needs Iconv
    def convert_to_utf_8(response)
      if RUBY_PLATFORM == "java"
        if RUBY_VERSION > "1.9.0"
          response.force_encoding("utf-8")
        else
          bytes = response.to_java_bytes
          converted_bytes = java.lang.String.new(bytes, "UTF-8").get_bytes("UTF-8")
          String.from_java_bytes(converted_bytes)
        end
      else
        if RUBY_VERSION > "1.9.0"
          response.force_encoding("utf-8")
        else
          ::Iconv.conv('UTF-8//IGNORE', 'UTF-8', response + ' ')[0..-2]
        end
      end
    end

  end


end
