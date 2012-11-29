require 'rails/generators'

module MTGExtractor
  class MTGExtractorGenerator < ::Rails::Generators::Base
    include Rails::Generators::Migration
    source_root File.expand_path('../templates', __FILE__)

    desc "add the migrations"
    def self.next_migration_number(path)
      unless @prev_migration_nr
        @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      else
        @prev_migration_nr += 1
      end
      @prev_migration_nr.to_s
    end

    def create_migration_file
      migration_template "create_cards.rb", "db/migrate/create_cards.rb"
    end

    def copy_card_classes
      copy_file "card.rb", "app/models/card.rb"
      copy_file "set.rb", "app/models/set.rb"
      copy_file "card_type.rb", "app/models/card_type.rb"
    end
  end
end

