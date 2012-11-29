module MTGExtractor
  class Card

    attr_accessor :name, :converted_cost, :mana_cost, :oracle_text,
      :power, :toughness, :loyalty, :color, :gatherer_url, :image_url,
      :multiverse_id, :expansion, :expansion_symbol_url, :rarity,
      :transformed_id

    def initialize
    end

  end
end
