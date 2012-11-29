require 'rails/railtie'

module MTGExtractor
  class Railtie < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |f| load f }
    end

    generators do
      require 'generators/mtgextractor_generator.rb'
    end
  end
end
