# Includes everything
require './lib/mtgextractor'

include RSpec::Matchers

SUPPORT_DIR = File.expand_path("support", File.dirname(__FILE__))
def read_gatherer_page(filename)
  File.open("#{SUPPORT_DIR}/#{filename}", "r") {|f| f.read }
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.color = true
end

