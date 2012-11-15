require 'restclient'
require 'uri'

# Scrapes a Gatherer search page for a given set to return a list of card details
# pages for that set
class SetExtractor

  attr_accessor :name, :url

  CARDS_FOR_SET_URL = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?output=checklist&set=["escaped_set_name"]'

  def initialize(name)
    @name = name
    @url  = URI.encode(CARDS_FOR_SET_URL.gsub("escaped_set_name", name))
  end
  
  def get_card_detail_urls
    ids = []
    response = RestClient.get(@url)
    extract_card_detail_urls(response)
  end

  private

  def extract_card_detail_urls(html)
    match_data = /Card\/Details\.aspx\?multiverseid=(\d+)/
    multiverse_ids = html.scan(match_data).flatten.uniq
    card_urls = []
    multiverse_ids.each {|id| card_urls << "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=#{id}" }
    card_urls
  end

end
