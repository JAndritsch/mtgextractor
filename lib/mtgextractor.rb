require "card_extractor"
require "set_extractor"

if defined?(Rails)
  require 'railtie'
  require 'card'
  require 'set'
  require 'card_type'
end

module MTGExtractor
end
