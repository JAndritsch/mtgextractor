require 'mtgextractor'
require 'yaml'
require "#{Rails.root}/app/models/mtg_card"
require "#{Rails.root}/app/models/mtg_set"
require "#{Rails.root}/app/models/mtg_type"
require "#{Rails.root}/app/models/mtg_card_type"

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

    # Create or find set
    set_name = ENV["SET"]
    set = MtgSet.find_or_create_by_name(:name => set_name)

    puts "Processing set '#{set_name}'..."
    card_urls = MTGExtractor::SetExtractor.new(set_name).get_card_detail_urls
    puts "Found #{card_urls.count} cards in the set '#{set_name}'"

    card_urls.each_with_index do |url, index|
      index += 1
      card_details = MTGExtractor::CardExtractor.new(url).get_card_details

      # Create/find and collect types
      types = []
      type_names = card_details['types']
      type_names.each do |type|
        types << MtgType.find_or_create_by_name(type)
      end
      
      # Create card
      card = MtgCard.new(:name => card_details['name'])
      card.mtg_set_id = set.id
      card.mtg_types = types
      card.save

      puts "#{index} / #{card_urls.count}: Processed card '#{card_details['name']}'"
    end
    
  end
end
