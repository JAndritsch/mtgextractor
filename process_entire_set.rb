require './set_extractor'
require './card_extractor'

print "Enter the full set name you'd like to process: "
set = gets.chomp

puts "Processing set '#{set}'..."
card_urls = SetExtractor.new(set).get_card_detail_urls
puts "Found #{card_urls.count} cards in the set '#{set}'"

cards = []
card_urls.each_with_index do |url, index|
  index += 1
  card_details = CardExtractor.new(url).get_card_details
  puts "#{index} / #{card_urls.count}: Processed card '#{card_details['name']}'"
  cards << card_details
end

puts "DONE!"

