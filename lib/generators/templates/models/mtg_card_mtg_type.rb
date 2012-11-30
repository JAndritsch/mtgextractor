class MtgCardMtgType < ActiveRecord::Base
  belongs_to :mtg_types
  belongs_to :mtg_cards
end
