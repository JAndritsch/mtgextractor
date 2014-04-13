
# Scrapes a Gatherer search page for a given set to return a list of card details
# pages for that set
module MTGExtractor
  class SetExtractor

    require 'restclient'
    require 'uri'
    require 'cgi'

    attr_accessor :name, :url

    CARDS_FOR_SET_URL = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?output=checklist&set=["escaped_set_name"]'

    def initialize(name)
      @name = name
      @url  = URI.encode(CARDS_FOR_SET_URL.gsub("escaped_set_name", name))
    end

    def get_card_urls
      ids = []
      response = RestClient.get(@url)
      extract_card_urls(response)
    end

    def extract_card_urls(html)
      match_data = /Card\/Details\.aspx\?multiverseid=(\d+)/
      multiverse_ids = html.scan(match_data).flatten.uniq
      multiverse_ids.collect {|id| "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{id}" }
    end

    def self.get_all_sets
      response = RestClient.get('http://gatherer.wizards.com/Pages/Default.aspx')
      set_select_regex = /<select name="ctl00\$ctl00\$MainContent\$Content\$SearchControls\$setAddText" id="ctl00_ctl00_MainContent_Content_SearchControls_setAddText">\s*(<option[^>]*>[^>]*<\/option>\s*)+<\/select>/
      set_regex = /value="([^"]+)"/

      set_select = response.match(set_select_regex)[0]
      set_select.scan(set_regex).flatten.map { |n| CGI.unescapeHTML(n) }
    end

  end
end
