require 'mtgextractor'
require 'yaml'
require "#{Rails.root}/app/models/mtg_card"
require "#{Rails.root}/app/models/mtg_set"

namespace 'mtgextractor' do
  desc 'Extracts every card in every set from Gatherer and saves it to the DB'
  task :update_all_sets do
    # pending 
  end

  desc 'Extracts every card in provided set from Gatherer and saves it to the DB'
  task :update_set do
    environment = ENV["RAILS_ENV"] || "development"
    database_yaml = YAML::load(File.open("#{Rails.root}/config/database.yml"))[environment]
    ActiveRecord::Base.establish_connection(database_yaml)

    set_name = ENV["SET"]
    set = MtgSet.new(:name => set_name).save

    puts "Processing set '#{set_name}'..."
    card_urls = MTGExtractor::SetExtractor.new(set_name).get_card_detail_urls
    puts "Found #{card_urls.count} cards in the set '#{set_name}'"

    card_urls.each_with_index do |url, index|
      index += 1
      card_details = MTGExtractor::CardExtractor.new(url).get_card_details
      puts "#{index} / #{card_urls.count}: Processed card '#{card_details['name']}'"
      card = MtgCard.new(:name => card_details['name'])
      card.mtg_set_id = set.id
      card.save
    end
    
  end
end
