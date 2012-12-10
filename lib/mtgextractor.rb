require "card_extractor"
require "set_extractor"

require 'mtgextractor/rails/railtie' if defined?(Rails)
require 'mtgextractor/rails/engine' if defined?(Rails) && Rails.version >= '3.1'

module MTGExtractor
end
