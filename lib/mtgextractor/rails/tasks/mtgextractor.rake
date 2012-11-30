require 'mtgextractor'
require 'yaml'
require "#{Rails.root}/app/models/mtg_card"
require "#{Rails.root}/app/models/mtg_set"
require "#{Rails.root}/app/models/mtg_type"
require "#{Rails.root}/app/models/mtg_card_type"

namespace 'mtgextractor' do
  desc 'Extracts every card in every set from Gatherer and saves it to the DB'
  task :update_all_sets do
    environment = ENV["RAILS_ENV"] || "development"
    database_yaml = YAML::load(File.open("#{Rails.root}/config/database.yml"))[environment]
    ActiveRecord::Base.establish_connection(database_yaml)

    all_sets = MTGExtractor::SetExtractor.get_all_sets
    all_sets.each do |set|
      process_set(set)
    end
  end

  desc 'Extracts every card in provided set from Gatherer and saves it to the DB'
  task :update_set do
    environment = ENV["RAILS_ENV"] || "development"
    database_yaml = YAML::load(File.open("#{Rails.root}/config/database.yml"))[environment]
    ActiveRecord::Base.establish_connection(database_yaml)

    process_set(ENV["SET"])
  end
end

private 

def process_set(set_name)
  set = MtgSet.find_or_create_by_name(:name => set_name)

  puts "====================================="
  puts "Processing set '#{set_name}'..."
  puts "====================================="
  card_urls = MTGExtractor::SetExtractor.new(set_name).get_card_detail_urls

  card_urls.each_with_index do |url, index|
    index += 1
    card_details = MTGExtractor::CardExtractor.new(url).get_card_details

    # Create/find and collect types
    types = []
    type_names = card_details['types']
    type_names.each do |type|
      types << MtgType.find_or_create_by_name(type)
    end

    # Storing mana cost as a string...bad idea?
    mana_cost = card_details['mana_cost'] ? card_details['mana_cost'].join(" ") : nil

    card = MtgCard.new(
      :name => card_details['name'],
      :gatherer_url => card_details['gatherer_url'],
      :multiverse_id => card_details['multiverse_id'],
      :image_url => card_details['image_url'],
      :mana_cost => mana_cost,
      :converted_cost => card_details['converted_cost'],
      :oracle_text => card_details['oracle_text'],
      :power => card_details['power'],
      :toughness => card_details['toughness'],
      :loyalty => card_details['loyalty'],
      :rarity => card_details['rarity'],
      :transformed_id => card_details['transformed_id'],
      :colors => card_details['colors']
    )

    card.mtg_set_id = set.id
    card.mtg_types = types
    card.save

    puts "#{index} / #{card_urls.count}: Processed card '#{card_details['name']}'"
  end

end
